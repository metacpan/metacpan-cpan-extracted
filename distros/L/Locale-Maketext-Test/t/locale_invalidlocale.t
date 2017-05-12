use Test::More;
use Test::NoWarnings;
use File::Spec;
use File::Basename;
use Locale::Maketext::Test;

plan tests => 6;

my $handler = Locale::Maketext::Test->new(directory => dirname(File::Spec->rel2abs($0)) . '/locales');
my $result = $handler->testlocales();

is scalar(keys %{$result->{errors}}), 2, 'found errors as locales files have issues';
is $result->{status}, 0, 'status is 0 as there are errors';

is @{$result->{errors}->{ru}}[0], '(line=26): %plural() requires 3 parameters for this language (provided: 2)', 'correct error message';
is scalar @{$result->{errors}->{pt}}, 2, 'correct number of error message for pt file';

is scalar(keys %{$result->{warnings}}), 0, 'no warnings found';
