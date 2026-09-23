#!/usr/bin/env perl
# Rocky mountains via geometry shader: envelope-driven terrain with flat-shaded facets
# Terrain heightmap from crossed spline envelopes, displaced in geometry shader
# with fractal noise for rocky detail and envelope-controlled erosion/snow line
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
use POSIX qw(floor tan);

my $W = 900;
my $H = 600;
my $GRID = 80;  # terrain resolution

# Terrain profile envelopes
srand(42);
my @hx = map { $_ / 7 } 0 .. 7;
my @vx = (0.1, 0.4, 0.8, 0.3, 0.95, 0.5, 0.7, 0.15);
my $terrain_x = spline(\@hx, \@vx, resolution => 8);

my @hz = map { $_ / 5 } 0 .. 5;
my @vz = (0.2, 0.6, 0.4, 0.85, 0.3, 0.2);
my $terrain_z = spline(\@hz, \@vz, resolution => 8);

# Erosion envelope: controls how much detail/roughness
my $erosion = env([[0.5, 1.0, 0.3, 0.8], [0.33, 0.34, 0.33], [2, -2, 2]],
    morpher_formula => 'smoothstep', is_fold_over => 1);

# Snow line envelope
my $snowline = env([[0.7, 0.5, 0.8], [0.5, 0.5], [1, 1]],
    is_fold_over => 1);

my $sx = $terrain_x->static;
my $sz = $terrain_z->static;
my $dx = $terrain_x->duration;
my $dz = $terrain_z->duration;

# Pre-compute heightmap
my @heights;
for my $zi (0 .. $GRID) {
    for my $xi (0 .. $GRID) {
        my $hx = $sx->($xi / $GRID * $dx);
        my $hz = $sz->($zi / $GRID * $dz);
        $heights[$zi * ($GRID + 1) + $xi] = ($hx + $hz) * 0.5;
    }
}

# Pack height data as texture (1D float array uploaded as uniform)
my $height_data = pack('f*', @heights);

# Shaders
my $vert_src = <<'GLSL';
#version 150
in vec3 aPos;
in float aHeight;
out VS_OUT {
    float height;
    vec3 worldPos;
} vs_out;

uniform mat4 uMVP;
uniform float uTime;

void main() {
    vec3 pos = aPos;
    pos.y = aHeight;
    vs_out.height = aHeight;
    vs_out.worldPos = pos;
    gl_Position = uMVP * vec4(pos, 1.0);
}
GLSL

my $geom_src = <<'GLSL';
#version 150
layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

in VS_OUT {
    float height;
    vec3 worldPos;
} gs_in[];

out vec4 frag_color;
out vec3 frag_normal;

uniform float uTime;
uniform float uErosion;
uniform float uSnowLine;

// Pseudo-random hash
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Value noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1, 0));
    float c = hash(i + vec2(0, 1));
    float d = hash(i + vec2(1, 1));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal brownian motion
float fbm(vec2 p, float erosion) {
    float v = 0.0;
    float amp = 0.5;
    float freq = 1.0;
    for (int i = 0; i < 5; i++) {
        v += amp * noise(p * freq);
        freq *= 2.0 + erosion;
        amp *= 0.5 - erosion * 0.1;
    }
    return v;
}

