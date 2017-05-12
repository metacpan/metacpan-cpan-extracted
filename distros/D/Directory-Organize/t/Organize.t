# vim: set sw=4 ts=4 tw=78 et si:
use strict;
use Test;

BEGIN { plan tests => 33, todo => [] }

use Directory::Organize;

my ($do,@dirs);

$do = new Directory::Organize("t");

ok(defined $do,1,'should have a new object');

unless (-f 't/2008/02/20/.project') {

    $do->set_today(20,2,2008);
    $do->new_dir('some project');
    $do->set_today(23,8,2008);
    $do->new_dir('some other project');
    $do->new_dir('a third project');

}

$do->set_pattern('other');

@dirs = $do->get_descriptions();

ok(scalar(@dirs),1,'there should be only one project with pattern "other"');
ok($dirs[0]->[0],'2008/08/23','path should be 2008/02/20');
ok($dirs[0]->[1],'some other project','should be "some other project"');

$do->set_pattern();

@dirs = $do->get_descriptions();

ok($dirs[0]->[0],'2008/08/23a','path should be 2008/08/23a');
ok($dirs[0]->[1],'a third project','should be "a third project"');
ok($dirs[1]->[0],'2008/08/23','path should be 2008/08/23a');
ok($dirs[1]->[1],'some other project','should be "some other project"');
ok($dirs[2]->[0],'2008/02/20','path should be 2008/02/20');
ok($dirs[2]->[1],'some project','should be "some project"');

$do->set_time_constraint('=',2008,2);

@dirs = $do->get_descriptions();

ok(scalar(@dirs),1,'there should be only one project in 2008/02');
ok($dirs[0]->[1],'some project','should be "some project"');

$do->set_time_constraint('<',2008,2,21);

@dirs = $do->get_descriptions();

ok(scalar(@dirs),1,'there should be only one project before 2008/02/21');
ok($dirs[0]->[1],'some project','should be "some project"');

$do->set_time_constraint('>',2008,2,20);

@dirs = $do->get_descriptions();

ok(scalar(@dirs),2,'there should be two project after 2008/02/20');
ok($dirs[0]->[1],'a third project','should be "a third project"');
ok($dirs[1]->[1],'some other project','should be "some other project"');

$do->set_time_constraint('<',2008,8,24);

@dirs = $do->get_descriptions();

ok(scalar(@dirs),3,'there should be three project before 2008/08/24');
ok($dirs[0]->[1],'a third project','should be "a third project"');
ok($dirs[1]->[1],'some other project','should be "some other project"');
ok($dirs[2]->[1],'some project','should be "some project"');

my ($tday,$tmonth,$tyear) = (localtime)[3,4,5];
$tmonth += 1;
$tyear  += 1900;
$do->set_today();

ok($do->{tday},$tday,"this day should be $tday");
ok($do->{tmonth},$tmonth,"this month should be $tmonth");
ok($do->{tyear},$tyear,"this year should be $tyear");

$do->set_today(1);

ok($do->{tday},1,"this day should be 1");
ok($do->{tmonth},$tmonth,"this month should be $tmonth");
ok($do->{tyear},$tyear,"this year should be $tyear");

$do->set_today(1,1);

ok($do->{tday},1,"this day should be 1");
ok($do->{tmonth},1,"this month should be 1");
ok($do->{tyear},$tyear,"this year should be $tyear");

$do->set_today(1,1,2008);

ok($do->{tday},1,"this day should be 1");
ok($do->{tmonth},1,"this month should be 1");
ok($do->{tyear},2008,"this year should be 2008");
