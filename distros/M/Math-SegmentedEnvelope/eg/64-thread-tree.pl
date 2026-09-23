#!/usr/bin/env perl
# Thread tree: recursive branching structure with envelope-shaped limbs
# Trunk splits into branches, branches into twigs, twigs carry leaf clusters
# Each branch's thickness and curvature controlled by envelopes
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

my $W = 900;
my $H = 750;
my $PI = 3.14159265358979323846;
my $samples = 40;

# Branch thickness envelope: thick at base, tapering
my $thickness = env([[1.0, 0.85, 0.6, 0.3, 0.1],
                     [0.2, 0.3, 0.3, 0.2], [-1, -1, -2, -2]],
    morpher_formula => 'smoothstep');
my $thick_s = $thickness->static;
my $thick_d = $thickness->duration;

# Branch curvature: how much each branch bends
my $curve_env = spline([0, 0.3, 0.7, 1.0], [0, 0.3, 0.8, 1.0]);
my $curve_s = $curve_env->static;
my $curve_d = $curve_env->duration;

# Leaf cluster shape
my $leaf = env([[0, 0.06, 0.04, 0.05, 0],
                [0.25, 0.25, 0.25, 0.25], [2, -2, 2, -2]],
    morpher_formula => 'smoothstep');
my $leaf_vals = [$leaf->table($samples)];

# Wind
my $wind = env([[0.15, 0.5, 0.2, 0.4, 0.15],
                [0.3, 0.2, 0.3, 0.2], [2, -2, 2, -2]],
    morpher_formula => 'smoothstep', is_fold_over => 1);
my $wind_s = $wind->static;
my $wind_d = $wind->duration;

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
    float alpha=1.0-smoothstep(0.3,1.0,d);
    float sheen=exp(-d*d*4.0)*0.15;
    outColor=vec4(gColor.rgb+sheen, gColor.a*alpha);
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

# Pre-generate tree structure (recursive)
my @branches;  # each: { origin, direction, length, thickness, depth, seed }

sub gen_tree {
    my ($ox,$oy,$oz, $dx,$dy,$dz, $len, $thick, $depth, $seed) = @_;
    return if $depth > 4 || $thick < 0.3;

    push @branches, {
        ox => $ox, oy => $oy, oz => $oz,
        dx => $dx, dy => $dy, dz => $dz,
        len => $len, thick => $thick, depth => $depth, seed => $seed,
    };

    # Branch endpoint
    my $ex = $ox + $dx * $len;
    my $ey = $oy + $dy * $len;
    my $ez = $oz + $dz * $len;

    # Number of child branches
    my $children = ($depth < 2) ? 3 : 2;
    $children++ if rand() < 0.3;

    for my $ci (0 .. $children - 1) {
        srand($seed * 1000 + $ci * 137 + $depth * 31);
        my $spread = 0.4 + $depth * 0.15;
        my $child_theta = ($ci / $children + rand() * 0.3) * 2 * $PI;
        my $child_phi = 0.3 + rand() * $spread;

        # New direction: tilt away from parent + spread
        my $cdx = $dx * cos($child_phi) + cos($child_theta) * sin($child_phi);
        my $cdy = $dy * cos($child_phi) + sin($child_phi) * 0.5;
        my $cdz = $dz * cos($child_phi) + sin($child_theta) * sin($child_phi);
        my $cl = sqrt($cdx**2 + $cdy**2 + $cdz**2) || 1;
        $cdx /= $cl; $cdy /= $cl; $cdz /= $cl;

        # Bias upward
        $cdy = abs($cdy) * 0.8 + 0.2;
        $cl = sqrt($cdx**2 + $cdy**2 + $cdz**2);
        $cdx /= $cl; $cdy /= $cl; $cdz /= $cl;

        gen_tree($ex, $ey, $ez,
                 $cdx, $cdy, $cdz,
                 $len * (0.6 + rand() * 0.2),
                 $thick * (0.5 + rand() * 0.2),
                 $depth + 1,
                 $seed * 7 + $ci * 13 + 1);
    }
}

