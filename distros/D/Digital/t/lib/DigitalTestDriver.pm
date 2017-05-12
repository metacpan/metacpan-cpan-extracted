package DigitalTestDriver;

use Digital::Driver;

to K => sub { ( ( $_ * 4.88 ) - 25 ) / 10 };

to C => sub { $_ - 273.15 }, 'K';

to F => sub { ( $_ * ( 9 / 5 ) ) - 459.67 }, 'K';

1;
