#!/usr/bin/env perl
# ODE physics: rigid body cubes and spheres colliding on envelope terrain
# Uses Open Dynamics Engine (ODE) via FFI for real collision detection,
# friction, bouncing, and stacking. Terrain is an ODE heightfield from envelopes.
#
# Build helper: cd eg && cc -shared -fPIC -O2 -o libode_helper.so ode_helper.c $(pkg-config --cflags --libs ode) -lm
#
# Requires: FFI::Platypus, OpenGL::Modern, OpenGL::GLUT, OpenGL::Array, libode
use strict;
use warnings;

BEGIN {
    eval { require FFI::Platypus; 1 } or die "Requires FFI::Platypus\n";
    eval { require OpenGL::Modern; OpenGL::Modern->import(':all'); 1 } or die "Requires OpenGL::Modern\n";
    eval { require OpenGL::GLUT; OpenGL::GLUT->import(':all'); 1 } or die "Requires OpenGL::GLUT\n";
    eval { require OpenGL::Array; 1 } or die "Requires OpenGL::Array\n";
}

use FindBin;
use FFI::Platypus;
use FFI::Platypus::Buffer qw(scalar_to_pointer);
use Math::SegmentedEnvelope qw(spline env);
use Time::HiRes qw(time);
use POSIX qw(tan floor);

my $W = 900;
my $H = 700;
my $PI = 3.14159265358979323846;
my $GRID = 40;

# ODE FFI
my $lib = "$FindBin::Bin/libode_helper.so";
die "Build helper first: cd eg && cc -shared -fPIC -O2 -o libode_helper.so ode_helper.c \$(pkg-config --cflags --libs ode) -lm\n"
    unless -f $lib;

my $ffi = FFI::Platypus->new(api => 2, lib => [$lib]);
$ffi->attach(ode_init => ['float'] => 'void');
$ffi->attach(ode_set_heightfield => ['opaque', 'int', 'int', 'float', 'float'] => 'void');
$ffi->attach(ode_add_box => ['float','float','float','float','float','float','float','float'] => 'int');
$ffi->attach(ode_add_sphere => ['float','float','float','float','float','float','float','float'] => 'int');
$ffi->attach(ode_step => ['float'] => 'void');
$ffi->attach(ode_get_num_bodies => [] => 'int');
$ffi->attach(ode_get_body => ['int', 'opaque'] => 'void');
$ffi->attach(ode_cleanup => [] => 'void');

# Terrain envelopes
my $terrain_x = spline([0, 0.15, 0.3, 0.5, 0.65, 0.8, 1.0],
                       [0.1, 0.5, 0.25, 0.7, 0.3, 0.55, 0.08], resolution => 8);
my $terrain_z = spline([0, 0.12, 0.35, 0.55, 0.75, 0.9, 1.0],
                       [0.08, 0.45, 0.6, 0.2, 0.5, 0.35, 0.05], resolution => 8);
my $tsx = $terrain_x->static; my $tdx = $terrain_x->duration;
my $tsz = $terrain_z->static; my $tdz = $terrain_z->duration;

# Build heightfield data
my $hf_w = $GRID + 1;
my $hf_h = $GRID + 1;
my $hf_data = pack('f*', map {
    my $zi = int($_ / $hf_w);
    my $xi = $_ % $hf_w;
    $tsx->($xi / $GRID * $tdx) * $tsz->($zi / $GRID * $tdz);
} 0 .. $hf_w * $hf_h - 1);
my $hf_ptr = unpack('Q', pack('P', $hf_data));

# Terrain mesh for rendering
my (@tverts, @tidx);
for my $zi (0 .. $GRID) {
    for my $xi (0 .. $GRID) {
        my $x = $xi / $GRID;
        my $z = $zi / $GRID;
        push @tverts, $x, $tsx->($x * $tdx) * $tsz->($z * $tdz), $z;
    }
}
for my $zi (0 .. $GRID-1) {
    for my $xi (0 .. $GRID-1) {
        my $i = $zi * ($GRID+1) + $xi;
        push @tidx, $i, $i+1, $i+$GRID+1, $i+1, $i+$GRID+2, $i+$GRID+1;
    }
}

