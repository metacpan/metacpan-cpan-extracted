# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use Test;
use File::Glob;
BEGIN { plan tests => 15 };
use MLDBM::TinyDB qw/db/;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

ok(ref(MLDBM::TinyDB->init('table_test1',
		[qw/table_test1 field_test1/,
		[qw/table_test2 field_test21 field_test22 field_test23/]]
	)), 'MLDBM::TinyDB');

ok(scalar(db('table_test2')->set_recs([
		{'field_test21'=>"abb", 'field_test22'=>"red", 'field_test23'=>4},
		{'field_test21'=>"abb", 'field_test22'=>"blue", 'field_test23'=>3},
		{'field_test21'=>"bccc", 'field_test22'=>undef, 'field_test23'=>2},
		{'field_test21'=>"ooo", 'field_test22'=>'orange', 'field_test23'=>2},
		{'field_test21'=>"bbuu", 'field_test22'=>"black", 'field_test23'=>4}])), 5);
ok(sub {
	my $it = db('table_test2');
	my $aref = $it->get_recs;
	my @test;
	my @flds = $it->flds;
	foreach my $r (@$aref) {
		push(@test,[@$r{qw/field_test21 field_test22 field_test23/}]);
	} 
	my @ss = map { $_->[0] } sort {$a->[0] cmp $b->[0]} @test;
	my @ms = map { $_->[1] } $it->sort(q/a(field_test21)cmpb(field_test21)/); 
	my @ss1 = map { $_->[0], $_->[1] } sort {$a->[0] cmp $b->[0]||length($a->[1])<=>length($b->[1])} @test;
	my @ms1 = map { $_->[1], $_->[2] } $it->sort(q/a(field_test21)cmpb(field_test21)||lengtha(field_test22)<=>lengthb(field_test22)/); 
	return "@ss" eq "@ms" && "@ss1" eq "@ms1";
});

ok(join('',db('table_test2')->search(
		'length(field_test21)==field_test23||!defined(field_test22)')),'124');

ok(join('',db('table_test1')->set_recs([
				{'field_test1'=>"joe", 'table_test2'=>[1, 2]},
				{'field_test1'=>"may", 'table_test2'=>[0, 2, 4]}],0,2)),'02');
				
ok( sub { 
		my $aref = db('table_test1')->get_recs(1);
		return  !defined($aref->[0]{'field_test1'})?1:0; 
	} );

ok(join('',db('table_test1')->set_recs([
		{'field_test1'=>"bob", 'table_test2'=>[3, 4]},
		{'field_test1'=>"mary", 'table_test2'=>[2, 3]}],1,3)),'13');

ok( sub {
		my $aref = db('table_test2')->get_recs(0,2,4);
		return	grep $_==2, @{$aref->[0]{nodes}} &&
			grep $_==2, @{$aref->[1]{nodes}} &&
			grep $_==2, @{$aref->[2]{nodes}};
	} );

ok(join('',db('table_test1')->delete(2)),'2');

ok( sub {
		my $aref = db('table_test2')->get_recs(0,2,4);
		return !( grep $_==2, @{$aref->[0]{nodes}} &&
			  grep $_==2, @{$aref->[1]{nodes}} &&
			  grep $_==2, @{$aref->[2]{nodes}} );
	} );

ok(sub {	
		my $aref = db('table_test1')->get_recs(0);
		return  "@{$aref->[0]{'table_test2'}}" eq "1 2";
	} );

ok(join('',db('table_test2')->delete(1)),'1');

ok(sub {	
		my $aref = db('table_test1')->get_recs(0);
		return  "@{$aref->[0]{'table_test2'}}" eq '1';
	} );

ok(sub {
		my $aref = db('table_test1')->get_ext_recs;
		return  
			$aref->[0]{'table_test2'}[0][0]{'field_test21'} 	eq 'bccc' && 
			"@{$aref->[0]{'table_test2'}}[1]" 			eq '1' &&
			$aref->[1]{'table_test2'}[0][0]{'field_test21'} 	eq 'ooo' && 
			$aref->[1]{'table_test2'}[0][1]{'field_test21'} 	eq 'bbuu' && 
			"@{$aref->[1]{'table_test2'}}[1,2]" 			eq '2 3' &&
			$aref->[2]{'table_test2'}[0][0]{'field_test21'} 	eq 'bccc' && 
			$aref->[2]{'table_test2'}[0][1]{'field_test21'} 	eq 'ooo' && 
			"@{$aref->[2]{'table_test2'}}[1,2]" 			eq '1 2';
	} );

%{MLDBM::TinyDB::db} = ();
unlink glob(qq/table_test*/);
