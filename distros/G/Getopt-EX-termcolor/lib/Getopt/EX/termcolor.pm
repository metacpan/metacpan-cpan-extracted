=encoding utf-8

=head1 NAME

Getopt::EX::termcolor - Getopt::EX termcolor module

=head1 VERSION

Version 1.07

=head1 SYNOPSIS

    use Getopt::EX::Loader;
    my $rcloader = Getopt::EX::Loader->new(
        BASECLASS => [ 'App::command', 'Getopt::EX' ],
        );

    or

    use Getopt::EX::Long qw(:DEFAULT ExConfigure);
    ExConfigure BASECLASS => [ "App::command", "Getopt::EX" ];

    then

    $ command -Mtermcolor::bg=

=head1 DESCRIPTION

This is a common module for command using L<Getopt::EX> to manipulate
system dependent terminal color.

Actual action is done by sub-module under L<Getopt::EX::termcolor>,
such as L<Getopt::EX::termcolor::Apple_Terminal>.

Each sub-module is expected to have C<&get_color> function which
return the list of RGB values for requested name, but currently name
C<background> is only supported.  Each RGB values are expected in a
range of 0 to 255 by default.  If the list first entry is a HASH
reference, it may include maximum number indication like C<< { max =>
65535 } >>.

Terminal luminance is calculated from RGB values by this equation and
produces decimal value from 0 to 100.

    ( 30 * R + 59 * G + 11 * B ) / MAX

=begin comment

If the environment variable C<TERM_LUMINANCE> is defined, its value is
used as a luminance without calling sub-modules.  The value of
C<TERM_LUMINANCE> is expected in range of 0 to 100.

=end comment

If the environment variable C<TERM_BGCOLOR> is defined, it is used as
a background RGB value without calling sub-modules.  RGB value is a
combination of integer described in 24bit/12bit hex, 24bit decimal or
6x6x6 216 color format.  RGB color notation is compatible with
L<Getopt::EX::Colormap>.

    24bit hex     #000000 .. #FFFFFF
    12bit hex     #000    .. #FFF
    24bit decimal 0,0,0   .. 255,255,255
    6x6x6 216     000     .. 555

