package ReturnsOk;

# returns_ok() for the tests.  Uses Test::Returns when it is installed.  That
# module needs Perl 5.26 or later, so on older Perls a small stand-in checks
# the few schema keys these tests use (type, min, optional).

use strict;
use warnings;

use Exporter 'import';
use Test::Builder;

our @EXPORT = ('returns_ok');

my $HAVE_TEST_RETURNS = eval { require Test::Returns; 1 };

sub returns_ok {
	my ( $value, $schema, $name ) = @_;

	if ($HAVE_TEST_RETURNS) {
		local $Test::Builder::Level = $Test::Builder::Level + 1;
		return Test::Returns::returns_ok( $value, $schema, $name );
	}

	my %check = (
		string   => sub { defined $_[0] && !ref $_[0] },
		arrayref => sub { ref $_[0] eq 'ARRAY' },
	);
	my $good;
	if ( !defined $value && $schema->{optional} ) {
		$good = 1;
	} else {
		$good = ( $check{ $schema->{type} } || sub { 1 } )->($value);
		$good &&= @{$value} >= $schema->{min} if $good && defined $schema->{min} && ref $value eq 'ARRAY';
	}
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	return Test::Builder->new->ok( $good, $name );
}

1;
