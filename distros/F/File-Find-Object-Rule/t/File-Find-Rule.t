#!perl
#       $Id: /mirror/lab/perl/File-Find-Rule/t/File-Find-Rule.t 2100 2006-05-28T16:06:50.725367Z richardc  $

use strict;
use warnings;

use Test::More tests => 42;

use lib './t/lib';

use File::Find::Object::TreeCreate;

use File::Path;

my $tree_creator = File::Find::Object::TreeCreate->new();

{
    my $tree =
    {
        'name' => "FFRt-to/",
        'subs' =>
        [
            {
                'name' => "File-Find-Rule.t",
                'contents' => $tree_creator->cat(
                    "./t/sample-data/to-copy-from/File-Find-Rule.t"
                ),
            },
            {
                'name' => "findorule.t",
                'contents' => $tree_creator->cat(
                    "./t/sample-data/to-copy-from/findorule.t"
                ),
            },
            {
                'name' => "foobar",
                'contents' => $tree_creator->cat(
                    "./t/sample-data/to-copy-from/foobar"
                ),

            },
            {
                'name' => "lib/",
                'subs' =>
                [
                    {
                        'name' => "File/",
                        'subs' =>
                        [
                            {
                                name => "Find/",
                                subs =>
                                [
                                    {
                                        name => "Object/",
                                        subs =>
                                        [
                                            {
                                                name => "Rule/",
                                                subs =>
                                                [
                                                    {
                                                        name => "Test/",
                                                        subs =>
                                                        [
                                                        {
                                                            name => "ATeam.pm",
content => $tree_creator->cat(
    "./t/sample-data/to-copy-from/lib/File/Find/Object/Rule/Test/ATeam.pm"

),
}
                                                        ],
                                                    },
                                                ],
                                            }
                                        ],
                                    },
                                ],
                            },
                        ],
                    },
                ],
            },
        ],
    };

    $tree_creator->create_tree("./t/sample-data/", $tree);
}

my $class;
my $copy_fn = $tree_creator->get_path(
    "./t/sample-data/FFRt-to/"
);

my $lib_fn = $tree_creator->get_path(
    "./t/sample-data/FFRt-to/lib/"
);

my $FFR_t = $tree_creator->get_path(
    "./t/sample-data/FFRt-to/File-Find-Rule.t"
);
my $findorule_t = $tree_creator->get_path(
    "./t/sample-data/FFRt-to/findorule.t"
);
my $foobar_fn = $tree_creator->get_path(
    "./t/sample-data/FFRt-to/foobar"
);

my @tests = ($FFR_t, $findorule_t);

my @ateam_path =
    map { $tree_creator->get_path("./t/sample-data/FFRt-to/$_") }
    qw(
        lib
        lib/File
        lib/File/Find
        lib/File/Find/Object
        lib/File/Find/Object/Rule
        lib/File/Find/Object/Rule/Test
        lib/File/Find/Object/Rule/Test/ATeam.pm
    );

my $ATeam_pm_fn = $ateam_path[-1];

BEGIN {
    $class = 'File::Find::Object::Rule';
    # TEST
    use_ok($class)
}


# on win32 systems the t/foobar file isn't 10 bytes it's 11, so the
# previous tests on the magic number 10 failed.  rt.cpan.org #3838
my $foobar_size = -s $foobar_fn;

my $f = $class->new;
# TEST
isa_ok($f, $class);

sub _run_find
{
    my $finder = shift;
    return [ sort $finder->in($copy_fn) ];
}

# name
$f = $class->name( qr/\.t$/ );
# TEST
is_deeply( _run_find($f),
           [ @tests ],
           "name( qr/\\.t\$/ )" );

{
    # This test that starts returns the rule object.
    # See: http://www.nntp.perl.org/group/perl.beginners/2012/04/msg120670.html
    my $rule = $class->name( qr/\.t$/ )->start($copy_fn);

    my @results;
    while (my $item = $rule->match()) {
        push @results, $item;
    }
    # TEST
    is_deeply(
        [ @results ],
        [ @tests ],
        "->start() Test."
    );
}

$f = $class->name( 'foobar' );
# TEST
is_deeply( _run_find($f),
           [ $foobar_fn ],
           "name( 'foobar' )" );

$f = $class->name( '*.t' );
# TEST
is_deeply( _run_find($f),
          \@tests,
          "name( '*.t' )" );

