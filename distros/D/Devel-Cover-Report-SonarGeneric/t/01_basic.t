use strict;
use warnings;

use Test::More;
use Path::Tiny qw(path);

use_ok "Devel::Cover::Report::SonarGeneric";

chdir('t');

my $rfn = "cover_db/sonar_generic.xml";

unlink $rfn if -e $rfn;

ok(! -e $rfn, 'start fresh');

$ENV{DEVEL_COVER_DB_FORMAT} = 'JSON';
system('cover -report SonarGeneric');

ok(-e $rfn, 'report generated');

my $expect = <<'END';
<coverage version="1">
  <file path="lib/lib/archive.pm">
    <lineToCover lineNumber="3" covered="true"/>
    <lineToCover lineNumber="4" covered="true"/>
    <lineToCover lineNumber="6" covered="true"/>
    <lineToCover lineNumber="8" covered="true"/>
    <lineToCover lineNumber="9" covered="true"/>
    <lineToCover lineNumber="10" covered="true"/>
    <lineToCover lineNumber="11" covered="true"/>
    <lineToCover lineNumber="103" covered="true"/>
    <lineToCover lineNumber="104" covered="true"/>
    <lineToCover lineNumber="106" covered="true"/>
    <lineToCover lineNumber="108" covered="true"/>
    <lineToCover lineNumber="109" covered="true"/>
    <lineToCover lineNumber="110" covered="true" branchesToCover="2" coveredBranches="1"/>
    <lineToCover lineNumber="111" covered="true"/>
    <lineToCover lineNumber="112" covered="true" branchesToCover="2" coveredBranches="1"/>
    <lineToCover lineNumber="113" covered="true"/>
    <lineToCover lineNumber="114" covered="true"/>
    <lineToCover lineNumber="115" covered="true"/>
    <lineToCover lineNumber="116" covered="true"/>
    <lineToCover lineNumber="117" covered="true" branchesToCover="2" coveredBranches="2"/>
    <lineToCover lineNumber="118" covered="true"/>
    <lineToCover lineNumber="119" covered="true" branchesToCover="2" coveredBranches="2"/>
    <lineToCover lineNumber="120" covered="true" branchesToCover="2" coveredBranches="2"/>
    <lineToCover lineNumber="121" covered="true"/>
    <lineToCover lineNumber="122" covered="true"/>
    <lineToCover lineNumber="124" covered="true"/>
    <lineToCover lineNumber="125" covered="true" branchesToCover="2" coveredBranches="2"/>
    <lineToCover lineNumber="126" covered="true"/>
    <lineToCover lineNumber="131" covered="true"/>
    <lineToCover lineNumber="132" covered="true" branchesToCover="2" coveredBranches="2"/>
    <lineToCover lineNumber="133" covered="true"/>
    <lineToCover lineNumber="134" covered="true"/>
    <lineToCover lineNumber="135" covered="true"/>
    <lineToCover lineNumber="140" covered="true"/>
    <lineToCover lineNumber="141" covered="true"/>
    <lineToCover lineNumber="142" covered="true" branchesToCover="2" coveredBranches="1"/>
    <lineToCover lineNumber="143" covered="true"/>
    <lineToCover lineNumber="144" covered="true"/>
    <lineToCover lineNumber="145" covered="true"/>
    <lineToCover lineNumber="146" covered="true"/>
    <lineToCover lineNumber="148" covered="true"/>
    <lineToCover lineNumber="153" covered="false"/>
    <lineToCover lineNumber="155" covered="false"/>
    <lineToCover lineNumber="156" covered="false"/>
    <lineToCover lineNumber="158" covered="false"/>
    <lineToCover lineNumber="160" covered="false"/>
    <lineToCover lineNumber="161" covered="false"/>
    <lineToCover lineNumber="163" covered="false"/>
    <lineToCover lineNumber="165" covered="false"/>
    <lineToCover lineNumber="166" covered="false" branchesToCover="2" coveredBranches="0"/>
    <lineToCover lineNumber="167" covered="false"/>
    <lineToCover lineNumber="168" covered="false"/>
    <lineToCover lineNumber="171" covered="false"/>
    <lineToCover lineNumber="173" covered="false"/>
  </file>
</coverage>
END

my $rtxt = path($rfn)->slurp;

is($rtxt, $expect, 'content matches');

done_testing();
