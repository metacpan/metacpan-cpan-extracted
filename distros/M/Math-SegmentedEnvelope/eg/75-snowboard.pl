#!/usr/bin/env perl
# Snowboard simulation: segmented elastic board on envelope terrain
# Board = 8 rigid segments connected by spring-hinge joints (wood flex)
# Terrain from crossed envelope splines, soft ODE contact (snow compression)
# Rider = 2 jointed bodies on center segment
# ALL dynamics from ODE collision + gravity. No hack forces.
#
# Build: cd eg && cc -shared -fPIC -O2 -o libsnowboard_helper.so snowboard_helper.c $(pkg-config --cflags --libs ode) -lm
#
# Requires: FFI::Platypus, OpenGL::Modern, OpenGL::GLUT, OpenGL::Array
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
use Getopt::Long;

my $do_screenshots = 0;
my $do_grid = 0;
my $straight = 0;
my $no_rider = 0;
GetOptions('screenshots' => \$do_screenshots, 'grid' => \$do_grid,
           'straight' => \$straight, 'no-rider' => \$no_rider);

my $W = 1000;
my $H = 700;
my $PI = 3.14159265358979323846;
my $NUM_SEG = 8;

my $slope_len = 200.0;
my $slope_wid = 30.0;
my $slope_drop = 90.0;
my $GRID_X = 200;
my $GRID_Z = 60;
my $board_len = 3.0;
my $board_wid = 0.5;
my $board_thk = 0.05;

# FFI
my $lib = "$FindBin::Bin/libsnowboard_helper.so";
die "Build helper first\n" unless -f $lib;
my $ffi = FFI::Platypus->new(api => 2, lib => [$lib]);
$ffi->attach(snow_init => ['float'] => 'void');
$ffi->attach(snow_set_heightfield => ['opaque','int','int','float','float','float','float'] => 'void');
$ffi->attach(snow_create_board => ['float','float','float','float','float','float','float','float'] => 'void');
$ffi->attach(snow_set_rider => ['float','float'] => 'void');
$ffi->attach(snow_step => ['float'] => 'void');
$ffi->attach(snow_get_segments => ['opaque'] => 'void');
$ffi->attach(snow_get_rider => ['opaque'] => 'void');
$ffi->attach(snow_get_board_info => ['opaque'] => 'void');
$ffi->attach(snow_get_spray => ['opaque','int'] => 'int');
$ffi->attach(snow_cleanup => [] => 'void');
$ffi->attach(snow_set_has_rider => ['int'] => 'void');

# Terrain from envelope splines
my $slope_profile = spline(
    [0, 0.08, 0.18, 0.3, 0.42, 0.55, 0.65, 0.78, 0.88, 1.0],
    [1.0, 0.93, 0.88, 0.78, 0.72, 0.6, 0.52, 0.38, 0.22, 0.03],
    resolution => 4);
my $cross_profile = spline(
    [0, 0.15, 0.35, 0.5, 0.65, 0.85, 1.0],
    [0.15, 0.04, 0.005, 0, 0.005, 0.04, 0.15]);  # steeper valley walls

my $sp = $slope_profile->static; my $sd = $slope_profile->duration;
my $cp = $cross_profile->static; my $cd = $cross_profile->duration;

# Heightfield
my $hf_w = $GRID_X + 1;
my $hf_h = $GRID_Z + 1;
my ($hmin, $hmax) = (999, -999);
my @hf_vals;
for my $zi (0 .. $GRID_Z) {
    for my $xi (0 .. $GRID_X) {
        my $h = $sp->($xi/$GRID_X * $sd) * $slope_drop + $cp->($zi/$GRID_Z * $cd) * 2;
        push @hf_vals, $h;
        $hmin = $h if $h < $hmin;
        $hmax = $h if $h > $hmax;
    }
}
my $hf_data = pack('f*', @hf_vals);
my $hf_ptr = unpack('Q', pack('P', $hf_data));

# Terrain mesh for rendering
my (@tverts, @tidx);
for my $zi (0 .. $GRID_Z) {
    for my $xi (0 .. $GRID_X) {
        push @tverts, $xi/$GRID_X * $slope_len, $hf_vals[$zi*$hf_w+$xi], $zi/$GRID_Z * $slope_wid;
    }
}
for my $zi (0 .. $GRID_Z-1) {
    for my $xi (0 .. $GRID_X-1) {
        my $i = $zi*$hf_w+$xi;
        push @tidx, $i,$i+$hf_w,$i+1, $i+1,$i+$hf_w,$i+$hf_w+1;
    }
}

# Board outline envelope (snowboard shape)
my $board_outline = spline(
    [0, 0.08, 0.2, 0.4, 0.5, 0.6, 0.8, 0.92, 1.0],
    [0.03, 0.18, 0.25, 0.22, 0.20, 0.22, 0.25, 0.18, 0.03]);

# Generate 8 segment meshes from board outline (with slight overlap)
sub make_box_mesh {
    my ($hw,$hh,$hd) = @_;
    my @v;
    my @faces = (
        [$hw,-$hh,-$hd, $hw,$hh,-$hd, $hw,$hh,$hd, $hw,-$hh,-$hd, $hw,$hh,$hd, $hw,-$hh,$hd],
        [-$hw,-$hh,$hd, -$hw,$hh,$hd, -$hw,$hh,-$hd, -$hw,-$hh,$hd, -$hw,$hh,-$hd, -$hw,-$hh,-$hd],
        [-$hw,$hh,-$hd, $hw,$hh,-$hd, $hw,$hh,$hd, -$hw,$hh,-$hd, $hw,$hh,$hd, -$hw,$hh,$hd],
        [-$hw,-$hh,$hd, $hw,-$hh,$hd, $hw,-$hh,-$hd, -$hw,-$hh,$hd, $hw,-$hh,-$hd, -$hw,-$hh,-$hd],
        [-$hw,-$hh,$hd, $hw,-$hh,$hd, $hw,$hh,$hd, -$hw,-$hh,$hd, $hw,$hh,$hd, -$hw,$hh,$hd],
        [$hw,-$hh,-$hd, -$hw,-$hh,-$hd, -$hw,$hh,-$hd, $hw,-$hh,-$hd, -$hw,$hh,-$hd, $hw,$hh,-$hd],
    );
    for my $f (@faces) { push @v, @$f }
    return @v;
}