# Cube and sphere mesh templates
my @cube_v;
for my $f ([[-1,-1,-1],[1,-1,-1],[1,1,-1],[-1,1,-1]],
           [[-1,-1,1],[1,-1,1],[1,1,1],[-1,1,1]],
           [[-1,-1,-1],[-1,-1,1],[-1,1,1],[-1,1,-1]],
           [[1,-1,-1],[1,-1,1],[1,1,1],[1,1,-1]],
           [[-1,-1,-1],[1,-1,-1],[1,-1,1],[-1,-1,1]],
           [[-1,1,-1],[1,1,-1],[1,1,1],[-1,1,1]]) {
    for my $t ([0,1,2],[0,2,3]) { push @cube_v, map { @{$f->[$_]} } @$t }
}

my @sphere_v;
{ my ($rings,$segs) = (8,10);
  for my $r (0..$rings-1) { for my $s (0..$segs) {
    for my $dr (0,1) {
        my $phi = ($r+$dr)/$rings*$PI; my $th = $s/$segs*2*$PI;
        push @sphere_v, sin($phi)*cos($th), cos($phi), sin($phi)*sin($th);
    }
  }}
}

# Shaders
my $tv = <<'GLSL';
#version 150
in vec3 aPos; out vec3 vPos; uniform mat4 uMVP;
void main() { vPos=aPos; gl_Position=uMVP*vec4(aPos,1); }
GLSL
my $tg = <<'GLSL';
#version 150
layout(triangles) in; layout(triangle_strip,max_vertices=3) out;
in vec3 vPos[]; out vec4 fC;
void main() {
    vec3 fn=normalize(cross(vPos[1]-vPos[0],vPos[2]-vPos[0]));
    float d=max(dot(fn,normalize(vec3(0.4,0.8,0.3))),0.0);
    for(int i=0;i<3;i++){gl_Position=gl_in[i].gl_Position;
        float h=vPos[i].y;vec3 c;
        if(h>0.5)c=mix(vec3(0.5,0.43,0.36),vec3(0.85,0.83,0.8),(h-0.5)/0.5);
        else if(h>0.2)c=mix(vec3(0.22,0.5,0.16),vec3(0.5,0.43,0.36),(h-0.2)/0.3);
        else c=vec3(0.28,0.52,0.2);
        fC=vec4(c*(0.3+d*0.7),1);EmitVertex();}EndPrimitive();}
GLSL
my $tf = <<'GLSL';
#version 150
in vec4 fC; out vec4 o; void main(){o=fC;}
GLSL

my $sv = <<'GLSL';
#version 150
in vec3 aPos; out vec3 vN; uniform mat4 uMVP; uniform mat4 uM;
void main() { vN=mat3(uM)*aPos; gl_Position=uMVP*(uM*vec4(aPos,1)); }
GLSL
my $sg = <<'GLSL';
#version 150
layout(triangles) in; layout(triangle_strip,max_vertices=3) out;
in vec3 vN[]; out vec4 fC; uniform vec4 uC;
void main() {
    vec3 fn=normalize(cross(vN[1]-vN[0],vN[2]-vN[0]));
    float d=max(dot(fn,normalize(vec3(0.5,0.8,0.3))),0.0);
    for(int i=0;i<3;i++){gl_Position=gl_in[i].gl_Position;
        fC=vec4(uC.rgb*(0.35+d*0.65),uC.a);EmitVertex();}EndPrimitive();}
GLSL
my $sf = <<'GLSL';
#version 150
in vec4 fC; out vec4 o; void main(){o=fC;}
GLSL

