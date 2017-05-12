use 5.008_001;
use strict;
use inc::Module::Install 0.77;

if ( -e 'MANIFEST.SKIP' ) {
    system(
          'perl -Mutf8 -MPod::Simple::Text -e '
        . '"binmode STDOUT, q{:utf8}; Pod::Simple::Text->parse_from_file(@ARGV)" '
        . 'lib/Log/Simple/Color.pm > README' );
}

# Define metadata
name          'Log-Simple-Color';
license       'perl';
author        'Keedi Kim - 김도형 <keedi@cpan.org>';
all_from      'lib/Log/Simple/Color.pm';

# Specific dependencies
perl_version  '5.008_001';
requires      'version'         => 0;
requires      'File::Spec'      => '0.80';
requires      'Module::Install' => '0.77';
requires      'Term::ANSIColor' => '1.12' unless win32;
requires      'Win32::Console'  => '0.09' if win32;
test_requires 'Test::More'      => '0.42';

#homepage       '';
#bugtracker     '';
#repository     '';

WriteAll;