my @seg_meshes;  # array of arrayrefs, one per segment
my @seg_vcounts;
{
    my $bso = $board_outline->static;
    my $bsd = $board_outline->duration;
    my $seg_len = $board_len / $NUM_SEG;
    my $half_seg = $seg_len / 2;
    my $thick = $board_thk;
    my $slices_per_seg = 3;  # subdivisions within each segment

    for my $si (0 .. $NUM_SEG - 1) {
        my @sv;
        my $t0 = $si / $NUM_SEG;
        my $t1 = ($si + 1) / $NUM_SEG;
        for my $j (0 .. $slices_per_seg - 1) {
            my $s0 = $t0 + $j / $slices_per_seg * ($t1 - $t0);
            my $s1 = $t0 + ($j+1) / $slices_per_seg * ($t1 - $t0);
            my $x0 = -$half_seg + $j / $slices_per_seg * $seg_len;
            my $x1 = -$half_seg + ($j+1) / $slices_per_seg * $seg_len;
            my $w0 = $bso->($s0 * $bsd);
            my $w1 = $bso->($s1 * $bsd);
            # Top face
            push @sv, $x0,$thick,-$w0, $x1,$thick,-$w1, $x1,$thick,$w1;
            push @sv, $x0,$thick,-$w0, $x1,$thick,$w1, $x0,$thick,$w0;
            # Bottom face
            push @sv, $x0,-$thick,-$w0, $x1,-$thick,$w1, $x1,-$thick,-$w1;
            push @sv, $x0,-$thick,-$w0, $x0,-$thick,$w0, $x1,-$thick,$w1;
            # Side faces
            push @sv, $x0,-$thick,$w0, $x1,-$thick,$w1, $x1,$thick,$w1;
            push @sv, $x0,-$thick,$w0, $x1,$thick,$w1, $x0,$thick,$w0;
            push @sv, $x0,$thick,-$w0, $x1,$thick,-$w1, $x1,-$thick,-$w1;
            push @sv, $x0,$thick,-$w0, $x1,-$thick,-$w1, $x0,-$thick,-$w0;
        }
        push @seg_meshes, \@sv;
        push @seg_vcounts, scalar(@sv) / 3;
    }
}

# Rider body meshes
my @lower_v = make_box_mesh(0.20, 0.20, 0.22);
my @upper_v = make_box_mesh(0.25, 0.40, 0.18);
my @head_v  = make_box_mesh(0.12, 0.14, 0.13);
my @leg_v   = make_box_mesh(0.07, 0.50, 0.07);
my @arm_v   = make_box_mesh(0.055, 0.50, 0.055);
my @boot_v  = make_box_mesh(0.10, 0.08, 0.15);

sub limb_mat {
    my ($ax,$ay,$az, $bx,$by,$bz, $sc_w) = @_;
    $sc_w //= 1.0;
    my $dx=$bx-$ax; my $dy=$by-$ay; my $dz=$bz-$az;
    my $len = sqrt($dx*$dx+$dy*$dy+$dz*$dz) || 0.01;
    my ($yx,$yy,$yz) = ($dx/$len, $dy/$len, $dz/$len);
    my ($xx,$xy,$xz);
    if (abs($yy) < 0.99) {
        ($xx,$xy,$xz) = (-$yz, 0, $yx);
    } else {
        ($xx,$xy,$xz) = (1, 0, 0);
    }
    my $xl = sqrt($xx*$xx+$xy*$xy+$xz*$xz) || 1;
    ($xx,$xy,$xz) = ($xx/$xl, $xy/$xl, $xz/$xl);
    my ($zx,$zy,$zz) = ($xy*$yz-$xz*$yy, $xz*$yx-$xx*$yz, $xx*$yy-$xy*$yx);
    my $zl = sqrt($zx*$zx+$zy*$zy+$zz*$zz) || 1;
    ($zx,$zy,$zz) = ($zx/$zl, $zy/$zl, $zz/$zl);
    my $tx = ($ax+$bx)*0.5; my $ty = ($ay+$by)*0.5; my $tz = ($az+$bz)*0.5;
    return (
        $xx*$sc_w, $xy*$sc_w, $xz*$sc_w, 0,
        $yx*$len,  $yy*$len,  $yz*$len,  0,
        $zx*$sc_w, $zy*$sc_w, $zz*$sc_w, 0,
        $tx, $ty, $tz, 1
    );
}

# Rider state
my $rider_fore_aft = 0;
my $rider_lean = 0;

# Camera
my ($cam_x, $cam_y, $cam_z) = (0, 5, 0);

# Trail
my @trail;
my $trail_max = 64;
my $trail_interval = 0.08;
my $trail_last_t = 0;

