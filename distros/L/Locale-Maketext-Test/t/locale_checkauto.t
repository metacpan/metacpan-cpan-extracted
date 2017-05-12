use Test::More;
use Test::NoWarnings;
use File::Spec;
use File::Basename;
use Locale::Maketext::Test;

plan tests => 3;

my $handler = Locale::Maketext::Test->new(
    directory => dirname(File::Spec->rel2abs($0)) . '/locales',
    languages => ['pt'],
    auto      => 1
);

my $result = $handler->testlocales();

is scalar keys %{$result->{errors}}, 0, 'No error as auto flag is set, so it will skip untranslated/fuzzy strings';
is $result->{status}, 1, 'Status is 1 as there are no errors';

