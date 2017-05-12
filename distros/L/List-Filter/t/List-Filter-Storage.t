# Test file. Run this: "perl List-Filter-Storage.t"
#   doom@kzsu.stanford.edu     2007/05/19 21:53:01

use warnings;
use strict;
$|=1;
my $DEBUG = 0;
use Data::Dumper;
use YAML qw( DumpFile LoadFile );
use File::Path qw(mkpath);
use File::Basename;
use File::Copy qw(copy move);
use Data::Dumper;
use DBI;
use Test::Trap qw( trap $trap );
use Carp;

use Test::More;
BEGIN { plan tests => 67 };
use FindBin qw($Bin);
use lib ("$Bin/../../..");

my $class;
BEGIN {
  $class = 'List::Filter::Storage';
  use_ok( $class );
}

use List::Filter;
use List::Filter::Transform;

ok(1, "Traditional: 'We made it this far.'");

# additional global definitions (and initializations)
my $temp_loc = "$Bin/tmp";
mkpath( $temp_loc );

{ my $test_name = "Testing creation of a $class object";
  my $filter_storage = $class->new({ storage=> [ "/tmp/nada.yaml" ] });

  isa_ok( $filter_storage, $class, $test_name);

  $test_name = "Testing that $class object can";
  my @needed_methods = qw(lookup save);
  foreach my $method (@needed_methods) {
    # my $testcase = "$method";
    # ok( $filter_storage->can( $method ), "$test_name $testcase" );
    my @methods = ( $method );
    can_ok( $filter_storage, @methods  );
  }
}

{ my $test_name = "Testing $class: getting a filter from a yaml file";

  my $test_loc   = "$temp_loc/testA/.list-filter";
  mkpath( $test_loc );
  my $stash_file  = "$test_loc/filters.yaml";

  my $stash = define_testb_stash_1(); # same content as later test
  DumpFile( $stash_file, $stash );

  my $filter_storage = $class->new({ storage=> [ $stash_file ] });

  my $name = 'doom_filter';

  my $filter = $filter_storage->lookup( $name );
  ($DEBUG) && print "filter object:\n", Dumper($filter), "\n";

  my $method = $filter->method;
  my $expected_method = "skip_any";
  is ($method, $expected_method,
      "$test_name: got expected method, 'skip_any'");

  my $terms = $filter->terms;
  my $expected_terms = [
                                     '~$',
                                     '/\\#',
                                     ',v$',
                                     '\\.elc$',
                                     '\\bold',
                                     '\\bOld',
                                     '\\bOLD',
                                     'bak$',
                                     'Bak$',
                                     'BAK$'
                                   ];
  is_deeply( $terms, $expected_terms,
             "$test_name: read expected terms");
}

{ my $test_name = "Getting filters from two yaml files";

  my $test_loc      = "$temp_loc/testB/.list-filter";
  mkpath( $test_loc );

  my $stash_file_1  = "$test_loc/filters.yaml";
  my $stash_file_2  = "$test_loc/others.yaml";

  my $stash_1 = define_testb_stash_1();
  my $stash_2 = define_testb_stash_2();

  DumpFile( $stash_file_1, $stash_1);
  DumpFile( $stash_file_2, $stash_2);

  my $owner ='';
  my $password = '';

  # Using two different syntaxes to access YAML
  my $filter_storage = $class->new(
      { storage=>
        [ $stash_file_2 ,
          { format     => 'YAML',
            connect_to => $stash_file_1,
            owner      => $owner,
            password   => $password,
          }
        ] });

  my $name = "doom_filter";
  my $filter = $filter_storage->lookup( $name );
  my $method = $filter->method;

  is( $method, "skip_any", "$test_name: read data from href arg");

  $name = "final_select";
  $filter = $filter_storage->lookup( $name );
  $method = $filter->method;

  is( $method, "nonexistent", "$test_name: read data from file arg");
}

