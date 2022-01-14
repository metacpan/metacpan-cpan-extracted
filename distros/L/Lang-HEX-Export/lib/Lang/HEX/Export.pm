package Lang::HEX::Export;

use strict;
use warnings;
use utf8;
use feature qw(signatures);
no warnings "experimental::signatures";
no warnings "experimental::smartmatch";

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
	arrayElement
	concat
);

our $VERSION = '0.01';

sub arrayElement($element, $array) {
	if( $element ~~ $array ) {
		return 1;
	} else {
		return 0;
	}
}

sub concat($stringOne, $stringTwo) {
	return $stringOne . $stringTwo;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lang::HEX::Export - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Lang::HEX::Export;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Lang::HEX::Export, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

pc, E<lt>pc@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by pc

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
