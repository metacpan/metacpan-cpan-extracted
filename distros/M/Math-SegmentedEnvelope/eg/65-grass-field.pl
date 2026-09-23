#!/usr/bin/env perl
# Grass field: thousands of envelope-shaped grass blades swaying in wind
# Each blade's height, curvature, and sway is controlled by envelopes
# Blades are clustered in patches with varying density and color
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

use Math::SegmentedEnvelope qw(env spline);
use Time::HiRes qw(time);
use POSIX qw(tan floor);

srand(42);

my $W = 1000;
my $H = 700;
my $PI = 3.14159265358979323846;
my $samples = 12;  # points per blade (keep low, many blades)

my $field_size = 4.0;
my $num_blades = 2000;

# Blade shape envelopes: width taper from base to tip
my @blade_shapes = (
    env([[1.0, 0.9, 0.6, 0.2, 0.0], [0.2, 0.3, 0.3, 0.2], [-1, -1, -2, -1]]),
    env([[1.0, 0.95, 0.7, 0.3, 0.0], [0.15, 0.35, 0.3, 0.2], [-1, -1, -1, -2]]),
    spline([0, 0.3, 0.7, 1.0], [1.0, 0.8, 0.4, 0.0]),
);
my @shape_vals;
push @shape_vals, [$_->table($samples)] for @blade_shapes;

# Blade curvature: how much each blade bends over
my @blade_curves = (
    spline([0, 0.3, 0.7, 1.0], [0, 0.05, 0.3, 0.7]),
    spline([0, 0.4, 0.8, 1.0], [0, 0.02, 0.15, 0.5]),
    spline([0, 0.2, 0.6, 1.0], [0, 0.08, 0.4, 0.9]),
);
my @curve_vals;
push @curve_vals, [$_->table($samples)] for @blade_curves;

# Wind envelope: controls global sway
my $wind = env([[0.3, 0.7, 0.4, 0.8, 0.3],
                [0.4, 0.3, 0.3, 0.4], [2, -2, 2, -2]],
    morpher_formula => 'smoothstep', is_fold_over => 1);
my $wind_s = $wind->static;
my $wind_d = $wind->duration;

# Wind gust: periodic strong gusts
my $gust = env([[0.0, 0.0, 1.0, 0.5, 0.0],
                [0.3, 0.1, 0.2, 0.4], [1, 3, -2, -1]],
    morpher_formula => 'smoothstep', is_fold_over => 1);
my $gust_s = $gust->static;
my $gust_d = $gust->duration;

# Pre-generate blade positions and properties
my @blades;
for my $i (0 .. $num_blades - 1) {
    my $x = (rand() - 0.5) * $field_size;
    my $z = (rand() - 0.5) * $field_size;

    # Cluster density: use noise-like pattern
    my $density = sin($x * 3) * cos($z * 2.5) * 0.5 + 0.5;
    next if rand() > $density + 0.3;

    my $height = 0.15 + rand() * 0.25;
    my $lean_dir = rand() * 2 * $PI;
    my $lean_amount = 0.3 + rand() * 0.5;
    my $shape_idx = int(rand() * @shape_vals);
    my $curve_idx = int(rand() * @curve_vals);
    my $phase = rand() * $PI * 2;
    my $hue_var = rand() * 0.08 - 0.04;

    push @blades, {
        x => $x, z => $z,
        height => $height,
        lean_dir => $lean_dir,
        lean => $lean_amount,
        shape => $shape_idx,
        curve => $curve_idx,
        phase => $phase,
        hue_var => $hue_var,
    };
}
printf "Generated %d grass blades\n", scalar @blades;

# Shaders
my $vert_src = <<'GLSL';
#version 150
in vec3 aPos; in vec4 aColor; in float aThick;
out VS_OUT { vec4 color; float thick; } vs_out;
uniform mat4 uMVP;
void main() {
    gl_Position = uMVP * vec4(aPos, 1.0);
    vs_out.color = aColor; vs_out.thick = aThick;
}
GLSL

my $geom_src = <<'GLSL';
#version 150
layout(lines) in;
layout(triangle_strip, max_vertices = 4) out;
in VS_OUT { vec4 color; float thick; } gs_in[];
out vec4 gColor; out float gEdge;
uniform vec2 uResolution;
void main() {
    vec4 p0=gl_in[0].gl_Position, p1=gl_in[1].gl_Position;
    vec2 d=normalize(p1.xy/p1.w-p0.xy/p0.w), n=vec2(-d.y,d.x);
    float t0=gs_in[0].thick/uResolution.y, t1=gs_in[1].thick/uResolution.y;
    gColor=gs_in[0].color; gEdge=-1.0;
    gl_Position=vec4(p0.xy-n*t0*p0.w,p0.zw); EmitVertex();
    gColor=gs_in[0].color; gEdge=1.0;
    gl_Position=vec4(p0.xy+n*t0*p0.w,p0.zw); EmitVertex();
    gColor=gs_in[1].color; gEdge=-1.0;
    gl_Position=vec4(p1.xy-n*t1*p1.w,p1.zw); EmitVertex();
    gColor=gs_in[1].color; gEdge=1.0;
    gl_Position=vec4(p1.xy+n*t1*p1.w,p1.zw); EmitVertex();
    EndPrimitive();
}
GLSL

