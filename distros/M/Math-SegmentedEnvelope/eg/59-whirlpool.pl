#!/usr/bin/env perl
# Whirlpool: envelope-shaped spiral streams funneling into a vortex
# Each stream follows a logarithmic spiral path, with envelope controlling
# the radius, descent speed, and ribbon width as it spirals inward
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

use Math::SegmentedEnvelope qw(adsr perc spline env);
use Time::HiRes qw(time);
use POSIX qw(tan floor);

my $W = 900;
my $H = 700;
my $PI = 3.14159265358979323846;

my $num_streams = 24;
my $samples = 120;
my $spiral_turns = 3.5;

# Envelope profiles: control how each stream's radius decays toward center
my @stream_envs = (
    env([[1.0, 0.8, 0.5, 0.15, 0.02], [0.2, 0.3, 0.3, 0.2], [-2, -2, -3, -2]],
        morpher_formula => 'smoothstep'),
    spline([0, 0.3, 0.6, 0.85, 1.0], [1.0, 0.7, 0.3, 0.08, 0.01]),
    adsr(0.05, 0.3, 0.15, 0.5, peak => 1.0, morpher_formula => 'cubic_out'),
    perc(0.1, 0.9, peak => 1.0, morpher_formula => 'smoothstep'),
    env([[1.0, 0.9, 0.4, 0.6, 0.1, 0.02],
         [0.15, 0.2, 0.2, 0.25, 0.2], [-1, -3, 2, -2, -3]],
        morpher_formula => 'sine'),
);

# Descent envelope: how fast each stream drops as it spirals in
my $descent = env([[0, 0.1, 0.5, 1.5, 3.0],
                   [0.2, 0.3, 0.3, 0.2], [1, 2, 2, 3]],
    morpher_formula => 'cubic_in');
my $descent_s = $descent->static;
my $descent_d = $descent->duration;

# Width envelope: ribbon gets thinner toward center
my $width_env = env([[8, 6, 3, 1, 0.5],
                     [0.3, 0.3, 0.2, 0.2], [-1, -2, -2, -1]]);
my $width_s = $width_env->static;
my $width_d = $width_env->duration;

# Turbulence envelope: modulates jitter intensity
my $turb = env([[0.2, 0.8, 0.4, 0.6, 0.2],
                [0.3, 0.2, 0.2, 0.3], [2, -2, 2, -2]],
    morpher_formula => 'smoothstep', is_fold_over => 1);
my $turb_s = $turb->static;
my $turb_d = $turb->duration;

# Pre-sample stream profiles
my @stream_vals;
for my $i (0 .. $num_streams - 1) {
    my $e = $stream_envs[$i % @stream_envs];
    push @stream_vals, [$e->table($samples)];
}

# Shaders
my $vert_src = <<'GLSL';
#version 150
in vec3 aPos;
in vec4 aColor;
in float aThick;
out VS_OUT {
    vec4 color;
    float thick;
} vs_out;
uniform mat4 uMVP;
void main() {
    gl_Position = uMVP * vec4(aPos, 1.0);
    vs_out.color = aColor;
    vs_out.thick = aThick;
}
GLSL

my $geom_src = <<'GLSL';
#version 150
layout(lines) in;
layout(triangle_strip, max_vertices = 4) out;

in VS_OUT {
    vec4 color;
    float thick;
} gs_in[];

out vec4 gColor;
out float gEdge;

uniform vec2 uResolution;

void main() {
    vec4 p0 = gl_in[0].gl_Position;
    vec4 p1 = gl_in[1].gl_Position;

    vec2 d = normalize(p1.xy / p1.w - p0.xy / p0.w);
    vec2 n = vec2(-d.y, d.x);

    float t0 = gs_in[0].thick / uResolution.y;
    float t1 = gs_in[1].thick / uResolution.y;

    gColor = gs_in[0].color; gEdge = -1.0;
    gl_Position = vec4(p0.xy - n * t0 * p0.w, p0.zw); EmitVertex();
    gColor = gs_in[0].color; gEdge = 1.0;
    gl_Position = vec4(p0.xy + n * t0 * p0.w, p0.zw); EmitVertex();
    gColor = gs_in[1].color; gEdge = -1.0;
    gl_Position = vec4(p1.xy - n * t1 * p1.w, p1.zw); EmitVertex();
    gColor = gs_in[1].color; gEdge = 1.0;
    gl_Position = vec4(p1.xy + n * t1 * p1.w, p1.zw); EmitVertex();

    EndPrimitive();
}
GLSL

