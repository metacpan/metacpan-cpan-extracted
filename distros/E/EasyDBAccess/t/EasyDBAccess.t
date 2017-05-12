use strict;
use warnings(FATAL=>'all');
use EasyDBAccess;

#===export EasyTest Function
sub plan {&EasyTest::std_plan};
*ok = \&EasyTest::ok;
sub DIE {&EasyTest::DIE};
sub NO_DIE {&EasyTest::NO_DIE};
#added by huang.shuai at 06-07-13
sub ANY {&EasyTest::ANY};
#==============================

plan(233);

my $realtest = 0;

if (!$realtest){
for(1..233){ok(1, 1);}
}
else{

my $dba;
my $dbh;
my $rc;
my ($err_code, $err_detail, $err_pkg);

my $test_db_option={host=>'testdb.lua.cn', usr=>'test_usr', pass=>'passwd', database=>'test_db'};
my $test_db_wrong_option={host=>'testdb.lua.cn', usr=>'test', pass=>'WRONG PASS', database=>'test'};


#===new, once, test 1-18

#--param count error
ok(&DIE, \&EasyDBAccess::new, ['EasyDBAccess']);

ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::new, ['EasyDBAccess']);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 2, &ANY, 'EasyDBAccess'], \&EasyDBAccess::new, ['EasyDBAccess'], 1);

ok(&DIE, \&EasyDBAccess::new, ['EasyDBAccess', 'param1','param2','wastedparam']);

ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::new, ['EasyDBAccess', 'param1','param2','wastedparam']);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 2, &ANY, 'EasyDBAccess'], \&EasyDBAccess::new, ['EasyDBAccess', 'param1','param2','wastedparam'], 1);

#--connect database fail
ok(&DIE, \&EasyDBAccess::new, ['EasyDBAccess', $test_db_wrong_option]);

ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::new, ['EasyDBAccess', $test_db_wrong_option]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 3, &ANY, 'EasyDBAccess'], \&EasyDBAccess::new, ['EasyDBAccess', $test_db_wrong_option], 1);

#--connect success
ok(&NO_DIE, \&EasyDBAccess::new, ['EasyDBAccess', $test_db_option]);

ok(1, \&EasyDBAccess::once, []);
ok([&ANY, 0, &ANY, 'EasyDBAccess'], \&EasyDBAccess::new, ['EasyDBAccess', $test_db_option], 1);


#===dbh, type, close, test 19-22

my $dba_1 = EasyDBAccess::new('EasyDBAccess', $test_db_option);

ok(&NO_DIE, \&EasyDBAccess::dbh, [$dba_1]);
ok('mysql', \&EasyDBAccess::type, [$dba_1]);
ok(1, \&EasyDBAccess::close, [$dba_1]);
$dba_1->close();
ok($dba_1, undef);


my $dba_2 = EasyDBAccess::new('EasyDBAccess', $test_db_option);

#===id, test 23-29

ok('0E0', \&EasyDBAccess::execute, [$dba_2, 'CREATE TABLE RES(ATTRIB VARCHAR(255) NOT NULL,ID INT NOT NULL)']);

ok('1', \&EasyDBAccess::id, [$dba_2, 'key1']);
ok('2', \&EasyDBAccess::id, [$dba_2, 'key1']);
ok('1', \&EasyDBAccess::id, [$dba_2, 'key2']);
ok('3', \&EasyDBAccess::id, [$dba_2, 'key1']);
ok(&DIE, \&EasyDBAccess::id, [$dba_1, 'key1']);

ok('0E0', \&EasyDBAccess::execute, [$dba_2, 'DROP TABLE IF EXISTS RES']);


#====sid, sid_info, test 30-34

ok('0E0', \&EasyDBAccess::execute, [$dba_2,
    'CREATE TABLE SID(RECORD_TIME VARCHAR(255) NOT NULL,SID VARCHAR(255) NOT NULL,COMMENT VARCHAR(255))']);

ok(&NO_DIE, \&EasyDBAccess::sid, [$dba_2, 'test sid']);
ok(&DIE, \&EasyDBAccess::sid, [$dba_1, 'test sid']);

