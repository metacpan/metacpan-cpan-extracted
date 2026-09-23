#!/usr/bin/env perl
# 3D rolling shapes: cubes and pyramids tumbling down envelope terrain
# Each shape has angular velocity that makes it tumble realistically
# Cubes bounce and slide, pyramids tip and roll on their faces
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

use Math::SegmentedEnvelope qw(spline env);
use Time::HiRes qw(time);
use POSIX qw(tan floor);

srand(42);

my $W = 900;
my $H = 700;
my $PI = 3.14159265358979323846;
my $GRID = 40;

# Terrain
my $terrain_x = spline([0, 0.12, 0.3, 0.5, 0.65, 0.8, 1.0],
                       [0.15, 0.7, 0.35, 0.85, 0.3, 0.6, 0.1], resolution => 8);
my $terrain_z = spline([0, 0.15, 0.4, 0.55, 0.75, 0.9, 1.0],
                       [0.1, 0.55, 0.8, 0.25, 0.65, 0.4, 0.12], resolution => 8);

my $sx = $terrain_x->static; my $dx = $terrain_x->duration;
my $sz = $terrain_z->static; my $dz = $terrain_z->duration;
my $der_x = $terrain_x->resample($GRID)->derivative->static;
my $der_z = $terrain_z->resample($GRID)->derivative->static;
my $ddx = $terrain_x->resample($GRID)->derivative->duration;
my $ddz = $terrain_z->resample($GRID)->derivative->duration;

sub height_at { my($x,$z)=@_;$x=0 if $x<0;$x=1 if $x>1;$z=0 if $z<0;$z=1 if $z>1;$sx->($x*$dx)*$sz->($z*$dz) }
sub grad_at { my($x,$z)=@_;$x=0 if $x<0;$x=1 if $x>1;$z=0 if $z<0;$z=1 if $z>1;
    ($der_x->($x*$ddx)*$sz->($z*$dz), $der_z->($z*$ddz)*$sx->($x*$dx)) }

# Terrain mesh
my (@tverts, @tidx);
for my $zi(0..$GRID){for my $xi(0..$GRID){push @tverts,$xi/$GRID,height_at($xi/$GRID,$zi/$GRID),$zi/$GRID}}
for my $zi(0..$GRID-1){for my $xi(0..$GRID-1){
    my $i=$zi*($GRID+1)+$xi;push @tidx,$i,$i+1,$i+$GRID+1,$i+1,$i+$GRID+2,$i+$GRID+1}}

# Shape types
my $gravity = 3.0;
my $friction = 0.990;
my $bounce = 0.4;
my $angular_friction = 0.97;
my $num_shapes = 16;
my @shapes;

# Cube vertices (centered, size 1)
my @cube_v;
for my $face (
    [[-1,-1,-1],[1,-1,-1],[1,1,-1],[-1,1,-1]],  # back
    [[-1,-1,1],[1,-1,1],[1,1,1],[-1,1,1]],       # front
    [[-1,-1,-1],[-1,-1,1],[-1,1,1],[-1,1,-1]],   # left
    [[1,-1,-1],[1,-1,1],[1,1,1],[1,1,-1]],        # right
    [[-1,-1,-1],[1,-1,-1],[1,-1,1],[-1,-1,1]],    # bottom
    [[-1,1,-1],[1,1,-1],[1,1,1],[-1,1,1]],        # top
) {
    # Two triangles per face
    for my $tri ([0,1,2],[0,2,3]) {
        push @cube_v, map { @{$face->[$_]} } @$tri;
    }
}

# Pyramid vertices (4 base corners + apex)
my @pyr_v;
my @base = ([-1,0,-1],[1,0,-1],[1,0,1],[-1,0,1]);
my @apex = (0, 1.5, 0);
# Base triangles
push @pyr_v, @{$base[0]}, @{$base[1]}, @{$base[2]};
push @pyr_v, @{$base[0]}, @{$base[2]}, @{$base[3]};
# Side triangles
for my $i (0..3) {
    push @pyr_v, @{$base[$i]}, @{$base[($i+1)%4]}, @apex;
}

