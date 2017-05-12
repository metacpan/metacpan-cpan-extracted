use strict;
use warnings;
no warnings 'uninitialized';

use Test::More tests => 30 ;

diag( "Testing File::Tabular $File::Tabular::VERSION, Perl $], $^X" );

my $tmpJournal = "tmpJournal.txt";

BEGIN {use_ok("File::Tabular");}

unlink $tmpJournal;

my $f = new File::Tabular("t/htmlEntities.txt", 
			  {avoidMatchKey => 1});
isa_ok($f, 'File::Tabular', "open DATA");

# fetch first row
my $row = $f->fetchrow;
is($row->{Name}, "amp", "fetchrow");
is($., 1, "next line no");

# fetch several rows according to regex ; get back rows and line numbers
my ($rows, $nums) = $f->fetchall(where => 'accent');
isa_ok($rows, 'ARRAY', "fetchall rows");
isa_ok($nums, 'ARRAY', "fetchall nums");
is($rows->[0]{Name}, 'Aacute', 'Aacute');
is($nums->[0], 6, 'Aacute line');


$f->rewind;
is($., 0, 'rewind');


# same thing, more complex filter
$rows = $f->fetchall(where => '+Description:(+accent -o -*cu* ) -Name=~"^E"');


is($rows->[0]{Name}, 'Agrave', 'Agrave');
is(scalar(@$rows), 7, 'complex filter n lines');
$f->rewind;


# special query K_E_Y:val 
$row = $f->fetchrow(where => 'K_E_Y:20');
ok((not defined($row)), 'did not find key 20');
$f->rewind;
$row = $f->fetchrow(where => 'K_E_Y:202');
is($row->{Name}, 'Ecirc', 'did find key 202');
$f->rewind;

# do not match key in usual request
$row = $f->fetchrow(where => '202');
ok((not defined($row)), 'key 202 not matched by default query');
$f->rewind;
$row = $f->fetchrow(where => '~ 202');
is($row->{Name}, 'Ecirc', 'key 202 matched by regex');
$f->rewind;



# fetch other rows as a hashref, keys from field 'Name'
$rows = $f->fetchall(where => 'circumflex', key => 'Name');
isa_ok($rows, 'HASH', "fetchall rows Name");
my $r = $rows->{ucirc};
isa_ok($r, 'HASH');
is($r->{Char}, 'û', 'ucirc');

# open a new file for writing and write some lines
my $w = new File::Tabular("+>", undef, # temporary file, see perlfunc/open
		       {fieldSep => '&',
			headers => [$f->{ht}->names],
		        autoNumField => 'Num',
		        journal => $tmpJournal});

isa_ok($w, 'File::Tabular', "open TMP");

my @tmp = sort {$a->{Name} cmp $b->{Name}} values %$rows;

$w->append(\@tmp);
$w->rewind;
$row = $w->fetchrow;
my $n = $row->{Name};
is($n, 'Acirc', 'first written line');

# some modifications in lines
$w->splices(2 => 2, undef,             # delete lines 2, 3
 	    5 => 1, [@tmp[0, 1, 2]],   # replace line 5 by 3 lines
	    8 => 0, [@tmp[0, 1, 2, 3]],# insert 4 lines before line 8
 	    -1 => 0, [@tmp[0, 1]]);    # add again 2 lines

$w->rewind;
my @names = map {$_->{Name}} @{$w->fetchall()};
ok(eq_array(\@names, [qw(Acirc Ecirc Ucirc 
			 Acirc Ecirc Icirc 
			 ecirc icirc 
			 Acirc Ecirc Icirc Ocirc
			 ocirc ucirc
			 Acirc Ecirc)]), "circ list");



# write data using keys and test autonum
my $foo = $w->{ht}->new;
$foo->{Name} = 'foo';
$foo->{Num}  = '#';
$w->clear;
$w->append(\@tmp);
$w->rewind;
$w->writeKeys({Acirc => undef,
 	       Icirc => $foo,
 	       ocirc => $foo}, 'Name');

$w->rewind;
$rows = $w->fetchall(key => 'Name');
ok(not(exists $rows->{Acirc}), "not Acirc");
ok(not(exists $rows->{ocirc}), "not ocirc");

is($rows->{foo}->{Name}, "foo", "foo");

$f->rewind;
$w->clear;
$w->append($f->fetchall);
$w->append($foo, $foo);
$w->rewind;

my $filter = $w->compileFilter('foo');
$row = $w->fetchrow($filter);
is($row->{Num}, 256, "autonum 1");
$row = $w->fetchrow($filter);
is($row->{Num}, 257, "autonum 2");

$w->rewind;
$rows = $w->fetchall;

close $w->{journal}{FH}; # need explicit close for flush before playJournal


# open a new file for replaying journal
my $w2 = new File::Tabular("+>", undef, # temporary file
		       {fieldSep => '&',
			headers => [$f->{ht}->names],
		        autoNumField => 'Num'});

$w2->playJournal($tmpJournal);
$w2->rewind;
my $rows2 = $w2->fetchall;
is_deeply($rows, $rows2, "journal");


# check stat functions
ok($f->stat->{size} > 0, "nonempty size");
ok($f->stat->{mode} > 0, "nonempty block size");
ok(defined($f->mtime->{hour}), "mtime hour");
