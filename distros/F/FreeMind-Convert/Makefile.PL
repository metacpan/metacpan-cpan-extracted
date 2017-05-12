use inc::Module::Install;
name 'FreeMind-Convert';
all_from 'lib/FreeMind/Convert.pm';

requires('Class::Accessor') ;
requires('XML::Simple') ;
requires('Jcode') ;
requires('HTML::Entities') ;

install_script('bin/mm2mediawiki.pl') ;
if( $^O eq 'MSWin32' ){
    features(
        'using Script for Windows' => [
            -default => 0,
            recommends('Win32::Clipboard'),
        ],
    );
}

build_requires 'Test::More';
use_test_base;
auto_include;
auto_install;
WriteAll;
