=encoding utf-8

=head1 NAME

Getopt::EX::termcolor - Getopt::EX termcolor module

=head1 SYNOPSIS

    use Getopt::EX::Loader;
    my $rcloader = new Getopt::EX::Loader
        BASECLASS => [ 'App::command', 'Getopt::EX' ];

    or

    use Getopt::EX::Long qw(:DEFAULT ExConfigure);
    ExConfigure BASECLASS => [ "App::command", "Getopt::EX" ];

    then

    $ command -Mtermcolor::bg=

=head1 VERSION

Version 1.02

=head1 DESCRIPTION

This is a common module for command using L<Getopt::EX> to manipulate
system dependent terminal color.

Actual action is done by sub-module under L<Getopt::EX::termcolor>,
such as L<Getopt::EX::termcolor::Apple_Terminal>.

At this point, only terminal background color is supported.  Each
sub-module is expected to have C<&brightness> function which returns
integer value between 0 and 100.  If the sub-module was found and
C<&brightness> function exists, its result is taken as a brightness of
the terminal.

However, if the environment variable C<TERM_BRIGHTNESS> is defined,
its value is used as a brightness without calling sub-modules.  The
value of C<TERM_BRIGHTNESS> is expected in range of 0 to 100.

=head1 MODULE FUNCTION

=over 7

=item B<bg>

Call this function with module option:

    $ command -Mtermcolor::bg=

If the terminal brightness is unkown, nothing happens.  Otherwise, the
module insert B<--light-terminal> or B<--dark-terminal> option
according to the brightness value.  These options are defined as
C$<move(0,0)> in this module and do nothing.  They can be overridden
by other module or user definition.

You can change the behavior of this module by calling C<&set> function
with module option.  It takes some parameters and they override
default values.

    threshold : threshold of light/dark  (default 50)
    default   : default brightness value (default none)
    light     : light terminal option    (default "--light-terminal")
    dark      : dark terminal option     (default "--dark-terminal")

Use like this:

    option default \
        -Mtermcolor::bg(default=100,light=--light,dark=--dark)

=back

=head1 UTILITY FUNCTION

=over 7

=item B<rgb_to_brightness>

This exportable function caliculates brightness (luminane) from RGB
values.  It accepts three parameters of 0 to 65535 integer.

Maximum value can be specified by optional hash argument.

    rgb_to_brightness( { max => 255 }, 255, 255, 255);

Brightness is caliculated from RGB values by this equation.

    Y = 0.30 * R + 0.59 * G + 0.11 * B

=back

=head1 SEE ALSO

L<Getopt::EX>

L<Getopt::EX::termcolor::Apple_Terminal>

L<Getopt::EX::termcolor::iTerm>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright (C) 2020 Kazumasa Utashiro.

You can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

package Getopt::EX::termcolor;

use v5.14;
use strict;
use warnings;
use Data::Dumper;

our $VERSION = "1.02";

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw(rgb_to_brightness);

sub rgb_to_brightness {
    my $opt = ref $_[0] ? shift : {};
    my $max = $opt->{max} || 65535;
    my($r, $g, $b) = @_;
    int(($r * 30 + $g * 59 + $b * 11) / $max); # 0 .. 100
}

my $mod;
my $argv;

sub initialize {
    ($mod, $argv) = @_;
    set_brightness();
}

sub set_brightness {
    if (defined $ENV{TERM_BRIGHTNESS}) { return }
    if (defined $ENV{BRIGHTNESS}) {
	$ENV{TERM_BRIGHTNESS} = $ENV{BRIGHTNESS};
	return;
    }
    my $brightness = sub {
	my $v = $ENV{TERM_BRIGHTNESS} // $ENV{BRIGHTNESS};
	if (defined $v && $v =~ /^\d+$/
	    && 0 <= $v && $v <= 100
	    ) {
	    return $v;
	}
	if (my $term_program = $ENV{TERM_PROGRAM}) {
	    my $submod = $term_program =~ s/\.app$//r;
	    my $mod = __PACKAGE__ . "::$submod";
	    my $brightness = "$mod\::brightness";
	    no strict 'refs';
	    if (eval "require $mod" and defined &$brightness) {
		my $v = &$brightness;
		if (0 <= $v and $v <= 100) {
		    return $v;
		}
	    }
	}
	undef;
    }->();
    $ENV{TERM_BRIGHTNESS} = $brightness // return;
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
    my %arg = @_;
    %bg_param = (%bg_param,
		 pairgrep { exists $bg_param{$a} } %arg);

    (my $brightness = $ENV{TERM_BRIGHTNESS})
	//= $bg_param{default} // return;

    # default to do nothing.
    $mod->setopt($bg_param{light} => '$<move(0,0)>');
    $mod->setopt($bg_param{dark}  => '$<move(0,0)>');

    $mod->setopt(default =>
		 $brightness > $bg_param{threshold}
		 ? $bg_param{light}
		 : $bg_param{dark});
}

1;

__DATA__

#  LocalWords:  termcolor
