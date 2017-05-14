# NO WARRANTY! Copyright(C) 1998 Tuomas J. Lukka. 
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution, EXCEPT on the files                 
# which belong under the mozilla public license.                                
                                                                                
use blib;
require 'VRML/JS.pm';

package VRML::JS;
my $t = {};
my $t2 = {};

VRML::JS::init();
my $cx,$glo;
my $cx2,$glo2;
$cx = VRML::JS::newcontext($glo,$t);
$cx2 = VRML::JS::newcontext($glo2,$t2);

print "GLO: $glo\n";

sub rs {my $rs; my $res = VRML::JS::runscript($cx,$glo,$_[0],$rs); 
	print "FROM '$_[0]' GOT '$res' AND '$rs'\n"}
sub rs2 {my $rs; my $res = VRML::JS::runscript($cx2,$glo2,$_[0],$rs); 
	print "FROM CTX 2 '$_[0]' GOT '$res' AND '$rs'\n"}

rs "2+2";

rs "function f(k) {return k+2}";
rs "f(5)";

rs2 "function f(k) {return k-2}";
rs2 "f(5)";
rs "f(5)";

rs " a = new SFColor(0.5,0.6,0.7); ";

rs " a.b ";
rs " a.b=3 ";
rs " a.b ";
rs " a.xyz ";
rs " a.xyz=3 ";
rs " a.xyz ";

rs " a.toString() ";

rs " a[0] ";
rs " a[1] ";
rs " a[2] ";

rs2 "b = new SFColor(0.5,0.6,0.7);";
rs2 "b.g = 5;";
rs2 "b.toString()";


VRML::JS::addasgnprop($cx,$glo,"color", "new SFColor(0.1,0.2,0.3)");


rs " color.r ";
rs " color ";

rs " color.__touched() ";
rs " color.r = 5 ";
rs " color.__touched() ";
rs " color.__touched() ";
rs " color  ";
rs " color = new SFColor(0.5,0.6,0.7); ";
rs " color.__touched() ";
rs " color  ";
rs " color.__touched() ";
rs " color.__touched() ";
rs " function f() {color = new SFColor(0.5,0.6,0.7);} ";
rs " color  ";
rs " f() ";
rs " color  ";
rs " color.__touched() ";
rs " a = new SFColor(0.2,0.3,0.4); ";

VRML::JS::addwatchprop($cx,$glo,"time");

rs " time = 5; ";
rs " _time_touched;";
rs " _time_touched=0;";
rs " time ";
rs " _time_touched;";
rs " _time_touched=0;";
rs " time = 6; ";
rs " _time_touched;";
rs " _time_touched=0;";
rs " time ; ";

rs ' foo = new SFNode("","BARBAZ"); ';
rs ' foo.__id ';
rs ' bar = new MFNode(new SFNode("","EJFLIEJLFSF")) ';
rs ' bar[0].__id ';

rs ' zip = new MFVec3f(new SFVec3f(1,1,1),new SFVec3f(1,2,4)); ';
rs ' zip ';
rs ' zip.length ';
rs ' zip.length ';
rs ' zip[0] ';
rs ' zip[1] ';
rs ' zip[2] ';

