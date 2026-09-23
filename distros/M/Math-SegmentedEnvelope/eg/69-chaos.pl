#!/usr/bin/env perl
# CHAOS: everything at once -- morphing torus + sphere + lattice + curtain + tree
# all sharing FBO trails, all driven by envelopes, all interacting
# The structure continuously transforms between geometric forms
#
# Requires: OpenGL::Modern, OpenGL::GLUT, OpenGL::Array
use strict;
use warnings;

BEGIN {
    eval { require OpenGL::Modern; OpenGL::Modern->import(':all'); 1 }
        or die "This example requires OpenGL::Modern\n";
    eval { require OpenGL::GLUT; OpenGL::GLUT->import(':all'); 1 }
        or die "This example requires OpenGL::GLUT\n";
    eval { require OpenGL::Array; 1 }
        or die "This example requires OpenGL::Array\n";
}

use Math::SegmentedEnvelope qw(env spline adsr perc);
use Time::HiRes qw(time);
use POSIX qw(tan floor);

srand(42);

my $W = 1000;
my $H = 800;
my $PI = 3.14159265358979323846;
my $samples = 60;
my $num_threads = 80;

# Master morph: controls what shape the whole structure is
# 0=sphere, 1=torus, 2=lattice explosion, 3=curtain drape, 4=tree, 5=vortex
my $num_forms = 6;
my $form_time = 4.0;  # seconds per form
my $trans_time = 2.0;  # seconds to morph between forms

# Thread profile envelopes
my @profiles = map {
    my $i = $_;
    env([[ map { sin($i * 1.7 + $_ * 0.8) * 0.5 + 0.5 } 0..4 ],
         [0.25, 0.25, 0.25, 0.25],
         [ map { sin($i * 2.3 + $_ * 1.1) * 3 } 0..3 ]],
        morpher_formula => 'smoothstep');
} 0 .. 7;
my @prof_vals = map { [$_->table($samples)] } @profiles;

# Beat envelope: rhythmic pulse
my $beat = env([[0.8, 1.3, 0.9, 1.2, 0.8], [0.15, 0.1, 0.15, 0.1], [3, -3, 3, -3]],
    morpher_formula => 'bounce_out', is_fold_over => 1);
my $beat_s = $beat->static;
my $beat_d = $beat->duration;

# Shaders (same FBO pipeline as before)
my $lv = <<'G';
#version 150
in vec3 aPos; in vec4 aColor; in float aThick;
out vec4 vColor; out float vThick;
uniform mat4 uMVP;
void main() { gl_Position=uMVP*vec4(aPos,1); vColor=aColor; vThick=aThick; }
G
my $lg = <<'G';
#version 150
layout(lines) in; layout(triangle_strip, max_vertices=4) out;
in vec4 vColor[]; in float vThick[];
out vec4 gC; out float gE;
uniform vec2 uR;
void main() {
    vec4 p0=gl_in[0].gl_Position,p1=gl_in[1].gl_Position;
    vec2 d=normalize(p1.xy/p1.w-p0.xy/p0.w),n=vec2(-d.y,d.x);
    float t0=vThick[0]/uR.y,t1=vThick[1]/uR.y;
    gC=vColor[0];gE=-1;gl_Position=vec4(p0.xy-n*t0*p0.w,p0.zw);EmitVertex();
    gC=vColor[0];gE=1;gl_Position=vec4(p0.xy+n*t0*p0.w,p0.zw);EmitVertex();
    gC=vColor[1];gE=-1;gl_Position=vec4(p1.xy-n*t1*p1.w,p1.zw);EmitVertex();
    gC=vColor[1];gE=1;gl_Position=vec4(p1.xy+n*t1*p1.w,p1.zw);EmitVertex();
    EndPrimitive();
}
G
my $lf = <<'G';
#version 150
in vec4 gC; in float gE; out vec4 o;
void main() { float d=abs(gE); o=vec4(gC.rgb+exp(-d*d*4.0)*0.4, gC.a*(1.0-smoothstep(0.3,1.0,d))); }
G
my $qv = <<'G';
#version 150
in vec2 aPos; out vec2 vUV;
void main() { gl_Position=vec4(aPos,0,1); vUV=aPos*0.5+0.5; }
G
my $ff = <<'G';
#version 150
in vec2 vUV; out vec4 o; uniform sampler2D uT; uniform float uD;
void main() { o=vec4(texture(uT,vUV).rgb*uD,1); }
G
my $bf = <<'G';
#version 150
in vec2 vUV; out vec4 o; uniform sampler2D uT; uniform vec2 uDir;
void main() {
    vec4 c=vec4(0);
    c+=texture(uT,vUV-uDir*3.0)*0.05; c+=texture(uT,vUV-uDir*2.0)*0.09;
    c+=texture(uT,vUV-uDir)*0.22; c+=texture(uT,vUV)*0.28;
    c+=texture(uT,vUV+uDir)*0.22; c+=texture(uT,vUV+uDir*2.0)*0.09;
    c+=texture(uT,vUV+uDir*3.0)*0.05; o=c;
}
G
my $bl = <<'G';
#version 150
in vec2 vUV; out vec4 o; uniform sampler2D uT;
void main() { o=texture(uT,vUV); }
G

