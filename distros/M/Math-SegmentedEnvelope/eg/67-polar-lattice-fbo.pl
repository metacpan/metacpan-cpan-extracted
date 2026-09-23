#!/usr/bin/env perl
# Polar lattice with FBO trails: render to offscreen framebuffer,
# fade+blur previous frame, composite with new frame for smooth motion blur
#
# Pipeline per frame:
#   1. Bind FBO, draw fade quad (darkens previous frame = trail decay)
#   2. Apply horizontal blur pass to FBO texture
#   3. Draw new lattice arms on top
#   4. Blit FBO to screen
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
my $samples = 80;

# Envelope banks (8 each)
my @angle_envs = (
    env([[0, 6.28], [1], [1]]),
    spline([0, 0.3, 0.7, 1.0], [0, 4.0, 2.0, 6.28]),
    env([[0, 9.42, 3.14, 12.57], [0.3, 0.4, 0.3], [2, -2, 2]]),
    env([[0, -3.14, 0, 3.14], [0.3, 0.4, 0.3], [2, -3, 2]], morpher_formula => 'smoothstep'),
    spline([0, 0.2, 0.5, 0.8, 1.0], [0, 3.14, 0, -3.14, 0]),
    env([[0, 12.57], [1], [2]], morpher_formula => 'cubic_in'),
    spline([0, 0.3, 0.5, 0.7, 1.0], [0, -6.28, 3.14, -3.14, 6.28]),
    env([[0, 6.28, 0, 6.28], [0.33, 0.34, 0.33], [3, -3, 3]], morpher_formula => 'elastic_out'),
);
my @radius_envs = (
    env([[0.2, 1.5, 0.2], [0.5, 0.5], [2, -2]], morpher_formula => 'smoothstep'),
    spline([0, 0.25, 0.5, 0.75, 1.0], [0.1, 1.2, 0.5, 1.0, 0.1]),
    adsr(0.1, 0.2, 0.8, 0.3, peak => 1.5, morpher_formula => 'smoothstep'),
    perc(0.05, 0.95, peak => 1.8, morpher_formula => 'cubic_out'),
    env([[0.5, 1.2, 0.3, 1.0, 0.5], [0.25, 0.25, 0.25, 0.25], [2, -3, 3, -2]], morpher_formula => 'bounce_out'),
    spline([0, 0.15, 0.5, 0.85, 1.0], [0.8, 1.5, 0.2, 1.3, 0.8]),
    env([[0.3, 0.8, 1.5, 0.8, 0.3], [0.25, 0.25, 0.25, 0.25], [2, 2, -2, -2]], morpher_formula => 'smoothstep'),
    env([[1.0, 0.1, 1.0, 0.1, 1.0], [0.25, 0.25, 0.25, 0.25], [-3, 3, -3, 3]], morpher_formula => 'sine'),
);

my @angle_keys = map { [$_->table($samples)] } @angle_envs;
my @radius_keys = map { [$_->table($samples)] } @radius_envs;
my $n_angle = scalar @angle_keys;
my $n_radius = scalar @radius_keys;
my $morph_sec = 4.0;

my $height_env = env([[0, 0.3, 0, -0.3, 0], [0.25, 0.25, 0.25, 0.25], [2, -2, 2, -2]],
    morpher_formula => 'smoothstep', is_fold_over => 1);
my $height_vals = [$height_env->table($samples)];

my $pulse = env([[1.0, 1.08, 1.0], [0.5, 0.5], [2, -2]],
    morpher_formula => 'smoothstep', is_fold_over => 1);
my $pulse_s = $pulse->static;
my $pulse_d = $pulse->duration;