sub spawn_shapes {
    @shapes = ();
    for my $i (0 .. $num_shapes - 1) {
        my $bx = 0.1 + rand() * 0.8;
        my $bz = 0.1 + rand() * 0.8;
        # Find high point
        for (1..5) {
            my $tx = 0.1 + rand() * 0.8; my $tz = 0.1 + rand() * 0.8;
            ($bx,$bz) = ($tx,$tz) if height_at($tx,$tz) > height_at($bx,$bz);
        }
        push @shapes, {
            type  => $i % 2 == 0 ? 'cube' : 'pyramid',
            x => $bx, z => $bz,
            vx => (rand()-0.5)*0.05, vz => (rand()-0.5)*0.05,
            size  => 0.015 + rand() * 0.012,
            hue   => $i / $num_shapes,
            # Rotation state (Euler angles)
            rx => rand()*$PI*2, ry => rand()*$PI*2, rz => rand()*$PI*2,
            # Angular velocity
            wx => 0, wy => 0, wz => 0,
            trail => [],
        };
    }
}
spawn_shapes();

# Shaders
my $tv_src = <<'GLSL';
#version 150
in vec3 aPos; out vec3 vPos;
uniform mat4 uMVP;
void main() { vPos=aPos; gl_Position=uMVP*vec4(aPos,1); }
GLSL
my $tg_src = <<'GLSL';
#version 150
layout(triangles) in; layout(triangle_strip, max_vertices=3) out;
in vec3 vPos[]; out vec4 fColor;
void main() {
    vec3 fn=normalize(cross(vPos[1]-vPos[0],vPos[2]-vPos[0]));
    float diff=max(dot(fn,normalize(vec3(0.4,0.8,0.3))),0.0);
    for(int i=0;i<3;i++){gl_Position=gl_in[i].gl_Position;
        float h=vPos[i].y; vec3 c;
        if(h>0.55)c=mix(vec3(0.5,0.43,0.36),vec3(0.85,0.83,0.8),(h-0.55)/0.45);
        else if(h>0.25)c=mix(vec3(0.22,0.5,0.16),vec3(0.5,0.43,0.36),(h-0.25)/0.3);
        else c=vec3(0.28,0.52,0.2);
        fColor=vec4(c*(0.3+diff*0.7),1);EmitVertex();}EndPrimitive();}
GLSL
my $tf_src = <<'GLSL';
#version 150
in vec4 fColor; out vec4 o; void main(){o=fColor;}
GLSL

# Shape shader: vertex transforms with model matrix for rotation
my $sv_src = <<'GLSL';
#version 150
in vec3 aPos; out vec3 vNorm;
uniform mat4 uMVP; uniform mat4 uModel;
void main() {
    vec4 world = uModel * vec4(aPos, 1.0);
    gl_Position = uMVP * world;
    vNorm = mat3(uModel) * aPos;  // approximate normal from vertex position
}
GLSL
my $sg_src = <<'GLSL';
#version 150
layout(triangles) in; layout(triangle_strip, max_vertices=3) out;
in vec3 vNorm[]; out vec4 fColor;
uniform vec4 uColor;
void main() {
    vec3 e1=vNorm[1]-vNorm[0], e2=vNorm[2]-vNorm[0];
    vec3 fn=normalize(cross(e1,e2));
    float diff=max(dot(fn,normalize(vec3(0.5,0.8,0.3))),0.0);
    for(int i=0;i<3;i++){gl_Position=gl_in[i].gl_Position;
        fColor=vec4(uColor.rgb*(0.35+diff*0.65),uColor.a);EmitVertex();}EndPrimitive();}
GLSL
my $sf_src = <<'GLSL';
#version 150
in vec4 fColor; out vec4 o; void main(){o=fColor;}
GLSL

# Trail shader (simple lines)
my $lv_src = <<'GLSL';
#version 150
in vec3 aPos; uniform mat4 uMVP;
void main(){gl_Position=uMVP*vec4(aPos,1);}
GLSL
my $lf_src = <<'GLSL';
#version 150
uniform vec4 uColor; out vec4 o; void main(){o=uColor;}
GLSL

my ($pt,$ps,$ptrl,$utm,$utt,$usm,$usmm,$usc,$utlm,$utlc);
my ($vat,$vbt,$ibt,$vas,$vbs,$vatrl,$vbtrl,$start,$last_t);

sub cs{my($t,$s)=@_;my $h=glCreateShader($t);glShaderSource_p($h,$s);glCompileShader($h);
    my($o)=glGetShaderiv_p($h,GL_COMPILE_STATUS);die"S:".glGetShaderInfoLog_p($h)unless $o;$h}
