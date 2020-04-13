=encoding utf-8

=head1 NAME

Getopt::EX::autocolor - Getopt::EX autocolor module

=head1 SYNOPSIS

    use Getopt::EX::Loader;
    my $rcloader = new Getopt::EX::Loader
        BASECLASS => [ 'App::command', 'Getopt::EX' ];

    $ command -Mautocolor

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

This is a common module for command using L<Getopt::EX> to set system
dependent autocolor option.

Each module is expected to set B<--light-terminal> or
B<--dark-terminal> option according to the brightness of a terminal
program.

If the environment variable C<BRIGHTNESS> is defined, its value is
used as a brightness without calling submodules.  The value of
C<BRIGHTNESS> is expected in range of 0 to 100.

=head1 SEE ALSO

L<Getopt::EX>

L<Getopt::EX::autocolor::Apple_Terminal>

L<Getopt::EX::autocolor::iTerm2>

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

our $VERSION = "0.01";

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw(rgb_to_brightness);

our %opt = (
    light => "--light-terminal",
    dark  => "--dark-terminal",
    threshold => 50,
    );

sub rgb_to_brightness {
    my($r, $g, $b) = @_;
    int(($r * 30 + $g * 59 + $b * 11) / 65535); # 0 .. 100
}

my %TERM_PROGRAM = qw(
    Apple_Terminal	Apple_Terminal
    iTerm.app		iTerm
    );

sub initialize {
    my $mod = shift;

    # default to do nothing.
    $mod->setopt($opt{light} => '$<move(0,0)>');
    $mod->setopt($opt{dark}  => '$<move(0,0)>');

    if ((my $brightness = $ENV{BRIGHTNESS} // '') =~ /^\d+$/) {
	$mod->setopt(default =>
		     $brightness > $opt{threshold}
		     ? $opt{light}
		     : $opt{dark});
    }
    elsif (my $term_program = $ENV{TERM_PROGRAM}) {

	if (defined (my $module = $TERM_PROGRAM{$term_program})) {
	    $mod->setopt(default => "-Mautocolor::${module}");
	}

    }
}

1;

__DATA__
