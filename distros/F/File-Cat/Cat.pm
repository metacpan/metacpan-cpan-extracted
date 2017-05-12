package File::Cat;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw( &cat &cattail	);

$VERSION = '1.2';



=head1 NAME

File::Cat - Perl implementation of cat(1)

=head1 SYNOPSIS

  use File::Cat;

  cat ('/etc/motd', \*STDOUT)
	or die "Can't cat /etc/motd: $!";

=head1 DESCRIPTION

File::Cat is a module of adventure, danger, and low cunning. With it, you
will explore some of the most inane programs ever seen by mortals. No
computer should be without one!

=head1 FUNCTIONS

=over

=item *

cat I<EXPR>, I<FILEHANDLE>

Copies data from EXPR to FILEHANDLE, or returns false if an error occurred.
EXPR can be either an open readable filehandle or a filename to use as input.

=cut



sub cat ($$) {
	my ($input, $handle) = @_;

	unless (ref \$input eq 'GLOB' or ref \$input eq 'REF') {
		open FILE, $input or return;
	}
	while (<FILE>) {
		print $handle $_;
	}
	close FILE;
	
	return (1);
}



=pod

=item *

cattail I<EXPR>, I<FILEHANDLE>

Prints EXPR to FILEHANDLE -- backwards, line by line -- or returns
false if an error occurred. Again, EXPR can be either a filehandle
or a filename.

=cut



sub cattail ($$) {
	my ($input, $handle) = @_;
	my @lines = (0);

    unless (ref \$input eq 'GLOB' or ref \$input eq 'REF') {
		open FILE, $input or return;
	}

	while (<FILE>) {
		$lines[$.] = tell FILE;
	}

	pop @lines;
	while (defined ($_ = pop @lines)) {
		seek FILE, $_, 0;
		print $handle scalar(<FILE>);
	}
	close FILE;

	return (1);
}



=pod

=back

=head1 AUTHOR

Dennis Taylor, E<lt>corbeau@execpc.comE<gt>

=head1 APOLOGIES TO...

Marc Blank.

=head1 SEE ALSO

cat(1)

=cut