my $sid = $dba_2->sid('test sid');
ok({"record_time"=>hex substr($sid, 0, 8), "sid"=>hex substr($sid, 8), "comment"=>"test sid"},
    \&EasyDBAccess::sid_info, [$dba_2, $sid]);

ok('0E0', \&EasyDBAccess::execute, [$dba_2, 'DROP TABLE IF EXISTS SID']);


#===note, test 35-37

ok('0E0', \&EasyDBAccess::execute, [$dba_2,
    'CREATE TABLE NOTE(TEXT VARCHAR(255) NOT NULL,RECORD_TIME VARCHAR(255) NOT NULL)']);

ok(&NO_DIE, \&EasyDBAccess::note, [$dba_2, 'test note']);

ok('0E0', \&EasyDBAccess::execute, [$dba_2, 'DROP TABLE IF EXISTS NOTE']);


#====_replace, test 38-43

my $str = "SELECT * FROM RES LIMIT %start_pos, %length";
ok(0, \&EasyDBAccess::_replace, [$str, {"start_pos" => undef}]);
ok($str, "SELECT * FROM RES LIMIT %start_pos, %length");

#my $aaa=        [$str, {"st" => "ra"}];
#ok(1, \&EasyDBAccess::_replace, $aaa);
ok(1, \&EasyDBAccess::_replace, [$str, {"start_pos" => "1"}]);
EasyDBAccess::_replace($str, {"start_pos" => "1"});
ok($str, "SELECT * FROM RES LIMIT 1, %length");

$str = "SELECT * FROM RES LIMIT %start_pos, %length";
ok(0, \&EasyDBAccess::_replace, [$str, {"length" => "1", "start_pos" => undef}]);
EasyDBAccess::_replace($str, {"length" => "1", "start_pos" => undef});
ok($str, "SELECT * FROM RES LIMIT %start_pos, 1");


#===_encode, _decode



#===qquote



#===_dump, test 44-47

ok('20', \&EasyDBAccess::_dump, ['20']);
ok('[10, 20]', \&EasyDBAccess::_dump, [['10', '20']]);
ok('{"num1" => 10, "num2" => 20}', \&EasyDBAccess::_dump, [{"num1" => "10", "num2" => "20"}]);
ok('()', \&EasyDBAccess::_dump, []);


#===_IFNULL, test 48-49

ok('param1', \&EasyDBAccess::_IFNULL, ['param1', 'param2']);
ok('param2', \&EasyDBAccess::_IFNULL, [undef, 'param2']);


#===build_array, test 50-55

ok('0E0', \&EasyDBAccess::execute, [$dba_2, 'CREATE TABLE RES(ATTRIB VARCHAR(255) NOT NULL,ID INT NOT NULL)']);

my $c_id = $dba_2->id('person');
ok([$c_id, 'tom', '23'], \&EasyDBAccess::build_array,
        [[qw/? name age/], {name=>'tom', age=>23, other_key=>'hello'}, [$c_id]]);
ok([[$c_id, 'tom', '23'], 0], \&EasyDBAccess::build_array,
        [[qw/? name age/], {name=>'tom', age=>23, other_key=>'hello'}, [$c_id]], 1);

ok([undef], \&EasyDBAccess::build_array,
        [[qw/score/], {name=>'tom',age=>23,other_key=>'hello'}, [$c_id]]);
ok([[undef], 1], \&EasyDBAccess::build_array,
        [[qw/score/], {name=>'tom',age=>23,other_key=>'hello'}, [$c_id]], 1);

ok('0E0', \&EasyDBAccess::execute, [$dba_2, 'DROP TABLE IF EXISTS RES']);

#===build_update, test 56-57

ok('NAME=?,', \&EasyDBAccess::build_update,
        [[qw/name age/], {name=>'jack', other_key=>'hello'}]);
ok(['NAME=?', ['jack'], 1, 'NAME=?,'], \&EasyDBAccess::build_update,
        [[qw/name age/], {name=>'jack', other_key=>'hello'}], 1);


