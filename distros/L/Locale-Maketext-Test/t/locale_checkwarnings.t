use Test::More;
use Test::NoWarnings;
use File::Spec;
use File::Basename;
use Locale::Maketext::Test;

plan tests => 3;

my $handler = Locale::Maketext::Test->new(
    directory => dirname(File::Spec->rel2abs($0)) . '/locales',
    languages => ['pt'],
    debug     => 1
);

my $result = $handler->testlocales();

is scalar @{$result->{warnings}->{pt}}, 2, 'Got warnings as parameters are not properly used';
is $result->{status}, 0, 'Status is 0 as debug flag is set and it has warnings';