# Shaders
my $tv_s = <<'GLSL';
#version 330
layout(location=0) in vec3 aPos;
out vec3 vP; out vec3 vWorld;
uniform mat4 uMVP;
void main() { vP=aPos; vWorld=aPos; gl_Position=uMVP*vec4(aPos,1); }
GLSL
my $tg_s = <<'GLSL';
#version 330
layout(triangles) in; layout(triangle_strip,max_vertices=3) out;
in vec3 vP[]; in vec3 vWorld[];
out vec4 fC; out vec3 fWorld; out vec3 fNormal;
uniform float uTime; uniform vec3 uBoardPos;
uniform vec4 uTrail[64]; uniform int uTrailN;
void main() {
    vec3 fn=normalize(cross(vP[1]-vP[0],vP[2]-vP[0]));
    vec3 light=normalize(vec3(0.3,0.85,0.15));
    vec3 light2=normalize(vec3(-0.5,0.3,0.8));
    float diff=max(dot(fn,light),0.0);
    float diff2=max(dot(fn,light2),0.0)*0.3;
    float ambient=0.35;
    for(int i=0;i<3;i++){
        gl_Position=gl_in[i].gl_Position; fWorld=vWorld[i]; fNormal=fn;
        float h=vP[i].y;
        vec3 snow_shadow=vec3(0.72,0.78,0.88);
        vec3 snow_lit=vec3(0.92,0.93,0.96);
        vec3 c=mix(snow_shadow,snow_lit,diff);
        float sss=max(dot(-fn,light),0.0)*0.12;
        c+=vec3(0.85,0.88,0.95)*sss;
        float hn=clamp(h/40.0,0.0,1.0);
        c=mix(c,vec3(0.65,0.72,0.82),(1.0-hn)*0.2);
        c*=ambient+diff*0.5+diff2;
        c=clamp(c,0.0,1.0);
        c=max(c,vec3(0.55,0.58,0.65));
        // Trail
        float track=0.0;
        for(int j=0;j<uTrailN;j++){
            float tdx=vWorld[i].x-uTrail[j].x;
            float tdz=vWorld[i].z-uTrail[j].y;
            float tw=uTrail[j].w;
            float td2=(tdx*tdx+tdz*tdz)/(tw*tw+0.001);
            track+=exp(-td2*8.0)*(1.0-uTrail[j].z*0.7);
        }
        track=clamp(track,0.0,1.0);
        c*=1.0-track*0.25;
        c+=vec3(-0.02,-0.01,0.04)*track;
        fC=vec4(c,1.0); EmitVertex();
    }
    EndPrimitive();
}
GLSL
my $tf_s = <<'GLSL';
#version 330
in vec4 fC; in vec3 fWorld; in vec3 fNormal; out vec4 o;
uniform float uTime; uniform vec3 uCamPos; uniform float uGrid;
float hash2(vec2 p){vec3 p3=fract(vec3(p.xyx)*vec3(0.1031,0.1030,0.0973));
    p3+=dot(p3,p3.yzx+33.33);return fract((p3.x+p3.y)*p3.z);}
void main(){
    vec3 c=fC.rgb;
    vec3 view=normalize(uCamPos-fWorld);
    float dist=length(uCamPos-fWorld);
    float da=1.0/(1.0+dist*0.04);
    float sp1=hash2(floor(fWorld.xz*30.0));
    float sp2=hash2(floor(fWorld.xz*90.0+vec2(7.3,13.1)));
    float sm=max(step(0.94,sp1),step(0.97,sp2));
    vec3 light=normalize(vec3(0.3,0.85,0.15));
    vec3 hv=normalize(view+light);
    float spec=pow(max(dot(fNormal,hv),0.0),12.0);
    float tw=sin(uTime*5.0+sp1*60.0)*0.5+0.5;
    c+=vec3(1.0,0.98,0.95)*sm*(spec*0.5+0.25)*tw*da*1.5;
    float fresnel=pow(1.0-max(dot(fNormal,view),0.0),3.0);
    c+=vec3(0.7,0.75,0.85)*fresnel*0.12;
    if(uGrid>0.5){
        vec2 w=fWorld.xz;
        vec2 f1=fract(w); vec2 d1=min(f1,1.0-f1);
        float l1=clamp((1.0-smoothstep(0.0,0.02,d1.x))+(1.0-smoothstep(0.0,0.02,d1.y)),0.0,1.0);
        vec2 f5=fract(w/5.0); vec2 d5=min(f5,1.0-f5)*5.0;
        float l5=clamp((1.0-smoothstep(0.0,0.05,d5.x))+(1.0-smoothstep(0.0,0.05,d5.y)),0.0,1.0);
        vec2 f10=fract(w/10.0); vec2 d10=min(f10,1.0-f10)*10.0;
        float l10=clamp((1.0-smoothstep(0.0,0.10,d10.x))+(1.0-smoothstep(0.0,0.10,d10.y)),0.0,1.0);
        float fade=1.0-smoothstep(15.0,50.0,dist);
        c=mix(c,vec3(0.20,0.30,0.55),l1*0.25*fade);
        c=mix(c,vec3(0.10,0.20,0.50),l5*0.45);
        c=mix(c,vec3(0.80,0.10,0.10),l10*0.70);
    }
    vec3 fog=vec3(0.65,0.73,0.87);
    c=mix(c,fog,1.0-exp(-dist*0.008));
    o=vec4(c,1.0);
}
GLSL
my $sv_s = <<'GLSL';
#version 330
layout(location=0) in vec3 aPos; out vec3 vN;
uniform mat4 uMVP; uniform mat4 uM;
void main(){vN=mat3(uM)*aPos;gl_Position=uMVP*(uM*vec4(aPos,1));}
GLSL
my $sg_s = <<'GLSL';
#version 330
layout(triangles) in; layout(triangle_strip,max_vertices=3) out;
in vec3 vN[]; out vec4 fC; uniform vec4 uC;
void main(){
    vec3 fn=normalize(cross(vN[1]-vN[0],vN[2]-vN[0]));
    float d=max(dot(fn,normalize(vec3(0.4,0.8,0.3))),0.0);
    float d2=max(dot(fn,normalize(vec3(-0.3,0.6,0.5))),0.0)*0.3;
    for(int i=0;i<3;i++){gl_Position=gl_in[i].gl_Position;
        fC=vec4(uC.rgb*(0.5+d*0.4+d2),uC.a);EmitVertex();}EndPrimitive();}