my $frag_src = <<'GLSL';
#version 150
in vec4 gColor; in float gEdge;
out vec4 outColor;
void main() {
    float d=abs(gEdge);
    float alpha=1.0-smoothstep(0.2,1.0,d);
    outColor=vec4(gColor.rgb, gColor.a*alpha);
}
GLSL

my ($prog, $u_mvp, $u_resolution, $vbo, $vao, $start);

sub compile_shader {
    my($type,$src)=@_;my $s=glCreateShader($type);
    glShaderSource_p($s,$src);glCompileShader($s);
    my($ok)=glGetShaderiv_p($s,GL_COMPILE_STATUS);
    die "Shader: ".glGetShaderInfoLog_p($s) unless $ok; $s;
}
sub mat4_perspective {
    my($fov,$asp,$n,$f)=@_;my $t=1/tan($fov*$PI/360);
    my @m=(0)x16;$m[0]=$t/$asp;$m[5]=$t;
    $m[10]=($f+$n)/($n-$f);$m[11]=-1;$m[14]=2*$f*$n/($n-$f);@m;
}
sub mat4_lookat {
    my($ex,$ey,$ez,$cx,$cy,$cz,$ux,$uy,$uz)=@_;
    my @f=($cx-$ex,$cy-$ey,$cz-$ez);
    my $l=sqrt($f[0]**2+$f[1]**2+$f[2]**2);@f=map{$_/$l}@f;
    my @s=($f[1]*$uz-$f[2]*$uy,$f[2]*$ux-$f[0]*$uz,$f[0]*$uy-$f[1]*$ux);
    $l=sqrt($s[0]**2+$s[1]**2+$s[2]**2);@s=map{$_/$l}@s;
    my @u=($s[1]*$f[2]-$s[2]*$f[1],$s[2]*$f[0]-$s[0]*$f[2],$s[0]*$f[1]-$s[1]*$f[0]);
    ($s[0],$u[0],-$f[0],0,$s[1],$u[1],-$f[1],0,$s[2],$u[2],-$f[2],0,
     -($s[0]*$ex+$s[1]*$ey+$s[2]*$ez),-($u[0]*$ex+$u[1]*$ey+$u[2]*$ez),
     $f[0]*$ex+$f[1]*$ey+$f[2]*$ez,1);
}
sub mat4_mult {
    my($a,$b)=@_;my @r=(0)x16;
    for my $i(0..3){for my $j(0..3){for my $k(0..3){$r[$j*4+$i]+=$a->[$k*4+$i]*$b->[$j*4+$k]}}}@r;
}
sub hsv {
    my($h,$s,$v)=@_;$h=($h-floor($h))*6;my $f=$h-floor($h);
    my $p=$v*(1-$s);my $q=$v*(1-$s*$f);my $t=$v*(1-$s*(1-$f));
    my @c=([$v,$t,$p],[$q,$v,$p],[$p,$v,$t],[$p,$q,$v],[$t,$p,$v],[$v,$p,$q]);
    @{$c[int($h)%6]};
}
sub fmod { $_[0]-floor($_[0]/$_[1])*$_[1] }

sub init_gl {
    my $vs=compile_shader(GL_VERTEX_SHADER,$vert_src);
    my $gs=compile_shader(GL_GEOMETRY_SHADER,$geom_src);
    my $fs=compile_shader(GL_FRAGMENT_SHADER,$frag_src);
    $prog=glCreateProgram();
    glAttachShader($prog,$_) for ($vs,$gs,$fs);
    glBindAttribLocation($prog,0,'aPos');
    glBindAttribLocation($prog,1,'aColor');
    glBindAttribLocation($prog,2,'aThick');
    glLinkProgram($prog);
    my($ok)=glGetProgramiv_p($prog,GL_LINK_STATUS);
    die "Link: ".glGetProgramInfoLog_p($prog) unless $ok;
    glDeleteShader($_) for ($vs,$gs,$fs);
    $u_mvp=glGetUniformLocation($prog,'uMVP');
    $u_resolution=glGetUniformLocation($prog,'uResolution');
    ($vao)=glGenVertexArrays_p(1);
    ($vbo)=glGenBuffers_p(1);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_DEPTH_TEST);
    $start=time();
}

