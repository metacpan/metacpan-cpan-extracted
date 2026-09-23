#!/usr/bin/env perl
# Polar lattice: each arm's 3D path is defined by two envelopes:
#   - angle envelope: controls polar angle over the arm's length
#   - radius envelope: controls distance from center
# Combined they trace spirals, loops, figure-eights, cardioids, etc.
# Different envelope pairs produce wildly different arm shapes.
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

my $num_arms = 36;
my $samples = 100;

# Angle envelopes: map t [0,1] -> angle in radians
# These control *how* the arm sweeps angularly
my @angle_envs = (
    env([[0, 6.28], [1], [1]]),                                     # linear full circle
    spline([0, 0.3, 0.7, 1.0], [0, 4.0, 2.0, 6.28]),             # fast-slow-fast
    env([[0, 9.42, 3.14, 12.57], [0.3, 0.4, 0.3], [2, -2, 2]]),  # overshoot spiral
    env([[0, -3.14, 0, 3.14], [0.3, 0.4, 0.3], [2, -3, 2]],      # swing back and forth
        morpher_formula => 'smoothstep'),
    spline([0, 0.2, 0.5, 0.8, 1.0], [0, 3.14, 0, -3.14, 0]),    # figure-eight angle
    env([[0, 12.57], [1], [2]], morpher_formula => 'cubic_in'),     # accelerating spiral
    spline([0, 0.3, 0.5, 0.7, 1.0], [0, -6.28, 3.14, -3.14, 6.28]), # zigzag
    env([[0, 6.28, 0, 6.28], [0.33, 0.34, 0.33], [3, -3, 3]],
        morpher_formula => 'elastic_out'),                             # elastic sweep
);

# Radius envelopes: map t [0,1] -> radius
my @radius_envs = (
    env([[0.2, 1.5, 0.2], [0.5, 0.5], [2, -2]],
        morpher_formula => 'smoothstep'),                           # expand then contract
    spline([0, 0.25, 0.5, 0.75, 1.0], [0.1, 1.2, 0.5, 1.0, 0.1]), # petal
    adsr(0.1, 0.2, 0.8, 0.3, peak => 1.5,
        morpher_formula => 'smoothstep'),                           # bloom then fade
    perc(0.05, 0.95, peak => 1.8, morpher_formula => 'cubic_out'), # shoot outward
    env([[0.5, 1.2, 0.3, 1.0, 0.5], [0.25, 0.25, 0.25, 0.25],
         [2, -3, 3, -2]], morpher_formula => 'bounce_out'),         # bouncy
    spline([0, 0.15, 0.5, 0.85, 1.0], [0.8, 1.5, 0.2, 1.3, 0.8]), # cardioid-ish
    env([[0.3, 0.8, 1.5, 0.8, 0.3], [0.25, 0.25, 0.25, 0.25],
         [2, 2, -2, -2]], morpher_formula => 'smoothstep'),          # diamond pulse
    env([[1.0, 0.1, 1.0, 0.1, 1.0], [0.25, 0.25, 0.25, 0.25],
         [-3, 3, -3, 3]], morpher_formula => 'sine'),                # flutter
);

# Pre-sample all envelope keyframes
my @angle_keys = map { [$_->table($samples)] } @angle_envs;
my @radius_keys = map { [$_->table($samples)] } @radius_envs;
my $n_angle = scalar @angle_keys;
my $n_radius = scalar @radius_keys;

# Morph timing: seconds per keyframe transition
my $morph_sec = 4.0;

# Lerp two sample arrays by mix [0,1]
sub lerp_samples {
    my ($a, $b, $mix) = @_;
    my @r;
    for my $i (0 .. $#$a) {
        push @r, $a->[$i] * (1 - $mix) + $b->[$i] * $mix;
    }
    return \@r;
}

# Get morphed samples for a given envelope bank at time t
# Each arm cycles through all keyframes at its own offset
sub morph_bank {
    my ($keys, $n_keys, $t, $arm_offset) = @_;
    my $phase = ($t / $morph_sec + $arm_offset) * $n_keys;
    $phase -= floor($phase / $n_keys) * $n_keys;
    my $idx_a = int($phase) % $n_keys;
    my $idx_b = ($idx_a + 1) % $n_keys;
    my $mix = $phase - floor($phase);
    # Smoothstep the mix
    $mix = $mix * $mix * (3 - 2 * $mix);
    return lerp_samples($keys->[$idx_a], $keys->[$idx_b], $mix);
}

