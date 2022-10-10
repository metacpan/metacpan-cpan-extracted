=pod

=encoding utf-8

=head1 PURPOSE

Test for GitHub issue 8.

=head1 SEE ALSO

L<https://github.com/tobyink/p5-exporter-tiny/issues/8>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
	package Local::Exporter;
	use Exporter::Shiny;
	sub chocolate { 1 }
	sub vanilla   { 2 }
	our %EXPORT_TAGS = ( want => [ qw( chocolate vanilla ) ] );
	our @EXPORT_OK   = map { @$_ } values %EXPORT_TAGS;
};

my %stuff;
my $dump  = sub {
	use Data::Dumper;
	diag Dumper( \%stuff );
};

%stuff = ();
Local::Exporter->import( { into => \%stuff }, qw( -all ) );
is_deeply(
	[ sort keys %stuff ],
	[ 'chocolate', 'vanilla' ],
	'-all',
) or &$dump;

%stuff = ();
Local::Exporter->import( { into => \%stuff }, qw( -all !vanilla ) );
is_deeply(
	[ sort keys %stuff ],
	[ 'chocolate' ],
	'-all !vanilla',
) or &$dump;

%stuff = ();
Local::Exporter->import( { into => \%stuff }, qw( -want ) );
is_deeply(
	[ sort keys %stuff ],
	[ 'chocolate', 'vanilla' ],
	'-want',
) or &$dump;

%stuff = ();
Local::Exporter->import( { into => \%stuff }, qw( -all !-want ) );
is_deeply(
	[ sort keys %stuff ],
	[],
	'-all !-want',
) or &$dump;

%stuff = ();
Local::Exporter->import( { into => \%stuff }, qw( -want !-want ) );
is_deeply(
	[ sort keys %stuff ],
	[],
	'-want !-want',
) or &$dump;
