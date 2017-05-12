use inc::Module::Install;
name('Jifty-Plugin-OpenID');
all_from('lib/Jifty/Plugin/OpenID.pm');

requires('Jifty');
requires('Net::OpenID::Consumer' => '1.03' );
requires('Cache::FileCache');
# suspend this test on 1.00 will be back in 1.01
#requires('Test::OpenID::Server' );
requires('LWPx::ParanoidAgent');

install_share;

auto_install();
#tests('t/*.t t/*/t/*.t');
tests('t/*.t');

WriteAll;
