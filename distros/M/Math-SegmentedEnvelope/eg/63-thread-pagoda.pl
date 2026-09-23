#!/usr/bin/env perl
# Thread pagoda: tiered tower with upswept eaves, built from envelope threads
# Each tier has: floor ring, roof ring with curved overhang, vertical pillars,
# and decorative hanging threads from eave tips
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

my $W = 900;
my $H = 750;
my $PI = 3.14159265358979323846;
my $samples = 80;

my $tiers = 5;
my $pillars_per_tier = 8;
my $base_radius = 1.2;
my $tier_height = 0.35;
my $radius_shrink = 0.82;  # each tier is this fraction of the one below

# Eave profile: the upswept curve of each roof
my $eave = spline([0, 0.3, 0.7, 0.9, 1.0],
                  [0, -0.02, -0.01, 0.06, 0.15]);
my $eave_s = $eave->static;
my $eave_d = $eave->duration;

# Pillar curve: slight bulge (entasis)
my $pillar = env([[1.0, 1.08, 1.05, 1.0], [0.3, 0.4, 0.3], [2, -1, -2]],
    morpher_formula => 'smoothstep');
my $pillar_s = $pillar->static;
my $pillar_d = $pillar->duration;

# Hanging thread displacement
my $hang = env([[0, 0.06, 0.03, 0.05, 0.02],
                [0.2, 0.3, 0.3, 0.2], [2, -2, 2, -1]],
    morpher_formula => 'sine');
my $hang_vals = [$hang->table($samples)];