my $frag_src = <<'GLSL';
#version 150
in vec4 gColor;
in float gEdge;
out vec4 outColor;
void main() {
    float d = abs(gEdge);
    float alpha = 1.0 - smoothstep(0.4, 1.0, d);
    float glow = exp(-d * d * 6.0) * 0.25;
    outColor = vec4(gColor.rgb + glow, gColor.a * alpha);
}
GLSL

my ($prog, $u_mvp, $u_resolution, $vbo, $vao);
my $start;

sub compile_shader {
    my ($type, $src) = @_;
    my $s = glCreateShader($type);
    glShaderSource_p($s, $src);
    glCompileShader($s);
    my ($ok) = glGetShaderiv_p($s, GL_COMPILE_STATUS);
    die "Shader: " . glGetShaderInfoLog_p($s) unless $ok;
    return $s;
}

sub mat4_perspective {
    my ($fov,$asp,$n,$f) = @_;
    my $t = 1/tan($fov*$PI/360);
    my @m=(0)x16; $m[0]=$t/$asp; $m[5]=$t;
    $m[10]=($f+$n)/($n-$f); $m[11]=-1; $m[14]=2*$f*$n/($n-$f);
    return @m;
}

sub mat4_lookat {
    my($ex,$ey,$ez,$cx,$cy,$cz,$ux,$uy,$uz)=@_;
    my @f=($cx-$ex,$cy-$ey,$cz-$ez);
    my $l=sqrt($f[0]**2+$f[1]**2+$f[2]**2); @f=map{$_/$l}@f;
    my @s=($f[1]*$uz-$f[2]*$uy,$f[2]*$ux-$f[0]*$uz,$f[0]*$uy-$f[1]*$ux);
    $l=sqrt($s[0]**2+$s[1]**2+$s[2]**2); @s=map{$_/$l}@s;
    my @u=($s[1]*$f[2]-$s[2]*$f[1],$s[2]*$f[0]-$s[0]*$f[2],$s[0]*$f[1]-$s[1]*$f[0]);
    return($s[0],$u[0],-$f[0],0,$s[1],$u[1],-$f[1],0,$s[2],$u[2],-$f[2],0,
        -($s[0]*$ex+$s[1]*$ey+$s[2]*$ez),-($u[0]*$ex+$u[1]*$ey+$u[2]*$ez),
        $f[0]*$ex+$f[1]*$ey+$f[2]*$ez,1);
}

sub mat4_mult {
    my($a,$b)=@_;my @r=(0)x16;
    for my $i(0..3){for my $j(0..3){for my $k(0..3){$r[$j*4+$i]+=$a->[$k*4+$i]*$b->[$j*4+$k]}}}
    return @r;
}

sub hsv {
    my ($h,$s,$v)=@_;
    $h=($h-floor($h))*6; my $f=$h-floor($h);
    my $p=$v*(1-$s); my $q=$v*(1-$s*$f); my $t=$v*(1-$s*(1-$f));
    my @c=([$v,$t,$p],[$q,$v,$p],[$p,$v,$t],[$p,$q,$v],[$t,$p,$v],[$v,$p,$q]);
    return @{$c[int($h)%6]};
}

sub init_gl {
    my $vs = compile_shader(GL_VERTEX_SHADER, $vert_src);
    my $gs = compile_shader(GL_GEOMETRY_SHADER, $geom_src);
    my $fs = compile_shader(GL_FRAGMENT_SHADER, $frag_src);
    $prog = glCreateProgram();
    glAttachShader($prog, $_) for ($vs, $gs, $fs);
    glBindAttribLocation($prog, 0, 'aPos');
    glBindAttribLocation($prog, 1, 'aColor');
    glBindAttribLocation($prog, 2, 'aThick');
    glLinkProgram($prog);
    my ($ok) = glGetProgramiv_p($prog, GL_LINK_STATUS);
    die "Link: ".glGetProgramInfoLog_p($prog) unless $ok;
    glDeleteShader($_) for ($vs, $gs, $fs);
    $u_mvp = glGetUniformLocation($prog, 'uMVP');
    $u_resolution = glGetUniformLocation($prog, 'uResolution');

    ($vao) = glGenVertexArrays_p(1);
    ($vbo) = glGenBuffers_p(1);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_DEPTH_TEST);

    $start = time();
}

