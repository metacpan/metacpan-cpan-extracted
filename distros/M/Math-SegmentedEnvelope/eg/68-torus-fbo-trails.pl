#!/usr/bin/env perl
# Torus FBO trails: envelope pairs encode (u,v) coordinates on a torus surface
# u-envelope = toroidal angle (around hole), v-envelope = poloidal angle (around tube)
# Each arm traces a unique path on the torus, morphing between 8 keyframes
# FBO pipeline: fade + blur for glowing motion trails
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

my $W = 900;
my $H = 700;
my $PI = 3.14159265358979323846;
my $num_arms = 32;
my $samples = 100;
my $major_r = 1.0;
my $minor_r = 0.4;

# U envelopes: toroidal angle paths (how the arm goes around the hole)
my @u_envs = (
    env([[0, 6.28], [1], [1]]),                                        # full loop
    spline([0, 0.3, 0.7, 1.0], [0, 4.0, 2.0, 6.28]),                # fast-slow-fast
    env([[0, 12.57], [1], [2]], morpher_formula => 'cubic_in'),        # accelerating double loop
    env([[0, -3.14, 6.28], [0.5, 0.5], [2, -2]],
        morpher_formula => 'smoothstep'),                               # reverse then forward
    spline([0, 0.2, 0.5, 0.8, 1.0], [0, 3.14, -1.0, 5.0, 6.28]),   # wobbly
    env([[0, 6.28, 0, 6.28], [0.33, 0.34, 0.33], [3, -3, 3]],
        morpher_formula => 'elastic_out'),                              # elastic
    env([[0, 9.42, 3.14, 12.57], [0.3, 0.4, 0.3], [2, -2, 2]]),     # spiral overshoot
    spline([0, 0.25, 0.5, 0.75, 1.0], [0, -6.28, 3.14, -3.14, 6.28]), # zigzag
);

# V envelopes: poloidal angle paths (how the arm wraps around the tube)
my @v_envs = (
    env([[0, 6.28], [1], [1]]),                                        # full loop around tube
    env([[0, 18.85], [1], [1]]),                                       # 3 wraps (helix)
    spline([0, 0.3, 0.7, 1.0], [0, 12.57, 6.28, 18.85]),            # varying helix
    env([[0, 6.28, 0], [0.5, 0.5], [2, -2]],
        morpher_formula => 'smoothstep'),                               # loop and unloop
    env([[0, -6.28, 12.57], [0.5, 0.5], [-2, 3]],
        morpher_formula => 'bounce_out'),                               # bounce wrap
    spline([0, 0.2, 0.5, 0.8, 1.0], [0, 3.14, 0, -3.14, 0]),       # figure-eight around tube
    env([[0, 25.13], [1], [3]], morpher_formula => 'cubic_in'),        # accelerating 4-wrap
    env([[0, 12.57, 0, 12.57], [0.33, 0.34, 0.33], [2, -2, 2]],
        morpher_formula => 'sine'),                                     # pulsing helix
);

my @u_keys = map { [$_->table($samples)] } @u_envs;
my @v_keys = map { [$_->table($samples)] } @v_envs;
my $n_u = scalar @u_keys;
my $n_v = scalar @v_keys;
my $morph_sec = 5.0;

# Lift envelope: how far above/below the torus surface
my $lift_env = env([[0, 0.05, -0.03, 0.04, 0], [0.25, 0.25, 0.25, 0.25], [2, -2, 2, -2]],
    morpher_formula => 'smoothstep', is_fold_over => 1);
my $lift_vals = [$lift_env->table($samples)];

my $pulse = env([[1.0, 1.05, 1.0], [0.5, 0.5], [2, -2]],
    morpher_formula => 'smoothstep', is_fold_over => 1);
my $pulse_s = $pulse->static;
my $pulse_d = $pulse->duration;

