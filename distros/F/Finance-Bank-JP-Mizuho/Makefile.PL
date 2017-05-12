use strict;
use warnings;
use inc::Module::Install;

name          'Finance-Bank-JP-Mizuho';
all_from      'lib/Finance/Bank/JP/Mizuho.pm';
readme_from   'lib/Finance/Bank/JP/Mizuho.pm';
readme_markdown_from 'lib/Finance/Bank/JP/Mizuho.pm';

requires      'Carp';
requires      'DateTime';
requires      'Encode';
requires      'Finance::OFX::Parse::Simple';
requires      'HTTP::Cookies';
requires      'IO::Socket::SSL';
requires      'LWP::UserAgent';

test_requires 'Config::Pit';
test_requires 'FindBin';
test_requires 'Test::More';

resources( repository => 'http://github.com/ngs/p5-finance-bank-jp-mizuho' );

WriteAll;