sub lp{my @s=@_;my $p=glCreateProgram();glAttachShader($p,$_)for@s;glLinkProgram($p);
    my($o)=glGetProgramiv_p($p,GL_LINK_STATUS);die"L:".glGetProgramInfoLog_p($p)unless $o;
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

# Rotation matrix from Euler angles
sub rot_matrix {
    my ($rx,$ry,$rz,$tx,$ty,$tz,$sc) = @_;
    my ($cx,$sx)=(cos($rx),sin($rx));
    my ($cy,$sy)=(cos($ry),sin($ry));
    my ($cz,$sz)=(cos($rz),sin($rz));
    # Rz * Ry * Rx, scaled, translated
    return (
        $sc*($cy*$cz), $sc*($sx*$sy*$cz-$cx*$sz), $sc*($cx*$sy*$cz+$sx*$sz), 0,
        $sc*($cy*$sz), $sc*($sx*$sy*$sz+$cx*$cz), $sc*($cx*$sy*$sz-$sx*$cz), 0,
        $sc*(-$sy),    $sc*($sx*$cy),              $sc*($cx*$cy),              0,
        $tx, $ty, $tz, 1
    );
}

sub init_gl {
    $pt=lp(cs(GL_VERTEX_SHADER,$tv_src),cs(GL_GEOMETRY_SHADER,$tg_src),cs(GL_FRAGMENT_SHADER,$tf_src));
    $utm=glGetUniformLocation($pt,'uMVP');

    $ps=lp(cs(GL_VERTEX_SHADER,$sv_src),cs(GL_GEOMETRY_SHADER,$sg_src),cs(GL_FRAGMENT_SHADER,$sf_src));
    $usm=glGetUniformLocation($ps,'uMVP');$usmm=glGetUniformLocation($ps,'uModel');$usc=glGetUniformLocation($ps,'uColor');

    $ptrl=lp(cs(GL_VERTEX_SHADER,$lv_src),cs(GL_FRAGMENT_SHADER,$lf_src));
    $utlm=glGetUniformLocation($ptrl,'uMVP');$utlc=glGetUniformLocation($ptrl,'uColor');

    # Terrain
    ($vat)=glGenVertexArrays_p(1);($vbt)=glGenBuffers_p(1);($ibt)=glGenBuffers_p(1);
    glBindVertexArray($vat);glBindBuffer(GL_ARRAY_BUFFER,$vbt);
    my $tv=OpenGL::Array->new_list(GL_FLOAT,@tverts);
    glBufferData_c(GL_ARRAY_BUFFER,$tv->length,$tv->ptr,GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);glVertexAttribPointer_c(0,3,GL_FLOAT,GL_FALSE,0,0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,$ibt);
    my $ti=OpenGL::Array->new_list(GL_UNSIGNED_INT,@tidx);
    glBufferData_c(GL_ELEMENT_ARRAY_BUFFER,$ti->length,$ti->ptr,GL_STATIC_DRAW);
    glBindVertexArray(0);

    # Shape VBOs (cubes + pyramids share one)
    ($vas)=glGenVertexArrays_p(1);($vbs)=glGenBuffers_p(1);
    ($vatrl)=glGenVertexArrays_p(1);($vbtrl)=glGenBuffers_p(1);

    glEnable(GL_DEPTH_TEST);glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    $start=time();$last_t=$start;
}

sub display {
    my $now=time(); my $dt=$now-$last_t; $dt=0.033 if $dt>0.033; $last_t=$now;

    # Physics
    for my $s (@shapes) {
        my($gx,$gz)=grad_at($s->{x},$s->{z});
        $s->{vx} -= $gravity*atan2($gx,1)*$dt*0.5;
        $s->{vz} -= $gravity*atan2($gz,1)*$dt*0.5;
        $s->{vx} *= $friction; $s->{vz} *= $friction;
        $s->{x} += $s->{vx}*$dt; $s->{z} += $s->{vz}*$dt;

        # Angular velocity from slope + linear velocity
        my $speed=sqrt($s->{vx}**2+$s->{vz}**2);
        $s->{wx} += $s->{vz}*$dt*30;  # roll around X from Z motion
        $s->{wz} -= $s->{vx}*$dt*30;  # roll around Z from X motion
        $s->{wy} += ($gx-$gz)*$dt*5;  # yaw from slope asymmetry
        $s->{wx} *= $angular_friction;
        $s->{wy} *= $angular_friction;
        $s->{wz} *= $angular_friction;
        $s->{rx} += $s->{wx}*$dt;
        $s->{ry} += $s->{wy}*$dt;
        $s->{rz} += $s->{wz}*$dt;

        # Edge bounce
        if($s->{x}<0.02){$s->{x}=0.02;$s->{vx}=abs($s->{vx})*$bounce;$s->{wz}+=2}
        if($s->{x}>0.98){$s->{x}=0.98;$s->{vx}=-abs($s->{vx})*$bounce;$s->{wz}-=2}
        if($s->{z}<0.02){$s->{z}=0.02;$s->{vz}=abs($s->{vz})*$bounce;$s->{wx}-=2}
        if($s->{z}>0.98){$s->{z}=0.98;$s->{vz}=-abs($s->{vz})*$bounce;$s->{wx}+=2}

        my $h=height_at($s->{x},$s->{z});
        push @{$s->{trail}},[$s->{x},$h+$s->{size},$s->{z}];
        shift @{$s->{trail}} while @{$s->{trail}}>25;
    }

    glClearColor(0.5,0.6,0.75,1);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

    my $ca=($now-$start)*0.1;
    my @proj=m4p(50,$W/$H,0.01,10);
    my @view=m4l(0.5+cos($ca)*1.4,1.0,0.5+sin($ca)*1.4,0.5,0.3,0.5,0,1,0);
    my @mvp=m4m(\@proj,\@view);
    my $m=OpenGL::Array->new_list(GL_FLOAT,@mvp);

    # Terrain
    glUseProgram($pt);glUniformMatrix4fv_c($utm,1,GL_FALSE,$m->ptr);
    glBindVertexArray($vat);glDrawElements_c(GL_TRIANGLES,scalar@tidx,GL_UNSIGNED_INT,0);glBindVertexArray(0);

    # Shapes
    glUseProgram($ps);glUniformMatrix4fv_c($usm,1,GL_FALSE,$m->ptr);

    for my $s (@shapes) {
        my $h=height_at($s->{x},$s->{z})+$s->{size};
        my @model=rot_matrix($s->{rx},$s->{ry},$s->{rz},$s->{x},$h,$s->{z},$s->{size});
        my $mm=OpenGL::Array->new_list(GL_FLOAT,@model);
        glUniformMatrix4fv_c($usmm,1,GL_FALSE,$mm->ptr);
        my($cr,$cg,$cb)=hsv($s->{hue},0.8,0.85);
        glUniform4f($usc,$cr,$cg,$cb,0.95);

        my @v = $s->{type} eq 'cube' ? @cube_v : @pyr_v;
        my $oa=OpenGL::Array->new_list(GL_FLOAT,@v);
        glBindVertexArray($vas);glBindBuffer(GL_ARRAY_BUFFER,$vbs);
        glBufferData_c(GL_ARRAY_BUFFER,$oa->length,$oa->ptr,GL_DYNAMIC_DRAW);
        glEnableVertexAttribArray(0);glVertexAttribPointer_c(0,3,GL_FLOAT,GL_FALSE,0,0);
        glDrawArrays(GL_TRIANGLES,0,scalar(@v)/3);
        glBindVertexArray(0);

        # Trail
        if(@{$s->{trail}}>2){
            glUseProgram($ptrl);glUniformMatrix4fv_c($utlm,1,GL_FALSE,$m->ptr);
            glUniform4f($utlc,$cr,$cg,$cb,0.3);
            my @tv;push @tv,@$_ for @{$s->{trail}};
            my $toa=OpenGL::Array->new_list(GL_FLOAT,@tv);
            glBindVertexArray($vatrl);glBindBuffer(GL_ARRAY_BUFFER,$vbtrl);
            glBufferData_c(GL_ARRAY_BUFFER,$toa->length,$toa->ptr,GL_DYNAMIC_DRAW);
            glEnableVertexAttribArray(0);glVertexAttribPointer_c(0,3,GL_FLOAT,GL_FALSE,0,0);
            glLineWidth(2);glDrawArrays(GL_LINE_STRIP,0,scalar(@tv)/3);
            glBindVertexArray(0);
            glUseProgram($ps);glUniformMatrix4fv_c($usm,1,GL_FALSE,$m->ptr);
        }
    }

    glutSwapBuffers();
}

sub idle{glutPostRedisplay()}
sub keyboard{exit(0)if ord($_[0])==27;spawn_shapes()if ord($_[0])==32}

glutInit();glutInitDisplayMode(GLUT_DOUBLE|GLUT_RGBA|GLUT_DEPTH|GLUT_MULTISAMPLE);
glutInitWindowSize($W,$H);glutCreateWindow('Rolling Cubes & Pyramids');
init_gl();glutDisplayFunc(\&display);glutIdleFunc(\&idle);glutKeyboardFunc(\&keyboard);
printf "Rolling shapes: %d (%d cubes + %d pyramids) — Space=respawn, ESC=quit\n",
    $num_shapes, scalar(grep{$_->{type}eq'cube'}@shapes), scalar(grep{$_->{type}eq'pyramid'}@shapes);
glutMainLoop();