void main() {
    // Flat shading: compute face normal
    vec3 e1 = gs_in[1].worldPos - gs_in[0].worldPos;
    vec3 e2 = gs_in[2].worldPos - gs_in[0].worldPos;
    vec3 face_normal = normalize(cross(e1, e2));

    for (int i = 0; i < 3; i++) {
        vec4 pos = gl_in[i].gl_Position;
        float h = gs_in[i].height;
        vec3 wp = gs_in[i].worldPos;

        // Add fractal rocky detail in geometry shader
        float rock_detail = fbm(wp.xz * 8.0 + uTime * 0.1, uErosion) * uErosion * 0.08;
        pos.y += rock_detail * (0.3 + h);  // more detail at higher elevation

        gl_Position = pos;

        // Color by elevation with biomes
        vec3 col;
        float snow = uSnowLine;
        if (h > snow) {
            // Snow caps
            float snow_noise = noise(wp.xz * 20.0) * 0.1;
            col = mix(vec3(0.85, 0.85, 0.9), vec3(1.0, 0.98, 0.95),
                      (h - snow) / (1.0 - snow) + snow_noise);
        } else if (h > snow - 0.15) {
            // Rock/alpine
            float rock = noise(wp.xz * 15.0);
            col = mix(vec3(0.45, 0.38, 0.32), vec3(0.55, 0.48, 0.4), rock);
        } else if (h > 0.25) {
            // Forest/grass
            float grass = noise(wp.xz * 10.0);
            col = mix(vec3(0.2, 0.45, 0.15), vec3(0.15, 0.35, 0.1), grass);
        } else {
            // Lowland/water edge
            col = mix(vec3(0.3, 0.5, 0.2), vec3(0.6, 0.55, 0.4), h / 0.25);
        }

        // Simple directional lighting
        vec3 light_dir = normalize(vec3(0.5, 0.8, 0.3));
        float diffuse = max(dot(face_normal, light_dir), 0.0);
        float ambient = 0.3;
        col *= ambient + diffuse * 0.7;

        // Fog at distance
        float dist = length(wp.xz - vec2(0.5));
        float fog = smoothstep(0.3, 0.7, dist);
        col = mix(col, vec3(0.6, 0.65, 0.75), fog * 0.5);

        frag_color = vec4(col, 1.0);
        frag_normal = face_normal;
        EmitVertex();
    }
    EndPrimitive();
}
GLSL

my $frag_src = <<'GLSL';
#version 150
in vec4 frag_color;
in vec3 frag_normal;
out vec4 outColor;

void main() {
    outColor = frag_color;
}
GLSL

my ($prog, $u_mvp, $u_time, $u_erosion, $u_snowline, $vbo_pos, $vbo_height, $ibo, $vao);
my ($num_indices, $start);

sub compile_shader {
    my ($type, $src) = @_;
    my $s = glCreateShader($type);
    glShaderSource_p($s, $src);
    glCompileShader($s);
    my ($ok) = glGetShaderiv_p($s, GL_COMPILE_STATUS);
    unless ($ok) {
        my $log = glGetShaderInfoLog_p($s);
        die "Shader: $log\n";
    }
    return $s;
}

sub mat4_perspective {
    my ($fov, $aspect, $near, $far) = @_;
    my $f = 1 / tan($fov * 3.14159265 / 360);
    my @m = (0) x 16;
    $m[0] = $f / $aspect; $m[5] = $f;
    $m[10] = ($far + $near) / ($near - $far);
    $m[11] = -1;
    $m[14] = 2 * $far * $near / ($near - $far);
    return @m;
}

sub mat4_lookat {
    my ($ex,$ey,$ez, $cx,$cy,$cz, $ux,$uy,$uz) = @_;
    my @f = ($cx-$ex, $cy-$ey, $cz-$ez);
    my $fl = sqrt($f[0]**2 + $f[1]**2 + $f[2]**2);
    @f = map { $_ / $fl } @f;
    my @s = ($f[1]*$uz - $f[2]*$uy, $f[2]*$ux - $f[0]*$uz, $f[0]*$uy - $f[1]*$ux);
    my $sl = sqrt($s[0]**2 + $s[1]**2 + $s[2]**2);
    @s = map { $_ / $sl } @s;
    my @u = ($s[1]*$f[2] - $s[2]*$f[1], $s[2]*$f[0] - $s[0]*$f[2], $s[0]*$f[1] - $s[1]*$f[0]);
    return (
        $s[0], $u[0], -$f[0], 0,
        $s[1], $u[1], -$f[1], 0,
        $s[2], $u[2], -$f[2], 0,
        -($s[0]*$ex + $s[1]*$ey + $s[2]*$ez),
        -($u[0]*$ex + $u[1]*$ey + $u[2]*$ez),
        $f[0]*$ex + $f[1]*$ey + $f[2]*$ez, 1
    );
}

sub mat4_mult {
    my ($a, $b) = @_;
    my @r = (0) x 16;
    for my $i (0..3) {
        for my $j (0..3) {
            for my $k (0..3) {
                $r[$j*4+$i] += $a->[$k*4+$i] * $b->[$j*4+$k];
            }
        }
    }
    return @r;
}

