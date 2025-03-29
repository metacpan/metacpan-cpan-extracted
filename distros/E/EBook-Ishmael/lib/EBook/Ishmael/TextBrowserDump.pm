package EBook::Ishmael::TextBrowserDump;
use 5.016;
our $VERSION = '1.04';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(browser_dump);

use List::Util qw(first);

use File::Which;

our $CAN_DUMP = 0;

# From links
my $WIDTH_MAX = 512;
my $WIDTH_MIN = 10;

my @ORDER = qw(
	lynx
	links
	elinks
	w3m
	chawan
	queequeg
);

my %Browsers = (
	'lynx' => {
		Bins  => [ qw(lynx) ],
		Bin   => undef,
		Opts  => [ qw(-dump -force_html -nolist -display_charset=utf8) ],
		Width => '-width %d',
		Xhtml => [ qw(-xhtml_parsing) ],
	},
	'links' => {
		Bins  => [ qw(links links2) ],
		Bin   => undef,
		Opts  => [ qw(-dump -force-htm -codepage utf8) ],
		Width => '-width %d',
		Xhtml => [],
	},
	'elinks' => {
		Bins  => [ qw(elinks) ],
		Bin   => undef,
		Opts  => [ qw(-dump -force-html -no-home -no-references -no-numbering
		              -dump-charset utf8) ],
		Width => '-dump-width %d',
		Xhtml => [],
	},
	'w3m' => {
		Bins  => [ qw(w3m) ],
		Bin   => undef,
		Opts  => [ qw(-dump -T text/html -O utf8) ],
		Width => '-cols %d',
		Xhtml => [],
	},
	'chawan' => {
		Bins  => [ qw(cha) ],
		Bin   => undef,
		Opts  => [ qw(-d -I utf8 -O utf8 -T text/html) ],
		Width => "-o 'display.columns=%d'",
		Xhtml => [],
	},
	'queequeg' => {
		Bins  => [ qw(queequeg) ],
		Bin   => undef,
		Opts  => [ qw(-e utf8) ],
		Width => '-w %d',
		Xhtml => [],
	},
);

my $Default = undef;

for my $k (@ORDER) {

	my $bin = first { which $_ } @{ $Browsers{ $k }->{Bins} };

	next unless defined $bin;

	$Browsers{ $k }->{Bin} = $bin;

	$Default //= $k;

}

$CAN_DUMP = defined $Default;

unless ($CAN_DUMP) {
	warn "No valid text browser was found installed on your system, you " .
	     "will be unable to use any feature requiring a text browser\n";
}

sub browser_dump {

	# Automatically convert qx// input to Perl's internal encoding.
	use open IN => ':crlf :encoding(UTF-8)';

	unless (defined $Default) {
		die "Cannot use browser to dump HTML; no valid browser was found on your system\n";
	}

	my $file  = shift;
	my $param = shift // {};

	my $browser = $param->{browser} // $Default;
	my $xhtml   = $param->{xhtml}   // 0;
	my $width   = $param->{width}   // 80;

	unless (exists $Browsers{ $browser }) {
		die "'$browser' is not a valid browser\n";
	}

	unless (defined $Browsers{ $browser }->{Bin}) {
		die "'$browser' is not installed on your system\n";
	}

	unless ($width >= $WIDTH_MIN and $width <= $WIDTH_MAX) {
		die "Width cannot be greater than $WIDTH_MAX or less than $WIDTH_MIN\n";
	}

	my $cmd = sprintf
		"%s %s %s %s '%s'",
		$Browsers{ $browser }->{Bin},
		sprintf($Browsers{ $browser }->{Width}, $width),
		join(" ", @{ $Browsers{ $browser }->{Opts} }),
		($xhtml ? join(" ", @{ $Browsers{ $browser }->{Xhtml} }) : ''),
		$file;

	my $dump = qx/$cmd/;

	unless ($? >> 8 == 0) {
		die "Failed to dump $file with $Browsers{ $browser }->{Bin}\n";
	}

	return $dump;

}

1;

=head1 NAME

EBook::Ishmael::TextBrowserDump - Format HTML via text web browsers

=head1 SYNOPSIS

  use EBook::Ishmael::TextBrowserDump;

  my $dump = browser_dump($file);

=head1 DESCRIPTION

B<EBook::Ishmael::TextBrowserDump> is a module for dumping the contents of
HTML files to formatted text, via text web browsers like L<lynx(1)>. For
L<ishmael> user documentation, you should consult its manual (this is
developer documentation).

B<EBook::Ishmael::TextBrowserDump> requires at least one of the following
programs to be installed:

=over 4

=item L<elinks(1)>

=item L<links(1)>

=item L<lynx(1)>

=item L<w3m(1)>

=item chawan

=item L<queequeg(1)>

=back

=head1 SUBROUTINES

=head2 $dump = browser_dump($file, $opt_ref)

Subroutine that dumps the formatted text contents of C<$file> via a text
web browser.

C<browser_dump()> can also be given a hash ref of options.

=over 4

=item browser

The specific browser you would like to use for the dumping. See above for a list
of valid browsers. If not specified, defaults to the first browser
C<browser_dump()> finds installed on your system.

=item xhtml

Bool specifying whether the input file is XHTML or not. Defaults to C<0>.

=item width

Specify the width of the formatted text. Defaults to C<80>.

=back

=head1 GLOBAL VARIABLES

=head2 $EBook::Ishmael::TextBrowserDump::CAN_DUMP

Bool stating whether this module is able to dump or not (is a valid
text browser installed or not).

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg Page|https://codeberg.org/1-1sam/ishmael>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<queequeg(1)>, L<elinks(1)>, L<links(1)>, L<lynx(1)>, L<w3m(1)>, L<cha(1)>

=cut
