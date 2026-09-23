#!/usr/bin/env perl
# Envelope curtain: vertical ribbons hanging from a horizontal rail
# Each strand's shape is a different envelope, swaying like fabric in wind
# Geometry shader expands lines into wide translucent strips
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

use Math::SegmentedEnvelope qw(adsr perc asr spline env);
use Time::HiRes qw(time);
use POSIX qw(tan floor);

my $W = 1000;
my $H = 700;
my $PI = 3.14159265358979323846;

my $num_strands = 60;
my $samples = 64;
my $curtain_width = 4.0;
my $curtain_height = 2.5;

# Each strand gets an envelope controlling its depth displacement (Z bulge)
my @strand_envs = (
    adsr(0.1, 0.2, 0.5, 0.2, morpher_formula => 'smoothstep'),
    perc(0.05, 0.95, morpher_formula => 'cubic_out'),
    spline([0, 0.3, 0.6, 1.0], [0, 0.8, 0.2, 0]),
    env([[0, 0.6, 0.3, 0.7, 0], [0.2, 0.3, 0.3, 0.2], [2, -2, 2, -3]],
        morpher_formula => 'smoothstep'),
    asr(0.15, 0.5, 0.35, morpher_formula => 'sine'),
    env([[0, 1, 0.5, 1, 0], [0.25, 0.25, 0.25, 0.25], [3, -3, 3, -3]],
        morpher_formula => 'bounce_out'),
);

my @strand_vals;
for my $i (0 .. $num_strands - 1) {
    my $e = $strand_envs[$i % @strand_envs];
    push @strand_vals, [$e->table($samples)];
}

# Wind envelope: controls sway intensity
my $wind = env([[0.2, 0.8, 0.3, 0.6, 0.2], [0.5, 0.4, 0.4, 0.7], [2, -2, 2, -2]],
    morpher_formula => 'smoothstep', is_fold_over => 1);
my $wind_s = $wind->static;
my $wind_d = $wind->duration;

# Shaders
my $vert_src = <<'GLSL';
#version 150
in vec3 aPos;
in vec4 aColor;
out VS_OUT {
    vec4 color;
} vs_out;
uniform mat4 uMVP;
void main() {
    gl_Position = uMVP * vec4(aPos, 1.0);
    vs_out.color = aColor;
}
GLSL

my $geom_src = <<'GLSL';
#version 150
layout(lines) in;
layout(triangle_strip, max_vertices = 4) out;

in VS_OUT { vec4 color; } gs_in[];
out vec4 gColor;
out float gEdge;

uniform float uStrandWidth;
uniform vec2 uResolution;

void main() {
    vec4 p0 = gl_in[0].gl_Position;
    vec4 p1 = gl_in[1].gl_Position;

    // Ribbon normal: always face camera (billboard in X)
    float hw = uStrandWidth / uResolution.x;

    gColor = gs_in[0].color; gEdge = -1.0;
    gl_Position = p0 + vec4(-hw * p0.w, 0, 0, 0); EmitVertex();
    gColor = gs_in[0].color; gEdge = 1.0;
    gl_Position = p0 + vec4( hw * p0.w, 0, 0, 0); EmitVertex();
    gColor = gs_in[1].color; gEdge = -1.0;
    gl_Position = p1 + vec4(-hw * p1.w, 0, 0, 0); EmitVertex();
    gColor = gs_in[1].color; gEdge = 1.0;
    gl_Position = p1 + vec4( hw * p1.w, 0, 0, 0); EmitVertex();

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
    // Soft fabric edge
    float alpha = 1.0 - smoothstep(0.3, 1.0, d);
    // Subtle sheen at center
    float sheen = exp(-d * d * 8.0) * 0.15;
    outColor = vec4(gColor.rgb + sheen, gColor.a * alpha);
}
GLSL

my ($prog, $u_mvp, $u_strand_width, $u_resolution, $vbo, $vao);
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
    glLinkProgram($prog);
    my ($ok) = glGetProgramiv_p($prog, GL_LINK_STATUS);
    die "Link: ".glGetProgramInfoLog_p($prog) unless $ok;
    glDeleteShader($_) for ($vs, $gs, $fs);

    $u_mvp = glGetUniformLocation($prog, 'uMVP');
    $u_strand_width = glGetUniformLocation($prog, 'uStrandWidth');
    $u_resolution = glGetUniformLocation($prog, 'uResolution');

    ($vao) = glGenVertexArrays_p(1);
    ($vbo) = glGenBuffers_p(1);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);

    $start = time();
}