#===die_to_file



#===_lookup_err_code, test 58-61

ok(1062, \&EasyDBAccess::_lookup_err_code, ['1062']);
ok(1062, \&EasyDBAccess::_lookup_err_code, ['ER_DUP_ENTRY']);
ok(&DIE, \&EasyDBAccess::_lookup_err_code, []);
ok(&DIE, \&EasyDBAccess::_lookup_err_code, ['param1', 'param2']);


#===is_int, test 62-71

ok(1, \&EasyDBAccess::is_int, ['0']);
ok('', \&EasyDBAccess::is_int, ['0', -1, 0]);
ok('', \&EasyDBAccess::is_int, ['-1', 0]);
ok(1, \&EasyDBAccess::is_int, ['-2147483648']);
ok('', \&EasyDBAccess::is_int, ['-2147483649']);
ok(1, \&EasyDBAccess::is_int, ['2147483647']);
ok('', \&EasyDBAccess::is_int, ['2147483648']);
ok('', \&EasyDBAccess::is_int, ['test']);
ok(&DIE, \&EasyDBAccess::is_int, []);
ok(&DIE, \&EasyDBAccess::is_int, ['1', 2, 3, 4]);


#===is_id, test 72-75

ok('', \&EasyDBAccess::is_id, ['0']);
ok(1, \&EasyDBAccess::is_id, ['1']);
ok(1, \&EasyDBAccess::is_id, ['4294967295']);
ok('', \&EasyDBAccess::is_id, ['4294967296']);


#===append_file



#===execute, select, select_row, select_one, select_col, select_array, err_str, err_code

#--sql null error, test 76-105
ok(&DIE, \&EasyDBAccess::execute, [$dba_2, undef, [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::execute, [$dba_2, undef, [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 2, &ANY, 'EasyDBAccess'], \&EasyDBAccess::execute, [$dba_2, undef, [], {start_pos => 1}], 1);

ok(&DIE, \&EasyDBAccess::select, [$dba_2, undef, [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select, [$dba_2, undef, [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 2, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select, [$dba_2, undef, [], {start_pos => 1}], 1);

ok(&DIE, \&EasyDBAccess::select_row, [$dba_2, undef, [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select_row, [$dba_2, undef, [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 2, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_row, [$dba_2, undef, [], {start_pos => 1}], 1);

ok(&DIE, \&EasyDBAccess::select_one, [$dba_2, undef, [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select_one, [$dba_2, undef, [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 2, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_one, [$dba_2, undef, [], {start_pos => 1}], 1);

ok(&DIE, \&EasyDBAccess::select_col, [$dba_2, undef, [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select_col, [$dba_2, undef, [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 2, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_col, [$dba_2, undef, [], {start_pos => 1}], 1);

ok(&DIE, \&EasyDBAccess::select_array, [$dba_2, undef, [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select_array, [$dba_2, undef, [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 2, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_array, [$dba_2, undef, [], {start_pos => 1}], 1);

#--there ok a null value in inline_param, test 106-135
ok(&DIE, \&EasyDBAccess::execute, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::execute, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 2, &ANY, 'EasyDBAccess'], \&EasyDBAccess::execute, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}], 1);

ok(&DIE, \&EasyDBAccess::select, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 2, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}], 1);

ok(&DIE, \&EasyDBAccess::select_row, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select_row, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 2, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_row, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}], 1);

ok(&DIE, \&EasyDBAccess::select_one, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select_one, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 2, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_one, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}], 1);

ok(&DIE, \&EasyDBAccess::select_col, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select_col, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 2, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_col, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}], 1);

ok(&DIE, \&EasyDBAccess::select_array, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select_array, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 2, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_array, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => undef}], 1);

#--sql execute error, test 136-171
ok(&DIE, \&EasyDBAccess::execute, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::execute, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 5, &ANY, 'EasyDBAccess'], \&EasyDBAccess::execute, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}], 1);
ok(1146, \&EasyDBAccess::err_code, [$dba_2]);

ok(&DIE, \&EasyDBAccess::select, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 5, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}], 1);
ok(1146, \&EasyDBAccess::err_code, [$dba_2]);

ok(&DIE, \&EasyDBAccess::select_row, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select_row, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 5, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_row, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}], 1);
ok(1146, \&EasyDBAccess::err_code, [$dba_2]);

ok(&DIE, \&EasyDBAccess::select_one, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select_one, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 5, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_one, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}], 1);
ok(1146, \&EasyDBAccess::err_code, [$dba_2]);

ok(&DIE, \&EasyDBAccess::select_col, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select_col, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 5, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_col, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}], 1);
ok(1146, \&EasyDBAccess::err_code, [$dba_2]);

