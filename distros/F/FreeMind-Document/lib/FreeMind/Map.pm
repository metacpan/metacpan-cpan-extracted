package FreeMind::Map;

use 5.010001;
use strict;
use warnings;

BEGIN {
	$FreeMind::Map::AUTHORITY = 'cpan:TOBYINK';
	$FreeMind::Map::VERSION   = '0.002';
}

use XML::LibXML::Augment
	-type  => 'Element',
	-names => ['map'],
;

require FreeMind::Document;

__PACKAGE__->FreeMind::Document::_has(
	version => { required => 1 },
);

1;

__END__

=pod

=encoding utf-8

=head1 NAME

FreeMind::Document - a FreeMind C<< <map> >> XML element

=head1 DESCRIPTION

This is a subclass of L<XML::LibXML::Element> providing the following
attribute accessors:

=over

=item C<< version >>

=back

=head1 SEE ALSO

L<FreeMind::Document>, L<FreeMind::Node>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