sub lerp_samples {
    my ($a,$b,$mx)=@_;my @r;
    push @r, $a->[$_]*(1-$mx)+$b->[$_]*$mx for 0..$#$a;\@r;
}
sub morph_bank {
    my ($keys,$n,$t,$off)=@_;
    my $ph=($t/$morph_sec+$off)*$n;$ph-=floor($ph/$n)*$n;
    my $ia=int($ph)%$n;my $ib=($ia+1)%$n;
    my $mx=$ph-floor($ph);$mx=$mx*$mx*(3-2*$mx);
    lerp_samples($keys->[$ia],$keys->[$ib],$mx);
}

sub torus_point {
    my ($u,$v,$R,$r)=@_;
    (($R+$r*cos($v))*cos($u), $r*sin($v), ($R+$r*cos($v))*sin($u));
}

# === Shaders ===
my $lattice_vert = <<'GLSL';
#version 150
in vec3 aPos; in vec4 aColor; in float aThick;
out VS_OUT { vec4 color; float thick; } vs_out;
uniform mat4 uMVP;
void main() { gl_Position=uMVP*vec4(aPos,1.0); vs_out.color=aColor; vs_out.thick=aThick; }
GLSL

my $lattice_geom = <<'GLSL';
#version 150
layout(lines) in; layout(triangle_strip, max_vertices=4) out;
in VS_OUT { vec4 color; float thick; } gs_in[];
out vec4 gColor; out float gEdge;
uniform vec2 uResolution;
void main() {
    vec4 p0=gl_in[0].gl_Position,p1=gl_in[1].gl_Position;
    vec2 d=normalize(p1.xy/p1.w-p0.xy/p0.w),n=vec2(-d.y,d.x);
    float t0=gs_in[0].thick/uResolution.y,t1=gs_in[1].thick/uResolution.y;
    gColor=gs_in[0].color;gEdge=-1.0;gl_Position=vec4(p0.xy-n*t0*p0.w,p0.zw);EmitVertex();
    gColor=gs_in[0].color;gEdge=1.0;gl_Position=vec4(p0.xy+n*t0*p0.w,p0.zw);EmitVertex();
    gColor=gs_in[1].color;gEdge=-1.0;gl_Position=vec4(p1.xy-n*t1*p1.w,p1.zw);EmitVertex();
    gColor=gs_in[1].color;gEdge=1.0;gl_Position=vec4(p1.xy+n*t1*p1.w,p1.zw);EmitVertex();
    EndPrimitive();
}
GLSL

my $lattice_frag = <<'GLSL';
#version 150
in vec4 gColor; in float gEdge; out vec4 outColor;
void main() {
    float d=abs(gEdge);
    float alpha=1.0-smoothstep(0.4,1.0,d);
    float glow=exp(-d*d*5.0)*0.3;
    outColor=vec4(gColor.rgb+glow,gColor.a*alpha);
}
GLSL

my $quad_vert = <<'GLSL';
#version 150
in vec2 aPos; out vec2 vUV;
void main() { gl_Position=vec4(aPos,0,1); vUV=aPos*0.5+0.5; }
GLSL

my $fade_frag = <<'GLSL';
#version 150
in vec2 vUV; out vec4 outColor;
uniform sampler2D uTex; uniform float uDecay;
void main() { vec4 c=texture(uTex,vUV); outColor=vec4(c.rgb*uDecay,1.0); }
GLSL

my $blur_frag = <<'GLSL';
#version 150
in vec2 vUV; out vec4 outColor;
uniform sampler2D uTex; uniform vec2 uDir;
void main() {
    vec4 c=vec4(0);
    c+=texture(uTex,vUV-uDir*2.0)*0.06;
    c+=texture(uTex,vUV-uDir)*0.24;
    c+=texture(uTex,vUV)*0.40;
    c+=texture(uTex,vUV+uDir)*0.24;
    c+=texture(uTex,vUV+uDir*2.0)*0.06;
    outColor=c;
}
GLSL

my $blit_frag = <<'GLSL';
#version 150
in vec2 vUV; out vec4 outColor;
uniform sampler2D uTex;
void main() { outColor=texture(uTex,vUV); }
GLSL

