#-*- perl -*-

use lib '.';
use inc::Module::Install;

# Define metadata
all_from 'lib/MIME/Charset.pm';
license 'perl';
check_nmake;

# Specific dependencies
configure_requires 'CPAN' => 0; # for inc::Module::AutoInstall
test_requires 'Test::More' => '0';
if ( $] >= 5.007003 ) {
    requires 'Encode' => '1.98';
    include 'Module::AutoInstall';
    feature 'Extended mappings by Japanese codepages',
      -default          => 0,
      'Encode::EUCJPASCII' => '0.02';
    feature 'Additional mappings for JIS X 0213',
      -default        => 0,
      'Encode::JISX0213' => '0.03';
    feature 'Additional mappings for Chinese standards',
      -default           => 0,
      'Encode::HanExtra' => '0.20';
    feature 'Additional mappings for rarely used old standards',
      -default           => 0,
      'Encode::DIN66003' => '0.01';
    feature 'Support for POD2 - translations of Perl documentation',
      -default           => 0,
      'POD2::Base'       => '0.041';
}

# Write out
no_index directory => 't', 'inc';
auto_install force => 0, do_once => 1;
WriteAll;

