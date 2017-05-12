use inc::Module::Install;
name('Jifty-Plugin-Chart');
all_from('lib/Jifty/Plugin/Chart.pm');

requires('Jifty' => '0.90409');
recommends('Chart::Base');
recommends('GD');          # for a testing hack
recommends('GD::Graph');
recommends('XML::Simple');
recommends('Image::Info'); # for testing

auto_install();
tests(qw( t/*/t/*.t ));

install_share;

WriteAll;