my($pl,$pf,$pb,$pbl,$um,$ur,$uft,$ufd,$ubt,$ubd,$ublt);
my($vl,$bl2,$vq,$bq,$fa,$ta,$fb,$tb,$rd,$start);

sub cs{my($t,$s)=@_;my $h=glCreateShader($t);glShaderSource_p($h,$s);glCompileShader($h);
    my($o)=glGetShaderiv_p($h,GL_COMPILE_STATUS);die "S: ".glGetShaderInfoLog_p($h)unless $o;$h}
sub lp{my @s=@_;my $p=glCreateProgram();glAttachShader($p,$_)for@s;glLinkProgram($p);
    my($o)=glGetProgramiv_p($p,GL_LINK_STATUS);die "L: ".glGetProgramInfoLog_p($p)unless $o;
    glDeleteShader($_)for@s;$p}
sub m4p{my($f,$a,$n,$r)=@_;my $t=1/tan($f*$PI/360);my @m=(0)x16;$m[0]=$t/$a;$m[5]=$t;
    $m[10]=($r+$n)/($n-$r);$m[11]=-1;$m[14]=2*$r*$n/($n-$r);@m}
sub m4l{my($ex,$ey,$ez,$cx,$cy,$cz,$ux,$uy,$uz)=@_;
    my @f=($cx-$ex,$cy-$ey,$cz-$ez);my $l=sqrt($f[0]**2+$f[1]**2+$f[2]**2);@f=map{$_/$l}@f;
    my @s=($f[1]*$uz-$f[2]*$uy,$f[2]*$ux-$f[0]*$uz,$f[0]*$uy-$f[1]*$ux);
    $l=sqrt($s[0]**2+$s[1]**2+$s[2]**2);@s=map{$_/$l}@s;
    my @u=($s[1]*$f[2]-$s[2]*$f[1],$s[2]*$f[0]-$s[0]*$f[2],$s[0]*$f[1]-$s[1]*$f[0]);
    ($s[0],$u[0],-$f[0],0,$s[1],$u[1],-$f[1],0,$s[2],$u[2],-$f[2],0,
     -($s[0]*$ex+$s[1]*$ey+$s[2]*$ez),-($u[0]*$ex+$u[1]*$ey+$u[2]*$ez),
     $f[0]*$ex+$f[1]*$ey+$f[2]*$ez,1)}
sub m4m{my($a,$b)=@_;my @r=(0)x16;for my $i(0..3){for my $j(0..3){for my $k(0..3){
    $r[$j*4+$i]+=$a->[$k*4+$i]*$b->[$j*4+$k]}}}@r}
sub hsv{my($h,$s,$v)=@_;$h=($h-floor($h))*6;my $f=$h-floor($h);
    my $p=$v*(1-$s);my $q=$v*(1-$s*$f);my $t=$v*(1-$s*(1-$f));
    my @c=([$v,$t,$p],[$q,$v,$p],[$p,$v,$t],[$p,$q,$v],[$t,$p,$v],[$v,$p,$q]);@{$c[int($h)%6]}}
