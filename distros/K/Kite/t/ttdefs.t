#!/usr/bin/perl -w

use strict;
use lib qw( ./lib ../lib);
use Kite::PScript::Defs;

eval "use Template";
if ($@) {
    print "1..0\n";
    exit;
}

print "1..1\n";

my $tt2  = Template->new();
my $vars = {
    psdefs => bless({ }, 'Kite::PScript::Defs'),
};

my $str;
$tt2->process(\*DATA, $vars, \$str)
    || die $tt2->error();

print $str =~ m[/mm { 72 mul 25.4 div } bind def]
	? "ok 1\n" : "not ok 1\n";


__END__
[% psdefs.mm %]
