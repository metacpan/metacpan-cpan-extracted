#!env perl

use strict;  
use warnings;

use inc::Module::Install;

name "Language-Farnsworth";
all_from       'lib/Language/Farnsworth.pm';
version_from "lib/Language/Farnsworth.pm";
license 'artistic';
recommends 'REST::Google::Translate' => 0;
recommends 'Finance::Currency::Convert::XE' => 0;
#requires 'REST::Google::Translate' => 0;
#requires 'Finance::Currency::Convert::XE' => 0;

requires 'List::MoreUtils' => 0;
requires 'DateTimeX::Easy' => 0;
requires 'DateTime::Format::Flexible' => 0.16;
requires 'DateTime' => 0;
requires 'Math::Pari' => 0;
requires 'enum' => 0;
requires 'Scalar::Util' => 0;
requires 'Encode' => 0;
requires 'Data::Dumper' => 0;
requires 'Carp' => 0;

test_requires 'Test::More' => 0;
test_requires 'Test::Exception' => 0;

WriteAll;
