use Devel::DumpTrace::PPI ':test';
use Test::More tests => 12;
use strict;
use warnings;
use vars qw(@r $s %t $u);
no warnings 'redefine';

# test the distinction between ABBREV_STRONG and new ABBREV_SMART

*preval = \&Devel::DumpTrace::PPI::preval;
*Devel::DumpTrace::_abbrev_style = sub { &Devel::DumpTrace::ABBREV_SMART };

@r = (1..100);
%t = (%ENV, 1001 .. 2000);
$s = 7;

my $code1 = q{$r[4*(5+6/3+$s-2*2)]};
my $doc1 = new PPI::Document(\$code1);
my $s1 = $doc1->find('PPI::Statement');
my @z1 = preval($s1->[0], 1, __PACKAGE__);
ok("@z1" =~ /\.\.\.,41,\.\.\./, "smart abbrev of long array")
or diag("\@z1 is \"@z1\"");

$s = '50';
my $code2 = q[$t{'1' . $s . '5'}];
my $doc2 = new PPI::Document(\$code2);
my $s2 = $doc2->find('PPI::Statement');
my @z2 = preval($s2->[0], 1, __PACKAGE__);
ok("@z2" =~ /1505=>1506/, "smart abbrev of long hash");

*Devel::DumpTrace::_abbrev_style = sub { &Devel::DumpTrace::ABBREV_STRONG };

@z1 = preval($s1->[0], 1, __PACKAGE__);
@z2 = preval($s2->[0], 1, __PACKAGE__);
ok("@z1" !~ /\.\.\.,41,\.\.\./, "not smart abbrev of long array");
ok("@z2" !~ /1505=>1506/, "not smart abbrev of long hash");

############################################################

# using smart abbreviations should not have side effects ...

*Devel::DumpTrace::_abbrev_style = sub { &Devel::DumpTrace::ABBREV_SMART };

my $foobar = 13;
sub foo::bar { return $foobar++ }

open $u, '<', $0;
$s = 9;
foreach my $expr ( q{&foo::bar}, q{exp(4.0)}, q{<$u>}, q{$s++} ) {
    my $code3 = '$r[' . $expr . ']';
    my $doc3 = new PPI::Document(\$code3);
    my $s3 = $doc3->find('PPI::Statement');
    my @z31 = preval($s3->[0], 1, __PACKAGE__);
    my @z32 = preval($s3->[0], 1, __PACKAGE__);
    my @z33 = preval($s3->[0], 1, __PACKAGE__);

    # print "@z31\n@z33\n";

    ok("@z31" eq "@z32" && "@z31" eq "@z33",
       "smart abbreviation should not have side effects");
    ok($foobar == 13,
       "smart abbreviation should not have side effects");
}
