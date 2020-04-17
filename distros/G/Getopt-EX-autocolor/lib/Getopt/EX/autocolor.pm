=encoding utf-8

=head1 NAME

Getopt::EX::autocolor - Getopt::EX autocolor module

=head1 SYNOPSIS

    use Getopt::EX::Loader;
    my $rcloader = new Getopt::EX::Loader
        BASECLASS => [ 'App::command', 'Getopt::EX' ];

    $ command -Mautocolor

=head1 VERSION

Version 0.04

=head1 DESCRIPTION

This is a common module for command using L<Getopt::EX> to set system
dependent autocolor option.

Actual action is done by sub-module under L<Getopt::EX::autocolor>,
such as L<Getopt::EX::autocolor::Apple_Terminal>.

Each sub-module is expected to have C<&brightness> function which
returns integer value between 0 and 100.  If the sub-module was found
and C<&brightness> function exists, its result is taken as a
brightness of the terminal.

However, if the environment variable C<BRIGHTNESS> is defined, its
value is used as a brightness without calling sub-modules.  The value
of C<BRIGHTNESS> is expected in range of 0 to 100.

If the brightness can not be taken, nothing happens.  Otherwise, the
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

For example, use like:

    option default \
        -Mautocolor::set(default=100,light=--light,dark=--dark)

=head1 FUNCTIONS

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

L<Getopt::EX::autocolor::Apple_Terminal>

L<Getopt::EX::autocolor::iTerm>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright (C) 2020 Kazumasa Utashiro.

You can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

package Getopt::EX::autocolor;

use v5.14;
use strict;
use warnings;
use Data::Dumper;

our $VERSION = "0.04";

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw(rgb_to_brightness);

our %param = (
    light => "--light-terminal",
    dark  => "--dark-terminal",
    default => undef,
    threshold => 50,
    );

sub rgb_to_brightness {
    my $opt = ref $_[0] ? shift : {};
    my $max = $opt->{max} || 65535;
    my($r, $g, $b) = @_;
    int(($r * 30 + $g * 59 + $b * 11) / $max); # 0 .. 100
}

sub call(&@) { $_[0]->(@_[1..$#_]) }

sub finalize {
    my $mod = shift;

    # default to do nothing.
    $mod->setopt($param{light} => '$<move(0,0)>');
    $mod->setopt($param{dark}  => '$<move(0,0)>');

    my $brightness = call {
	my $v = $ENV{BRIGHTNESS};
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
    };

    $brightness //= $param{default} // return;

    $mod->setopt(default =>
		 $brightness > $param{threshold}
		 ? $param{light}
		 : $param{dark});
}

use List::Util qw(pairgrep);

sub set {
    my %arg = @_;
    %param = (%param, pairgrep { exists $param{$a} } %arg);
}

1;

__DATA__

#  LocalWords:  autocolor