my ($prog_lat,$prog_fade,$prog_blur,$prog_blit);
my ($u_mvp,$u_res,$u_ft,$u_fd,$u_bt,$u_bd,$u_blt);
my ($vao_l,$vbo_l,$vao_q,$vbo_q);
my ($fbo_a,$tex_a,$fbo_b,$tex_b,$rbo,$start);

sub cs { my($t,$s)=@_;my $sh=glCreateShader($t);glShaderSource_p($sh,$s);glCompileShader($sh);
    my($ok)=glGetShaderiv_p($sh,GL_COMPILE_STATUS);die "Sh: ".glGetShaderInfoLog_p($sh) unless $ok;$sh }
sub lp { my @s=@_;my $p=glCreateProgram();glAttachShader($p,$_)for@s;glLinkProgram($p);
    my($ok)=glGetProgramiv_p($p,GL_LINK_STATUS);die "Lk: ".glGetProgramInfoLog_p($p) unless $ok;
    glDeleteShader($_)for@s;$p }
sub m4p { my($fov,$asp,$n,$f)=@_;my $t=1/tan($fov*$PI/360);my @m=(0)x16;$m[0]=$t/$asp;$m[5]=$t;
    $m[10]=($f+$n)/($n-$f);$m[11]=-1;$m[14]=2*$f*$n/($n-$f);@m }
sub m4l { my($ex,$ey,$ez,$cx,$cy,$cz,$ux,$uy,$uz)=@_;
    my @f=($cx-$ex,$cy-$ey,$cz-$ez);my $l=sqrt($f[0]**2+$f[1]**2+$f[2]**2);@f=map{$_/$l}@f;
    my @s=($f[1]*$uz-$f[2]*$uy,$f[2]*$ux-$f[0]*$uz,$f[0]*$uy-$f[1]*$ux);
    $l=sqrt($s[0]**2+$s[1]**2+$s[2]**2);@s=map{$_/$l}@s;
    my @u=($s[1]*$f[2]-$s[2]*$f[1],$s[2]*$f[0]-$s[0]*$f[2],$s[0]*$f[1]-$s[1]*$f[0]);
    ($s[0],$u[0],-$f[0],0,$s[1],$u[1],-$f[1],0,$s[2],$u[2],-$f[2],0,
     -($s[0]*$ex+$s[1]*$ey+$s[2]*$ez),-($u[0]*$ex+$u[1]*$ey+$u[2]*$ez),
     $f[0]*$ex+$f[1]*$ey+$f[2]*$ez,1) }
sub m4m { my($a,$b)=@_;my @r=(0)x16;for my $i(0..3){for my $j(0..3){for my $k(0..3){
    $r[$j*4+$i]+=$a->[$k*4+$i]*$b->[$j*4+$k]}}}@r }
sub hsv { my($h,$s,$v)=@_;$h=($h-floor($h))*6;my $f=$h-floor($h);
    my $p=$v*(1-$s);my $q=$v*(1-$s*$f);my $t=$v*(1-$s*(1-$f));
    my @c=([$v,$t,$p],[$q,$v,$p],[$p,$v,$t],[$p,$q,$v],[$t,$p,$v],[$v,$p,$q]);@{$c[int($h)%6]} }
sub fmod { $_[0]-floor($_[0]/$_[1])*$_[1] }
sub dq { glBindVertexArray($vao_q);glDrawArrays(GL_TRIANGLE_STRIP,0,4);glBindVertexArray(0) }

