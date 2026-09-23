#!/usr/bin/env perl
# Interactive envelope REPL: type commands, see ASCII plots update
#
# Commands:
#   adsr 0.1 0.1 0.7 0.3     create ADSR envelope
#   perc 0.01 0.5             create percussive envelope
#   spline 0,0 0.3,1 0.7,0.3 1,0   create spline from x,y pairs
#   formula <expr>            set morpher formula (e.g. "bounce_out")
#   scale <n>                 scale levels by factor
#   stretch <n>               stretch durations
#   reverse                   reverse envelope
#   invert                    invert (1 - level)
#   quantize <n>              quantize to N steps
#   trim <from> <to>          extract time slice
#   normalize                 normalize to [0,1]
#   loop <n>                  repeat N times
#   info                      show envelope details
#   svg [file]                export SVG
#   help                      show commands
#   quit                      exit
use strict;
use warnings;
use Math::SegmentedEnvelope qw(adsr perc asr env spline morpher_formulas);

$| = 1;
my $e;
my $width = 70;
my $height = 15;

sub plot {
    return unless $e;
    my @vals = $e->table($width);
    my ($min, $max) = ($vals[0], $vals[0]);
    for (@vals) { $min = $_ if $_ < $min; $max = $_ if $_ > $max }
    my $range = $max - $min || 1;

    my @grid;
    for my $y (0 .. $height - 1) { $grid[$y] = [(' ') x $width] }
    for my $x (0 .. $width - 1) {
        my $y = int(($vals[$x] - $min) / $range * ($height - 1) + 0.5);
        $y = 0 if $y < 0; $y = $height - 1 if $y >= $height;
        $grid[$height - 1 - $y][$x] = '*';
    }
    for my $y (0 .. $height - 1) {
        my $level = $min + ($height - 1 - $y) / ($height - 1) * $range;
        printf "%6.2f |%s\n", $level, join('', @{$grid[$y]});
    }
    printf "       +%s\n", '-' x $width;
    printf "        0%s%.2fs\n", ' ' x ($width - 7), $e->duration;
}

sub show_info {
    return print "No envelope loaded.\n" unless $e;
    printf "Segments: %d, Duration: %.4f\n", $e->segments, $e->duration;
    printf "Range: [%.4f, %.4f]\n", $e->min_value, $e->max_value;
    printf "Morpher: %s", $e->morpher_formula // 'default';
    printf " [%s]", $e->morpher_jit_backend if $e->morpher_formula;
    print "\n";
    printf "Flags: morph=%d hold=%d fold=%d wrap_neg=%d\n",
        $e->is_morph, $e->is_hold, $e->is_fold_over, $e->is_wrap_neg;
}

sub show_help {
    print <<'HELP';
Commands:
  adsr A D S R          ADSR envelope (e.g. adsr 0.1 0.1 0.7 0.3)
  perc A D              Percussive (e.g. perc 0.01 0.5)
  asr A S R             Attack-Sustain-Release
  spline x,y x,y ...    Spline through points (e.g. spline 0,0 0.5,1 1,0)
  formula <name|expr>   Set morpher (e.g. formula bounce_out)
  scale|stretch|offset N  Transform
  reverse|invert|normalize  Transform
  quantize N            Snap to N levels
  trim FROM TO          Extract time slice
  loop N                Repeat N times
  map <expr>            Apply Perl expr to levels ($_ is level value)
  info                  Show details
  svg [file]            Export SVG
  morphers              List predefined morpher names
  help                  This help
  quit                  Exit
HELP
}

# Default envelope
$e = adsr(0.1, 0.1, 0.7, 0.3);
print "Envelope REPL (type 'help' for commands)\n\n";
plot();

while (1) {
    print "\nenv> ";
    my $line = <STDIN>;
    last unless defined $line;
    chomp $line;
    $line =~ s/^\s+|\s+$//g;
    next unless length $line;

    my @args = split /\s+/, $line;
    my $cmd = shift @args;

    eval {
        if ($cmd eq 'quit' || $cmd eq 'exit' || $cmd eq 'q') {
            exit 0;
        } elsif ($cmd eq 'help' || $cmd eq '?') {
            show_help();
        } elsif ($cmd eq 'adsr') {
            $e = adsr(map { $_ + 0 } @args);
            plot();
        } elsif ($cmd eq 'perc') {
            $e = perc(map { $_ + 0 } @args);
            plot();
        } elsif ($cmd eq 'asr') {
            $e = asr(map { $_ + 0 } @args);
            plot();
        } elsif ($cmd eq 'spline') {
            my (@t, @v);
            for my $pair (@args) {
                my ($t, $v) = split /,/, $pair;
                push @t, $t + 0;
                push @v, $v + 0;
            }
            $e = spline(\@t, \@v);
            plot();
        } elsif ($cmd eq 'formula') {
            $e->morpher_formula($args[0]);
            plot();
        } elsif ($cmd eq 'scale') {
            $e = $e->scale($args[0] + 0);
            plot();
        } elsif ($cmd eq 'stretch') {
            $e = $e->stretch($args[0] + 0);
            plot();
        } elsif ($cmd eq 'offset') {
            $e = $e->offset($args[0] + 0);
            plot();
        } elsif ($cmd eq 'reverse') {
            $e = $e->reverse;
            plot();
        } elsif ($cmd eq 'invert') {
            $e = $e->invert;
            plot();
        } elsif ($cmd eq 'normalize') {
            $e = $e->normalize;
            plot();
        } elsif ($cmd eq 'quantize') {
            $e = $e->quantize($args[0] + 0);
            plot();
        } elsif ($cmd eq 'trim') {
            $e = $e->trim($args[0] + 0, $args[1] + 0);
            plot();
        } elsif ($cmd eq 'loop') {
            $e = $e->loop($args[0] + 0);
            plot();
        } elsif ($cmd eq 'map') {
            my $expr = join(' ', @args);
            $e = $e->map_levels(eval "sub { local \$_ = \$_[0]; $expr }");
            plot();
        } elsif ($cmd eq 'info') {
            show_info();
        } elsif ($cmd eq 'svg') {
            my $file = $args[0] // 'envelope.svg';
            open my $fh, '>', $file or die "Cannot write $file: $!";
            print $fh $e->to_svg(width => 600, height => 200);
            close $fh;
            print "Wrote $file\n";
        } elsif ($cmd eq 'morphers') {
            my @names = morpher_formulas();
            print join(', ', @names), "\n";
        } else {
            print "Unknown command: $cmd (type 'help')\n";
        }
    };
    if ($@) {
        print "Error: $@";
    }
}