GLSL
my $sf_s = <<'GLSL';
#version 330
in vec4 fC; out vec4 o; void main(){o=fC;}
GLSL
my $pv_s = <<'GLSL';
#version 330
layout(location=0) in vec3 aPos; layout(location=1) in float aAlpha;
layout(location=2) in float aSize;
out float vAlpha; uniform mat4 uMVP;
void main(){gl_Position=uMVP*vec4(aPos,1);gl_PointSize=aSize*500.0/gl_Position.w;vAlpha=aAlpha;}
GLSL
my $pf_s = <<'GLSL';
#version 330
in float vAlpha; out vec4 o;
void main(){vec2 c=gl_PointCoord*2.0-1.0;float d=dot(c,c);
    if(d>1.0)discard;o=vec4(0.9,0.92,0.95,(1.0-d)*vAlpha*0.6);}
GLSL

my ($pt,$ps,$pp,$utm,$usm,$usmm,$usc,$upm,$ut_time,$ut_board,$ut_cam,$ut_trail,$ut_trailn,$ut_grid);
my ($vat,$vbt,$ibt,$vap,$vbp,$start);
my (@seg_vaos, @seg_vbos);  # per-segment board mesh VAOs
my ($val,$vbl,$vau,$vbu,$vah,$vbh,$valeg,$vbleg,$vaarm,$vbarm,$vaboot,$vbboot);

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
    my ($qx,$qy,$qz,$qw, $tx,$ty,$tz, $sc) = @_;
    my ($xx,$yy,$zz) = ($qx*$qx, $qy*$qy, $qz*$qz);
    my ($xy,$xz,$yz) = ($qx*$qy, $qx*$qz, $qy*$qz);
    my ($wx,$wy,$wz) = ($qw*$qx, $qw*$qy, $qw*$qz);
    return (
        $sc*(1-2*($yy+$zz)), $sc*(2*($xy+$wz)),   $sc*(2*($xz-$wy)),   0,
        $sc*(2*($xy-$wz)),   $sc*(1-2*($xx+$zz)),  $sc*(2*($yz+$wx)),   0,
        $sc*(2*($xz+$wy)),   $sc*(2*($yz-$wx)),    $sc*(1-2*($xx+$yy)), 0,
        $tx, $ty, $tz, 1
    );
}

# Buffers
my $seg_buf = "\0" x (56 * 4);  # 8 segments * 7 floats * 4 bytes
my $seg_ptr = unpack('Q', pack('P', $seg_buf));
my $rider_buf = "\0" x (14 * 4);
my $rider_ptr = unpack('Q', pack('P', $rider_buf));
my $info_buf = "\0" x (2 * 4);
my $info_ptr = unpack('Q', pack('P', $info_buf));
my $spray_buf = "\0" x (512 * 5 * 4);
my $spray_ptr = unpack('Q', pack('P', $spray_buf));

sub spawn_board {
    my $sx = $slope_len * 0.15;
    my $sz = $slope_wid * 0.5;
    # Terrain height at spawn (center)
    my $h_center = $sp->($sx / $slope_len * $sd) * $slope_drop;
    my $sy = $h_center + 0.3;  # just above terrain — no big drop
    snow_create_board($board_len, $board_wid, $board_thk, 5.0, $sx, $sy, $sz, 0.0);
    ($cam_x,$cam_y,$cam_z) = ($sx - 4, $sy + 2.5, $sz + 3);
    @trail = ();
}