my($pt,$ps,$utm,$usm,$usmm,$usc);
my($vat,$vbt,$ibt,$vas,$vbs,$start);

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

# Quaternion to rotation matrix (column-major 4x4)
sub quat_to_mat {
    my ($qx,$qy,$qz,$qw,$tx,$ty,$tz,$sc) = @_;
    my($xx,$yy,$zz)=($qx*$qx,$qy*$qy,$qz*$qz);
    my($xy,$xz,$yz)=($qx*$qy,$qx*$qz,$qy*$qz);
    my($wx,$wy,$wz)=($qw*$qx,$qw*$qy,$qw*$qz);
    return (
        $sc*(1-2*($yy+$zz)), $sc*2*($xy+$wz),     $sc*2*($xz-$wy),     0,
        $sc*2*($xy-$wz),     $sc*(1-2*($xx+$zz)), $sc*2*($yz+$wx),     0,
        $sc*2*($xz+$wy),     $sc*2*($yz-$wx),     $sc*(1-2*($xx+$yy)), 0,
        $tx, $ty, $tz, 1
    );
}

sub init_physics {
    ode_init(-1.6);  # moon gravity
    ode_set_heightfield($hf_ptr, $hf_w, $hf_h, 1.0, 1.0);

    srand(42);
    # Spawn shapes on high points
    for my $i (0 .. 23) {
        my ($bx, $bz, $best) = (0.5, 0.5, 0);
        for (1..8) {
            my $tx = 0.1 + rand()*0.8;
            my $tz = 0.1 + rand()*0.8;
            my $h = $tsx->($tx*$tdx) * $tsz->($tz*$tdz);
            ($bx,$bz,$best) = ($tx,$tz,$h) if $h > $best;
        }
        my $h = $best + 0.1 + rand() * 0.3;  # drop from above

        my $hue = $i / 24;
        my @hsv = hsv($hue, 0.8, 0.85);

        if ($i % 3 == 0) {
            # Sphere
            my $r = 0.015 + rand() * 0.01;
            ode_add_sphere($bx, $h, $bz, $r, 0.5 + rand(), @hsv);
        } else {
            # Box
            my $sz = 0.02 + rand() * 0.015;
            ode_add_box($bx, $h, $bz, $sz, 0.8 + rand(), @hsv);
        }
    }
}

sub hsv{my($h,$s,$v)=@_;$h=($h-floor($h))*6;my $f=$h-floor($h);
    my $p=$v*(1-$s);my $q=$v*(1-$s*$f);my $t=$v*(1-$s*(1-$f));
    my @c=([$v,$t,$p],[$q,$v,$p],[$p,$v,$t],[$p,$q,$v],[$t,$p,$v],[$v,$p,$q]);@{$c[int($h)%6]}}

sub init_gl {
    $pt=lp(cs(GL_VERTEX_SHADER,$tv),cs(GL_GEOMETRY_SHADER,$tg),cs(GL_FRAGMENT_SHADER,$tf));
    $utm=glGetUniformLocation($pt,'uMVP');
    $ps=lp(cs(GL_VERTEX_SHADER,$sv),cs(GL_GEOMETRY_SHADER,$sg),cs(GL_FRAGMENT_SHADER,$sf));
    $usm=glGetUniformLocation($ps,'uMVP');$usmm=glGetUniformLocation($ps,'uM');$usc=glGetUniformLocation($ps,'uC');

    ($vat)=glGenVertexArrays_p(1);($vbt)=glGenBuffers_p(1);($ibt)=glGenBuffers_p(1);
    glBindVertexArray($vat);glBindBuffer(GL_ARRAY_BUFFER,$vbt);
    my $toa=OpenGL::Array->new_list(GL_FLOAT,@tverts);
    glBufferData_c(GL_ARRAY_BUFFER,$toa->length,$toa->ptr,GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);glVertexAttribPointer_c(0,3,GL_FLOAT,GL_FALSE,0,0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,$ibt);
    my $tia=OpenGL::Array->new_list(GL_UNSIGNED_INT,@tidx);
    glBufferData_c(GL_ELEMENT_ARRAY_BUFFER,$tia->length,$tia->ptr,GL_STATIC_DRAW);
    glBindVertexArray(0);

    ($vas)=glGenVertexArrays_p(1);($vbs)=glGenBuffers_p(1);

    glEnable(GL_DEPTH_TEST);glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

    init_physics();
    $start = time();
}

