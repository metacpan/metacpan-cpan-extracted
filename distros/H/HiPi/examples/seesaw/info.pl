#!/usr/bin/perl

use strict;
use warnings;
use HiPi qw( :seesaw );
use HiPi::Interface::Seesaw;

# call with seesaw hex address
# e.g. seesaw/info.pl 0x49

my $seesawaddress = ( $ARGV[0] ) ?  hex($ARGV[0]) : 0x49;

my $dev = HiPi::Interface::Seesaw->new(
    address     => $seesawaddress,
);
print qq(------------------------------\n);
print qq(Seesaw Breakout Info\n);
print qq(------------------------------\n);
print 'Version       : ' . $dev->get_version . qq(\n);
print 'Version Date  : ' . $dev->get_date_code . qq(\n);
print 'Product Code  : ' . $dev->get_product_code . qq(\n);
my $pwmwidth = $dev->get_pwm_width;
print 'PWM Width     : ' . $pwmwidth . qq(\n);
my $hid = $dev->get_hardware_id;
printf(qq(Hardware ID   : 0x%X\n), $hid);
my $opts = $dev->get_options;
printf(qq(Options       : 0x%X\n), $opts);
my $i2c = $dev->get_i2c_address();
printf(qq(EEPROM I2C    : 0x%02X\n), $i2c);
my $optionnames = $dev->get_option_names();
print 'OPTION NAMES  : ' . $optionnames . qq(\n);

1;

__END__