sub init_gl {
    my $vs = compile_shader(GL_VERTEX_SHADER, $vert_src);
    my $gs = compile_shader(GL_GEOMETRY_SHADER, $geom_src);
    my $fs = compile_shader(GL_FRAGMENT_SHADER, $frag_src);

    $prog = glCreateProgram();
    glAttachShader($prog, $_) for ($vs, $gs, $fs);
    glBindAttribLocation($prog, 0, 'aPos');
    glBindAttribLocation($prog, 1, 'aHeight');
    glLinkProgram($prog);
    my ($ok) = glGetProgramiv_p($prog, GL_LINK_STATUS);
    die "Link: " . glGetProgramInfoLog_p($prog) . "\n" unless $ok;
    glDeleteShader($_) for ($vs, $gs, $fs);

    $u_mvp      = glGetUniformLocation($prog, 'uMVP');
    $u_time     = glGetUniformLocation($prog, 'uTime');
    $u_erosion  = glGetUniformLocation($prog, 'uErosion');
    $u_snowline = glGetUniformLocation($prog, 'uSnowLine');

    # Build terrain mesh
    my (@pos, @ht, @idx);
    for my $zi (0 .. $GRID) {
        for my $xi (0 .. $GRID) {
            my $x = $xi / $GRID;
            my $z = $zi / $GRID;
            my $h = $heights[$zi * ($GRID + 1) + $xi];
            push @pos, $x, $h, $z;
            push @ht, $h;
        }
    }
    for my $zi (0 .. $GRID - 1) {
        for my $xi (0 .. $GRID - 1) {
            my $i = $zi * ($GRID + 1) + $xi;
            push @idx, $i, $i + 1, $i + $GRID + 1;
            push @idx, $i + 1, $i + $GRID + 2, $i + $GRID + 1;
        }
    }
    $num_indices = scalar @idx;

    ($vao) = glGenVertexArrays_p(1);
    glBindVertexArray($vao);

    ($vbo_pos) = glGenBuffers_p(1);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo_pos);
    my $pos_oa = OpenGL::Array->new_list(GL_FLOAT, @pos);
    glBufferData_c(GL_ARRAY_BUFFER, $pos_oa->length, $pos_oa->ptr, GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer_c(0, 3, GL_FLOAT, GL_FALSE, 0, 0);

    ($vbo_height) = glGenBuffers_p(1);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo_height);
    my $ht_oa = OpenGL::Array->new_list(GL_FLOAT, @ht);
    glBufferData_c(GL_ARRAY_BUFFER, $ht_oa->length, $ht_oa->ptr, GL_STATIC_DRAW);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer_c(1, 1, GL_FLOAT, GL_FALSE, 0, 0);

    ($ibo) = glGenBuffers_p(1);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, $ibo);
    my $idx_oa = OpenGL::Array->new_list(GL_UNSIGNED_INT, @idx);
    glBufferData_c(GL_ELEMENT_ARRAY_BUFFER, $idx_oa->length, $idx_oa->ptr, GL_STATIC_DRAW);

    glBindVertexArray(0);

    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);

    $start = time();
}

sub fmod { $_[0] - floor($_[0] / $_[1]) * $_[1] }

sub display {
    my $t = time() - $start;

    my $ero = $erosion->static->(fmod($t * 0.3, $erosion->duration));
    my $snow = $snowline->static->(fmod($t * 0.2, $snowline->duration));

    glClearColor(0.55, 0.6, 0.72, 1.0);  # sky
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram($prog);

    # Orbiting camera
    my $cam_angle = $t * 0.15;
    my $cam_r = 1.2;
    my $cam_h = 0.6 + sin($t * 0.1) * 0.1;
    my $cx = 0.5 + cos($cam_angle) * $cam_r;
    my $cz = 0.5 + sin($cam_angle) * $cam_r;

    my @proj = mat4_perspective(45, $W / $H, 0.01, 10);
    my @view = mat4_lookat($cx, $cam_h, $cz, 0.5, 0.3, 0.5, 0, 1, 0);
    my @mvp = mat4_mult(\@proj, \@view);

    my $mvp_oa = OpenGL::Array->new_list(GL_FLOAT, @mvp);
    glUniformMatrix4fv_c($u_mvp, 1, GL_FALSE, $mvp_oa->ptr);
    glUniform1f($u_time, $t);
    glUniform1f($u_erosion, $ero);
    glUniform1f($u_snowline, $snow);

    glBindVertexArray($vao);
    glDrawElements_c(GL_TRIANGLES, $num_indices, GL_UNSIGNED_INT, 0);
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
glutCreateWindow('Envelope Rocky Mountains');

init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "Rocky mountains — %dx%d grid, geometry shader — ESC to quit\n", $GRID, $GRID;
glutMainLoop();
