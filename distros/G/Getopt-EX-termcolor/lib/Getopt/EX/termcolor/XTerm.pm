=head1 NAME

Getopt::EX::termcolor::XTerm

=head1 SYNOPSIS

use Getopt::EX::termcolor::XTerm;

=head1 DESCRIPTION

This is a L<Getopt::EX::termcolor> module for XTerm.

=head1 SEE ALSO

L<Getopt::EX::termcolor>

L<https://www.xfree86.org/current/ctlseqs.html>

=cut

package Getopt::EX::termcolor::XTerm;

use v5.14;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(test);

use Carp;
use Data::Dumper;
use IO::Handle;
use Term::ReadKey;

use Getopt::EX::termcolor;

sub get_colors {
    map {
	my @rgb = get_color($_);
	@rgb ? undef : [ @rgb ];
    } @_;
}

my %alias = qw(
    foreground text_foreground
    background text_background
    );

sub get_color {
    my $res = lc shift;
    $res = $alias{$res} if $alias{$res};
    return color_rgb($res);
}

our $debug = $ENV{DEBUG_GETOPTEX};

use constant {
    CSI => "\e[", # Control Sequence Introducer
    OSC => "\e]", # Operating System Command
};

sub osc_command {
    my($Ps, $Pt) = @_;
    OSC . "$Ps;$Pt" . "\a";
}

use List::Util qw(pairmap);

my @oscPs_map = qw(
    10 text_foreground
    11 text_background
    12 text_cursor
    13 mouse_foreground
    14 mouse_background
    15 Tektronix_foreground
    16 Tektronix_background
    17 highlight_background
    18 Tektronix_cursor
    19 highlight_foreground
    );
my %oscPs = pairmap { $b => $a, lc $b => $a } @oscPs_map;
my @oscPs_names = pairmap { $b } @oscPs_map;

sub uncntrl {
    $_[0] =~ s/([^\040-\176])/sprintf "\\%03o", ord $1/gear;
}

# OSC Set Text Parameter
sub osc_stp {
    my $name = shift;
    my $color = @_ ? shift : '?';
    my $Ps = $oscPs{$name} or croak;
    osc_command $Ps, $color;
}

my $osc_st_re = qr/[\a\x9c]|\e\\/;
my $osc_answer_re = qr/\e\]\d+;(?<answer>[\x08-\x13\x20-\x7d]*)$osc_st_re/;

sub osc_answer {
    @_ or return;
    defined $_[0] or return;
    $_[0] =~ $osc_answer_re and $+{answer};
}

sub ask {
    my $request = shift;
    if ($debug) {
	printf STDERR "[%s] Request: %s\n",
	    __PACKAGE__,
	    uncntrl $request;
    }
    open my $tty, "+<", "/dev/tty" or return;
    ReadMode "cbreak", $tty;
    printflush $tty $request;
    my $timeout = 0.1;
    my $answer = '';
    while (defined (my $key = ReadKey $timeout, $tty)) {
	if (0 and $debug) {
	    printf STDERR "[%s] ReadKey: \"%s\"\n",
		__PACKAGE__,
		$key =~ /\P{Cc}/ ? $key : uncntrl $key;
	}
	$answer .= $key;
	last if $answer =~ /$osc_st_re\z/;
    }
    ReadMode "restore", $tty;
    if ($debug) {
	printf STDERR "[%s] Answer:  %s\n",
	    __PACKAGE__,
	    uncntrl $answer;
    }
    return $answer;
}

use List::Util qw(max);

sub color_rgb {
    my $name = shift;
    my $rgb = osc_answer ask osc_stp $name or return;
    my @rgb = $rgb =~ m{rgb:([\da-f]+)/([\da-f]+)/([\da-f]+)}i or return;
    my $max = (2 ** (length($1) * 4)) - 1;
    my @opt = $max == 255 ? () : ( { max => $max } );
    ( @opt, map { hex } @rgb );
}

do { test() } if __FILE__ eq $0;

sub test {
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse = 1;
    my $max = max map { length } @oscPs_names;
    for my $name (@oscPs_names) {
	my @rgb = color_rgb($name);
	printf "%*s: %s",
	    $max, $name,
	    @rgb ? Dumper(\@rgb)=~s/\n(?!\z)\s*/ /gr : "n/a\n";
    }
}

1;
