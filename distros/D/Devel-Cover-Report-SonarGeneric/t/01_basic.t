use strict;
use warnings;

use Test::More;
use Path::Tiny qw(path);
use Devel::Cover::DB;

use_ok "Devel::Cover::Report::SonarGeneric";

chdir('t');

my $rfn = path('cover_db/sonar_generic.xml');
$rfn->remove;

ok(! $rfn->exists, 'start fresh');

$ENV{DEVEL_COVER_DB_FORMAT} = 'JSON';

my $db    = Devel::Cover::DB->new(db => 'cover_db');
my @files = sort $db->cover->items;

Devel::Cover::Report::SonarGeneric->report($db, {file => \@files});

ok($rfn->exists, 'report generated');

my $expect = <<'END';
<coverage version="1">
  <file path="lib/lib/archive.pm">
    <lineToCover lineNumber="3" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="4" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="6" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="8" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="9" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="10" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="11" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="103" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="104" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="106" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="108" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="109" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="110" covered="true" branchesToCover="2" coveredBranches="1"/>
    <lineToCover lineNumber="111" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="112" covered="true" branchesToCover="2" coveredBranches="1"/>
    <lineToCover lineNumber="113" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="114" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="115" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="116" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="117" covered="true" branchesToCover="2" coveredBranches="2"/>
    <lineToCover lineNumber="118" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="119" covered="true" branchesToCover="5" coveredBranches="3"/>
    <lineToCover lineNumber="120" covered="true" branchesToCover="5" coveredBranches="3"/>
    <lineToCover lineNumber="121" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="122" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="124" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="125" covered="true" branchesToCover="4" coveredBranches="4"/>
    <lineToCover lineNumber="126" covered="true" branchesToCover="2" coveredBranches="2"/>
    <lineToCover lineNumber="131" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="132" covered="true" branchesToCover="2" coveredBranches="2"/>
    <lineToCover lineNumber="133" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="134" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="135" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="140" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="141" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="142" covered="true" branchesToCover="2" coveredBranches="1"/>
    <lineToCover lineNumber="143" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="144" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="145" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="146" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="148" covered="true" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="153" covered="false" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="155" covered="false" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="156" covered="false" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="158" covered="false" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="160" covered="false" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="161" covered="false" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="163" covered="false" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="165" covered="false" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="166" covered="false" branchesToCover="2" coveredBranches="0"/>
    <lineToCover lineNumber="167" covered="false" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="168" covered="false" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="171" covered="false" branchesToCover="0" coveredBranches="0"/>
    <lineToCover lineNumber="173" covered="false" branchesToCover="0" coveredBranches="0"/>
  </file>
</coverage>
END

is($rfn->slurp, $expect, 'content matches');

done_testing();