sub display {
    my $t = time() - $start;
    my $w = $wind_s->(fmod($t * 0.4, $wind_d));
    my $g = $gust_s->(fmod($t * 0.15, $gust_d));

    # Wind direction slowly rotates
    my $wind_angle = $t * 0.1;
    my $wind_dx = cos($wind_angle);
    my $wind_dz = sin($wind_angle);
    my $wind_str = $w + $g * 0.8;

    glClearColor(0.35, 0.55, 0.3, 1);  # green ground visible through gaps
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram($prog);

    # Low camera, looking across the field
    my $cam_a = $t * 0.05;
    my $cam_x = cos($cam_a) * 2.5;
    my $cam_z = sin($cam_a) * 2.5;
    my @proj = mat4_perspective(60, $W/$H, 0.01, 20);
    my @view = mat4_lookat(
        $cam_x, 0.4, $cam_z,
        0, 0.15, 0,
        0, 1, 0);
    my @mvp = mat4_mult(\@proj, \@view);
    my $m = OpenGL::Array->new_list(GL_FLOAT, @mvp);
    glUniformMatrix4fv_c($u_mvp, 1, GL_FALSE, $m->ptr);
    glUniform2f($u_resolution, $W, $H);

    # per vertex: x,y,z, r,g,b,a, thick = 8 floats
    my @verts;
    my @cmds;
    my $total = 0;

    for my $bl (@blades) {
        my @sv = @{$shape_vals[$bl->{shape}]};
        my @cv = @{$curve_vals[$bl->{curve}]};

        # Wind wave: propagates across field
        my $wave_phase = ($bl->{x} * $wind_dx + $bl->{z} * $wind_dz) * 2 + $t * 3;
        my $local_wind = $wind_str * (0.6 + 0.4 * sin($wave_phase + $bl->{phase}));

        for my $j (0 .. $samples) {
            my $s = $j / $samples;

            # Width taper
            my $width = $sv[$j % $samples] * 2.0;

            # Curvature: blade bends in lean direction + wind direction
            my $bend = $cv[$j % $samples];
            my $lean_x = cos($bl->{lean_dir}) * $bend * $bl->{lean};
            my $lean_z = sin($bl->{lean_dir}) * $bend * $bl->{lean};

            # Wind push: adds to lean, stronger at tip
            my $wind_push = $local_wind * $s * $s * 0.3;
            $lean_x += $wind_dx * $wind_push;
            $lean_z += $wind_dz * $wind_push;

            my $x = $bl->{x} + $lean_x * $bl->{height};
            my $y = $s * $bl->{height} * (1 - $bend * 0.2);
            my $z = $bl->{z} + $lean_z * $bl->{height};

            # Color: dark green at base, lighter/yellow at tip
            my $hue = 0.28 + $bl->{hue_var} + $s * 0.05;
            my $sat = 0.7 - $s * 0.2;
            my $val = 0.3 + $s * 0.35;
            # Wind-exposed blades lighter
            $val += $local_wind * $s * 0.15;
            my ($cr,$cg,$cb) = hsv($hue, $sat, $val);

            push @verts, $x, $y, $z, $cr, $cg, $cb, 0.85, $width;
        }
        push @cmds, [$total, $samples + 1];
        $total += $samples + 1;
    }

    # Ground plane (dark green quad via two line strips)
    my $gs = $field_size * 0.6;
    for my $row (-3 .. 3) {
        my $z = $row * $gs / 3;
        push @verts, -$gs, -0.001, $z, 0.2, 0.35, 0.15, 0.3, 40;
        push @verts,  $gs, -0.001, $z, 0.2, 0.35, 0.15, 0.3, 40;
        push @cmds, [$total, 2]; $total += 2;
    }

    my $stride = 8 * 4;
    my $oa = OpenGL::Array->new_list(GL_FLOAT, @verts);
    glBindVertexArray($vao);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo);
    glBufferData_c(GL_ARRAY_BUFFER, $oa->length, $oa->ptr, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer_c(0, 3, GL_FLOAT, GL_FALSE, $stride, 0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer_c(1, 4, GL_FLOAT, GL_FALSE, $stride, 3*4);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer_c(2, 1, GL_FLOAT, GL_FALSE, $stride, 7*4);

    for my $cmd (@cmds) { glDrawArrays(GL_LINE_STRIP, $cmd->[0], $cmd->[1]) }

    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glDisableVertexAttribArray(2);
    glBindVertexArray(0);
    glutSwapBuffers();
}

# Fix: lean_x without $ sigil was used above — need to declare properly
# The variable is local in the loop, declared with my above, this is fine.

sub idle { glutPostRedisplay() }
sub keyboard { exit(0) if ord($_[0]) == 27 }

glutInit();
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH | GLUT_MULTISAMPLE);
glutInitContextVersion(3, 2);
glutInitContextProfile(0x0001);
glutInitWindowSize($W, $H);
glutCreateWindow('Envelope Grass Field');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "Grass field: %d blades — ESC to quit\n", scalar @blades;
glutMainLoop();
