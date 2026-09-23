#!/usr/bin/env perl
# 3D rolling balls: balls roll on a 3D terrain defined by two crossed envelopes
# Height at (x,z) = envelope_x(x) * envelope_z(z)
# Gradient in X from derivative_x, gradient in Z from derivative_z
# Balls start from random positions on the hillsides
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
my $GRID = 50;

# Terrain envelopes (X and Z profiles)
my $terrain_x = spline([0, 0.15, 0.3, 0.45, 0.6, 0.75, 0.9, 1.0],
                       [0.2, 0.7, 0.3, 0.9, 0.4, 0.8, 0.5, 0.15], resolution => 8);
my $terrain_z = spline([0, 0.12, 0.35, 0.5, 0.7, 0.85, 1.0],
                       [0.15, 0.6, 0.35, 0.85, 0.25, 0.7, 0.1], resolution => 8);

my $sx = $terrain_x->static;
my $sz = $terrain_z->static;
my $dx = $terrain_x->duration;
my $dz = $terrain_z->duration;

# Pre-sampled derivatives for gradient
my $deriv_x = $terrain_x->resample($GRID)->derivative->static;
my $deriv_z = $terrain_z->resample($GRID)->derivative->static;
my $ddx = $terrain_x->resample($GRID)->derivative->duration;
my $ddz = $terrain_z->resample($GRID)->derivative->duration;

sub height_at {
    my ($x, $z) = @_;
    $x = 0 if $x < 0; $x = 1 if $x > 1;
    $z = 0 if $z < 0; $z = 1 if $z > 1;
    return $sx->($x * $dx) * $sz->($z * $dz);
}

sub gradient_at {
    my ($x, $z) = @_;
    $x = 0 if $x < 0; $x = 1 if $x > 1;
    $z = 0 if $z < 0; $z = 1 if $z > 1;
    my $hx = $sx->($x * $dx);
    my $hz = $sz->($z * $dz);
    my $gx = $deriv_x->($x * $ddx) * $hz;
    my $gz = $deriv_z->($z * $ddz) * $hx;
    return ($gx, $gz);
}

# Pre-compute terrain mesh
my (@terrain_verts, @terrain_indices);
for my $zi (0 .. $GRID) {
    for my $xi (0 .. $GRID) {
        my $x = $xi / $GRID;
        my $z = $zi / $GRID;
        my $h = height_at($x, $z);
        push @terrain_verts, $x, $h, $z;
    }
}
for my $zi (0 .. $GRID - 1) {
    for my $xi (0 .. $GRID - 1) {
        my $i = $zi * ($GRID + 1) + $xi;
        push @terrain_indices, $i, $i+1, $i+$GRID+1, $i+1, $i+$GRID+2, $i+$GRID+1;
    }
}

# Physics
my $gravity = 3.0;
my $friction = 0.992;
my $bounce_coeff = 0.5;
my $ball_r = 0.012;
my $num_balls = 20;
my @balls;

sub spawn_balls {
    @balls = ();
    for my $i (0 .. $num_balls - 1) {
        # Start on high points
        my $bx = 0.1 + rand() * 0.8;
        my $bz = 0.1 + rand() * 0.8;
        # Find a high spot nearby
        my $best_h = 0;
        for (1..5) {
            my $tx = 0.1 + rand() * 0.8;
            my $tz = 0.1 + rand() * 0.8;
            my $h = height_at($tx, $tz);
            if ($h > $best_h) { $bx = $tx; $bz = $tz; $best_h = $h }
        }
        push @balls, {
            x => $bx, z => $bz,
            vx => (rand() - 0.5) * 0.1,
            vz => (rand() - 0.5) * 0.1,
            r => $ball_r * (0.7 + rand() * 0.8),
            hue => $i / $num_balls,
            trail => [],
        };
    }
}
spawn_balls();

# Shaders
my $tv = <<'GLSL';
#version 150
in vec3 aPos;
out vec3 vPos;
uniform mat4 uMVP;
void main() { vPos = aPos; gl_Position = uMVP * vec4(aPos, 1.0); }
GLSL

