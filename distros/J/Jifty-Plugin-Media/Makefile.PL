use inc::Module::Install;
name('Jifty-Plugin-Media');
all_from('lib/Jifty/Plugin/Media.pm');
requires('Jifty' => '0.91117');
requires('File::Path');
requires('File::Basename');
requires('Text::Unaccent');

resources repository => 'git@github.com:yvesago/jifty-plugin-media.git';

install_share;

tests('t/*.t t/*/t/*.t');

WriteAll;
