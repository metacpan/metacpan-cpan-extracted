#!/usr/bin/env perl
# ODE slope chase: long angled slope, camera follows a rolling cube downhill
# Terrain is a long narrow envelope-shaped slope with bumps and ramps
# Camera tracks the lead cube with smooth follow
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
use Math::SegmentedEnvelope qw(spline env);
use Time::HiRes qw(time);
use POSIX qw(tan floor);

my $W = 1000;
my $H = 600;
my $PI = 3.14159265358979323846;

# Slope dimensions: long and narrow
my $slope_len = 20.0;   # X length
my $slope_wid = 1.5;    # Z width
my $slope_drop = 6.0;   # total height drop
my $GRID_X = 200;
my $GRID_Z = 20;

# ODE FFI
my $lib = "$FindBin::Bin/libode_helper.so";
die "Build helper first\n" unless -f $lib;
my $ffi = FFI::Platypus->new(api => 2, lib => [$lib]);
$ffi->attach(ode_init => ['float'] => 'void');
$ffi->attach(ode_set_heightfield => ['opaque','int','int','float','float'] => 'void');
$ffi->attach(ode_add_box => ['float','float','float','float','float','float','float','float'] => 'int');
$ffi->attach(ode_add_sphere => ['float','float','float','float','float','float','float','float'] => 'int');
$ffi->attach(ode_step => ['float'] => 'void');
$ffi->attach(ode_get_num_bodies => [] => 'int');
$ffi->attach(ode_get_body => ['int','opaque'] => 'void');
$ffi->attach(ode_cleanup => [] => 'void');

# Slope profile: bumpy downhill with ramps and dips
my $slope_profile = spline(
    [0, 0.05, 0.12, 0.2, 0.28, 0.35, 0.42, 0.5, 0.58, 0.65, 0.72, 0.8, 0.88, 0.95, 1.0],
    [1.0, 0.95, 0.92, 0.85, 0.88, 0.78, 0.72, 0.65, 0.68, 0.55, 0.48, 0.38, 0.42, 0.2, 0.05],
    resolution => 4,
);

# Cross-section: slight valley in the middle to keep shapes on track
my $cross_profile = env(
    [[0.03, 0, 0, 0.03], [0.3, 0.4, 0.3], [2, 1, 2]],
);

my $sp = $slope_profile->static;
my $sd = $slope_profile->duration;
my $cp = $cross_profile->static;
my $cd = $cross_profile->duration;

# Build heightfield
my $hf_w = $GRID_X + 1;
my $hf_h = $GRID_Z + 1;
my @hf_vals;
for my $zi (0 .. $GRID_Z) {
    for my $xi (0 .. $GRID_X) {
        my $x = $xi / $GRID_X;
        my $z = $zi / $GRID_Z;
        my $h = $sp->($x * $sd) * $slope_drop + $cp->($z * $cd);
        push @hf_vals, $h;
    }
}
my $hf_data = pack('f*', @hf_vals);
my $hf_ptr = unpack('Q', pack('P', $hf_data));

# Terrain mesh for rendering
my (@tverts, @tidx);
for my $zi (0 .. $GRID_Z) {
    for my $xi (0 .. $GRID_X) {
        my $x = $xi / $GRID_X * $slope_len;
        my $z = $zi / $GRID_Z * $slope_wid;
        my $h = $hf_vals[$zi * $hf_w + $xi];
        push @tverts, $x, $h, $z;
    }
}
for my $zi (0 .. $GRID_Z - 1) {
    for my $xi (0 .. $GRID_X - 1) {
        my $i = $zi * $hf_w + $xi;
        push @tidx, $i, $i+1, $i+$hf_w, $i+1, $i+$hf_w+1, $i+$hf_w;
    }
}

# Cube mesh
my @cube_v;
for my $f ([[-1,-1,-1],[1,-1,-1],[1,1,-1],[-1,1,-1]],
           [[-1,-1,1],[1,-1,1],[1,1,1],[-1,1,1]],
           [[-1,-1,-1],[-1,-1,1],[-1,1,1],[-1,1,-1]],
           [[1,-1,-1],[1,-1,1],[1,1,1],[1,1,-1]],
           [[-1,-1,-1],[1,-1,-1],[1,-1,1],[-1,-1,1]],
           [[-1,1,-1],[1,1,-1],[1,1,1],[-1,1,1]]) {
    for my $t ([0,1,2],[0,2,3]) { push @cube_v, map { @{$f->[$_]} } @$t }
}

# Sphere mesh
my @sphere_v;
{ my($rn,$sg)=(6,8);
  for my $r(0..$rn-1){for my $s(0..$sg){for my $d(0,1){
    my $phi=($r+$d)/$rn*$PI;my $th=$s/$sg*2*$PI;
    push @sphere_v,sin($phi)*cos($th),cos($phi),sin($phi)*sin($th)}}} }