sub init_gl {
    $pt=lp(cs(GL_VERTEX_SHADER,$tv_s),cs(GL_GEOMETRY_SHADER,$tg_s),cs(GL_FRAGMENT_SHADER,$tf_s));
    $utm=glGetUniformLocation($pt,'uMVP');
    $ut_time=glGetUniformLocation($pt,'uTime');
    $ut_board=glGetUniformLocation($pt,'uBoardPos');
    $ut_cam=glGetUniformLocation($pt,'uCamPos');
    $ut_trail=glGetUniformLocation($pt,'uTrail');
    $ut_trailn=glGetUniformLocation($pt,'uTrailN');
    $ut_grid=glGetUniformLocation($pt,'uGrid');
    $ps=lp(cs(GL_VERTEX_SHADER,$sv_s),cs(GL_GEOMETRY_SHADER,$sg_s),cs(GL_FRAGMENT_SHADER,$sf_s));
    $usm=glGetUniformLocation($ps,'uMVP');$usmm=glGetUniformLocation($ps,'uM');$usc=glGetUniformLocation($ps,'uC');
    $pp=lp(cs(GL_VERTEX_SHADER,$pv_s),cs(GL_FRAGMENT_SHADER,$pf_s));
    $upm=glGetUniformLocation($pp,'uMVP');

    # Terrain mesh
    ($vat)=glGenVertexArrays_p(1);($vbt)=glGenBuffers_p(1);($ibt)=glGenBuffers_p(1);
    glBindVertexArray($vat);glBindBuffer(GL_ARRAY_BUFFER,$vbt);
    my $tv=OpenGL::Array->new_list(GL_FLOAT,@tverts);
    glBufferData_c(GL_ARRAY_BUFFER,$tv->length,$tv->ptr,GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);glVertexAttribPointer_c(0,3,GL_FLOAT,GL_FALSE,0,0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,$ibt);
    my $ti=OpenGL::Array->new_list(GL_UNSIGNED_INT,@tidx);
    glBufferData_c(GL_ELEMENT_ARRAY_BUFFER,$ti->length,$ti->ptr,GL_STATIC_DRAW);
    glBindVertexArray(0);

    # Per-segment board meshes
    for my $i (0 .. $NUM_SEG - 1) {
        my ($va)=glGenVertexArrays_p(1);my ($vb)=glGenBuffers_p(1);
        glBindVertexArray($va);glBindBuffer(GL_ARRAY_BUFFER,$vb);
        my $a=OpenGL::Array->new_list(GL_FLOAT,@{$seg_meshes[$i]});
        glBufferData_c(GL_ARRAY_BUFFER,$a->length,$a->ptr,GL_STATIC_DRAW);
        glEnableVertexAttribArray(0);glVertexAttribPointer_c(0,3,GL_FLOAT,GL_FALSE,0,0);
        glBindVertexArray(0);
        push @seg_vaos, $va;
        push @seg_vbos, $vb;
    }

    # Rider body part meshes
    for my $pair ([\$val,\$vbl,\@lower_v], [\$vau,\$vbu,\@upper_v],
                  [\$vah,\$vbh,\@head_v], [\$valeg,\$vbleg,\@leg_v],
                  [\$vaarm,\$vbarm,\@arm_v], [\$vaboot,\$vbboot,\@boot_v]) {
        my ($va_r,$vb_r,$verts) = @$pair;
        ($$va_r)=glGenVertexArrays_p(1);($$vb_r)=glGenBuffers_p(1);
        glBindVertexArray($$va_r);glBindBuffer(GL_ARRAY_BUFFER,$$vb_r);
        my $a=OpenGL::Array->new_list(GL_FLOAT,@$verts);
        glBufferData_c(GL_ARRAY_BUFFER,$a->length,$a->ptr,GL_STATIC_DRAW);
        glEnableVertexAttribArray(0);glVertexAttribPointer_c(0,3,GL_FLOAT,GL_FALSE,0,0);
        glBindVertexArray(0);
    }

    # Spray particles
    ($vap)=glGenVertexArrays_p(1);($vbp)=glGenBuffers_p(1);

    glEnable(GL_DEPTH_TEST);glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_PROGRAM_POINT_SIZE);

    # Physics init
    snow_init(-3.0);
    snow_set_has_rider($no_rider ? 0 : 1);
    snow_set_heightfield($hf_ptr, $hf_w, $hf_h, $slope_len, $slope_wid, $hmin, $hmax);
    spawn_board();
    $start = time();
}

