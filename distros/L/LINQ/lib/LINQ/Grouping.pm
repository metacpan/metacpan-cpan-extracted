use 5.006;
use strict;
use warnings;

if ( $] < 5.010000 ) {
	require UNIVERSAL::DOES;
}

package LINQ::Grouping;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Class::Tiny qw( key values );

1;

__END__

=pod

=encoding utf-8

=head1 NAME

LINQ::Grouping - results of group_by

=head1 DESCRIPTION

The C<group_by> method of L<LINQ::Collection> returns LINQ::Grouping objects.
Please see the documntation in that interface.

=begin trustme

=item key

=item values

=end trustme

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=LINQ>.

=head1 SEE ALSO

L<LINQ::Collection>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
