use Test::Simple 'no_plan';
use lib './lib';
use File::PathInfo::Ext;
use strict;
use Cwd;
use File::Path;

# this should test dangerous operations like move/rename


$ENV{DOCUMENT_ROOT} = cwd().'/t/public_html';


my $x = new File::PathInfo::Ext;


File::Path::rmtree($ENV{DOCUMENT_ROOT}.'/timp');
ok( ! -d  $ENV{DOCUMENT_ROOT}.'/timp') or die;

mkdir $ENV{DOCUMENT_ROOT}.'/timp';
mkdir $ENV{DOCUMENT_ROOT}.'./blimp';
mkdir $ENV{DOCUMENT_ROOT}.'/timp/incoming';

ok( -d $ENV{DOCUMENT_ROOT}.'/timp') or die;
ok( -d $ENV{DOCUMENT_ROOT}.'/timp/','-d is true even with / end') or die;


# test ones we know are in docroot
for (
'./demo',
'./demo/hellokitty.gif',
'./demo/civil.txt',
'./Test Me Please.txt',
){

	my $rel = $_;

   my $absa = Cwd::abs_path("$ENV{DOCUMENT_ROOT}/$rel");

	my $a = $x->set($ENV{DOCUMENT_ROOT}."/$rel")
      or die("Cant set to $ENV{DOCUMENT_ROOT}/$rel");

   ok( $a eq $absa )
      or die( "$a is not $absa");
	
	$x->meta->{var} = 'yes';
	
	ok( $x->move($ENV{DOCUMENT_ROOT}.'/timp/'),'move' );	

	ok( !(-f $ENV{DOCUMENT_ROOT}."/$rel"),'gone ok' );

	ok($x->abs_loc eq $ENV{DOCUMENT_ROOT}.'/timp');

	ok($x->meta->{var} eq 'yes');

	ok($x->move("$ENV{DOCUMENT_ROOT}/$rel"),"move back to $rel");
	

}

warn"\n\n\n SET 2 \n\n";


open(FIL,">$ENV{DOCUMENT_ROOT}/moveme.txt");
print FIL "ha";
close FIL;

my $fm = new File::PathInfo::Ext("$ENV{DOCUMENT_ROOT}/moveme.txt");
ok($fm);
ok( $fm->abs_path eq "$ENV{DOCUMENT_ROOT}/moveme.txt");


ok( $fm->move("$ENV{DOCUMENT_ROOT}/timp/incoming"),
   "move() ing to a destination which is dir") or die;



ok( -f "$ENV{DOCUMENT_ROOT}/timp/incoming/moveme.txt", "file went there");


ok("$ENV{DOCUMENT_ROOT}/timp/incoming/moveme.txt" eq $fm->abs_path, 
   "info in object was updated after move");

my $n = "$ENV{DOCUMENT_ROOT}/timp/incoming/movedme.txt";
my $newloc = $fm->copy('movedme.txt');
warn " # on move newloc is : $newloc\n\n";
ok($newloc eq $n);

`touch "$ENV{DOCUMENT_ROOT}/timp/movedme.txt"`;

# make sure we can override
ok( ! $fm->move("$ENV{DOCUMENT_ROOT}/timp") );

my $newabs;
ok(  $newabs = $fm->move("$ENV{DOCUMENT_ROOT}/timp/anothercop.txt") );
ok $newabs eq "$ENV{DOCUMENT_ROOT}/timp/anothercop.txt";