my $tg = <<'GLSL';
#version 150
layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;
in vec3 vPos[];
out vec4 fColor;
uniform float uTime;
void main() {
    vec3 e1 = vPos[1] - vPos[0], e2 = vPos[2] - vPos[0];
    vec3 fn = normalize(cross(e1, e2));
    vec3 light = normalize(vec3(0.4, 0.8, 0.3));
    float diff = max(dot(fn, light), 0.0);
    for (int i = 0; i < 3; i++) {
        gl_Position = gl_in[i].gl_Position;
        float h = vPos[i].y;
        vec3 col;
        if (h > 0.6) col = mix(vec3(0.5, 0.42, 0.35), vec3(0.9, 0.88, 0.85), (h - 0.6) / 0.4);
        else if (h > 0.3) col = mix(vec3(0.2, 0.5, 0.15), vec3(0.5, 0.42, 0.35), (h - 0.3) / 0.3);
        else col = mix(vec3(0.3, 0.55, 0.2), vec3(0.2, 0.5, 0.15), h / 0.3);
        col *= 0.3 + diff * 0.7;
        fColor = vec4(col, 1.0);
        EmitVertex();
    }
    EndPrimitive();
}
GLSL

my $tf = <<'GLSL';
#version 150
in vec4 fColor; out vec4 outColor;
void main() { outColor = fColor; }
GLSL

# Simple shader for balls and trails (no geometry shader)
my $bv = <<'GLSL';
#version 150
in vec3 aPos;
uniform mat4 uMVP;
void main() { gl_Position = uMVP * vec4(aPos, 1.0); }
GLSL

my $bf = <<'GLSL';
#version 150
uniform vec4 uColor;
out vec4 outColor;
void main() { outColor = uColor; }
GLSL

my ($prog_terrain, $prog_ball);
my ($ut_mvp, $ut_time, $ub_mvp, $ub_color);
my ($vao_t, $vbo_t, $ibo_t, $vao_b, $vbo_b);
my ($start, $last_time);
my $num_tri_idx = scalar @terrain_indices;

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
    $m[10]=($f+$n)/($n-$f); $m[11]=-1; $m[14]=2*$f*$n/($n-$f); @m;
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
    my @c=([$v,$t,$p],[$q,$v,$p],[$p,$v,$t],[$p,$q,$v],[$t,$p,$v],[$v,$p,$q]);@{$c[int($h)%6]};
}

sub init_gl {
    # Terrain shader (with geometry shader for flat shading)
    my $tvs = compile_shader(GL_VERTEX_SHADER, $tv);
    my $tgs = compile_shader(GL_GEOMETRY_SHADER, $tg);
    my $tfs = compile_shader(GL_FRAGMENT_SHADER, $tf);
    $prog_terrain = glCreateProgram();
    glAttachShader($prog_terrain, $_) for ($tvs, $tgs, $tfs);
    glBindAttribLocation($prog_terrain, 0, 'aPos');
    glLinkProgram($prog_terrain);
    my ($ok) = glGetProgramiv_p($prog_terrain, GL_LINK_STATUS);
    die "TLink: ".glGetProgramInfoLog_p($prog_terrain) unless $ok;
    glDeleteShader($_) for ($tvs, $tgs, $tfs);
    $ut_mvp = glGetUniformLocation($prog_terrain, 'uMVP');
    $ut_time = glGetUniformLocation($prog_terrain, 'uTime');

    # Ball shader (simple, no geom)
    my $bvs = compile_shader(GL_VERTEX_SHADER, $bv);
    my $bfs = compile_shader(GL_FRAGMENT_SHADER, $bf);
    $prog_ball = glCreateProgram();
    glAttachShader($prog_ball, $bvs);
    glAttachShader($prog_ball, $bfs);
    glBindAttribLocation($prog_ball, 0, 'aPos');
    glLinkProgram($prog_ball);
    ($ok) = glGetProgramiv_p($prog_ball, GL_LINK_STATUS);
    die "BLink: ".glGetProgramInfoLog_p($prog_ball) unless $ok;
    glDeleteShader($bvs); glDeleteShader($bfs);
    $ub_mvp = glGetUniformLocation($prog_ball, 'uMVP');
    $ub_color = glGetUniformLocation($prog_ball, 'uColor');

    # Terrain mesh
    ($vao_t) = glGenVertexArrays_p(1);
    ($vbo_t) = glGenBuffers_p(1);
    ($ibo_t) = glGenBuffers_p(1);
    glBindVertexArray($vao_t);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo_t);
    my $tv_oa = OpenGL::Array->new_list(GL_FLOAT, @terrain_verts);
    glBufferData_c(GL_ARRAY_BUFFER, $tv_oa->length, $tv_oa->ptr, GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer_c(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, $ibo_t);
    my $ti_oa = OpenGL::Array->new_list(GL_UNSIGNED_INT, @terrain_indices);
    glBufferData_c(GL_ELEMENT_ARRAY_BUFFER, $ti_oa->length, $ti_oa->ptr, GL_STATIC_DRAW);
    glBindVertexArray(0);

    # Ball VBO
    ($vao_b) = glGenVertexArrays_p(1);
    ($vbo_b) = glGenBuffers_p(1);

    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    $start = time();
    $last_time = $start;
}