# Camera state
my ($cam_x, $cam_y, $cam_z) = (0, 2, 0);
my $lead_body = 0;  # which body the camera follows

# Shaders
my $tv_src = <<'GLSL';
#version 150
in vec3 aPos; out vec3 vP; uniform mat4 uMVP;
void main() { vP=aPos; gl_Position=uMVP*vec4(aPos,1); }
GLSL
my $tg_src = <<'GLSL';
#version 150
layout(triangles) in; layout(triangle_strip,max_vertices=3) out;
in vec3 vP[]; out vec4 fC;
void main() {
    vec3 fn=normalize(cross(vP[1]-vP[0],vP[2]-vP[0]));
    float d=max(dot(fn,normalize(vec3(0.3,0.8,0.2))),0.0);
    for(int i=0;i<3;i++){gl_Position=gl_in[i].gl_Position;
        float h=vP[i].y;vec3 c;
        if(h>2.0)c=vec3(0.5,0.45,0.38); else if(h>1.0)c=vec3(0.25,0.5,0.18);
        else c=vec3(0.3,0.55,0.22);
        // Side walls darker
        float edge=abs(vP[i].z)/0.6;
        c*=1.0-edge*0.3;
        fC=vec4(c*(0.3+d*0.7),1);EmitVertex();}EndPrimitive();}
GLSL
my $tf_src = <<'GLSL';
#version 150
in vec4 fC; out vec4 o; void main(){o=fC;}
GLSL

my $sv_src = <<'GLSL';
#version 150
in vec3 aPos; out vec3 vN; uniform mat4 uMVP; uniform mat4 uM;
void main() { vN=mat3(uM)*aPos; gl_Position=uMVP*(uM*vec4(aPos,1)); }
GLSL
my $sg_src = <<'GLSL';
#version 150
layout(triangles) in; layout(triangle_strip,max_vertices=3) out;
in vec3 vN[]; out vec4 fC; uniform vec4 uC;
void main() {
    vec3 fn=normalize(cross(vN[1]-vN[0],vN[2]-vN[0]));
    float d=max(dot(fn,normalize(vec3(0.4,0.8,0.3))),0.0);
    for(int i=0;i<3;i++){gl_Position=gl_in[i].gl_Position;
        fC=vec4(uC.rgb*(0.3+d*0.7),uC.a);EmitVertex();}EndPrimitive();}
GLSL
my $sf_src = <<'GLSL';
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

sub quat_to_mat {
    my($qx,$qy,$qz,$qw,$tx,$ty,$tz,$sc)=@_;
    my($xx,$yy,$zz)=($qx*$qx,$qy*$qy,$qz*$qz);
    my($xy,$xz,$yz)=($qx*$qy,$qx*$qz,$qy*$qz);
    my($wx,$wy,$wz)=($qw*$qx,$qw*$qy,$qw*$qz);
    ($sc*(1-2*($yy+$zz)),$sc*2*($xy+$wz),$sc*2*($xz-$wy),0,
     $sc*2*($xy-$wz),$sc*(1-2*($xx+$zz)),$sc*2*($yz+$wx),0,
     $sc*2*($xz+$wy),$sc*2*($yz-$wx),$sc*(1-2*($xx+$yy)),0,
     $tx,$ty,$tz,1);
}

sub hsv{my($h,$s,$v)=@_;$h=($h-floor($h))*6;my $f=$h-floor($h);
    my $p=$v*(1-$s);my $q=$v*(1-$s*$f);my $t=$v*(1-$s*(1-$f));
    my @c=([$v,$t,$p],[$q,$v,$p],[$p,$v,$t],[$p,$q,$v],[$t,$p,$v],[$v,$p,$q]);@{$c[int($h)%6]}}

sub init_physics {
    ode_init(-2.5);  # low gravity for long visible tumbling
    ode_set_heightfield($hf_ptr, $hf_w, $hf_h, $slope_len, $slope_wid);

    srand(42);
    # Spawn shapes at top of slope, spread across width
    for my $i (0 .. 11) {
        my $x = 0.3 + rand() * 0.5;  # near top
        my $z = $slope_wid * 0.3 + rand() * $slope_wid * 0.4;  # center of slope
        my $h = $sp->($x / $slope_len * $sd) * $slope_drop + 0.2 + $i * 0.08;
        my @c = hsv($i / 12, 0.8, 0.85);

        if ($i == 0) {
            # Lead cube (red, tracked by camera)
            $lead_body = ode_add_box($x, $h, $z, 0.06, 2.0, 1.0, 0.3, 0.2);
        } elsif ($i % 3 == 0) {
            ode_add_sphere($x, $h, $z, 0.03, 1.0, @c);
        } else {
            ode_add_box($x, $h, $z, 0.04 + rand()*0.02, 1.0 + rand(), @c);
        }
    }
}

