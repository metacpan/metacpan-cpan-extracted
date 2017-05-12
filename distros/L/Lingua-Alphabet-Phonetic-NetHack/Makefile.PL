
use lib '.';

use inc::Module::Install;

all_from('lib/Lingua/Alphabet/Phonetic/NetHack.pm');
requires( perl => '5.004' );

requires('Lingua::Alphabet::Phonetic');
test_requires('Test::More');
test_requires('Test::Pod');
test_requires('Test::Pod::Coverage');
# I think there's a bug in Module::CoreList or something, because this
# comes up missing on some platforms:
test_requires('Test::Simple');

WriteAll;

__END__