$f = $class->name( 'foobar', '*.t' );
# TEST
is_deeply( _run_find($f),
           [ @tests, $foobar_fn ],
           "name( 'foobar', '*.t' )" );

$f = $class->name( [ 'foobar', '*.t' ] );
# TEST
is_deeply( _run_find($f),
           [ @tests, $foobar_fn ],
           "name( [ 'foobar', '*.t' ] )" );



# exec
$f = $class->exec(sub { length($_[0]) == 6 })->maxdepth(1);
# TEST
is_deeply( _run_find($f),
           [ $foobar_fn ],
           "exec (short)" );

$f = $class->exec(sub { length($_[0]) > $foobar_size })->maxdepth(1);
# TEST
is_deeply( _run_find($f),
           [ $FFR_t ],
           "exec (long)" );

# TEST
is_deeply( [ find( maxdepth => 1, exec => sub { $_[2] eq $foobar_fn }, in => $copy_fn ) ],
           [ $foobar_fn ],
           "exec (check arg 2)" );

# name and exec, chained
$f = $class
  ->exec(sub { length > $foobar_size })
  ->name( qr/\.t$/ );

# TEST
is_deeply( _run_find($f),
           [ $FFR_t ],
           "exec(match) and name(match)" );

$f = $class
  ->exec(sub { length > $foobar_size })
  ->name( qr/foo/ )
  ->maxdepth(1);

# TEST
is_deeply( _run_find($f),
           [ ],
           "exec(match) and name(fail)" );


# directory
$f = $class
  ->directory
  ->maxdepth(1)
  ->exec(sub { $_ !~ /(\.svn|CVS)/ }); # ignore .svn/CVS dirs

# TEST
is_deeply( _run_find($f),
           [ $copy_fn,$lib_fn,],
           "directory autostub" );


# any/or
$f = $class->any( $class->exec( sub { length == 6 } ),
                  $class->name( qr/\.t$/ )
                        ->exec( sub { length > $foobar_size } )
                )->maxdepth(1);

# TEST
is_deeply( _run_find($f),
           [ $FFR_t, $foobar_fn ],
           "any" );

$f = $class->or( $class->exec( sub { length == 6 } ),
                 $class->name( qr/\.t$/ )
                       ->exec( sub { length > $foobar_size } )
               )->maxdepth(1);

# TEST
is_deeply( _run_find($f),
           [ $FFR_t, $foobar_fn ],
           "or" );


# not/none
$f = $class
  ->file
  ->not( $class->name( qr/^[^.]{1,8}(\.[^.]{0,3})?$/ ) )
  ->maxdepth(1)
  ->exec(sub { length == 6 || length > 11 });
# TEST
is_deeply( _run_find($f),
           [ $FFR_t ],
           "not" );

# not as not_*
$f = $class
  ->file
  ->not_name( qr/^[^.]{1,8}(\.[^.]{0,3})?$/ )
  ->maxdepth(1)
  ->exec(sub { length == 6 || length > 11 });
# TEST
is_deeply( _run_find($f),
           [ $FFR_t ],
           "not_*" );

# prune/discard (.svn demo)
# this test may be a little meaningless for a cpan release, but it
# fires perfectly in my dev sandbox
$f = $class->or( $class->directory
                        ->name(qr/(\.svn|CVS)/)
                        ->prune
                        ->discard,
                 $class->new->file );

# TEST
is_deeply( _run_find($f),
           [ @tests, $foobar_fn, $ATeam_pm_fn ],
           "prune/discard .svn"
         );


# procedural form of the CVS demo
$f = find(or => [ find( directory =>
                        name      => qr/(\.svn|CVS)/,
                        prune     =>
                        discard   => ),
                  find( file => ) ]);

# TEST
is_deeply( _run_find($f),
           [ @tests, $foobar_fn, $ATeam_pm_fn ],
           "procedural prune/discard .svn"
         );

# size (stat test)
# TEST
is_deeply( [ find( maxdepth => 1, file => size => $foobar_size, in => $copy_fn, ) ],
           [ $foobar_fn ],
           "size $foobar_size (stat)" );

# TEST
is_deeply( [ find( maxdepth => 1, file => size => "<= $foobar_size",
                   in => $copy_fn ) ],
           [ $foobar_fn ],
           "size <= $foobar_size (stat)" );
# TEST
is_deeply( [ find( maxdepth => 1, file => size => "<".($foobar_size + 1),
                   in => $copy_fn ) ],
           [ $foobar_fn ],
           "size <($foobar_size + 1) (stat)" );