sub init_gl {
    $pt=lp(cs(GL_VERTEX_SHADER,$tv_src),cs(GL_GEOMETRY_SHADER,$tg_src),cs(GL_FRAGMENT_SHADER,$tf_src));
    $utm=glGetUniformLocation($pt,'uMVP');
    $ps=lp(cs(GL_VERTEX_SHADER,$sv_src),cs(GL_GEOMETRY_SHADER,$sg_src),cs(GL_FRAGMENT_SHADER,$sf_src));
    $usm=glGetUniformLocation($ps,'uMVP');$usmm=glGetUniformLocation($ps,'uM');$usc=glGetUniformLocation($ps,'uC');

    ($vat)=glGenVertexArrays_p(1);($vbt)=glGenBuffers_p(1);($ibt)=glGenBuffers_p(1);
    glBindVertexArray($vat);glBindBuffer(GL_ARRAY_BUFFER,$vbt);
    my $tv=OpenGL::Array->new_list(GL_FLOAT,@tverts);
    glBufferData_c(GL_ARRAY_BUFFER,$tv->length,$tv->ptr,GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);glVertexAttribPointer_c(0,3,GL_FLOAT,GL_FALSE,0,0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,$ibt);
    my $ti=OpenGL::Array->new_list(GL_UNSIGNED_INT,@tidx);
    glBufferData_c(GL_ELEMENT_ARRAY_BUFFER,$ti->length,$ti->ptr,GL_STATIC_DRAW);
    glBindVertexArray(0);

    ($vas)=glGenVertexArrays_p(1);($vbs)=glGenBuffers_p(1);
    glEnable(GL_DEPTH_TEST);glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

    init_physics();
    $start=time();
}

my $buf = "\0" x 48;
my $buf_ptr = unpack('Q', pack('P', $buf));

sub display {
    ode_step(1.0/60.0);

    # Get lead body position
    ode_get_body($lead_body, $buf_ptr);
    my @ld = unpack('f12', $buf);
    my ($lx, $ly, $lz) = @ld[0..2];

    # Smooth camera follow: behind and above the lead cube
    my $target_x = $lx - 0.8;  # behind
    my $target_y = $ly + 0.5;  # above
    my $target_z = $lz + 0.6;  # slightly to the side
    my $smooth = 0.03;
    $cam_x += ($target_x - $cam_x) * $smooth;
    $cam_y += ($target_y - $cam_y) * $smooth;
    $cam_z += ($target_z - $cam_z) * $smooth;

    glClearColor(0.55, 0.65, 0.8, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    my @proj = m4p(60, $W/$H, 0.01, 20);
    my @view = m4l($cam_x, $cam_y, $cam_z, $lx + 0.3, $ly, $lz, 0, 1, 0);
    my @mvp = m4m(\@proj, \@view);
    my $m = OpenGL::Array->new_list(GL_FLOAT, @mvp);

    # Terrain
    glUseProgram($pt);
    glUniformMatrix4fv_c($utm, 1, GL_FALSE, $m->ptr);
    glBindVertexArray($vat);
    glDrawElements_c(GL_TRIANGLES, scalar @tidx, GL_UNSIGNED_INT, 0);
    glBindVertexArray(0);

    # Bodies
    glUseProgram($ps);
    glUniformMatrix4fv_c($usm, 1, GL_FALSE, $m->ptr);

    my $nb = ode_get_num_bodies();
    for my $i (0 .. $nb - 1) {
        ode_get_body($i, $buf_ptr);
        my @d = unpack('f12', $buf);
        my ($px,$py,$pz,$qx,$qy,$qz,$qw,$type,$size,$cr,$cg,$cb) = @d;

        my $sc = $type == 0 ? $size/2 : $size;
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

    glutSetWindowTitle(sprintf "Slope Chase — lead at (%.1f, %.1f) — ESC to quit", $lx, $ly);
    glutSwapBuffers();
}

sub idle { glutPostRedisplay() }
sub keyboard { exit(0) if ord($_[0]) == 27 }

glutInit();
glutInitDisplayMode(GLUT_DOUBLE|GLUT_RGBA|GLUT_DEPTH|GLUT_MULTISAMPLE);
glutInitWindowSize($W,$H);
glutCreateWindow('Slope Chase');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "Slope chase: %.0fm slope, %d shapes, camera follows lead cube — ESC to quit\n",
    $slope_len, ode_get_num_bodies();
glutMainLoop();
ode_cleanup();
