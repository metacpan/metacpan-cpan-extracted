use Test::More;
use Test::NoWarnings;
use File::Spec;
use File::Basename;
use Locale::Maketext::Test;

plan tests => 4;

my $handler = Locale::Maketext::Test->new(
    directory => dirname(File::Spec->rel2abs($0)) . '/locales',
    languages => ['id']);
my $result = $handler->testlocales();

is $result->{status}, 1, 'locale is correct';
is scalar(keys %{$result->{errors}}),   0, 'no errors found';
is scalar(keys %{$result->{warnings}}), 0, 'no warnings found';
