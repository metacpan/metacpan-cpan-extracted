#!perl

use v5.26;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
use Test::Warnings qw(warning);

plan tests => 3+2+2 + 3+4+3+7 + 1;


use Mac::Alias qw(:all);
use Path::Tiny;
use File::Copy qw(move);
use Unicode::Normalize qw(NFD);

my ($r, $w);


my $temp = Path::Tiny->tempdir('Mac-Alias-XXXXXXXX');


lives_ok {
	$w = warning { $r = make_alias 't/eg/none', $temp->child('none.alias') };
} 'make_alias no target lives';
ok ! $r, 'make_alias no target fails';
like($w, qr/\bFile not found\b/i, 'make_alias no target warns')
	or diag 'got warning(s): ', explain($w);


$temp->child('file')->touch;
lives_ok {
	warning { $r = make_alias 't/eg', $temp->child('file') };
} 'make_alias exists lives';
ok ! $r, 'make_alias exists fails';
# Fails either because the script can't be executed,
# or because the file already exists.


lives_ok {
	warning { $r = make_alias $temp->child('file'), $temp->child('alias') };
} 'make_alias target lives';
is $r, $temp->child('alias')->exists, 'make_alias target result';
# Either fails because the script can't be executed,
# or succeeds because the alias file was created.


my $alias = $temp->child('alias')->realpath;
my $target = $temp->child('file')->realpath;

SKIP: {
	skip 'requires osascript', 3+4+3+7 if ! $alias->exists;
	
	# verify earlier make succeeded
	is read_alias      $alias, $target, 'read_alias';
	is read_alias_mac  $alias, $target, 'read_alias_mac';
	is read_alias_perl $alias, $target, 'read_alias_perl';
	
	# read succeeds after alias was moved
	ok move($target, my $target1 = $target->sibling('file1')), 'move 1';
	is read_alias_mac $alias, $target1, 'read_alias_mac moved';
	ok move($target1, my $target2 = $target->sibling('file2')), 'move 2';
	is read_alias $alias, $target2, 'read_alias moved again';
	
	# alias has Unicode name, plus ` " \ $
	my $uname = "\x60TE\x22ST\x5c\x22 \x24TE\x{101}ST\x21";
	ok move($alias, my $unicode = $alias->sibling($uname)), 'move 3';
	lives_and { is read_alias     $unicode, $target2 } 'unicode alias read_alias';
	lives_and { is read_alias_mac $unicode, $target2 } 'unicode alias read_alias_mac';
	
	# target has Unicode name
	$unicode = $unicode->sibling("$uname target")->touch;
	lives_and {
		ok make_alias $unicode, $alias;
	} 'make_alias unicode lives';
	ok $unicode->exists, 'make_alias unicode success';
	ok move($unicode, my $unicode2 = $unicode->sibling("$uname 2")), 'move 4';
	lives_and { is NFD parse_alias($alias)->{path}, NFD $unicode } 'unicode target parse_alias';
	lives_and { is NFD read_alias_perl $alias, NFD $unicode  } 'unicode target read_alias_perl';
	lives_and { is NFD read_alias      $alias, NFD $unicode2 } 'unicode target read_alias';
	lives_and { is NFD read_alias_mac  $alias, NFD $unicode2 } 'unicode target read_alias_mac';
}


done_testing;