sub display {
    my $t = time() - $start;
    my $wind_val = $wind_s->($t - floor($t / $wind_d) * $wind_d);

    glClearColor(0.03, 0.03, 0.06, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram($prog);

    my $cam_a = $t * 0.12;
    my $cam_d = 4.0 + sin($t * 0.1) * 0.5;
    my @proj = mat4_perspective(50, $W/$H, 0.01, 20);
    my @view = mat4_lookat(
        cos($cam_a) * $cam_d, 0.5, sin($cam_a) * $cam_d,
        0, -0.5, 0,
        0, 1, 0);
    my @mvp = mat4_mult(\@proj, \@view);
    my $m = OpenGL::Array->new_list(GL_FLOAT, @mvp);
    glUniformMatrix4fv_c($u_mvp, 1, GL_FALSE, $m->ptr);
    glUniform1f($u_strand_width, 8.0);
    glUniform2f($u_resolution, $W, $H);

    # Build vertex data: per vertex = x,y,z, r,g,b,a (7 floats)
    my @verts;

    for my $si (0 .. $num_strands - 1) {
        my @vals = @{$strand_vals[$si]};
        my $strand_x = ($si / ($num_strands - 1) - 0.5) * $curtain_width;

        # Per-strand wind phase offset
        my $wind_phase = $si * 0.17 + $t * 1.5;
        my $wind_strength = $wind_val * (0.5 + 0.5 * sin($si * 0.3));

        # Hue: gradient across curtain width + slow shift
        my $hue = $si / $num_strands * 0.8 + $t * 0.02;

        for my $j (0 .. $samples - 1) {
            my $v = $j / ($samples - 1);
            my $env_val = $vals[$j];

            # Y: hang downward
            my $y = -$v * $curtain_height;

            # Z: envelope-shaped depth displacement + wind sway
            # More sway at bottom (gravity drape)
            my $gravity = $v * $v;
            my $sway = sin($wind_phase + $v * 3.0) * $gravity * $wind_strength * 0.4;
            my $z = $env_val * 0.3 * $gravity + $sway;

            # X: slight horizontal sway (secondary wind)
            my $x_sway = sin($wind_phase * 0.7 + $v * 2.0) * $gravity * $wind_strength * 0.1;
            my $x = $strand_x + $x_sway;

            # Color: hue gradient + darker at bottom
            my $brightness = 0.7 - $v * 0.3;
            my ($r, $g, $b) = hsv($hue + $v * 0.1, 0.5 + $env_val * 0.3, $brightness);

            # Alpha: fade at bottom tip
            my $alpha = 1.0 - smoothstep(0.85, 1.0, $v);
            $alpha *= 0.7 + $env_val * 0.3;

            push @verts, $x, $y, $z, $r, $g, $b, $alpha;
        }
    }

    my $stride = 7 * 4;
    my $oa = OpenGL::Array->new_list(GL_FLOAT, @verts);
    glBindVertexArray($vao);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo);
    glBufferData_c(GL_ARRAY_BUFFER, $oa->length, $oa->ptr, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer_c(0, 3, GL_FLOAT, GL_FALSE, $stride, 0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer_c(1, 4, GL_FLOAT, GL_FALSE, $stride, 3 * 4);

    for my $si (0 .. $num_strands - 1) {
        glDrawArrays(GL_LINE_STRIP, $si * $samples, $samples);
    }

    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glBindVertexArray(0);

    # Rail at top
    glLineWidth(3);
    my @rail = (-$curtain_width/2, 0, 0, $curtain_width/2, 0, 0);
    my $rail_oa = OpenGL::Array->new_list(GL_FLOAT,
        -$curtain_width/2, 0, 0, 0.6, 0.5, 0.4, 1.0,
         $curtain_width/2, 0, 0, 0.6, 0.5, 0.4, 1.0);
    glBindVertexArray($vao);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo);
    glBufferData_c(GL_ARRAY_BUFFER, $rail_oa->length, $rail_oa->ptr, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer_c(0, 3, GL_FLOAT, GL_FALSE, $stride, 0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer_c(1, 4, GL_FLOAT, GL_FALSE, $stride, 3 * 4);
    glUniform1f($u_strand_width, 3.0);
    glDrawArrays(GL_LINE_STRIP, 0, 2);
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glBindVertexArray(0);

    glutSwapBuffers();
}

sub smoothstep { my ($e0,$e1,$x)=@_; $x=($x-$e0)/($e1-$e0); $x=0 if $x<0; $x=1 if $x>1; $x*$x*(3-2*$x) }
sub idle { glutPostRedisplay() }
sub keyboard { exit(0) if ord($_[0]) == 27 }

glutInit();
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH | GLUT_MULTISAMPLE);
glutInitContextVersion(3, 2);
glutInitContextProfile(0x0001);
glutInitWindowSize($W, $H);
glutCreateWindow('Envelope Curtain');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "Curtain: %d strands x %d samples, wind-driven — ESC to quit\n",
    $num_strands, $samples;
glutMainLoop();