# TEST
is_deeply( [ find( maxdepth => 1, file => size => "<1K",
                   exec => sub { length == 6 },
                   in => $copy_fn ) ],
           [ $foobar_fn ],
           "size <1K (stat)" );

# TEST
is_deeply( [ find( maxdepth => 1, file => size => ">3K", in => $copy_fn ) ],
           [ $FFR_t ],
           "size >3K (stat)" );

# these next two should never fail.  if they do then the testing fairy
# went mad
# TEST
is_deeply( [ find( file => size => ">3M", in => $copy_fn ) ],
           [ ],
           "size >3M (stat)" );

# TEST
is_deeply( [ find( file => size => ">3G", in => $copy_fn ) ],
           [ ],
           "size >3G (stat)" );


#min/maxdepth

# TEST
is_deeply( [ find( maxdepth => 0, in => $copy_fn ) ],
           [ $copy_fn ],
           "maxdepth == 0" );



my $rule = find( or => [ find( name => qr/(\.svn|CVS)/,
                               discard =>),
                         find(),
                        ],
                 maxdepth => 1 );

# TEST
is_deeply( _run_find($rule),
           [ $copy_fn, @tests, $foobar_fn, $lib_fn ],
           "maxdepth == 1" );
# TEST
is_deeply( _run_find($rule),
           [ $copy_fn, @tests, $foobar_fn, $lib_fn ],
           "maxdepth == 1, trailing slash on the path" );

# TEST
is_deeply( _run_find($rule),
           [ $copy_fn, @tests, $foobar_fn, $lib_fn ],
           "maxdepth == 1, ./t" );
# TEST
is_deeply( _run_find($rule),
           [ $copy_fn, @tests, $foobar_fn, $lib_fn ],
           "maxdepth == 1, ./././///./t" );

# TEST
is_deeply( [ sort +find( or => [ find( name => qr/(\.svn|CVS)/,
                                       prune =>
                                       discard =>),
                                 find( ),
                               ],
                         mindepth => 1,
                         in => $copy_fn, ) ],
           [ @tests, $foobar_fn, @ateam_path ],
           "mindepth == 1" );


# TEST
is_deeply( [ sort +find( or => [ find( name => qr/(\.svn|CVS)/,
                                       discard =>),
                                 find(),
                               ],
                         maxdepth => 1,
                         mindepth => 1,
                         in => $copy_fn, ) ],
           [ @tests, $foobar_fn, $lib_fn ],
           "maxdepth = 1 mindepth == 1" );

# extras
my $ok = 0;
find( extras => { preprocess => sub { my ($self, $list) = @_; $ok = 1; return $list; } }, in => $copy_fn );
# TEST
ok( $ok, "extras preprocess fired" );

#iterator
$f = find( or => [ find( name => qr/(\.svn|CVS)/,
                         prune =>
                         discard =>),
                   find(),
                 ],
           start => $copy_fn );

{
my @found;
while ($_ = $f->match) { push @found, $_ }
# TEST
is_deeply( [ sort @found ], [ $copy_fn, @tests, $foobar_fn, @ateam_path ], "iterator" );
}

# negating in the procedural interface
# TEST
is_deeply( [ find( file => '!name' => qr/^[^.]{1,9}(\.[^.]{0,3})?$/,
                   maxdepth => 1,
                   in => $copy_fn ) ],
           [ $FFR_t ],
           "negating in the procedural interface" );

# grep
# TEST
is_deeply( [ find( maxdepth => 1, file => grep => [ qr/bytes./, [ qr/.?/ ] ], in => $copy_fn ) ],
           [ $foobar_fn ],
           "grep" );



# relative
# TEST
is_deeply( [ find( 'relative', maxdepth => 1, name => 'foobar', in => $copy_fn ) ],
           [ 'foobar' ],
           'relative' );



# bootstrapping extensions via import

eval { $class->import(':Test::Elusive') };
# TEST
like( $@, qr/^couldn't bootstrap File::Find::Object::Rule::Test::Elusive/,
      "couldn't find the Elusive extension" );

eval { $class->import(':Test::ATeam') };
# TEST
is ($@, "",  "if you can find them, maybe you can hire the A-Team" );
# TEST
can_ok( $class, 'ba' );

rmtree($tree_creator->get_path("./t/sample-data/FFRt-to"));
