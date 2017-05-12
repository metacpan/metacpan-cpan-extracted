use Test::More tests=>71;
use File::Spec;
use strict;

use lib 't';
use BackendModule;

BEGIN { use_ok(MODULE) };

do {
  #No options, explicit method calls
  my $list = MODULE->new( File::Spec->join('t','data','n'));
  isa_ok($list, MODULE);

  my %save;
  my $prefix = quotemeta(File::Spec->join('t','data','n'));

  for my $i (1 .. 4) {
    ok( $list->next, "got $i" );
    $save{ $list->get } = $i;
    like($list->get, qr/$prefix/, "File $i matched prefix");
  }
  ok(not(defined($list->next)), "no more files");
  for my $i (1..3) {
    ok( $save{ File::Spec->join('t','data','n',$i) }, "found $i" );
  }
  ok( $save{ File::Spec->join('t','data','n','n2', 4) }, "found 4" );
};

do {
  #default options, explicit method calls
  my $list = MODULE->new( File::Spec->join('t','data','n'));
  $list->show_directories(0);
  $list->show_dotfiles(0);

  my %save;
  my $prefix = quotemeta(File::Spec->join('t','data','n'));

  for my $i (1 .. 4) {
    ok( $list->next, "got $i" );
    $save{ $list->get } = $i;
    like($list->get, qr/$prefix/, "File $i matched prefix");
  }
  ok(not(defined($list->next)), "no more files");
  for my $i (1..3) {
    ok( $save{ File::Spec->join('t','data','n',$i) }, "found $i" );
  }
  ok( $save{ File::Spec->join('t','data','n','n2', 4) }, "found 4" );
};

do {
  #No options, overloaded operator
  my $list = MODULE->new( File::Spec->join('t','data','n'));

  my %save;
  my $file;
  my $i1=0;
  while ($file = <$list>) {
    $save{ $file } = ++$i1;
  }
  is( keys(%save), 4, "Got 4 files from iterator" );
  for my $i (1..3) {
    ok( $save{ File::Spec->join('t','data','n',$i) }, "found $i" );
  }
};

do {
  #show_dotfiles
  my $prefix = quotemeta(File::Spec->join('t','data','n'));
  my $list = MODULE->new( File::Spec->join('t','data','n'));
  $list->show_dotfiles(1);

  my %save;
  for my $i (1 .. 5) {
    ok( $list->next, "got $i" );
    $save{ $list->get } = $i;
    like($list->get, qr/$prefix/, "File $i matched prefix");
  }
  ok(not(defined($list->next)), "no more files");
  for my $i (1..3, '.dot') {
    ok( $save{ File::Spec->join('t','data','n',$i) }, "found $i" );
  }

};

do {
  #not recursive
  my $list = MODULE->new( File::Spec->join('t','data'));
  $list->recursive(0);
  $list->show_directories(1);

  ok ( $list->next, "got the dir" );
  ok(not(defined($list->next)), "no more files without recursive");
};

do {
  #show_directories, no prune
  my $list = MODULE->new( File::Spec->join('t','data'));
  $list->show_directories(1);

  my $n_dirs;
  my %save;
  my $prefix = quotemeta(File::Spec->join('t','data','n'));

  for my $i (1 .. 6) {
    ok( $list->next, "got $i" );
    $save{ $list->get } = $i;
    like($list->get, qr/$prefix/, "File $i matched prefix");
    ++ $n_dirs if $list->is_directory;
  }
  is ($n_dirs, 2, 'found 2 dirs');
  ok(not(defined($list->next)), "no more files");
  for my $i (1..3) {
    ok( $save{ File::Spec->join('t','data','n',$i) }, "found $i" );
  }
    ok( $save{ File::Spec->join('t','data','n') }, "found n" );
};

do {
  #show_directories + prune_directory
  my $list = MODULE->new( File::Spec->join('t','data', 'n'));
  $list->show_directories(1);

  my $count=0;
  while ( $list->next ) {
	  next unless $list->is_directory;
	  ok( $list->is_directory , "Is directory");
	  is (
	    $list->prune_directory, 
	    File::Spec->join('t','data', 'n', 'n2'),
	    'pruned right dir'
	   );
	  ++ $count;
  }
  is ($count, 1, 'found 1 file');
};

do {
  #show_directories + prune
  my $list = MODULE->new( File::Spec->join('t','data', 'n'));

  my $count=0;
  while ( $list->next ) {
    if ( $list->get eq File::Spec->join('t','data', 'n', 'n2', 4)) {
      $list->prune;
      next;
    }
    ++ $count;
  }
  is ($count, 3, 'found 3 files after pruning');
};