sub display {
    my $t = time() - $start;

    # Physics step
    ode_step(1.0/60.0);

    glClearColor(0.5,0.6,0.75,1);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

    my $ca = $t * 0.12;
    my @proj = m4p(50,$W/$H,0.01,10);
    my @view = m4l(0.5+cos($ca)*1.3,0.9,0.5+sin($ca)*1.3,0.5,0.25,0.5,0,1,0);
    my @mvp = m4m(\@proj,\@view);
    my $m = OpenGL::Array->new_list(GL_FLOAT,@mvp);

    # Terrain
    glUseProgram($pt);glUniformMatrix4fv_c($utm,1,GL_FALSE,$m->ptr);
    glBindVertexArray($vat);glDrawElements_c(GL_TRIANGLES,scalar@tidx,GL_UNSIGNED_INT,0);glBindVertexArray(0);

    # Bodies
    glUseProgram($ps);glUniformMatrix4fv_c($usm,1,GL_FALSE,$m->ptr);

    my $buf = "\0" x (12 * 4);  # 12 floats
    my $buf_ptr = unpack('Q', pack('P', $buf));
    my $nb = ode_get_num_bodies();

    for my $i (0 .. $nb - 1) {
        ode_get_body($i, $buf_ptr);
        my @d = unpack('f12', $buf);
        # d: x,y,z, qx,qy,qz,qw, type, size, r,g,b
        my ($px,$py,$pz,$qx,$qy,$qz,$qw,$type,$size,$cr,$cg,$cb) = @d;

        my $sc = $type == 0 ? $size/2 : $size;  # box: half-size, sphere: radius
        my @model = quat_to_mat($qx,$qy,$qz,$qw, $px,$py,$pz, $sc);
        my $mm = OpenGL::Array->new_list(GL_FLOAT, @model);
        glUniformMatrix4fv_c($usmm, 1, GL_FALSE, $mm->ptr);
        glUniform4f($usc, $cr, $cg, $cb, 0.95);

        my @v = $type == 0 ? @cube_v : @sphere_v;
        my $oa = OpenGL::Array->new_list(GL_FLOAT, @v);
        glBindVertexArray($vas);
        glBindBuffer(GL_ARRAY_BUFFER, $vbs);
        glBufferData_c(GL_ARRAY_BUFFER, $oa->length, $oa->ptr, GL_DYNAMIC_DRAW);
        glEnableVertexAttribArray(0);
        glVertexAttribPointer_c(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
        if ($type == 0) { glDrawArrays(GL_TRIANGLES, 0, scalar(@v)/3) }
        else { glDrawArrays(GL_TRIANGLE_STRIP, 0, scalar(@v)/3) }
        glBindVertexArray(0);
    }

    glutSwapBuffers();
}

sub idle { glutPostRedisplay() }
sub keyboard { exit(0) if ord($_[0]) == 27 }

glutInit();
glutInitDisplayMode(GLUT_DOUBLE|GLUT_RGBA|GLUT_DEPTH|GLUT_MULTISAMPLE);
glutInitWindowSize($W,$H);
glutCreateWindow('ODE Physics on Envelope Terrain');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "ODE physics: %d bodies on %dx%d envelope terrain — ESC to quit\n",
    ode_get_num_bodies(), $GRID, $GRID;
glutMainLoop();
ode_cleanup();
