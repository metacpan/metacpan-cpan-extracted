use inc::Module::Install;

name 'Devel-ebug-HTTP';
all_from 'lib/Devel/ebug/HTTP.pm';

requires Catalyst => '5.64';
requires Test::WWW::Mechanize::Catalyst => 0;
requires Catalyst::Plugin::Static => 0;
requires Catalyst::View::TT => 0;
requires Devel::ebug => "0.45";
requires HTML::Prototype => 0;
requires Path::Class => 0;
requires PPI => "1.110";
requires PPI::HTML => 0;

if ($^O !~ /mswin32/i) {
  requires Test::Expect => 0;
}

catalyst;

install_script glob('ebug_http');
auto_install;
WriteAll;
