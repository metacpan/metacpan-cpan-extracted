#!/usr/bin/perl -w

# $Id: make_readme.PL,v 1.1 2002/12/14 20:08:52 m_ilya Exp $

use strict;

use Pod::Text;

use lib qw(lib);
use HTTP::WebTest::SelfTest;

my($webtest_pm, $readme) = @ARGV;

my $parser = Pod::Text->new(width => 78);

# convert POD to text
$parser->parse_from_file($webtest_pm, $readme);

my $data = read_file($readme);

# kill SYNOPSIS
$data =~ s/\nSYNOPSIS.*?DESCRIPTION/\nDESCRIPTION/s;
# kill everything from EXAMPLE till RESTRICTIONS section
$data =~ s/\nEXAMPLE.*?RESTRICTIONS/\n\nRESTRICTIONS/s;
# kill SEE ALSO section
$data =~ s/\nSEE ALSO.*//s;

write_file($readme, $data);