sub draw_sphere_at {
    my ($cx, $cy, $cz, $r, $cr, $cg, $cb, $mvp_ref) = @_;
    my $rings = 6;
    my $segs = 8;
    my @v;
    for my $ri (0 .. $rings) {
        my $phi = $ri / $rings * $PI;
        for my $si (0 .. $segs) {
            my $theta = $si / $segs * 2 * $PI;
            push @v, $cx + sin($phi)*cos($theta)*$r,
                     $cy + cos($phi)*$r,
                     $cz + sin($phi)*sin($theta)*$r;
            # Next ring
            my $phi2 = ($ri+1) / $rings * $PI;
            push @v, $cx + sin($phi2)*cos($theta)*$r,
                     $cy + cos($phi2)*$r,
                     $cz + sin($phi2)*sin($theta)*$r;
        }
    }
    my $oa = OpenGL::Array->new_list(GL_FLOAT, @v);
    glBindVertexArray($vao_b);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo_b);
    glBufferData_c(GL_ARRAY_BUFFER, $oa->length, $oa->ptr, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer_c(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glUniform4f($ub_color, $cr, $cg, $cb, 0.9);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, scalar(@v) / 3);
    glBindVertexArray(0);
}

sub display {
    my $now = time();
    my $dt = $now - $last_time;
    $dt = 0.033 if $dt > 0.033;
    $last_time = $now;
    my $t = $now - $start;

    # Physics
    for my $b (@balls) {
        my ($gx, $gz) = gradient_at($b->{x}, $b->{z});
        my $ax = atan2($gx, 1);
        my $az = atan2($gz, 1);
        $b->{vx} -= $gravity * sin($ax) * $dt;
        $b->{vz} -= $gravity * sin($az) * $dt;
        $b->{vx} *= $friction;
        $b->{vz} *= $friction;
        $b->{x} += $b->{vx} * $dt;
        $b->{z} += $b->{vz} * $dt;

        # Bounce off edges
        if ($b->{x} < 0.01) { $b->{x} = 0.01; $b->{vx} = abs($b->{vx}) * $bounce_coeff }
        if ($b->{x} > 0.99) { $b->{x} = 0.99; $b->{vx} = -abs($b->{vx}) * $bounce_coeff }
        if ($b->{z} < 0.01) { $b->{z} = 0.01; $b->{vz} = abs($b->{vz}) * $bounce_coeff }
        if ($b->{z} > 0.99) { $b->{z} = 0.99; $b->{vz} = -abs($b->{vz}) * $bounce_coeff }

        # Trail
        my $h = height_at($b->{x}, $b->{z});
        push @{$b->{trail}}, [$b->{x}, $h + $b->{r}, $b->{z}];
        shift @{$b->{trail}} while @{$b->{trail}} > 30;
    }

    # Render
    glClearColor(0.5, 0.6, 0.75, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    my $cam_a = $t * 0.1;
    my @proj = mat4_perspective(50, $W/$H, 0.01, 10);
    my @view = mat4_lookat(
        0.5 + cos($cam_a) * 1.3, 1.0, 0.5 + sin($cam_a) * 1.3,
        0.5, 0.3, 0.5,
        0, 1, 0);
    my @mvp = mat4_mult(\@proj, \@view);
    my $m = OpenGL::Array->new_list(GL_FLOAT, @mvp);

    # Terrain
    glUseProgram($prog_terrain);
    glUniformMatrix4fv_c($ut_mvp, 1, GL_FALSE, $m->ptr);
    glUniform1f($ut_time, $t);
    glBindVertexArray($vao_t);
    glDrawElements_c(GL_TRIANGLES, $num_tri_idx, GL_UNSIGNED_INT, 0);
    glBindVertexArray(0);

    # Balls
    glUseProgram($prog_ball);
    glUniformMatrix4fv_c($ub_mvp, 1, GL_FALSE, $m->ptr);

    for my $b (@balls) {
        my $bh = height_at($b->{x}, $b->{z}) + $b->{r};
        my ($cr, $cg, $cb) = hsv($b->{hue}, 0.85, 0.9);

        # Trail
        if (@{$b->{trail}} > 2) {
            my @tv;
            for my $pt (@{$b->{trail}}) { push @tv, $pt->[0], $pt->[1], $pt->[2] }
            my $toa = OpenGL::Array->new_list(GL_FLOAT, @tv);
            glBindVertexArray($vao_b);
            glBindBuffer(GL_ARRAY_BUFFER, $vbo_b);
            glBufferData_c(GL_ARRAY_BUFFER, $toa->length, $toa->ptr, GL_DYNAMIC_DRAW);
            glEnableVertexAttribArray(0);
            glVertexAttribPointer_c(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
            glUniform4f($ub_color, $cr, $cg, $cb, 0.35);
            glLineWidth(2);
            glDrawArrays(GL_LINE_STRIP, 0, scalar(@tv) / 3);
            glBindVertexArray(0);
        }

        # Ball sphere
        draw_sphere_at($b->{x}, $bh, $b->{z}, $b->{r}, $cr, $cg, $cb, \@mvp);

        # Shadow (dark circle on terrain)
        my $sh = height_at($b->{x}, $b->{z}) + 0.001;
        my @sv;
        push @sv, $b->{x}, $sh, $b->{z};
        for my $si (0 .. 12) {
            my $a = $si / 12 * 2 * $PI;
            push @sv, $b->{x} + cos($a) * $b->{r} * 1.2,
                      $sh, $b->{z} + sin($a) * $b->{r} * 1.2;
        }
        my $soa = OpenGL::Array->new_list(GL_FLOAT, @sv);
        glBindVertexArray($vao_b);
        glBindBuffer(GL_ARRAY_BUFFER, $vbo_b);
        glBufferData_c(GL_ARRAY_BUFFER, $soa->length, $soa->ptr, GL_DYNAMIC_DRAW);
        glEnableVertexAttribArray(0);
        glVertexAttribPointer_c(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
        glUniform4f($ub_color, 0, 0, 0, 0.3);
        glDrawArrays(GL_TRIANGLE_FAN, 0, scalar(@sv) / 3);
        glBindVertexArray(0);
    }

    glutSwapBuffers();
}

sub idle { glutPostRedisplay() }
sub keyboard {
    exit(0) if ord($_[0]) == 27;
    spawn_balls() if ord($_[0]) == 32;
}

glutInit();
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH | GLUT_MULTISAMPLE);
glutInitWindowSize($W, $H);
glutCreateWindow('3D Rolling Balls');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "3D rolling balls: %d balls on %dx%d terrain — Space=respawn, ESC=quit\n",
    $num_balls, $GRID, $GRID;
glutMainLoop();