ok(&DIE, \&EasyDBAccess::select_array, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select_array, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}]);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 5, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_array, [$dba_2, 'SELECT * FROM RES LIMIT %start_pos,1', [], {start_pos => 1}], 1);
ok(1146, \&EasyDBAccess::err_code, [$dba_2]);

#--execute on a none select sql, test 172-203
ok('0E0', \&EasyDBAccess::execute, [$dba_2, 'DROP TABLE IF EXISTS HELLO']);
ok(['0E0', 0, &ANY, 'EasyDBAccess'], \&EasyDBAccess::execute, [$dba_2, 'DROP TABLE IF EXISTS HELLO'], 1);

ok(&DIE, \&EasyDBAccess::select, [$dba_2, 'DROP TABLE IF EXISTS HELLO']);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select, [$dba_2, 'DROP TABLE IF EXISTS HELLO']);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 5, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select, [$dba_2, 'DROP TABLE IF EXISTS HELLO'], 1);
ok(19, \&EasyDBAccess::err_code, [$dba_2]);

ok(&DIE, \&EasyDBAccess::select_row, [$dba_2, 'DROP TABLE IF EXISTS HELLO']);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select_row, [$dba_2, 'DROP TABLE IF EXISTS HELLO']);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 5, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_row, [$dba_2, 'DROP TABLE IF EXISTS HELLO'], 1);
ok(19, \&EasyDBAccess::err_code, [$dba_2]);

ok(&DIE, \&EasyDBAccess::select_one, [$dba_2, 'DROP TABLE IF EXISTS HELLO']);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select_one, [$dba_2, 'DROP TABLE IF EXISTS HELLO']);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 5, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_one, [$dba_2, 'DROP TABLE IF EXISTS HELLO'], 1);
ok(19, \&EasyDBAccess::err_code, [$dba_2]);

ok(&DIE, \&EasyDBAccess::select_col, [$dba_2, 'DROP TABLE IF EXISTS HELLO']);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select_col, [$dba_2, 'DROP TABLE IF EXISTS HELLO']);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 5, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_col, [$dba_2, 'DROP TABLE IF EXISTS HELLO'], 1);
ok(19, \&EasyDBAccess::err_code, [$dba_2]);

