use utf8;
use open qw( :encoding(UTF-8) :std );
use English;
use Test::Most tests => 4;

BEGIN {
    use_ok 'Geo::Region';
    use_ok 'Geo::Region::Constant';
}

diag join ', ' => (
    "Geo::Region v$Geo::Region::VERSION",
    "Moo v$Moo::VERSION",
    "Perl $PERL_VERSION ($EXECUTABLE_NAME)",
);

my $obj = new_ok 'Geo::Region';
can_ok $obj, qw( contains is_within countries );