{ my $test_name = "Filter creation, stored in yaml";

  my $test_loc   = "$temp_loc/testC/.list-filter";
  mkpath( $test_loc );

  my $stash_file  = "$test_loc/filters.yaml";

  my $filter_storage = $class->new({ storage=> [ $stash_file ] });

  my $filters = [];
   $filters->[0] = List::Filter->new(
     { name         => 'skip_boring_stuff',
       terms        => ['-\.vb$', '\-.js$'],
       method       => 'skip_boring_stuff',
       description  => "Skip the really boring stuff",
       modifiers    => "xi",
     } );

   $filter_storage->save( $filters->[0] );

   my $args = {
         name         => 'alpha',
         terms        => ['^A', '^0', '^1'],
         method       => 'match_any',
         description  => "Find the beginning at the beginning",
         modifiers    => "xi",
      };

   $filters->[1] = List::Filter->new( $args );

   $filter_storage->save( $filters->[1] );

   $filters->[2] = List::Filter->new(
     { name         => 'nada',
       terms        => ['^.*$', '0', 'nada', '', 'bupkes'],
       method       => 'match_nuttin',
       description  => "Being silly",
       modifiers    => "xi",
     } );

   $filter_storage->save( $filters->[2] );

  my $name    = "alpha";
  my $filter = $filter_storage->lookup( $name );

  is(         $filter->description,  $args->{description},
     "$test_name: read description from saved filter alpha ");
  is(         $filter->method,       $args->{method},
     "$test_name: read method from saved filter alpha ");
  is_deeply( $filter->terms,  $args->{terms},
     "$test_name: read terms from saved filter alpha ");
}