# Generate trunk + branches
gen_tree(0, 0, 0,  0, 1, 0,  0.8, 8, 0, 42);
printf "Generated %d branches\n", scalar @branches;

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
    my $w = $wind_s->(fmod($t * 0.3, $wind_d));

    glClearColor(0.04, 0.06, 0.1, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram($prog);

    my $cam_a = $t * 0.12;
    my @proj = mat4_perspective(50, $W/$H, 0.01, 20);
    my @view = mat4_lookat(
        cos($cam_a)*4, 2.0+sin($t*0.08)*0.5, sin($cam_a)*4,
        0, 1.2, 0,  0, 1, 0);
    my @mvp = mat4_mult(\@proj, \@view);
    my $m = OpenGL::Array->new_list(GL_FLOAT, @mvp);
    glUniformMatrix4fv_c($u_mvp, 1, GL_FALSE, $m->ptr);
    glUniform2f($u_resolution, $W, $H);

    my @verts;
    my @cmds;
    my $total = 0;

    for my $br (@branches) {
        my $depth = $br->{depth};
        my $phase = $t * (0.3 + $depth * 0.2) + $br->{seed} * 0.1;

        for my $j (0 .. $samples) {
            my $s = $j / $samples;

            # Thickness taper from envelope
            my $tw = $thick_s->($s * $thick_d) * $br->{thick};

            # Curvature: branch bends outward
            my $bend = $curve_s->($s * $curve_d) * 0.15 * ($depth + 1);

            # Wind sway: more at tips and higher branches
            my $sway_x = sin($phase + $s * 3) * $w * 0.05 * $s * ($depth + 1);
            my $sway_z = cos($phase * 0.7 + $s * 2.5) * $w * 0.03 * $s * ($depth + 1);

            my $x = $br->{ox} + $br->{dx} * $br->{len} * $s
                  + $bend * (1 - abs($br->{dy})) * $br->{dx} + $sway_x;
            my $y = $br->{oy} + $br->{dy} * $br->{len} * $s;
            my $z = $br->{oz} + $br->{dz} * $br->{len} * $s
                  + $bend * (1 - abs($br->{dy})) * $br->{dz} + $sway_z;

            # Color: brown trunk -> green tips
            my $green_mix = $depth / 4.0;
            my ($cr,$cg,$cb);
            if ($green_mix < 0.5) {
                ($cr,$cg,$cb) = hsv(0.07, 0.6, 0.35 + $s * 0.1);  # brown
            } else {
                my $leaf_green = 0.25 + $s * 0.1 + sin($br->{seed}) * 0.05;
                ($cr,$cg,$cb) = hsv($leaf_green, 0.7, 0.4 + $s * 0.2);
            }

            push @verts, $x, $y, $z, $cr, $cg, $cb, 0.8, $tw;
        }

        push @cmds, [$total, $samples + 1];
        $total += $samples + 1;

        # Leaf cluster at tips of outermost branches
        if ($depth >= 3) {
            my $tip_x = $br->{ox} + $br->{dx} * $br->{len};
            my $tip_y = $br->{oy} + $br->{dy} * $br->{len};
            my $tip_z = $br->{oz} + $br->{dz} * $br->{len};
            my $leaf_phase = $t * 0.6 + $br->{seed};

            # Small circular leaf cluster
            my $leaf_r = 0.08 + rand() * 0.04;
            for my $j (0 .. $samples / 2) {
                my $s = $j / ($samples / 2);
                my $theta = $s * 2 * $PI;
                my $lv = $leaf_vals->[$j % $samples];
                my $sway_l = sin($leaf_phase + $s * 5) * $w * 0.02 * 4;

                my $x = $tip_x + cos($theta) * ($leaf_r + $lv) + $sway_l;
                my $y = $tip_y + sin($theta * 0.5) * $leaf_r * 0.3;
                my $z = $tip_z + sin($theta) * ($leaf_r + $lv);

                my $hue = 0.22 + sin($br->{seed} + $s) * 0.08;
                my ($cr,$cg,$cb) = hsv($hue, 0.65, 0.5 + $lv * 3);
                push @verts, $x, $y, $z, $cr, $cg, $cb, 0.5, 1.0 + $lv * 8;
            }
            push @cmds, [$total, $samples/2 + 1];
            $total += $samples/2 + 1;
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
glutCreateWindow('Envelope Thread Tree');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "Thread tree: %d branches, depth 0-4 — ESC to quit\n", scalar @branches;
glutMainLoop();