sub lerp_samples {
    my ($a, $b, $mix) = @_;
    my @r;
    for my $i (0 .. $#$a) { push @r, $a->[$i] * (1 - $mix) + $b->[$i] * $mix }
    return \@r;
}

sub morph_bank {
    my ($keys, $n, $t, $off) = @_;
    my $ph = ($t / $morph_sec + $off) * $n;
    $ph -= floor($ph / $n) * $n;
    my $ia = int($ph) % $n;
    my $ib = ($ia + 1) % $n;
    my $mx = $ph - floor($ph);
    $mx = $mx * $mx * (3 - 2 * $mx);
    return lerp_samples($keys->[$ia], $keys->[$ib], $mx);
}

# === Shaders ===

# Lattice line shader (vertex + geometry + fragment)
my $lattice_vert = <<'GLSL';
#version 150
in vec3 aPos; in vec4 aColor; in float aThick;
out VS_OUT { vec4 color; float thick; } vs_out;
uniform mat4 uMVP;
void main() {
    gl_Position = uMVP * vec4(aPos, 1.0);
    vs_out.color = aColor; vs_out.thick = aThick;
}
GLSL

my $lattice_geom = <<'GLSL';
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

my $lattice_frag = <<'GLSL';
#version 150
in vec4 gColor; in float gEdge;
out vec4 outColor;
void main() {
    float d=abs(gEdge);
    float alpha=1.0-smoothstep(0.4,1.0,d);
    float glow=exp(-d*d*5.0)*0.3;
    outColor=vec4(gColor.rgb+glow, gColor.a*alpha);
}
GLSL

# Fullscreen quad shader (for fade + blur passes)
my $quad_vert = <<'GLSL';
#version 150
in vec2 aPos;
out vec2 vUV;
void main() {
    gl_Position = vec4(aPos, 0.0, 1.0);
    vUV = aPos * 0.5 + 0.5;
}
GLSL

# Fade pass: darken previous frame (trail decay)
my $fade_frag = <<'GLSL';
#version 150
in vec2 vUV;
out vec4 outColor;
uniform sampler2D uTex;
uniform float uDecay;
void main() {
    vec4 c = texture(uTex, vUV);
    outColor = vec4(c.rgb * uDecay, 1.0);
}
GLSL

# Blur pass: Gaussian-ish blur for soft trail glow
my $blur_frag = <<'GLSL';
#version 150
in vec2 vUV;
out vec4 outColor;
uniform sampler2D uTex;
uniform vec2 uDirection;  // (1/W, 0) or (0, 1/H)
void main() {
    vec4 c = vec4(0.0);
    // 5-tap Gaussian
    c += texture(uTex, vUV - uDirection * 2.0) * 0.06;
    c += texture(uTex, vUV - uDirection)       * 0.24;
    c += texture(uTex, vUV)                     * 0.40;
    c += texture(uTex, vUV + uDirection)       * 0.24;
    c += texture(uTex, vUV + uDirection * 2.0) * 0.06;
    outColor = c;
}
GLSL

# Composite pass: just blit texture to screen
my $blit_frag = <<'GLSL';
#version 150
in vec2 vUV;
out vec4 outColor;
uniform sampler2D uTex;
void main() {
    outColor = texture(uTex, vUV);
}
GLSL

my ($prog_lattice, $prog_fade, $prog_blur, $prog_blit);
my ($u_mvp, $u_resolution);
my ($u_fade_tex, $u_fade_decay);
my ($u_blur_tex, $u_blur_dir);
my ($u_blit_tex);
my ($vao_lines, $vbo_lines, $vao_quad, $vbo_quad);
my ($fbo_a, $tex_a, $fbo_b, $tex_b, $rbo_depth);
my $start;

sub compile_shader {
    my($type,$src)=@_;my $s=glCreateShader($type);
    glShaderSource_p($s,$src);glCompileShader($s);
    my($ok)=glGetShaderiv_p($s,GL_COMPILE_STATUS);
    die "Shader: ".glGetShaderInfoLog_p($s) unless $ok; $s;
}

sub link_program {
    my @shaders = @_;
    my $p = glCreateProgram();
    glAttachShader($p, $_) for @shaders;
    glLinkProgram($p);
    my ($ok) = glGetProgramiv_p($p, GL_LINK_STATUS);
    die "Link: ".glGetProgramInfoLog_p($p) unless $ok;
    glDeleteShader($_) for @shaders;
    return $p;
}

sub create_fbo_pair {
    # Two FBOs for ping-pong (blur needs read from one, write to other)
    for my $pair ([\$fbo_a, \$tex_a], [\$fbo_b, \$tex_b]) {
        my ($fbo_ref, $tex_ref) = @$pair;
        ($$tex_ref) = glGenTextures_p(1);
        glBindTexture(GL_TEXTURE_2D, $$tex_ref);
        glTexImage2D_c(GL_TEXTURE_2D, 0, GL_RGBA16F, $W, $H, 0, GL_RGBA, GL_FLOAT, 0);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        ($$fbo_ref) = glGenFramebuffers_p(1);
        glBindFramebuffer(GL_FRAMEBUFFER, $$fbo_ref);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, $$tex_ref, 0);
    }

    # Shared depth renderbuffer
    ($rbo_depth) = glGenRenderbuffers_p(1);
    glBindRenderbuffer(GL_RENDERBUFFER, $rbo_depth);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, $W, $H);
    glBindFramebuffer(GL_FRAMEBUFFER, $fbo_a);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, $rbo_depth);
    glBindFramebuffer(GL_FRAMEBUFFER, $fbo_b);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, $rbo_depth);

    # Clear both
    for my $fbo ($fbo_a, $fbo_b) {
        glBindFramebuffer(GL_FRAMEBUFFER, $fbo);
        glClearColor(0.02, 0.02, 0.04, 1);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
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

sub draw_fullscreen_quad {
    glBindVertexArray($vao_quad);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindVertexArray(0);
}

sub init_gl {
    # Lattice shader (with geometry shader)
    $prog_lattice = link_program(
        compile_shader(GL_VERTEX_SHADER, $lattice_vert),
        compile_shader(GL_GEOMETRY_SHADER, $lattice_geom),
        compile_shader(GL_FRAGMENT_SHADER, $lattice_frag));
    $u_mvp = glGetUniformLocation($prog_lattice, 'uMVP');
    $u_resolution = glGetUniformLocation($prog_lattice, 'uResolution');

    # Fade shader
    $prog_fade = link_program(
        compile_shader(GL_VERTEX_SHADER, $quad_vert),
        compile_shader(GL_FRAGMENT_SHADER, $fade_frag));
    glUseProgram($prog_fade);
    $u_fade_tex = glGetUniformLocation($prog_fade, 'uTex');
    $u_fade_decay = glGetUniformLocation($prog_fade, 'uDecay');

    # Blur shader
    $prog_blur = link_program(
        compile_shader(GL_VERTEX_SHADER, $quad_vert),
        compile_shader(GL_FRAGMENT_SHADER, $blur_frag));
    glUseProgram($prog_blur);
    $u_blur_tex = glGetUniformLocation($prog_blur, 'uTex');
    $u_blur_dir = glGetUniformLocation($prog_blur, 'uDirection');

    # Blit shader
    $prog_blit = link_program(
        compile_shader(GL_VERTEX_SHADER, $quad_vert),
        compile_shader(GL_FRAGMENT_SHADER, $blit_frag));
    glUseProgram($prog_blit);
    $u_blit_tex = glGetUniformLocation($prog_blit, 'uTex');

    # Line VAO/VBO
    ($vao_lines) = glGenVertexArrays_p(1);
    ($vbo_lines) = glGenBuffers_p(1);

    # Fullscreen quad VAO/VBO
    ($vao_quad) = glGenVertexArrays_p(1);
    ($vbo_quad) = glGenBuffers_p(1);
    glBindVertexArray($vao_quad);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo_quad);
    my $qa = OpenGL::Array->new_list(GL_FLOAT, -1,-1, 1,-1, -1,1, 1,1);
    glBufferData_c(GL_ARRAY_BUFFER, $qa->length, $qa->ptr, GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer_c(0, 2, GL_FLOAT, GL_FALSE, 0, 0);
    glBindVertexArray(0);

    # FBOs
    create_fbo_pair();

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    $start = time();
}

sub display {
    my $t = time() - $start;
    my $p = $pulse_s->(fmod($t * 0.3, $pulse_d));

    # === Pass 1: Fade previous frame in FBO A ===
    glBindFramebuffer(GL_FRAMEBUFFER, $fbo_b);
    glDisable(GL_DEPTH_TEST);
    glUseProgram($prog_fade);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, $tex_a);
    glUniform1i($u_fade_tex, 0);
    glUniform1f($u_fade_decay, 0.92);  # trail persistence (lower = faster fade)
    draw_fullscreen_quad();

    # === Pass 2: Blur the faded frame ===
    # Horizontal blur: B -> A
    glBindFramebuffer(GL_FRAMEBUFFER, $fbo_a);
    glUseProgram($prog_blur);
    glBindTexture(GL_TEXTURE_2D, $tex_b);
    glUniform1i($u_blur_tex, 0);
    glUniform2f($u_blur_dir, 1.0/$W, 0);
    draw_fullscreen_quad();

    # Vertical blur: A -> B
    glBindFramebuffer(GL_FRAMEBUFFER, $fbo_b);
    glBindTexture(GL_TEXTURE_2D, $tex_a);
    glUniform2f($u_blur_dir, 0, 1.0/$H);
    draw_fullscreen_quad();

    # Copy back B -> A for next frame's input
    glBindFramebuffer(GL_FRAMEBUFFER, $fbo_a);
    glUseProgram($prog_blit);
    glBindTexture(GL_TEXTURE_2D, $tex_b);
    glUniform1i($u_blit_tex, 0);
    draw_fullscreen_quad();

    # === Pass 3: Draw new lattice on FBO A ===
    glEnable(GL_DEPTH_TEST);
    glClear(GL_DEPTH_BUFFER_BIT);
    glUseProgram($prog_lattice);

    my $cam_a = $t * 0.15;
    my $cam_h = 2.0 + sin($t * 0.1) * 0.8;
    my @proj = mat4_perspective(55, $W/$H, 0.01, 20);
    my @view = mat4_lookat(cos($cam_a)*3.5, $cam_h, sin($cam_a)*3.5, 0,0,0, 0,1,0);
    my @mvp = mat4_mult(\@proj, \@view);
    my $m = OpenGL::Array->new_list(GL_FLOAT, @mvp);
    glUniformMatrix4fv_c($u_mvp, 1, GL_FALSE, $m->ptr);
    glUniform2f($u_resolution, $W, $H);

    # Build arms
    my @verts;
    my @cmds;
    my $total = 0;

    for my $arm (0 .. $num_arms - 1) {
        my $off = $arm / $num_arms;
        my @av = @{morph_bank(\@angle_keys, $n_angle, $t, $off)};
        my @rv = @{morph_bank(\@radius_keys, $n_radius, $t, $off * 1.3 + 0.5)};
        my @hv = @$height_vals;
        my $arm_off = $arm / $num_arms * 2 * $PI;
        my $tp = int($t * 0.5 + $arm * 0.2) % $samples;
        my $elev = sin($arm * 2.399) * 0.4;
        my $hue = $arm / $num_arms + $t * 0.03;

        for my $j (0 .. $samples - 1) {
            my $s = $j / ($samples - 1);
            my $idx = ($j + $tp) % $samples;
            my $angle = $av[$idx] + $arm_off;
            my $radius = $rv[$idx] * $p;
            my $x = cos($angle) * $radius;
            my $z = sin($angle) * $radius;
            my $y = $hv[$idx] * $p + sin($s * $PI) * $elev;
            my ($cr,$cg,$cb) = hsv($hue + $s * 0.2, 0.75, 0.4 + $radius * 0.3);
            push @verts, $x, $y, $z, $cr, $cg, $cb, 0.85, 1.5 + $radius * 3;
        }
        push @cmds, [$total, $samples]; $total += $samples;
    }

    my $stride = 8 * 4;
    my $oa = OpenGL::Array->new_list(GL_FLOAT, @verts);
    glBindVertexArray($vao_lines);
    glBindBuffer(GL_ARRAY_BUFFER, $vbo_lines);
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

    # === Pass 4: Blit FBO A to screen ===
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glDisable(GL_DEPTH_TEST);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram($prog_blit);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, $tex_a);
    glUniform1i($u_blit_tex, 0);
    draw_fullscreen_quad();
    glEnable(GL_DEPTH_TEST);

    glutSwapBuffers();
}

sub idle { glutPostRedisplay() }
sub keyboard { exit(0) if ord($_[0]) == 27 }

glutInit();
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH | GLUT_MULTISAMPLE);
glutInitContextVersion(3, 2);
glutInitContextProfile(0x0001);
glutInitWindowSize($W, $H);
glutCreateWindow('Polar Lattice FBO Trails');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "FBO trail lattice: %d arms, fade+blur pipeline — ESC to quit\n", $num_arms;
glutMainLoop();
