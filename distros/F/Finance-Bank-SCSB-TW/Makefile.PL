
use inc::Module::Install;

name 'Finance-Bank-SCSB-TW';
all_from 'lib/Finance/Bank/SCSB/TW.pm';

requires
    'List::MoreUtils'  => 0,
    'WWW::Mechanize'   => '1.50',
    'WWW::Mechanize::Sleepy' => 0,
    'HTML::Selector::XPath' => 0,
    'HTML::TreeBuilder::XPath' => 0;

WriteAll;