sub fm{$_[0]-floor($_[0]/$_[1])*$_[1]}
sub dq{glBindVertexArray($vq);glDrawArrays(GL_TRIANGLE_STRIP,0,4);glBindVertexArray(0)}

# Thread position generators for each form
sub pos_sphere  { my($th,$s,$t,$b)=@_;my $phi=acos(1-2*($th+0.5)/$num_threads);my $theta=$th*2.399+$t*0.3;
    my $r=1.2*$b;($r*sin($phi)*cos($theta+$s*6),$r*cos($phi)+sin($s*$PI*2+$t)*0.1*$b,$r*sin($phi)*sin($theta+$s*6)) }
sub pos_torus   { my($th,$s,$t,$b)=@_;my $u=$s*2*$PI+$th/$num_threads*2*$PI;my $v=$s*5*2*$PI+$th*0.5;
    my $R=1.0*$b;my $r=0.4*$b;(($R+$r*cos($v))*cos($u),$r*sin($v),($R+$r*cos($v))*sin($u)) }
sub pos_lattice { my($th,$s,$t,$b)=@_;my $golden=$PI*(3-sqrt(5));my $theta=$th*$golden;my $phi=acos(1-2*($th+0.5)/$num_threads);
    my $dx=sin($phi)*cos($theta);my $dy=cos($phi);my $dz=sin($phi)*sin($theta);
    my $r=$s*2.0*$b;($dx*$r+sin($t*2+$s*3)*0.1,$dy*$r,$dz*$r) }
sub pos_curtain { my($th,$s,$t,$b)=@_;my $x=($th/$num_threads-0.5)*4;my $v=$s;
    my $sway=sin($th*0.17+$t*1.5+$v*3)*$v*$v*0.3*$b;($x+$sway*0.3,-$v*2.5*$b,$sway) }
sub pos_tree    { my($th,$s,$t,$b)=@_;my $angle=$th/$num_threads*2*$PI;my $spread=$s*0.8+0.2;
    my $r=$spread*$b*sin($s*$PI*0.7);my $y=$s*2.5*$b;
    ($r*cos($angle+$s*2+sin($t+$th)*0.3),$y,$r*sin($angle+$s*2+sin($t+$th)*0.3)) }
sub pos_vortex  { my($th,$s,$t,$b)=@_;my $angle=$th/$num_threads*2*$PI+$s*3.5*2*$PI+$t*0.8;
    my $r=(1-$s)*2.0*$b;my $depth=$s*$s*3;($r*cos($angle),-$depth,$r*sin($angle)) }

my @forms = (\&pos_sphere, \&pos_torus, \&pos_lattice, \&pos_curtain, \&pos_tree, \&pos_vortex);
my @form_names = qw(sphere torus lattice curtain tree vortex);

sub acos { atan2(sqrt(1-$_[0]*$_[0]),$_[0]) }

