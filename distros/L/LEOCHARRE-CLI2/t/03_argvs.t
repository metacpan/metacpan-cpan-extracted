use Test::Simple 'no_plan';

# have to do this BEFORE we use the module, to have the args
BEGIN { push @ARGV,  qw(-k hahaha  ./ ./MANIFEST ./Makefile.PL ./t ./lib) }

use strict;
use lib './lib';
use LEOCHARRE::CLI2 qw/:argv k:/;


for my $sub (qw/argv_files argv_files_count argv_dirs argv_dirs_count argv_cwd/){
   ok( main->can($sub), "main can '$sub'")
}


ok argv_files();
ok argv_dirs();
ok argv_files_count();
ok argv_dirs_count();

ok argv_files_count() == 2;
ok argv_dirs_count() == 3;



my @files = argv_files();
ok( @files, "got files");
debug("files @files");



$opt_d = 1;

map { debug("file $_") } argv_files();
map { debug("dir $_") } argv_dirs();


map { debug("opt: '$_' = '$OPT{$_}'") } keys %OPT;

ok exists $OPT{k}, 'opt k is here';

debug("opt string = $OPT_STRING");

ok $opt_k eq 'hahaha', 'opt k is hahaha';