sub init_gl {
    $prog_lat=lp(cs(GL_VERTEX_SHADER,$lattice_vert),cs(GL_GEOMETRY_SHADER,$lattice_geom),cs(GL_FRAGMENT_SHADER,$lattice_frag));
    $u_mvp=glGetUniformLocation($prog_lat,'uMVP');$u_res=glGetUniformLocation($prog_lat,'uResolution');
    $prog_fade=lp(cs(GL_VERTEX_SHADER,$quad_vert),cs(GL_FRAGMENT_SHADER,$fade_frag));
    glUseProgram($prog_fade);$u_ft=glGetUniformLocation($prog_fade,'uTex');$u_fd=glGetUniformLocation($prog_fade,'uDecay');
    $prog_blur=lp(cs(GL_VERTEX_SHADER,$quad_vert),cs(GL_FRAGMENT_SHADER,$blur_frag));
    glUseProgram($prog_blur);$u_bt=glGetUniformLocation($prog_blur,'uTex');$u_bd=glGetUniformLocation($prog_blur,'uDir');
    $prog_blit=lp(cs(GL_VERTEX_SHADER,$quad_vert),cs(GL_FRAGMENT_SHADER,$blit_frag));
    glUseProgram($prog_blit);$u_blt=glGetUniformLocation($prog_blit,'uTex');

    ($vao_l)=glGenVertexArrays_p(1);($vbo_l)=glGenBuffers_p(1);
    ($vao_q)=glGenVertexArrays_p(1);($vbo_q)=glGenBuffers_p(1);
    glBindVertexArray($vao_q);glBindBuffer(GL_ARRAY_BUFFER,$vbo_q);
    my $qa=OpenGL::Array->new_list(GL_FLOAT,-1,-1,1,-1,-1,1,1,1);
    glBufferData_c(GL_ARRAY_BUFFER,$qa->length,$qa->ptr,GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);glVertexAttribPointer_c(0,2,GL_FLOAT,GL_FALSE,0,0);glBindVertexArray(0);

    for my $p ([\$fbo_a,\$tex_a],[\$fbo_b,\$tex_b]) {
        (${$p->[1]})=glGenTextures_p(1);glBindTexture(GL_TEXTURE_2D,${$p->[1]});
        glTexImage2D_c(GL_TEXTURE_2D,0,GL_RGBA16F,$W,$H,0,GL_RGBA,GL_FLOAT,0);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
        (${$p->[0]})=glGenFramebuffers_p(1);glBindFramebuffer(GL_FRAMEBUFFER,${$p->[0]});
        glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,${$p->[1]},0);
    }
    ($rbo)=glGenRenderbuffers_p(1);glBindRenderbuffer(GL_RENDERBUFFER,$rbo);
    glRenderbufferStorage(GL_RENDERBUFFER,GL_DEPTH_COMPONENT24,$W,$H);
    for my $f($fbo_a,$fbo_b) {
        glBindFramebuffer(GL_FRAMEBUFFER,$f);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER,GL_DEPTH_ATTACHMENT,GL_RENDERBUFFER,$rbo);
        glClearColor(0.02,0.015,0.04,1);glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    }
    glBindFramebuffer(GL_FRAMEBUFFER,0);
    glEnable(GL_BLEND);glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    $start=time();
}