sub init_gl {
    $pl=lp(cs(GL_VERTEX_SHADER,$lv),cs(GL_GEOMETRY_SHADER,$lg),cs(GL_FRAGMENT_SHADER,$lf));
    $um=glGetUniformLocation($pl,'uMVP');$ur=glGetUniformLocation($pl,'uR');
    $pf=lp(cs(GL_VERTEX_SHADER,$qv),cs(GL_FRAGMENT_SHADER,$ff));
    glUseProgram($pf);$uft=glGetUniformLocation($pf,'uT');$ufd=glGetUniformLocation($pf,'uD');
    $pb=lp(cs(GL_VERTEX_SHADER,$qv),cs(GL_FRAGMENT_SHADER,$bf));
    glUseProgram($pb);$ubt=glGetUniformLocation($pb,'uT');$ubd=glGetUniformLocation($pb,'uDir');
    $pbl=lp(cs(GL_VERTEX_SHADER,$qv),cs(GL_FRAGMENT_SHADER,$bl));
    glUseProgram($pbl);$ublt=glGetUniformLocation($pbl,'uT');

    ($vl)=glGenVertexArrays_p(1);($bl2)=glGenBuffers_p(1);
    ($vq)=glGenVertexArrays_p(1);($bq)=glGenBuffers_p(1);
    glBindVertexArray($vq);glBindBuffer(GL_ARRAY_BUFFER,$bq);
    my $qa=OpenGL::Array->new_list(GL_FLOAT,-1,-1,1,-1,-1,1,1,1);
    glBufferData_c(GL_ARRAY_BUFFER,$qa->length,$qa->ptr,GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);glVertexAttribPointer_c(0,2,GL_FLOAT,GL_FALSE,0,0);glBindVertexArray(0);

    for([\$fa,\$ta],[\$fb,\$tb]){(${$_->[1]})=glGenTextures_p(1);glBindTexture(GL_TEXTURE_2D,${$_->[1]});
        glTexImage2D_c(GL_TEXTURE_2D,0,GL_RGBA16F,$W,$H,0,GL_RGBA,GL_FLOAT,0);
        glTexParameteri(GL_TEXTURE_2D,$_,GL_LINEAR)for GL_TEXTURE_MIN_FILTER,GL_TEXTURE_MAG_FILTER;
        glTexParameteri(GL_TEXTURE_2D,$_,GL_CLAMP_TO_EDGE)for GL_TEXTURE_WRAP_S,GL_TEXTURE_WRAP_T;
        (${$_->[0]})=glGenFramebuffers_p(1);glBindFramebuffer(GL_FRAMEBUFFER,${$_->[0]});
        glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,${$_->[1]},0)}
    ($rd)=glGenRenderbuffers_p(1);glBindRenderbuffer(GL_RENDERBUFFER,$rd);
    glRenderbufferStorage(GL_RENDERBUFFER,GL_DEPTH_COMPONENT24,$W,$H);
    for($fa,$fb){glBindFramebuffer(GL_FRAMEBUFFER,$_);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER,GL_DEPTH_ATTACHMENT,GL_RENDERBUFFER,$rd);
        glClearColor(0.01,0.01,0.02,1);glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT)}
    glBindFramebuffer(GL_FRAMEBUFFER,0);
    glEnable(GL_BLEND);glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    $start=time();
}

