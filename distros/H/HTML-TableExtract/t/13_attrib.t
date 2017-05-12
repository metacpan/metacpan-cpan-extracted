#!/usr/bin/perl

use strict;
use lib './lib';
use Test::More tests => 556;

use FindBin;
use lib $FindBin::RealBin;
use testload;

my $file = "$Dat_Dir/basic.html";

use HTML::TableExtract;

my($label, $te, @tables);

# By border
$label = 'by attribute (regular)';
$te = HTML::TableExtract->new( attribs => { border => 1 } );
ok($te->parse_file($file), "$label (parse_file)");
@tables = $te->tables;
cmp_ok(@tables, '==', 3, "$label (extract count)");
good_data($_, "$label (data)") foreach @tables;

# By cellpadding
$label = 'by attribute (subset)';
$te = HTML::TableExtract->new( attribs => { cellpadding => 1 } );
ok($te->parse_file($file), "$label (parse_file)");
@tables = $te->tables;
cmp_ok(@tables, '==', 1, "$label (extract count)");
good_data($_, "$label (data)") foreach @tables;

# By cellpadding existence
$label = 'by attribute (undef)';
$te = HTML::TableExtract->new( attribs => { cellpadding => undef } );
ok($te->parse_file($file), "$label (parse_file)");
@tables = $te->tables;
cmp_ok(@tables, '==', 1, "$label (extract count)");
good_data($_, "$label (data)") foreach @tables;
