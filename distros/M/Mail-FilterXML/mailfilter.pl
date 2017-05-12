#!/usr/bin/perl
use FilterXML;

my $filter = new Mail::FilterXML(rules => "mail_rules.xml");

$filter->process();