sub display {
    my $t=time()-$start;
    my $b=$beat_s->(fm($t*0.7,$beat_d));

    # Which two forms are we morphing between?
    my $cycle=$form_time+$trans_time;
    my $total=$cycle*$num_forms;
    my $phase=$t-floor($t/$total)*$total;
    my $fi=int($phase/$cycle)%$num_forms;
    my $in_shape=$phase-$fi*$cycle;
    my($form_a,$form_b,$mix);
    if($in_shape<$form_time){$form_a=$forms[$fi];$form_b=$form_a;$mix=0}
    else{$form_a=$forms[$fi];$form_b=$forms[($fi+1)%$num_forms];$mix=($in_shape-$form_time)/$trans_time;$mix=$mix*$mix*(3-2*$mix)}

    # FBO: fade
    glBindFramebuffer(GL_FRAMEBUFFER,$fb);glDisable(GL_DEPTH_TEST);
    glUseProgram($pf);glActiveTexture(GL_TEXTURE0);glBindTexture(GL_TEXTURE_2D,$ta);
    glUniform1i($uft,0);glUniform1f($ufd,0.91);dq();
    # blur
    glBindFramebuffer(GL_FRAMEBUFFER,$fa);glUseProgram($pb);
    glBindTexture(GL_TEXTURE_2D,$tb);glUniform1i($ubt,0);glUniform2f($ubd,2.0/$W,0);dq();
    glBindFramebuffer(GL_FRAMEBUFFER,$fb);glBindTexture(GL_TEXTURE_2D,$ta);glUniform2f($ubd,0,2.0/$H);dq();
    glBindFramebuffer(GL_FRAMEBUFFER,$fa);glUseProgram($pbl);
    glBindTexture(GL_TEXTURE_2D,$tb);glUniform1i($ublt,0);dq();

    # Draw
    glEnable(GL_DEPTH_TEST);glClear(GL_DEPTH_BUFFER_BIT);glUseProgram($pl);
    my $ca=$t*0.2;my $ch=1.5+sin($t*0.13)*0.8;
    my @proj=m4p(55,$W/$H,0.01,20);my @view=m4l(cos($ca)*3.5,$ch,sin($ca)*3.5,0,0,0,0,1,0);
    my @mvp=m4m(\@proj,\@view);my $m=OpenGL::Array->new_list(GL_FLOAT,@mvp);
    glUniformMatrix4fv_c($um,1,GL_FALSE,$m->ptr);glUniform2f($ur,$W,$H);

    my(@verts,@cmds,$total2);$total2=0;
    for my $th(0..$num_threads-1){
        my @pv=@{$prof_vals[$th%@prof_vals]};
        my $hue=$th/$num_threads+$t*0.03;
        my $phase_off=$t*0.3+$th*0.1;

        for my $j(0..$samples-1){
            my $s=$j/($samples-1);
            my $pval=$pv[$j]*$b;

            # Get positions from both forms and lerp
            my @pa=$form_a->($th,$s,$t,$b);
            my @pb2=$form_b->($th,$s,$t,$b);
            my $x=$pa[0]*(1-$mix)+$pb2[0]*$mix;
            my $y=$pa[1]*(1-$mix)+$pb2[1]*$mix;
            my $z=$pa[2]*(1-$mix)+$pb2[2]*$mix;

            # Envelope displacement (perpendicular wobble)
            my $wobble=$pval*0.1*sin($phase_off+$s*7);
            $x+=$wobble;$y+=$wobble*0.5;

            my($cr,$cg,$cb)=hsv($hue+$s*0.2+$mix*0.1,0.7,0.4+$pval*0.5);
            my $thick=1.5+$pval*8;
            push @verts,$x,$y,$z,$cr,$cg,$cb,0.85,$thick;
        }
        push @cmds,[$total2,$samples];$total2+=$samples;
    }

    my $stride=8*4;my $oa=OpenGL::Array->new_list(GL_FLOAT,@verts);
    glBindVertexArray($vl);glBindBuffer(GL_ARRAY_BUFFER,$bl2);
    glBufferData_c(GL_ARRAY_BUFFER,$oa->length,$oa->ptr,GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(0);glVertexAttribPointer_c(0,3,GL_FLOAT,GL_FALSE,$stride,0);
    glEnableVertexAttribArray(1);glVertexAttribPointer_c(1,4,GL_FLOAT,GL_FALSE,$stride,3*4);
    glEnableVertexAttribArray(2);glVertexAttribPointer_c(2,1,GL_FLOAT,GL_FALSE,$stride,7*4);
    glDrawArrays(GL_LINE_STRIP,$_->[0],$_->[1])for@cmds;
    glDisableVertexAttribArray($_)for 0..2;glBindVertexArray(0);

    # Blit
    glBindFramebuffer(GL_FRAMEBUFFER,0);glDisable(GL_DEPTH_TEST);glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram($pbl);glActiveTexture(GL_TEXTURE0);glBindTexture(GL_TEXTURE_2D,$ta);
    glUniform1i($ublt,0);dq();glEnable(GL_DEPTH_TEST);

    # Show form name
    glutSetWindowTitle(sprintf "CHAOS: %s -> %s (%.0f%%) — ESC to quit",
        $form_names[$fi], $form_names[($fi+1)%$num_forms], $mix*100);

    glutSwapBuffers();
}

sub idle{glutPostRedisplay()}
sub keyboard{exit(0)if ord($_[0])==27}

glutInit();
glutInitDisplayMode(GLUT_DOUBLE|GLUT_RGBA|GLUT_DEPTH|GLUT_MULTISAMPLE);

glutInitWindowSize($W,$H);glutCreateWindow('CHAOS');
init_gl();glutDisplayFunc(\&display);glutIdleFunc(\&idle);glutKeyboardFunc(\&keyboard);
printf "CHAOS: %d threads, 6 forms, FBO trails+blur, beat-driven — ESC to quit\n",$num_threads;
glutMainLoop();