sub display {
    my $t = time() - $start;

    # Get center segment position for respawn check
    snow_get_segments($seg_ptr);
    my @segs = unpack('f56', $seg_buf);
    my ($cx,$cy,$cz) = ($segs[3*7], $segs[3*7+1], $segs[3*7+2]);  # seg[3] center
    my $ch = $sp->($cx / $slope_len * $sd) * $slope_drop;

    # Respawn if off slope
    if ($cx > $slope_len * 0.9 || $cy < $ch - 3
        || $cz < -1 || $cz > $slope_wid + 1) {
        snow_cleanup();
        snow_init(-3.0);
        snow_set_has_rider($no_rider ? 0 : 1);
        snow_set_heightfield($hf_ptr, $hf_w, $hf_h, $slope_len, $slope_wid, $hmin, $hmax);
        spawn_board();
    }

    # Rider S-turn control (disabled with --straight)
    if ($straight) {
        $rider_lean = 0;
        $rider_fore_aft = 0;
    } else {
        my $turn_freq = 0.35;
        my $phase = $t * $turn_freq * 2 * $PI;
        $rider_lean = sin($phase) * 0.3;
        $rider_fore_aft = cos($phase) * 0.15;
    }
    snow_set_rider($rider_fore_aft, $rider_lean);

    snow_step(1.0/60.0);

    # Get states
    snow_get_segments($seg_ptr);
    @segs = unpack('f56', $seg_buf);
    snow_get_board_info($info_ptr);
    my ($speed, $bedge) = unpack('f2', $info_buf);
    snow_get_rider($rider_ptr);
    my @r = unpack('f14', $rider_buf);

    # Center of board (average of seg[3] and seg[4])
    my $bx = ($segs[3*7] + $segs[4*7]) / 2;
    my $by = ($segs[3*7+1] + $segs[4*7+1]) / 2;
    my $bz = ($segs[3*7+2] + $segs[4*7+2]) / 2;

    # Trail
    if ($t - $trail_last_t > $trail_interval && $speed > 0.1) {
        unshift @trail, [$bx, $bz, 0, 0.15 + abs($bedge) * 0.10];
        pop @trail if @trail > $trail_max;
        $trail_last_t = $t;
    }
    for my $tp (@trail) { $tp->[2] += 1.0 / 60.0 / 8.0; }
    @trail = grep { $_->[2] < 1.0 } @trail;

    # Camera
    my $tx = $bx - 4;
    my $ty = $by + 2.5;
    my $tz = $bz + 3;
    $cam_x += ($tx - $cam_x) * 0.06;
    $cam_y += ($ty - $cam_y) * 0.06;
    $cam_z += ($tz - $cam_z) * 0.06;

    glClearColor(0.6, 0.7, 0.85, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    my @proj = m4p(60, $W/$H, 0.1, 500);
    my @view = m4l($cam_x,$cam_y,$cam_z, $bx+2,$by-0.5,$bz, 0,1,0);
    my @mvp = m4m(\@proj, \@view);
    my $m = OpenGL::Array->new_list(GL_FLOAT, @mvp);

    # Terrain
    glUseProgram($pt);
    glUniformMatrix4fv_c($utm,1,GL_FALSE,$m->ptr);
    glUniform1f($ut_time, $t);
    glUniform3f($ut_board, $bx, $by, $bz);
    glUniform3f($ut_cam, $cam_x, $cam_y, $cam_z);
    glUniform1f($ut_grid, $do_grid ? 1.0 : 0.0);
    my $tn = scalar @trail;
    glUniform1i($ut_trailn, $tn);
    if ($tn > 0) {
        my @td; for my $tp (@trail) { push @td, @$tp; }
        my $ta = OpenGL::Array->new_list(GL_FLOAT, @td);
        glUniform4fv_c($ut_trail, $tn, $ta->ptr);
    }
    glBindVertexArray($vat);glDrawElements_c(GL_TRIANGLES,scalar@tidx,GL_UNSIGNED_INT,0);glBindVertexArray(0);

    # Board segments -- each rendered at its ODE transform
    glUseProgram($ps);glUniformMatrix4fv_c($usm,1,GL_FALSE,$m->ptr);
    for my $i (0 .. $NUM_SEG - 1) {
        my $o = $i * 7;
        my @sm = quat_to_mat($segs[$o+3],$segs[$o+4],$segs[$o+5],$segs[$o+6],
                             $segs[$o],$segs[$o+1],$segs[$o+2], 1.0);
        my $mm = OpenGL::Array->new_list(GL_FLOAT, @sm);
        glUniformMatrix4fv_c($usmm,1,GL_FALSE,$mm->ptr);
        glUniform4f($usc, 0.85, 0.12, 0.15, 1.0);
        glBindVertexArray($seg_vaos[$i]);
        glDrawArrays(GL_TRIANGLES, 0, $seg_vcounts[$i]);
        glBindVertexArray(0);
    }

    goto SKIP_RIDER if $no_rider;

    # Rider is kinematic — compute position from center segment
    # Hips above center segment, torso above hips (rider orientation matches board)
    my ($cseg_x, $cseg_y, $cseg_z) = ($segs[3*7], $segs[3*7+1], $segs[3*7+2]);
    my @cseg_q = ($segs[3*7+3], $segs[3*7+4], $segs[3*7+5], $segs[3*7+6]);
    # Board "up" axis from quaternion
    my @bmat_tmp = quat_to_mat(@cseg_q, 0,0,0, 1.0);
    my ($up_x, $up_y, $up_z) = ($bmat_tmp[4], $bmat_tmp[5], $bmat_tmp[6]);
    my $hip_height = 0.55;
    my ($lx, $ly, $lz) = (
        $cseg_x + $up_x * $hip_height,
        $cseg_y + $up_y * $hip_height,
        $cseg_z + $up_z * $hip_height,
    );
    # Use board's quaternion for both lower and upper body (rigid upright rider)
    my @lq = @cseg_q;
    my @uq = @cseg_q;
    my $torso_y = $ly + $up_y * 0.55;
    my ($ux, $uy, $uz) = (
        $lx + $up_x * 0.55,
        $ly + $up_y * 0.55,
        $lz + $up_z * 0.55,
    );

    my $draw_quat = sub {
        my ($vao, $count, $px,$py,$pz, $cr,$cg,$cb, $q_ref) = @_;
        my @pm = quat_to_mat(@$q_ref, $px,$py,$pz, 1.0);
        my $mm = OpenGL::Array->new_list(GL_FLOAT, @pm);
        glUniformMatrix4fv_c($usmm,1,GL_FALSE,$mm->ptr);
        glUniform4f($usc, $cr,$cg,$cb, 1.0);
        glBindVertexArray($vao);
        glDrawArrays(GL_TRIANGLES, 0, $count);
        glBindVertexArray(0);
    };
    my $draw_limb = sub {
        my ($vao,$count, $ax,$ay,$az, $bxx,$byy,$bzz, $cr,$cg,$cb) = @_;
        my @lm = limb_mat($ax,$ay,$az, $bxx,$byy,$bzz, 1.0);
        my $mm = OpenGL::Array->new_list(GL_FLOAT, @lm);
        glUniformMatrix4fv_c($usmm,1,GL_FALSE,$mm->ptr);
        glUniform4f($usc, $cr,$cg,$cb, 1.0);
        glBindVertexArray($vao);
        glDrawArrays(GL_TRIANGLES, 0, $count);
        glBindVertexArray(0);
    };

    # Board axes from center segment quat
    my @bm = quat_to_mat($segs[3*7+3],$segs[3*7+4],$segs[3*7+5],$segs[3*7+6], 0,0,0, 1.0);
    my ($bfx,$bfy,$bfz) = ($bm[0],$bm[1],$bm[2]);
    my ($bux,$buy,$buz) = ($bm[4],$bm[5],$bm[6]);
    my ($brx,$bry,$brz) = ($bm[8],$bm[9],$bm[10]);

    # Binding positions (from front/rear segment positions)
    my ($fb_x,$fb_y,$fb_z) = ($segs[5*7], $segs[5*7+1]+$board_thk/2+0.06, $segs[5*7+2]);
    my ($rb_x,$rb_y,$rb_z) = ($segs[2*7], $segs[2*7+1]+$board_thk/2+0.06, $segs[2*7+2]);

    # Boots
    $draw_quat->($vaboot, scalar(@boot_v)/3, $fb_x,$fb_y,$fb_z, 0.2,0.2,0.22, \@lq);
    $draw_quat->($vaboot, scalar(@boot_v)/3, $rb_x,$rb_y,$rb_z, 0.2,0.2,0.22, \@lq);

    # Legs (boot to hip with knee bend)
    my $knee_h = 0.40;
    my $knee_fwd = 0.20;
    my $fk_x = $fb_x*(1-$knee_h)+$lx*$knee_h+$bfx*$knee_fwd;
    my $fk_y = $fb_y+($ly-$fb_y)*$knee_h;
    my $fk_z = $fb_z*(1-$knee_h)+$lz*$knee_h+$bfz*$knee_fwd;
    my $rk_x = $rb_x*(1-$knee_h)+$lx*$knee_h+$bfx*$knee_fwd;
    my $rk_y = $rb_y+($ly-$rb_y)*$knee_h;
    my $rk_z = $rb_z*(1-$knee_h)+$lz*$knee_h+$bfz*$knee_fwd;

    $draw_limb->($valeg,scalar(@leg_v)/3, $fb_x,$fb_y+0.08,$fb_z, $fk_x,$fk_y,$fk_z, 0.12,0.15,0.32);
    $draw_limb->($valeg,scalar(@leg_v)/3, $rb_x,$rb_y+0.08,$rb_z, $rk_x,$rk_y,$rk_z, 0.12,0.15,0.32);
    $draw_limb->($valeg,scalar(@leg_v)/3, $fk_x,$fk_y,$fk_z, $lx+$brx*0.12,$ly-0.05,$lz+$brz*0.12, 0.12,0.15,0.32);
    $draw_limb->($valeg,scalar(@leg_v)/3, $rk_x,$rk_y,$rk_z, $lx-$brx*0.12,$ly-0.05,$lz-$brz*0.12, 0.12,0.15,0.32);

    # Hips
    $draw_quat->($val, scalar(@lower_v)/3, $lx,$ly-0.05,$lz, 0.15,0.18,0.35, \@lq);
    # Torso
    $draw_quat->($vau, scalar(@upper_v)/3, $ux,$uy,$uz, 0.9,0.45,0.1, \@uq);

    # Upper body axes for arms
    my @um = quat_to_mat(@uq, 0,0,0, 1.0);
    my ($ufx,$ufy,$ufz) = ($um[0],$um[1],$um[2]);
    my ($uux,$uuy,$uuz) = ($um[4],$um[5],$um[6]);
    my ($urx,$ury,$urz) = ($um[8],$um[9],$um[10]);

    # Arms with turn swing
    my $sh_w = 0.28;
    my $arm_swing = $rider_lean * 0.25;
    my $ls_x=$ux-$urx*$sh_w; my $ls_y=$uy+$uuy*0.25-$ury*$sh_w; my $ls_z=$uz-$urz*$sh_w;
    my $lh_x=$ls_x-$urx*0.18+$ufx*(0.1-$arm_swing);
    my $lh_y=$ls_y-0.50; my $lh_z=$ls_z-$urz*0.18+$ufz*(0.1-$arm_swing);
    $draw_limb->($vaarm,scalar(@arm_v)/3, $ls_x,$ls_y,$ls_z, $lh_x,$lh_y,$lh_z, 0.85,0.40,0.08);
    my $rs_x=$ux+$urx*$sh_w; my $rs_y=$uy+$uuy*0.25+$ury*$sh_w; my $rs_z=$uz+$urz*$sh_w;
    my $rh_x=$rs_x+$urx*0.18+$ufx*(0.1+$arm_swing);
    my $rh_y=$rs_y-0.50; my $rh_z=$rs_z+$urz*0.18+$ufz*(0.1+$arm_swing);
    $draw_limb->($vaarm,scalar(@arm_v)/3, $rs_x,$rs_y,$rs_z, $rh_x,$rh_y,$rh_z, 0.85,0.40,0.08);

    # Head
    $draw_quat->($vah, scalar(@head_v)/3, $ux+$uux*0.48,$uy+$uuy*0.48,$uz+$uuz*0.48, 0.25,0.25,0.28, \@uq);

    SKIP_RIDER:

    # Spray particles
    my $nspray = snow_get_spray($spray_ptr, 512);
    if ($nspray > 0) {
        my @sd = unpack("f" . ($nspray * 5), $spray_buf);
        glUseProgram($pp);glUniformMatrix4fv_c($upm,1,GL_FALSE,$m->ptr);
        my $soa = OpenGL::Array->new_list(GL_FLOAT, @sd[0 .. $nspray*5-1]);
        glBindVertexArray($vap);glBindBuffer(GL_ARRAY_BUFFER,$vbp);
        glBufferData_c(GL_ARRAY_BUFFER,$soa->length,$soa->ptr,GL_DYNAMIC_DRAW);
        glEnableVertexAttribArray(0);glVertexAttribPointer_c(0, 3, GL_FLOAT, GL_FALSE, 5*4, 0);
        glEnableVertexAttribArray(1);glVertexAttribPointer_c(1, 1, GL_FLOAT, GL_FALSE, 5*4, 3*4);
        glEnableVertexAttribArray(2);glVertexAttribPointer_c(2, 1, GL_FLOAT, GL_FALSE, 5*4, 4*4);
        glDepthMask(GL_FALSE);
        glDrawArrays(GL_POINTS, 0, $nspray);
        glDepthMask(GL_TRUE);
        glBindVertexArray(0);
    }

    # Yaw (heading rotation around Y) from center segment quaternion
    my ($qx,$qy,$qz,$qw) = ($segs[3*7+3],$segs[3*7+4],$segs[3*7+5],$segs[3*7+6]);
    my $yaw_rad = atan2(2*($qw*$qy + $qx*$qz), 1 - 2*($qy*$qy + $qz*$qz));
    my $yaw_deg = $yaw_rad * 180 / $PI;

    glutSetWindowTitle(sprintf "Snowboard — %.1f m/s — edge %.0f%% — yaw %+.1f° — pos(%.1f,%.1f) — ESC",
        $speed, $bedge * 100, $yaw_deg, $bx, $bz);


    # HUD (opt-in with --grid): yaw, pos, speed — top-left corner
    if ($do_grid) {
        glUseProgram(0);
        glDisable(GL_DEPTH_TEST);
        glColor3f(0.05, 0.05, 0.05);
        glWindowPos2i(10, $H - 20);
        my $hud = sprintf "t=%.2fs pos=(%.2f, %.2f, %.2f) yaw=%+.1f° speed=%.2f",
            $t, $bx, $by, $bz, $yaw_deg, $speed;
        glutBitmapCharacter(GLUT_BITMAP_HELVETICA_18, ord($_)) for split //, $hud;
        glWindowPos2i(10, $H - 40);
        my $hud2 = sprintf "lean=%+.2f fore_aft=%+.2f (%s)",
            $rider_lean, $rider_fore_aft, $straight ? "STRAIGHT" : "S-turn";
        glutBitmapCharacter(GLUT_BITMAP_HELVETICA_12, ord($_)) for split //, $hud2;
    }

    # Grid numeric labels (opt-in) — only within camera range
    if ($do_grid) {
        glUseProgram(0);
        glDisable(GL_DEPTH_TEST);
        for (my $gx = 0; $gx <= $slope_len; $gx += 1) {
            for my $gz (2, 7.5, 15, 22.5, 28) {
                my $dx = $gx - $cam_x; my $dz = $gz - $cam_z;
                my $d = sqrt($dx*$dx + $dz*$dz);
                next if $d > 35;
                my $major = ($gx % 10 == 0);
                my $mid   = ($gx % 5 == 0);
                next if !$major && !$mid && $d > 8;
                next if !$major && $mid && $d > 20;
                my $gh = $sp->($gx/$slope_len * $sd) * $slope_drop
                       + $cp->($gz/$slope_wid * $cd) * 2 + 0.15;
                my $cx_c = $mvp[0]*$gx + $mvp[4]*$gh + $mvp[8]*$gz + $mvp[12];
                my $cy_c = $mvp[1]*$gx + $mvp[5]*$gh + $mvp[9]*$gz + $mvp[13];
                my $cw_c = $mvp[3]*$gx + $mvp[7]*$gh + $mvp[11]*$gz + $mvp[15];
                next if $cw_c <= 0.01;
                my $ndcx = $cx_c/$cw_c; my $ndcy = $cy_c/$cw_c;
                next if $ndcx < -0.98 || $ndcx > 0.98 || $ndcy < -0.98 || $ndcy > 0.98;
                my $px = int(($ndcx*0.5+0.5)*$W);
                my $py = int(($ndcy*0.5+0.5)*$H);
                glWindowPos2i($px, $py);
                my $gy = $gh - 0.15;  # actual terrain height (without label offset)
                my $str = $major ? sprintf("x%d z%g y%.1f", $gx, $gz, $gy)
                       : $mid   ? sprintf("%d/%g/%.0f", $gx, $gz, $gy)
                                : sprintf("%d", $gx);
                my $font = $major ? GLUT_BITMAP_HELVETICA_18
                         : $mid   ? GLUT_BITMAP_HELVETICA_12
                                  : GLUT_BITMAP_HELVETICA_10;
                if ($major)    { glColor3f(1.0, 0.05, 0.05); }
                elsif ($mid)   { glColor3f(0.15, 0.2, 0.7); }
                else           { glColor3f(0.25, 0.25, 0.35); }
                glutBitmapCharacter($font, ord($_)) for split //, $str;
            }
        }
        glEnable(GL_DEPTH_TEST);
    }

    # Screenshot (opt-in) — every 0.25s
    if ($do_screenshots) {
        my $slot = int($t * 4);  # 0.25s quanta
        our %_shots;
        if ($slot >= 0 && $slot < 48 && !$_shots{$slot} && $t > $slot * 0.25 + 0.02) {
            $_shots{$slot} = 1;
            my $oa = OpenGL::Array->new($W * $H * 3, GL_UNSIGNED_BYTE);
            glReadPixels_c(0, 0, $W, $H, GL_RGB, GL_UNSIGNED_BYTE, $oa->ptr);
            my $file = sprintf "/tmp/snowboard_screenshots/frame_%03d.ppm", $slot;
            if (open my $fh, '>', $file) {
                binmode $fh;
                print $fh "P6\n$W $H\n255\n";
                my $raw = $oa->retrieve_data(0, $W * $H * 3);
                for my $row (reverse 0 .. $H - 1) {
                    print $fh substr($raw, $row * $W * 3, $W * 3);
                }
                close $fh;
                warn "Screenshot: $file\n";
            }
        }
    }

    glutSwapBuffers();
}

sub idle { glutPostRedisplay() }
sub keyboard { exit(0) if ord($_[0]) == 27 }

glutInit();
glutInitDisplayMode(GLUT_DOUBLE|GLUT_RGBA|GLUT_DEPTH|GLUT_MULTISAMPLE);
glutInitWindowSize($W,$H);
glutCreateWindow('Snowboard');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "Snowboard: %.0fm slope, %d-segment elastic board, ODE physics — ESC to quit\n",
    $slope_len, $NUM_SEG;
glutMainLoop();
snow_cleanup();