# Wind sway
my $wind = env([[0.2, 0.6, 0.3, 0.5, 0.2], [0.3, 0.2, 0.3, 0.2], [2, -2, 2, -2]],
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
    float sheen=exp(-d*d*5.0)*0.15;
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

    glClearColor(0.03, 0.02, 0.06, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram($prog);

    my $cam_a = $t * 0.15;
    my $total_h = $tiers * $tier_height + 0.5;
    my @proj = mat4_perspective(50, $W/$H, 0.01, 20);
    my @view = mat4_lookat(
        cos($cam_a)*3.5, $total_h * 0.6 + sin($t*0.1)*0.3, sin($cam_a)*3.5,
        0, $total_h * 0.35, 0,
        0, 1, 0);
    my @mvp = mat4_mult(\@proj, \@view);
    my $m = OpenGL::Array->new_list(GL_FLOAT, @mvp);
    glUniformMatrix4fv_c($u_mvp, 1, GL_FALSE, $m->ptr);
    glUniform2f($u_resolution, $W, $H);

    my @verts;
    my @cmds;
    my $total = 0;
    my $tid = 0;

    for my $tier (0 .. $tiers - 1) {
        my $r = $base_radius * ($radius_shrink ** $tier);
        my $y_base = $tier * $tier_height;
        my $y_top  = $y_base + $tier_height;
        my $roof_overhang = $r * 0.3;
        my $hue = $tier / $tiers * 0.15 + 0.0;  # warm red-gold palette

        # Floor ring
        for my $j (0 .. $samples) {
            my $s = $j / $samples;
            my $theta = $s * 2 * $PI;
            my $x = cos($theta) * $r;
            my $z = sin($theta) * $r;
            my ($cr,$cg,$cb) = hsv($hue + 0.05, 0.5, 0.4);
            push @verts, $x, $y_base, $z, $cr, $cg, $cb, 0.6, 3.0;
        }
        push @cmds, [$total, $samples+1]; $total += $samples+1;

        # Roof ring with upswept eave profile
        my $roof_r = $r + $roof_overhang;
        for my $j (0 .. $samples) {
            my $s = $j / $samples;
            my $theta = $s * 2 * $PI;
            my $eave_lift = $eave_s->($s * $eave_d) * $tier_height * 0.8;

            # Wind sway: more at top tiers
            my $sway = sin($theta * 2 + $t * 1.5) * $w * 0.03 * ($tier + 1);
            my $rr = $roof_r + sin($theta * $pillars_per_tier) * $roof_overhang * 0.15;

            my $x = cos($theta) * $rr + $sway * cos($theta + $PI/2);
            my $y = $y_top + $eave_lift;
            my $z = sin($theta) * $rr + $sway * sin($theta + $PI/2);

            my ($cr,$cg,$cb) = hsv($hue + 0.02 + $eave_lift * 2, 0.6, 0.55 + $eave_lift * 2);
            push @verts, $x, $y, $z, $cr, $cg, $cb, 0.75, 3.5 + $eave_lift * 10;
        }
        push @cmds, [$total, $samples+1]; $total += $samples+1;

        # Pillars with entasis
        for my $pi (0 .. $pillars_per_tier - 1) {
            my $theta = $pi / $pillars_per_tier * 2 * $PI;
            my $phase = $t * 0.4 + $pi + $tier;

            for my $j (0 .. $samples) {
                my $s = $j / $samples;
                my $bulge = ($pillar_s->($s * $pillar_d) - 1.0) * $r * 0.08;
                my $pr = $r + $bulge;
                my $sway_y = sin($phase + $s * 3) * $w * 0.01 * ($tier + 1);

                my $x = cos($theta) * $pr + $sway_y * 0.5;
                my $y = $y_base + $s * $tier_height;
                my $z = sin($theta) * $pr;

                my ($cr,$cg,$cb) = hsv($hue + 0.1, 0.4, 0.5 + $bulge * 5);
                push @verts, $x, $y, $z, $cr, $cg, $cb, 0.65, 2.0 + abs($bulge) * 20;
            }
            push @cmds, [$total, $samples+1]; $total += $samples+1;
        }

        # Hanging threads from eave corners
        for my $pi (0 .. $pillars_per_tier - 1) {
            my $theta = ($pi + 0.5) / $pillars_per_tier * 2 * $PI;
            my $hang_len = $tier_height * 0.4;
            my $eave_tip_r = $roof_r + $roof_overhang * 0.1;
            my $eave_tip_y = $y_top + $eave_s->($eave_d) * $tier_height * 0.8;
            my $phase = $t * 0.8 + $pi * 1.3 + $tier * 2;

            for my $j (0 .. $samples / 2) {
                my $s = $j / ($samples / 2);
                my $hv = $hang_vals->[$j % $samples];
                my $swing = sin($phase + $s * 4) * $w * 0.02 * ($tier + 1);

                my $x = cos($theta) * ($eave_tip_r + $hv * 0.5) + $swing;
                my $y = $eave_tip_y - $s * $hang_len;
                my $z = sin($theta) * ($eave_tip_r + $hv * 0.5);

                my ($cr,$cg,$cb) = hsv($hue + 0.3 + $s * 0.1, 0.7, 0.6 - $s * 0.2);
                my $alpha = 0.6 * (1 - $s * 0.5);
                push @verts, $x, $y, $z, $cr, $cg, $cb, $alpha, 1.5 + $hv * 8;
            }
            push @cmds, [$total, $samples/2 + 1]; $total += $samples/2 + 1;
        }
    }

    # Spire on top
    my $spire_base_y = $tiers * $tier_height;
    my $spire_r = $base_radius * ($radius_shrink ** $tiers) * 0.15;
    my $spire_h = $tier_height * 1.5;
    for my $j (0 .. $samples) {
        my $s = $j / $samples;
        my $y = $spire_base_y + $s * $spire_h;
        my $sr = $spire_r * (1 - $s * 0.95);
        my $theta = $s * $PI * 4 + $t * 0.5;  # spiral spire
        my $x = cos($theta) * $sr;
        my $z = sin($theta) * $sr;
        my ($cr,$cg,$cb) = hsv(0.12 + $s * 0.05, 0.7, 0.7 + $s * 0.3);
        push @verts, $x, $y, $z, $cr, $cg, $cb, 0.9, 2.0 + (1-$s) * 4;
    }
    push @cmds, [$total, $samples+1]; $total += $samples+1;

    # Upload and draw
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
glutCreateWindow('Envelope Thread Pagoda');
init_gl();
glutDisplayFunc(\&display);
glutIdleFunc(\&idle);
glutKeyboardFunc(\&keyboard);

printf "Thread pagoda: %d tiers, %d pillars/tier, spline eaves — ESC to quit\n",
    $tiers, $pillars_per_tier;
glutMainLoop();