{ my $test_name = "Testing save and lookup of filters with yaml storage";
  my $test_loc   = "$temp_loc/testD/.list-filter";
  mkpath( "$test_loc" );

  my $stash_file  = "$test_loc/filters.yaml";

  # erase results of previous run
  unlink $stash_file if (-e $stash_file);

  my $filter_storage = $class->new({ storage=> [ $stash_file ] });

  my $filters = [];
   $filters->[0] = List::Filter->new(
     { name         => 'skip_boring_stuff',
       terms        => ['-\.vb$', '\-.js$'],
       method       => 'skip_boring_stuff',
       description  => "Skip the really boring stuff",
       modifiers    => "xi",
     } );
   $filter_storage->save( $filters->[0] );

   my $args = {
         name         => 'alpha',
         terms        => ['^A', '^0', '^1'],
         method       => 'match_any',
         description  => "Find the beginning at the beginning",
         modifiers    => "xi",
      };
   $filters->[1] = List::Filter->new( $args );
   $filter_storage->save( $filters->[1] );

   # Note: since this one has a leading underscore name, it won't be saved.
   $filters->[2] = List::Filter->new(
     { name         => '_you_can\'t_see_meee',
       terms        => ['\.XXX$', '\.AAA$'],
       method       => 'match_nuttin',
       description  => "Being silly",
       modifiers    => "xi",
     } );
   $filter_storage->save( $filters->[2] );

   $filters->[3] = List::Filter->new(
     { name         => 'but_i_can\'t_hide',
       terms        => ['drake$', '^patrick', '[0-57-9]'],
       method       => 'escape',
       description  => "Note: apostrophe in the name",
       modifiers    => "xi",
     } );
   $filter_storage->save( $filters->[3] );

  # Try using a different storage handle to read them back in
  my $filter_storage_read = $class->new({ storage=> [ $stash_file ] });

  my $filters_read = [];
  $filters_read->[0] = $filter_storage_read->lookup( 'skip_boring_stuff' );
  $filters_read->[1] = $filter_storage_read->lookup( 'alpha' );

  my @r = trap {
    $filters_read->[2] = $filter_storage_read->lookup( '_you_can\'t_see_meee' );
  };
  my $expected_errmess =
    qr{^Failed \s+ lookup \s+ of \s+ filter \s+ with \s+ name: \s+ _you_can\'t_see_meee \b}x;
  like ( $trap->stderr, qr/$expected_errmess/x,
         "Testing that filters with leading underscore names don't get stored in yaml." );

  $filters_read->[3] = $filter_storage_read->lookup( 'but_i_can\'t_hide' );


  # these three should match (only 2 should be a failed lookup)
  foreach my $i (0, 1, 3) {
    my $name = $filters->[ $i ]->name;
    foreach my $attribute ('method', 'description', 'modifiers', 'name') {
      is( $filters->[ $i ]->$attribute, $filters_read->[ $i ]->$attribute,
          "$attribute matches after save/lookup of filter $name (yaml)" );
    }

    my $attribute = 'terms';
    is_deeply( $filters->[ $i ]->$attribute, $filters_read->[ $i ]->$attribute,
               "$attribute matches after save/lookup of filter $name (yaml)" );
  }
}

# repeat the block of tests with a db instead of a yaml file
SKIP:
{ my $test_name = "Saving filters to an SQLite database";
  eval { require DBD::SQLite };

  my $how_many = 3;
  skip "DBD::SQLite not installed", $how_many if $@;

  my $test_loc         = "$temp_loc/testE";
  mkpath( $test_loc );
  my $test_loc_bonepile   = "$temp_loc/testE/Old";
  mkpath( $test_loc_bonepile );

  my $dbfile = "$test_loc/filters.sqlite";

  # get rid of existing dbfile, but keep last run's version around
  move( $dbfile, $test_loc_bonepile ) if -e $dbfile;

  my $connect_to = "dbi:SQLite:dbname=$dbfile";
  my $owner      = '';
  my $password   = '';

  my $filter_storage = $class->new(
      { storage=>
        [
          { format     => 'DBI',
            connect_to => $connect_to,
            owner      => $owner,
            password   => $password,
          }
        ] ,
      });

  my $filters = [];
   $filters->[0] = List::Filter->new(
     { name         => 'skip_boring_stuff',
       terms        => ['-\.vb$', '\-.js$'],
       method       => 'skip_boring_stuff',
       description  => "Skip the really boring stuff",
       modifiers    => "xi",
     } );

   $filter_storage->save( $filters->[0] );

   my $args = {
         name         => 'alpha',
         terms        => ['^A', '^0', '^1'],
         method       => 'match_any',
         description  => "Find the beginning at the beginning",
         modifiers    => "xi",
      };

   $filters->[1] = List::Filter->new( $args );

   $filter_storage->save( $filters->[1] );

   $filters->[2] = List::Filter->new(
     { name         => 'nada',
       terms        => ['^.*$', '0', 'nada', '', 'bupkes'],
       method       => 'match_nuttin',
       description  => "Being silly",
       modifiers    => "xi",
     } );

   $filter_storage->save( $filters->[2] );

  my $name    = "alpha";
  my $filter = $filter_storage->lookup( $name );

  is(  $filter->description,  $args->{description},
     "$test_name: read description from saved filter alpha ");
  is( $filter->method,       $args->{method},
     "$test_name: read method from saved filter alpha ");
  is_deeply( $filter->terms,  $args->{terms},
     "$test_name: read terms from saved filter alpha ");
} # end skip 3 DBD::SQLite not installed

{ my $test_name = "Filter creation, stored in memory";

  my $filter_storage = $class->new(
      { storage=>
        [
          { format     => 'MEM',
            connect_to => {},
          }
        ] });

  my $filters = [];
   $filters->[0] = List::Filter->new(
     { name         => 'skip_boring_stuff',
       terms        => ['-\.vb$', '\-.js$'],
       method       => 'skip_boring_stuff',
       description  => "Skip the really boring stuff",
       modifiers    => "xi",
     } );

   $filter_storage->save( $filters->[0] );

   my $args = {
         name         => 'alpha',
         terms        => ['^A', '^0', '^1'],
         method       => 'match_any',
         description  => "Find the beginning at the beginning",
         modifiers    => "xi",
      };

   $filters->[1] = List::Filter->new( $args );

   $filter_storage->save( $filters->[1] );

   $filters->[2] = List::Filter->new(
     { name         => 'nada',
       terms        => ['^.*$', '0', 'nada', '', 'bupkes'],
       method       => 'match_nuttin',
       description  => "Being silly",
       modifiers    => "xi",
     } );

   $filter_storage->save( $filters->[2] );


  my $name    = "alpha";
  my $filter = $filter_storage->lookup( $name );

  is(         $filter->description,  $args->{description},
     "$test_name: read description from saved filter alpha ");
  is(         $filter->method,       $args->{method},
     "$test_name: read method from saved filter alpha ");
  is_deeply( $filter->terms,  $args->{terms},
     "$test_name: read terms from saved filter alpha ");
}

{ my $test_name = "Testing transform storage:";

  my $test_loc = "$temp_loc/testF/.list-filter";
  mkpath( $test_loc );

  my $test_terms = [ [qr{pointy-haired \s+ boss}, 'i', 'esteemed leader' ],
                     [qr{kill},                   '' , 'reward' ],
                     [qr{Kill},                   '' , 'Reward' ],
                     [qr{attack at midnight},     '' , 'go out for donuts' ],
                   ];

  my $name = 'sanitize_email';
  my $transform = List::Filter::Transform->new(
     {
        terms        => \@{ $test_terms }, # aref to copy of contents of aref
        name         => $name,
        method       => 'sequential',
        description  => "remove dangerous phrases",
        modifiers    => "x",
     }
  );

  { my $testcase = "save to a yaml file";
    my $stash_file  = "$test_loc/transforms.yaml";

    # erase output from previous runs
    if (-e $stash_file) {
      unlink( $stash_file );
    }

    my $storage_tran = List::Filter::Storage->new(
                                { storage => [ $stash_file ],
                                  type    => 'transform',
                                } );

    $storage_tran->save( $transform );

    # creating a new handle to read from
    my $storage_tran_read = List::Filter::Storage->new(
                                { storage => [ $stash_file ],
                                  type    => 'transform',
                                } );

    my $transform_2 = $storage_tran_read->lookup( $name );

    my $retrieved_class = ref( $transform_2 );
    my $expected_class = 'List::Filter::Transform';
    is($retrieved_class, $expected_class, "$test_name: retrieved object of expected type");

    is( $transform_2->description,  "remove dangerous phrases",
        "$test_name: read description from saved transform $name ");
    is( $transform_2->method, 'sequential',
        "$test_name: read method from saved transform $name ");
    is( $transform_2->modifiers, 'x',
        "$test_name: read modifiers from saved transform $name ");
    is( $transform_2->name, 'sanitize_email',
        "$test_name: read name from saved transform $name ");

    is_deeply( $transform_2->terms, \@{ $test_terms },
               "$test_name: read terms from saved transform $name ");
  }

 { my $testcase = "second lookup from the same yaml file";
   my $stash_file  = "$test_loc/transforms.yaml";

   my $storage = List::Filter::Storage->new(
                                { storage => [ $stash_file ],
                                  type    => 'transform',
                                } );

   my $name = 'sanitize_email';
   my $transform_3 = $storage->lookup( $name );

   my $retrieved_class = ref( $transform_3 );
   my $expected_class = 'List::Filter::Transform';
   is($retrieved_class, $expected_class, "$test_name: retrieved object of expected type");

   my $method = $transform_3->method;
   my $expected_method = "sequential";
   is ($method, $expected_method,
       "$test_name: read expected method, 'sequential'");

   my $terms = $transform_3->terms;
   is_deeply( $terms, $test_terms,
              "$test_name: $testcase: read expected terms");

   my $modifiers = $transform_3->modifiers;
   is ($modifiers, 'x',
       "$test_name: $testcase: read expected modifiers");

   my $description = $transform_3->description;
   is ($description, "remove dangerous phrases",
       "$test_name: $testcase: read expected description");
 }

 SKIP:
  { my $testcase  = "Saving transforms to an SQLite database";

    eval { require DBD::SQLite };

    my $how_many = 5;
    skip "DBD::SQLite not installed", $how_many if $@;

    my $test_loc   = "$temp_loc/testG/sqlite";
    mkpath( "$test_loc" );
    my $test_loc_bonepile   = "$test_loc/Old";
    mkpath( $test_loc_bonepile );

    my $dbfile = "$test_loc/transforms.sqlite";

    # get rid of existing dbfile, but keep last run's version around
    move( $dbfile, $test_loc_bonepile ) if -e $dbfile;

    my $connect_to = "dbi:SQLite:dbname=$dbfile";
    my $owner      = '';
    my $password   = '';

    my $tranh = List::Filter::Storage->new(
                          { storage =>
                            [
                             { format     => 'DBI',
                               connect_to => $connect_to,
                               owner      => $owner,
                               password   => $password,
                             },
                            ],
                            type => 'transform',
                          });
    $tranh->save( $transform );

    my $name = 'sanitize_email';
    my $transform2 = $tranh->lookup( $name );

    my $retrieved_class = ref( $transform2 );
    my $expected_class = 'List::Filter::Transform';
    is($retrieved_class, $expected_class, "$test_name: retrieved object of expected type");

    my $method = $transform2->method;
    my $expected_method = "sequential";
    is ($method, $expected_method,
        "$test_name:$testcase  read expected method, 'sequential'");

    my $terms = $transform2->terms;
    is_deeply( $terms, $test_terms,
               "$test_name:$testcase  read expected terms");

    my $modifiers = $transform2->modifiers;
    is ($modifiers, 'x',
        "$test_name:$testcase  read expected modifiers");

    my $description = $transform2->description;
    is ($description, "remove dangerous phrases",
        "$test_name:$testcase  read expected description");
  } # end skip *5* DBD::SQLite not installed
}

{ my $test_name = "Testing lookup from filter standard libraries";

  my $lfs = List::Filter::Storage->new(
      { storage=>
        [
          { format     => 'CODE',
          }
        ] });

  my $lookup_name = ':jpeg';
  my $filter = $lfs->lookup( $lookup_name );
  # ($DEBUG) && print STDERR "retrieved filter:\n", Dumper( $filter ), "\n";

  my $name          = $filter->name;
  my $terms         = $filter->terms;
  my $description   = $filter->description;
  my $modifiers     = $filter->modifiers;
  my $method        = $filter->method;

  is( $name, $lookup_name, "$test_name: got filter object with right name attribute");
  is( $method, "find_any", "$test_name: got filter object with right method attribute");
  # current description: 'Find jpegs, for all common extensions.'
  like( $description, qr{ \b find \b .*? \b jpegs \b .*? \b common \s+ extensions \b  }ix,
       "$test_name: description attribute of filter object looks good");

  my $regexp_unmod  = join( '|', @{ $terms } );
  my $pat = '(?' . $modifiers  . ')' . $regexp_unmod;
  ($DEBUG) && print STDERR "regexp_unmod: $regexp_unmod, pat: $pat\n";

  my @img_filenames = qw( bogus.jpg IMG_666.JPG not_a.jpeg );
  foreach my $file (@img_filenames) {
    like( $file, qr{$pat}, "$test_name: :jpeg patterns seem to match $file");
  }
  my @rnd_filenames = qw( something.txt gotme.jpegged JPG.LIST );

  foreach my $file (@rnd_filenames) {
    unlike( $file, qr{$pat}, "$test_name: :jpeg patterns do not match $file" );
  }
}

{ my $test_name = "Testing list_filters from CODE storage format.";
  my $lfs = List::Filter::Storage->new(
      { storage=>
        [
          { format     => 'CODE',
          }
        ] });

  my @some_expected_filters = (
                               ':jpeg',
                               ':c-omit',
                               ':skipdull',
                               ':hide_vc',
                               ':dired-x-omit',
                               ':web_img',
                              );

  my $all_filters = $lfs->list_filters();
  ($DEBUG) && print STDERR Dumper($all_filters), "\n";

  my @found = ();
  foreach my $expected ( @some_expected_filters ) {
    foreach my $actual ( @{ $all_filters } ) {
      if ( $actual eq $expected ) {
        push @found, $actual;
        last;
      }
    }
  }

  my $count = scalar( @some_expected_filters );
  is_deeply( [ sort( @found ) ], [ sort( @some_expected_filters ) ],
             "$test_name: found all $count filters we looked for");
}

{ my $test_name = "Testing list_filters from non-standard CODE storage module.";
  my $dummy_lib_loc = "$Bin/dat/storage/code/lib";

  local @INC = @INC;
  unshift(@INC, "$dummy_lib_loc");

  # List::Filter::Storage
  my $lfs = $class->new(
      { storage=>
        [
          { format     => 'CODE',
            connect_to => [ 'List::Filter::Library::FileSystem::Not::Not::Not' ],
          }
        ],
        type => 'filter',

      });

  my $expected_filters = [ sort( @{ [
          ':jpeg',
          ':compile',
          ':updatedb_prune',
          ':skipdull',
          ':dired-x-omit',
          ':web_img',
          ':doom-omit',
          ':nada',
          ':allski',
        ] } ) ];

  my $all_filters = $lfs->list_filters();

  my $all_filters_sorted = [ sort( @{ $all_filters } ) ];

  ($DEBUG) && print STDERR Dumper($all_filters), "\n";
  is_deeply( $all_filters_sorted, $expected_filters, $test_name);
}

{ my $test_name = "Testing lookup from transform standard libraries";

  my $lfs = List::Filter::Storage->new(
      { type => 'transform',
        storage=>
        [
         { format     => 'CODE',
         }
        ] });

  my $lookup_name = ':dwim_upcaret';
  my $filter = $lfs->lookup( $lookup_name );
  ($DEBUG) && print STDERR "retrieved transform:\n", Dumper( $filter ), "\n";

  my $name          = $filter->name;
  my $terms         = $filter->terms;
  my $description   = $filter->description;
  my $modifiers     = $filter->modifiers;
  my $method        = $filter->method;

  is( $name, $lookup_name, "$test_name: got filter object with right name attribute");
  is( $method, "sequential", "$test_name: got filter object with right method attribute");
  # description: 'leading \'^\' converted to \\b, unless it\'s \'^/\' or \'^~\''
  like( $description, qr{ \b leading \b .*? \^ .*? \b converted \s+ to \b .*? \\b \b }ix,
       "$test_name: description attribute of filter object looks good");

  my $pat = $terms->[0][0];
  my $mod = $terms->[0][1];
  my $rep = $terms->[0][2];

  ($DEBUG) && print STDERR "pat: $pat, mod: $mod, rep: $rep\n";

  my $ex_pat = ' ^ \\^ (?![/~]) | (?<=\\|) \\^ (?![/~]) ';
  my $ex_mod = 'xg';
  my $ex_rep = '\\b';

  is ($pat, $ex_pat, "$test_name: got expected the dwim_upcaret pattern");
  is ($mod, $ex_mod, "$test_name: got expected dwim_upcaret mods");
  is ($rep, $ex_rep, "$test_name: got expected dewim_upcaret replace string");
}

###
# heredoc ghetto

sub define_testb_stash_1 {
  my $subname = ( caller(0) )[3];

my $yaml = <<'END_YAML_1';
---
doom_filter:
  description: 'The usual file filtering - skips "old", "bak", emacs backups, etc'
  terms:
    - '~$'
    - /\#
    - ',v$'
    - \.elc$
    - \bold
    - \bOld
    - \bOLD
    - bak$
    - Bak$
    - BAK$
  method: skip_any

END_YAML_1

  my $data = YAML::Load($yaml);

  ($DEBUG) && print STDERR "$subname: data: $data\n";
  return $data;
}

sub define_testb_stash_2 {
  my $subname = ( caller(0) )[3];
  my $yaml =<<'END_YAML_2';
---
final_select:
  description: 'The usual file filtering - skips "old", "bak", emacs backups, etc'
  terms:
    - '~$'
    - /\#
    - ',v$'
    - \.elc$
    - \bold
    - \bgah
    - \bgeh
    - \bOld
    - \bOLD
    - bak$
    - Bak$
    - BAK$
  method: nonexistent

END_YAML_2

  my $data = YAML::Load($yaml);
  ($DEBUG) && print STDERR "$subname: data: $data\n";
  return $data;
}

# end of List-Filter-Storage.t