# Y-height envelope: controls vertical spread
my $height_env = env([[0, 0.3, 0, -0.3, 0], [0.25, 0.25, 0.25, 0.25], [2, -2, 2, -2]],
    morpher_formula => 'smoothstep', is_fold_over => 1);
my $height_vals = [$height_env->table($samples)];

# Pulse
my $pulse = env([[1.0, 1.08, 1.0], [0.5, 0.5], [2, -2]],
    morpher_formula => 'smoothstep', is_fold_over => 1);
my $pulse_s = $pulse->static;
my $pulse_d = $pulse->duration;

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
    float alpha=1.0-smoothstep(0.4,1.0,d);
    float glow=exp(-d*d*5.0)*0.25;
    outColor=vec4(gColor.rgb+glow, gColor.a*alpha);
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
    glDepthFunc(GL_LEQUAL);
    $start=time();
}

sub display {
    my $t = time() - $start;
    my $p = $pulse_s->(fmod($t * 0.3, $pulse_d));

    glClearColor(0.02, 0.02, 0.04, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram($prog);

    my $cam_a = $t * 0.15;
    my $cam_h = 2.0 + sin($t * 0.1) * 0.8;
    my @proj = mat4_perspective(55, $W/$H, 0.01, 20);
    my @view = mat4_lookat(
        cos($cam_a)*3.5, $cam_h, sin($cam_a)*3.5,
        0, 0, 0,  0, 1, 0);
    my @mvp = mat4_mult(\@proj, \@view);
    my $m = OpenGL::Array->new_list(GL_FLOAT, @mvp);
    glUniformMatrix4fv_c($u_mvp, 1, GL_FALSE, $m->ptr);
    glUniform2f($u_resolution, $W, $H);

    my @verts;
    my @cmds;
    my $total = 0;

    # Trail: render ghost copies at past time offsets
    my $trail_count = 5;
    my $trail_step = 0.08;  # seconds between ghost frames

    for my $ghost (reverse 0 .. $trail_count) {
        my $gt = $t - $ghost * $trail_step;
        my $ghost_alpha = ($trail_count - $ghost) / $trail_count;
        $ghost_alpha = $ghost_alpha * $ghost_alpha;  # quadratic fade
        my $ghost_thick = 0.3 + 0.7 * $ghost_alpha;  # thinner ghosts

        for my $arm (0 .. $num_arms - 1) {
            my $arm_morph_offset = $arm / $num_arms;
            my @av = @{morph_bank(\@angle_keys, $n_angle, $gt, $arm_morph_offset)};
            my @rv = @{morph_bank(\@radius_keys, $n_radius, $gt, $arm_morph_offset * 1.3 + 0.5)};
            my @hv = @$height_vals;

            my $arm_offset = $arm / $num_arms * 2 * $PI;
            my $time_offset = $gt * 0.5 + $arm * 0.2;
            my $time_phase = int($time_offset) % $samples;
            my $elev = sin($arm * 2.399) * 0.4;
            my $hue = $arm / $num_arms + $gt * 0.03;

            for my $j (0 .. $samples - 1) {
                my $s = $j / ($samples - 1);
                my $idx = ($j + $time_phase) % $samples;

                my $angle = $av[$idx] + $arm_offset;
                my $radius = $rv[$idx] * $p;

                my $x = cos($angle) * $radius;
                my $z = sin($angle) * $radius;
                my $y = $hv[$idx] * $p + sin($s * $PI) * $elev;

                my ($cr, $cg, $cb) = hsv($hue + $s * 0.2, 0.75,
                    (0.4 + $radius * 0.3) * $ghost_alpha);
                my $thick = (1.5 + $radius * 3) * $ghost_thick;

                push @verts, $x, $y, $z, $cr, $cg, $cb, 0.8 * $ghost_alpha, $thick;
            }

            push @cmds, [$total, $samples];
            $total += $samples;
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

sub idle { glutPostRedisplay() }
sub keyboard { exit(0) if ord($_[0]) == 27 }

glutInit();
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH | GLUT_MULTISAMPLE);
glutInitContextVersion(3, 2);
glutInitContextProfile(0x0001);
glutInitWindowSize($W, $H);
glutCreateWindow('Polar Envelope Lattice');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "Polar lattice: %d arms, %d angle x %d radius envelopes — ESC to quit\n",
    $num_arms, scalar @angle_envs, scalar @radius_envs;
glutMainLoop();
