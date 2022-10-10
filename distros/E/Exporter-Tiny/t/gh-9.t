=pod

=encoding utf-8

=head1 PURPOSE

Test for GitHub issue 9.

=head1 SEE ALSO

L<https://github.com/tobyink/p5-exporter-tiny/issues/9>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
	package Local::Exporter;
	use Exporter::Shiny qw( FLAVORS @FLAVORS %FLAVORS );
	sub FLAVORS    { 'CHOCOLATE', 'VANILLA' }
	our @FLAVORS = ( 'chocolate', 'vanilla' );
	our %FLAVORS = ( 1 => 'chocolate', 2 => 'vanilla' );
};

our ( @FLAVORS, %FLAVORS );
use Local::Exporter -all;

is_deeply( [ FLAVORS() ], [ qw(   CHOCOLATE   VANILLA ) ] );
is_deeply( \@FLAVORS,     [ qw(   chocolate   vanilla ) ] );
is_deeply( \%FLAVORS,     { qw( 1 chocolate 2 vanilla ) } );