ok(&DIE, \&EasyDBAccess::select_array, [$dba_2, 'DROP TABLE IF EXISTS HELLO']);
ok(1, \&EasyDBAccess::once, []);
ok(undef, \&EasyDBAccess::select_array, [$dba_2, 'DROP TABLE IF EXISTS HELLO']);
ok(1, \&EasyDBAccess::once, []);
ok([undef, 5, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_array, [$dba_2, 'DROP TABLE IF EXISTS HELLO'], 1);
ok(19, \&EasyDBAccess::err_code, [$dba_2]);

#--SQL execute success, test 204-222
ok('0E0', \&EasyDBAccess::execute, [$dba_2, 'DROP TABLE IF EXISTS PERSON']);

ok(['0E0', 0, &ANY, 'EasyDBAccess'], \&EasyDBAccess::execute, [$dba_2, 'CREATE TABLE PERSON(NAME VARCHAR(255) NOT NULL,AGE INT NOT NULL)'], 1);

ok(undef, \&EasyDBAccess::select_row, [$dba_2, 'SELECT * FROM PERSON ORDER BY NAME ASC']);
ok([undef, 1, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_row, [$dba_2, 'SELECT * FROM PERSON ORDER BY NAME ASC'], 1);

ok(undef, \&EasyDBAccess::select_one, [$dba_2, 'SELECT * FROM PERSON ORDER BY NAME ASC']);
ok([undef, 1, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_one, [$dba_2, 'SELECT * FROM PERSON ORDER BY NAME ASC'], 1);

ok(1, \&EasyDBAccess::execute, [$dba_2, 'INSERT INTO PERSON VALUES(?,?)',['Bill',23]]);
ok([1, 0, &ANY, 'EasyDBAccess'], \&EasyDBAccess::execute, [$dba_2, 'INSERT INTO PERSON VALUES(?,?)',['Mike',23]], 1);
ok([1, 0, &ANY, 'EasyDBAccess'], \&EasyDBAccess::execute, [$dba_2, 'INSERT INTO PERSON VALUES(?,?)',['James',24]], 1);

ok([{"name" => "Bill", "age" => 23}, {"name" => "James", "age" => 24}, {"name" => "Mike", "age" => 23}],
                \&EasyDBAccess::select, [$dba_2, 'SELECT * FROM PERSON ORDER BY NAME ASC']);
ok([[{"name" => "Bill", "age" => 23}, {"name" => "James", "age" => 24}, {"name" => "Mike", "age" => 23}], 0, &ANY, 'EasyDBAccess'],
                \&EasyDBAccess::select, [$dba_2, 'SELECT * FROM PERSON ORDER BY NAME ASC'], 1);

ok({"name" => "Bill", "age" => 23}, \&EasyDBAccess::select_row, [$dba_2, 'SELECT * FROM PERSON ORDER BY NAME ASC']);
ok([{"name" => "Bill", "age" => 23}, 0, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_row, [$dba_2, 'SELECT * FROM PERSON ORDER BY NAME ASC'], 1);

ok("Bill", \&EasyDBAccess::select_one, [$dba_2, 'SELECT * FROM PERSON ORDER BY NAME ASC']);
ok(["Bill", 0, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_one, [$dba_2, 'SELECT * FROM PERSON ORDER BY NAME ASC'], 1);

ok(["Bill", "James", "Mike"], \&EasyDBAccess::select_col, [$dba_2, 'SELECT * FROM PERSON ORDER BY NAME ASC']);
ok([["Bill", "James", "Mike"], 0, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_col, [$dba_2, 'SELECT * FROM PERSON ORDER BY NAME ASC'], 1);

ok([["Bill", 23], ["James", 24], ["Mike", 23]], \&EasyDBAccess::select_array,
        [$dba_2, 'SELECT * FROM PERSON ORDER BY NAME ASC']);
ok([[["Bill", 23], ["James", 24], ["Mike", 23]], 0, &ANY, 'EasyDBAccess'], \&EasyDBAccess::select_array,
        [$dba_2, 'SELECT * FROM PERSON ORDER BY NAME ASC'], 1);


#===batch_insert, test 223

ok(1, \&EasyDBAccess::batch_insert, [$dba_2, 'insert into PERSON values %V','(?,?)',[[1,'tom'],[2,'gates'],[3,'bush']],100]);


#===insert_one_row, test 224-225

ok(1, \&EasyDBAccess::insert_one_row, [$dba_2, 'INSERT INTO PERSON VALUES(?,?)',['?', 'age'], {name=>'jim',age=>23,other_key=>'hello'}, ['jim']]);
ok([1, 0, &ANY, 'EasyDBAccess'], \&EasyDBAccess::insert_one_row,
  [$dba_2, 'INSERT INTO PERSON VALUES(?,?)', ['name', '?'], {name=>'tim',age=>23,other_key=>'hello'}, [23]], 1);


#===update, test 226-227

ok(1, \&EasyDBAccess::update, [$dba_2, 'UPDATE PERSON SET %ITEM WHERE NAME=?',['age'], {name=>'tim',age=>24}, ['tim']]);
ok([1, 0, &ANY, 'EasyDBAccess'], \&EasyDBAccess::update,
  [$dba_2, 'UPDATE PERSON SET %ITEM WHERE NAME=?', ['age'], {name=>'jim',age=>24, other_key=>'bye'}, ['jim']], 1);

#test 228

ok('0E0', \&EasyDBAccess::execute, [$dba_2, 'DROP TABLE IF EXISTS PERSON']);

#test 229-233
ok(['0E0', 0, &ANY, 'EasyDBAccess'], \&EasyDBAccess::execute, [$dba_2, 'CREATE TABLE PERSON(ID INT NOT NULL,NAME VARCHAR(255) NOT NULL,TEMP VARCHAR(255) NOT NULL DEFAULT \'def\')'], 1);
ok(1, \&EasyDBAccess::batch_insert, [$dba_2, 'insert into PERSON values %V','(?,?,?)',[[11,'bob', \&EasyDBAccess::DEFAULT],[12,'bill','value2']],10]);
ok(1, \&EasyDBAccess::insert_one_row, [$dba_2, 'INSERT INTO PERSON VALUES(?,?,?)',['id', '?', 'DEFAULT'], {id => 19, DEFAULT=>\&EasyDBAccess::DEFAULT}, ['kate']]);
ok('0E0', \&EasyDBAccess::execute, [$dba_2, 'DROP TABLE IF EXISTS PERSON']);

ok(1, \&EasyDBAccess::close, [$dba_2]);


}
1;


























package EasyTest;
use strict;
use warnings(FATAL=>'all');

#===================================
#===Module  : EasyTest
#===Comment : module for writing test script
#===================================

#===================================
#===Author  : qian.yu            ===
#===Email   : foolfish@cpan.org  ===
#===MSN     : qian.yu@adways.net ===
#===QQ      : 19937129           ===
#===Homepage: www.lua.cn         ===
#===================================

use Exporter 'import';
use Test qw();

our $bool_std_test;
our $plan_test_count;
our $test_count;
our $succ_test;
our $fail_test;
our ($true,$false);

BEGIN{
        our @EXPORT = qw(&ok &plan &std_plan &DIE &NO_DIE);
        $bool_std_test='';
        $plan_test_count=undef;
        $test_count=0;
        $succ_test=0;
        $fail_test=0;
        ($true,$false) = (1,'');
};

sub foo{1};
sub _name_pkg_name{__PACKAGE__;}

#===ok($result,$value); if $result same as $value test succ, else test fail
#===ok($result,$func,$ra_param);#same as ok($result,$func,$ra_param,0);
#===ok($ra_result,$func,$ra_param,1); test result in array  mode
#===ok($   result,$func,$ra_param,0); test result in scalar mode
sub ok{
        my $param_count=scalar(@_);
        if($param_count==2){
                if(&dump($_[0]) eq &dump($_[1])){
                        $test_count++;$succ_test++;
                        if($bool_std_test){
                                Test::ok($true);
                        }else{
                                print "ok $test_count\n";
                        }
                        return $true;
                }else{
                        $test_count++;$fail_test++;
                        if($bool_std_test){
                                Test::ok($false);
                        }else{
                                my $caller_info=sprintf('LINE %04s',[caller(0)]->[2]);
                                print "not ok $test_count $caller_info\n";
                        }
                        return $false;
                }
        }elsif($param_count==4||$param_count==3){
                my $result;
                my $mode;
                if($param_count==3){
                        $mode=1;
                }elsif($param_count==4&&defined($_[3])&&$_[3]==0){
                        $mode=1;
                }elsif($param_count==4&&defined($_[3])&&$_[3]==1){
                        $mode=2;
                }else{#default
                        $mode=1;
                }
                if($mode==1){
                        eval{$result=$_[1]->(@{$_[2]});};
                }elsif($mode==2){
#modified by huang.shuai at 06-07-12
#                       eval{$result=[$_[1]->({@$_[2]})];};
                        eval{$result=[$_[1]->(@{$_[2]})];};
                }else{
                        CORE::die 'BUG';
                }
                if($@){
                        undef $@;
                        if(DIE($_[0])){
                                $test_count++;$succ_test++;
                                if($bool_std_test){
                                        Test::ok($true);
                                }else{
                                        print "ok $test_count\n";
                                }
                                return $true;
                        }else{
                                $test_count++;$fail_test++;
                                if($bool_std_test){
                                        Test::ok($false);
                                }else{
                                        my $caller_info=sprintf('LINE %04s',[caller(0)]->[2]);
                                        print "not ok $test_count $caller_info\n";
                                }
                                return $false;
                        }
                }else{
#added by huang.shuai at 06-07-13
                        if ((defined $_[0]) && (defined $result)){
                            if (ref $_[0] ne 'ARRAY'){
                                if (ANY($_[0])){
                                    $_[0] = undef;
                                    $result = undef;
                                }
                            }else{
                                if($#{$_[0]} == $#$result){
                                    foreach(0 .. $#{$_[0]}){
                                        if(ANY($_[0][$_])){
                                            @{$_[0]}[$_] = undef;
                                            @$result[$_] = undef;
                                        }
                                    }
                                }
                            }
                        }
#====
                        if(NO_DIE($_[0])){
                                $test_count++;$succ_test++;
                                if($bool_std_test){
                                        Test::ok($true);
                                }else{
                                        print "ok $test_count\n";
                                }
                                return $true;
                        }elsif(&dump($_[0]) eq &dump($result)){
                                $test_count++;$succ_test++;
                                if($bool_std_test){
                                        Test::ok($true);
                                }else{
                                        print "ok $test_count\n";
                                }
                                return $true;
                        }else{
                                $test_count++;$fail_test++;
                                if($bool_std_test){
                                        Test::ok($false);
                                }else{
                                        my $caller_info=sprintf('LINE %04s',[caller(0)]->[2]);
                                        print "not ok $test_count $caller_info\n";
                                }
                                return $false;
                        }
                }
        }else{
                CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'ok: param count should be 2, 3, 4');
        }
}

sub plan($){
        $plan_test_count=$_[0];
        print "plan to test $plan_test_count \n";
}

sub std_plan($){
        $plan_test_count=$_[0];
        $bool_std_test=1;
        Test::plan(tests=>$plan_test_count);
}

sub DIE{
        my $code=1;
        if(scalar(@_)==0){
                return bless [$code,'DIE'],'Framework::EasyTest::CONSTANT';
        }elsif(scalar(@_)==1){
                return ref $_[0] eq 'Framework::EasyTest::CONSTANT' && $_[0]->[0]==$code?1:'';
        }else{
                die 'EasyTest::DIE: param number should be 0 or 1';
        }
}

sub NO_DIE{
        my $code=2;
        if(scalar(@_)==0){
                return bless [$code,'NO_DIE'],'Framework::EasyTest::CONSTANT';
        }elsif(scalar(@_)==1){
                return ref $_[0] eq 'Framework::EasyTest::CONSTANT' && $_[0]->[0]==$code?1:'';
        }else{
#modified by huang.shuai at 06-07-13
#               die 'EasyTest::DIE: param number should be 0 or 1';
                die 'EasyTest::NO_DIE: param number should be 0 or 1';
        }
}

#added by huang.shuai at 06-07-13
sub ANY{
        my $code=3;
        if(scalar(@_)==0){
                return bless [$code,'ANY'],'Framework::EasyTest::CONSTANT';
        }elsif(scalar(@_)==1){
                return ref $_[0] eq 'Framework::EasyTest::CONSTANT' && $_[0]->[0]==$code?1:'';
        }else{
                die 'EasyTest::ANY: param number should be 0 or 1';
        }
}

END{
#modified by huang.shuai at 06-07-13
#add 3 '\n'
        if(!$bool_std_test){
                if(defined($plan_test_count)){
                        if($plan_test_count==($succ_test+$fail_test)&&$fail_test==0){
                                print "plan test $plan_test_count ,finally test $test_count, $succ_test succ,$fail_test fail,test successful!\n";
                        }else{
                                CORE::die "plan test $plan_test_count ,finally test $test_count, $succ_test succ,$fail_test fail,test failed!\n";
                        }
                }else{
                        print "finally test $test_count, $succ_test succ,$fail_test fail\n";
                }
        }
}

sub qquote {
        local($_) = shift;
        s/([\\\"\@\$])/\\$1/g;
        s/([^\x00-\x7f])/sprintf("\\x{%04X}",ord($1))/eg if utf8::is_utf8($_);
        return qq("$_") unless
                /[^ !"\#\$%&'()*+,\-.\/0-9:;<=>?\@A-Z[\\\]^_`a-z{|}~]/;  # fast exit
        s/([\a\b\t\n\f\r\e])/{
                "\a" => "\\a","\b" => "\\b","\t" => "\\t","\n" => "\\n",
            "\f" => "\\f","\r" => "\\r","\e" => "\\e"}->{$1}/eg;
        s/([\0-\037\177])/'\\x'.sprintf('%02X',ord($1))/eg;
        s/([\200-\377])/'\\x'.sprintf('%02X',ord($1))/eg;
        return qq("$_");
}

sub qquote_bin{
        local($_) = shift;
        s/([\x00-\xff])/'\\x'.sprintf('%02X',ord($1))/eg;
        s/([^\x00-\x7f])/sprintf("\\x{%04X}",ord($1))/eg if utf8::is_utf8($_);
        return qq("$_");
}

sub dump{
        my $max_line=80;
        my $param_count=scalar(@_);
        my ($flag,$str1,$str2);
        if($param_count==1){
                my $data=$_[0];
                my $type=ref $data;
                if($type eq 'ARRAY'){
                        my $strs=[];
                        foreach(@$data){push @$strs,&dump($_);}

                        $str1='[';$flag=0;
                        foreach(@$strs){$str1.=$_.",\x20";$flag=1;}
                        if($flag==1){chop($str1);chop($str1);}
                        $str1.=']';

                        $str2='[';
                        foreach(@$strs){s/\n/\n\x20\x20/g;$str2.="\n\x20\x20".$_.',';}
                        $str2.="\n]";

                        return length($str1)>$max_line?$str2:$str1;
                }elsif($type eq 'HASH'){
                        my $strs=[];
                        foreach(keys(%$data)){push @$strs,[qquote($_),&dump($data->{$_})];}

                        $str1='{';$flag=0;
                        foreach(@$strs){$str1.="$_->[0]\x20=>\x20$_->[1],\x20";$flag=1;}
                        if($flag==1){chop($str1);chop($str1);}
                        $str1.='}';

                        $str2='{';
                        foreach(@$strs){ $_->[1]=~s/\n/\n\x20\x20/g;$str2.="\n\x20\x20$_->[0]\x20=>\x20$_->[1],";}
                        $str2.="\n}";

                        return length($str1)>$max_line?$str2:$str1;
                }elsif($type eq 'SCALAR'||$type eq 'REF'){
                        return "\\".&dump($$data);
                }elsif($type eq ''){
                        $flag=0;
                        if(!defined($data)){return 'undef'};
                        eval{if($data eq int $data){$flag=1;}};
                        if($@){undef $@;}
                        if($flag==0){return qquote($data);}
                        elsif($flag==1){return $data;}
                        else{ die 'dump:BUG!';}
                }else{
                        return ''.$data;#===if not a simple type
                }
        }else{
                my $strs=[];
                foreach(@_){push @$strs,&dump($_);}

                $str1='(';
                $flag=0;
                foreach(@$strs){$str1.=$_.",\x20";$flag=1;}
                if($flag==1){chop($str1);chop($str1);}
                $str1.=')';

                $str2='(';
                foreach(@$strs){s/\n/\n\x20\x20/g;$str2.="\n\x20\x20".$_.',';}
                $str2.="\n)";

                return length($str1)>$max_line?$str2:$str1;
        }
}

1;