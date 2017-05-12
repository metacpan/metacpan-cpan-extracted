use strict;
use warnings;
use Locale::Maketext::From::Strings;
use Test::More;

plan skip_all => 'Cannot read t/i18n/en.strings' unless -r 't/i18n/en.strings';

system 'rm -r t/out' if -d 't/out';

my $strings = Locale::Maketext::From::Strings->new(path => 't/i18n', namespace => 'MyApp::I18N', out_dir => 't/out');

is $strings->namespace, 'MyApp::I18N', 'namespace()';
is $strings->out_dir, 't/out', 'out_dir()';
is $strings->path, 't/i18n', 'path()';
is $strings->_namespace_dir, 'MyApp/I18N', '_namespace_dir()';

$strings->generate;

ok -e 't/out/MyApp/I18N.pm', 'generate t/out/MyApp/I18N.pm';
ok -e 't/out/MyApp/I18N/en.pm', 'generate t/out/MyApp/I18N/en.pm';

unshift @INC, 't/out';
require MyApp::I18N;
require MyApp::I18N::en;

no warnings 'once';

isa_ok 'MyApp::I18N', 'Locale::Maketext';
isa_ok 'MyApp::I18N::en', 'MyApp::I18N';

is_deeply(
  \%MyApp::I18N::LANGUAGES,
  { en => 'MyApp::I18N::en' },
  'LANGUAGES defined'
);

is_deeply(
  [sort keys %MyApp::I18N::en::Lexicon],
  [qw( hello_user sprintf visit_count welcome_message )],
  'MyApp::I18N::en::Lexicon',
);



done_testing;
