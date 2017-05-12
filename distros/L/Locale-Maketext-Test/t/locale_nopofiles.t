use Test::More;
use Test::NoWarnings;
use Test::Exception;
use File::Spec;
use File::Basename;
use Locale::Maketext::Test;

plan tests => 2;

my $handler = Locale::Maketext::Test->new(
    directory => dirname(File::Spec->rel2abs($0)) . '/locales',
    languages => ['DE']);

throws_ok {
    $handler->testlocales()
}
qr/Cannot open/, 'No file found error as language parameter provided does not match file structure';