You can set C<TERM_BGCOLOR> in you start up file of shell.  This
module has utility function C<bgcolor> which can be used like this:

    export TERM_BGCOLOR=`perl -MGetopt::EX::termcolor=bgcolor -e bgcolor`
    : ${TERM_BGCOLOR:=#FFFFFF}

=head1 MODULE FUNCTION

=over 7

=item B<bg>

Call this function with module option:

    $ command -Mtermcolor::bg=

If the terminal luminance is unknown, nothing happens.  Otherwise, the
module insert B<--light-terminal> or B<--dark-terminal> option
according to the luminance value.

You can change the behavior by optional parameters:

    threshold : threshold of light/dark  (default 50)
    default   : default luminance value  (default none)
    light     : light terminal option    (default "--light-terminal")
    dark      : dark terminal option     (default "--dark-terminal")

Use like this:

    option default \
        -Mtermcolor::bg(default=100,light=--light,dark=--dark)

=back

=head1 SEE ALSO

L<Getopt::EX>

L<Getopt::EX::termcolor::Apple_Terminal>

L<Getopt::EX::termcolor::iTerm>

L<Getopt::EX::termcolor::XTerm>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright (C) 2020 Kazumasa Utashiro.

You can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

use v5.14;
package Getopt::EX::termcolor;

our $VERSION = '1.07';

use warnings;
use Carp;
use Data::Dumper;

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw(rgb_to_luminance rgb_to_brightness luminance bgcolor);

#
# For backward compatibility.
#
sub rgb_to_brightness {
    goto &rgb_to_luminance;
}

sub rgb_to_luminance {
    @_ or return;
    my $opt = ref $_[0] ? shift : {};
    my $max = $opt->{max} || 255;
    my($r, $g, $b) = @_;
    use integer;
    ($r * 30 + $g * 59 + $b * 11) / $max; # 0 .. 100
}

my $mod;
my $argv;

sub initialize {
    ($mod, $argv) = @_;
    set_luminance();
}

our $debug = 0;

sub debug {
    $debug ^= 1;
}

sub call_mod_sub {
    my($mod, $name, @arg) = @_;
    my $call = "$mod\::$name";
    if (eval "require $mod" and defined &$call) {
	no strict 'refs';
	$call->(@arg);
    } else {
	if ($@ !~ /^Can't locate /) {
	    croak $@;
	}
    }
}

sub rgb255 {
    use integer;
    my $opt = ref $_[0] ? shift : {};
    my $max = $opt->{max} // 255;
    map { $_ * 255 / $max } @_;
}

sub get_rgb {
    my $cat = shift;
    my @rgb;
  RGB:
    {
	# TERM=xterm
	if (($ENV{TERM} // '') =~ /^xterm/) {
	    my $mod = __PACKAGE__ . "::XTerm";
	    @rgb = call_mod_sub $mod, 'get_color', $cat;
	    last if @rgb >= 3;
	}
	# TERM_PROGRAM
	if (my $term_program = $ENV{TERM_PROGRAM}) {
	    warn "TERM_PROGRAM=$ENV{TERM_PROGRAM}\n" if $debug;
	    my $submod = $term_program =~ s/\.app$//r;
	    my $mod = __PACKAGE__ . "::$submod";
	    @rgb = call_mod_sub $mod, 'get_color', $cat;
	    last if @rgb >= 3;
	}
	return ();
    }
  GOTCHA:
    rgb255 @rgb;
}

sub set_luminance {
    my $luminance;
    if (defined $ENV{TERM_LUMINANCE}) {
	warn "TERM_LUMINANCE=$ENV{TERM_LUMINANCE}\n" if $debug;
	return;
    }
    if ("BACKWARD COMPATIBILITY") {
	if (defined (my $env = $ENV{BRIGHTNESS})) {
	    warn "BRIGHTNESS=$env\n" if $debug;
	    $ENV{TERM_LUMINANCE} = $env;
	    return;
	}
    }
    if (my $bgcolor = $ENV{TERM_BGCOLOR}) {
	warn "TERM_BGCOLOR=$bgcolor\n" if $debug;
	if (my @rgb = parse_rgb($bgcolor)) {
	    $luminance = rgb_to_luminance @rgb;
	} else {
	    warn "Invalid format: TERM_BGCOLOR=$bgcolor\n";
	}
    } else {
	$luminance = get_luminance();
    }
    $ENV{TERM_LUMINANCE} = $luminance // return;
}

sub get_luminance {
    rgb_to_luminance get_rgb "background";
}

use List::Util qw(pairgrep);

#
# FOR BACKWARD COMPATIBILITY
# DEPELICATED IN THE FUTURE
#
sub set { goto &bg }

my %bg_param = (
    light => "--light-terminal",
    dark  => "--dark-terminal",
    default => undef,
    threshold => 50,
    );

sub bg {
    my %param =
	(%bg_param, pairgrep { exists $bg_param{$a} } @_);
    my $luminance =
	$ENV{TERM_LUMINANCE} // $param{default} // return;
    my $option = $luminance > $param{threshold} ?
	$param{light} : $param{dark}
    or return;

#   $mod->setopt($option => '$<ignore>');
    $mod->setopt(default => $option);
}

sub parse_rgb {
    my $rgb = shift;
    my @rgb = do {
	if    ($rgb =~ /^\#?([\da-f]{2})([\da-f]{2})([\da-f]{2})$/i) {
	    map { hex } $1, $2, $3;
	}
	elsif ($rgb =~ /^\#([\da-f])([\da-f])([\da-f])$/i) {
	    map { 0x11 * hex } $1, $2, $3;
	}
	elsif ($rgb =~ /^([0-5])([0-5])([0-5])$/) {
	    map { 0x33 * int } $1, $2, $3;
	}
	elsif ($rgb =~ /^(\d+),(\d+),(\d+)$/) {
	    map { int } $1, $2, $3;
	}
	else {
	    return ();
	}
    };
    @rgb;
}

sub luminance {
    my $v = get_luminance() // return;
    say $v;
}

sub bgcolor {
    my @rgb = get_rgb "background" or return;
    printf "#%02X%02X%02X\n", @rgb;
}

1;

__DATA__

#  LocalWords:  termcolor RGB
