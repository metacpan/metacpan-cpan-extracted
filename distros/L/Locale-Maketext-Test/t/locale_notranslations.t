use Test::More;
use Test::NoWarnings;
use File::Spec;
use File::Basename;
use Locale::Maketext::Test;

plan tests => 4;

my $handler = Locale::Maketext::Test->new(
    directory => dirname(File::Spec->rel2abs($0)) . '/locales',
    languages => ['pt']);

my $result = $handler->testlocales();

is scalar @{$result->{errors}->{pt}}, 2, 'One error is for missing translation, other for fuzzy';
is $result->{status}, 0, 'Status is 0 as translations is missing';
is scalar keys %{$result->{warnings}}, 0, 'No warnings as no debug flag is set';