sub display {
    my $t=time()-$start;
    my $p=$pulse_s->(fmod($t*0.3,$pulse_d));
    my $R=$major_r*$p;my $r=$minor_r*$p;

    # Pass 1: fade
    glBindFramebuffer(GL_FRAMEBUFFER,$fbo_b);glDisable(GL_DEPTH_TEST);
    glUseProgram($prog_fade);glActiveTexture(GL_TEXTURE0);glBindTexture(GL_TEXTURE_2D,$tex_a);
    glUniform1i($u_ft,0);glUniform1f($u_fd,0.93);dq();
    # Pass 2: blur H
    glBindFramebuffer(GL_FRAMEBUFFER,$fbo_a);glUseProgram($prog_blur);
    glBindTexture(GL_TEXTURE_2D,$tex_b);glUniform1i($u_bt,0);glUniform2f($u_bd,1.5/$W,0);dq();
    # Blur V
    glBindFramebuffer(GL_FRAMEBUFFER,$fbo_b);glBindTexture(GL_TEXTURE_2D,$tex_a);glUniform2f($u_bd,0,1.5/$H);dq();
    # Copy back
    glBindFramebuffer(GL_FRAMEBUFFER,$fbo_a);glUseProgram($prog_blit);
    glBindTexture(GL_TEXTURE_2D,$tex_b);glUniform1i($u_blt,0);dq();

    # Pass 3: draw lattice on torus
    glEnable(GL_DEPTH_TEST);glClear(GL_DEPTH_BUFFER_BIT);
    glUseProgram($prog_lat);
    my $ca=$t*0.12;my $ch=0.8+sin($t*0.08)*0.4;
    my @proj=m4p(50,$W/$H,0.01,20);
    my @view=m4l(cos($ca)*3,$ch,sin($ca)*3,0,0,0,0,1,0);
    my @mvp=m4m(\@proj,\@view);
    my $m=OpenGL::Array->new_list(GL_FLOAT,@mvp);
    glUniformMatrix4fv_c($u_mvp,1,GL_FALSE,$m->ptr);
    glUniform2f($u_res,$W,$H);

    my(@verts,@cmds,$total);$total=0;
    for my $arm(0..$num_arms-1) {
        my $off=$arm/$num_arms;
        my @uv=@{morph_bank(\@u_keys,$n_u,$t,$off)};
        my @vv=@{morph_bank(\@v_keys,$n_v,$t,$off*1.7+0.3)};
        my @lv=@$lift_vals;
        my $hue=$arm/$num_arms+$t*0.02;

        for my $j(0..$samples-1) {
            my $s=$j/($samples-1);
            my $u=$uv[$j]+$off*2*$PI;
            my $v=$vv[$j];
            my $lift=$lv[$j]*$p;
            my($x,$y,$z)=torus_point($u,$v,$R,$r+$lift);
            my($cr,$cg,$cb)=hsv($hue+$s*0.25,0.7,0.45+abs($lift)*5);
            my $thick=1.5+abs($lift)*20;
            push @verts,$x,$y,$z,$cr,$cg,$cb,0.85,$thick;
        }
        push @cmds,[$total,$samples];$total+=$samples;
    }

    my $stride=8*4;
    my $oa=OpenGL::Array->new_list(GL_FLOAT,@verts);
    glBindVertexArray($vao_l);glBindBuffer(GL_ARRAY_BUFFER,$vbo_l);
    glBufferData_c(GL_ARRAY_BUFFER,$oa->length,$oa->ptr,GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(0);glVertexAttribPointer_c(0,3,GL_FLOAT,GL_FALSE,$stride,0);
    glEnableVertexAttribArray(1);glVertexAttribPointer_c(1,4,GL_FLOAT,GL_FALSE,$stride,3*4);
    glEnableVertexAttribArray(2);glVertexAttribPointer_c(2,1,GL_FLOAT,GL_FALSE,$stride,7*4);
    glDrawArrays(GL_LINE_STRIP,$_->[0],$_->[1]) for @cmds;
    glDisableVertexAttribArray($_) for 0..2;
    glBindVertexArray(0);

    # Pass 4: blit to screen
    glBindFramebuffer(GL_FRAMEBUFFER,0);glDisable(GL_DEPTH_TEST);glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram($prog_blit);glActiveTexture(GL_TEXTURE0);glBindTexture(GL_TEXTURE_2D,$tex_a);
    glUniform1i($u_blt,0);dq();glEnable(GL_DEPTH_TEST);
    glutSwapBuffers();
}

sub idle { glutPostRedisplay() }
sub keyboard { exit(0) if ord($_[0]) == 27 }

glutInit();
glutInitDisplayMode(GLUT_DOUBLE|GLUT_RGBA|GLUT_DEPTH|GLUT_MULTISAMPLE);
glutInitContextVersion(3,2);glutInitContextProfile(0x0001);
glutInitWindowSize($W,$H);
glutCreateWindow('Torus Envelope FBO Trails');
init_gl();
glutDisplayFunc(\&display);glutIdleFunc(\&idle);glutKeyboardFunc(\&keyboard);
printf "Torus FBO trails: %d arms, %d u x %d v envelopes, fade+blur — ESC to quit\n",
    $num_arms,$n_u,$n_v;
glutMainLoop();