sub fmod { $_[0] - floor($_[0] / $_[1]) * $_[1] }

sub display {
    my $t = time() - $start;
    my $turb_val = $turb_s->(fmod($t * 0.5, $turb_d));

    glClearColor(0.01, 0.01, 0.03, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram($prog);

    # Camera: looking down into the vortex, slowly orbiting
    my $cam_a = $t * 0.15;
    my $cam_h = 2.5 + sin($t * 0.08) * 0.8;
    my $cam_r = 3.0;
    my @proj = mat4_perspective(55, $W/$H, 0.01, 20);
    my @view = mat4_lookat(
        cos($cam_a) * $cam_r, $cam_h, sin($cam_a) * $cam_r,
        0, -0.5, 0,
        0, 1, 0);
    my @mvp = mat4_mult(\@proj, \@view);
    my $m = OpenGL::Array->new_list(GL_FLOAT, @mvp);
    glUniformMatrix4fv_c($u_mvp, 1, GL_FALSE, $m->ptr);
    glUniform2f($u_resolution, $W, $H);

    # Build vertex data: x,y,z, r,g,b,a, thickness = 8 floats
    my @verts;

    for my $si (0 .. $num_streams - 1) {
        my @vals = @{$stream_vals[$si]};
        my $base_angle = $si / $num_streams * 2 * $PI;
        my $hue = $si / $num_streams + $t * 0.03;

        # Stream animates: offset phase scrolls inward over time
        my $phase_offset = $t * 0.8 + $si * 0.3;

        for my $j (0 .. $samples - 1) {
            my $s = $j / ($samples - 1);  # 0=outer rim, 1=center

            # Radius from envelope: decays toward center
            my $env_r = $vals[$j];
            my $radius = $env_r * 2.0;

            # Spiral angle: increases as we go inward
            my $angle = $base_angle + $s * $spiral_turns * 2 * $PI + $phase_offset;

            # Descent: deeper as we spiral in
            my $depth = $descent_s->($s * $descent_d);

            # Turbulence: small jitter, more near center
            my $jitter_x = sin($s * 17 + $t * 3 + $si) * $turb_val * $s * 0.1;
            my $jitter_z = cos($s * 13 + $t * 2.7 + $si * 1.3) * $turb_val * $s * 0.1;

            my $x = cos($angle) * $radius + $jitter_x;
            my $y = -$depth;
            my $z = sin($angle) * $radius + $jitter_z;

            # Color: hue shifts as it spirals, brightens near center
            my $bright = 0.3 + $s * 0.7;
            my $sat = 0.6 + $s * 0.3;
            my ($r, $g, $b) = hsv($hue + $s * 0.4, $sat, $bright);

            # Alpha: fade at both ends
            my $alpha = sin($s * $PI) * 0.7;
            $alpha *= $env_r;

            # Width from envelope
            my $thick = $width_s->($s * $width_d);

            push @verts, $x, $y, $z, $r, $g, $b, $alpha, $thick;
        }
    }

    my $stride = 8 * 4;
    my $oa = OpenGL::Array->new_list(GL_FLOAT, @verts);
    glBindVertexArray($vao);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo);
    glBufferData_c(GL_ARRAY_BUFFER, $oa->length, $oa->ptr, GL_DYNAMIC_DRAW);

    glEnableVertexAttribArray(0);
    glVertexAttribPointer_c(0, 3, GL_FLOAT, GL_FALSE, $stride, 0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer_c(1, 4, GL_FLOAT, GL_FALSE, $stride, 3 * 4);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer_c(2, 1, GL_FLOAT, GL_FALSE, $stride, 7 * 4);

    for my $si (0 .. $num_streams - 1) {
        glDrawArrays(GL_LINE_STRIP, $si * $samples, $samples);
    }

    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glDisableVertexAttribArray(2);
    glBindVertexArray(0);

    glutSwapBuffers();
}

sub idle { glutPostRedisplay() }
sub keyboard { exit(0) if ord($_[0]) == 27 }

glutInit();
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH | GLUT_MULTISAMPLE);
glutInitContextVersion(3, 2);
glutInitContextProfile(0x0001);
glutInitWindowSize($W, $H);
glutCreateWindow('Envelope Whirlpool');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "Whirlpool: %d streams x %d samples, %.1f spiral turns — ESC to quit\n",
    $num_streams, $samples, $spiral_turns;
glutMainLoop();
