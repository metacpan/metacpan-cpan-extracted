#!perl -w
#       $Id$

use strict;
use Test::More tests => 43;

my $class;
my @tests = qw( t/File-Find-Rule.t t/findrule.t );
BEGIN {
    $class = 'File::Find::Rule';
    use_ok($class)
}

# on win32 systems the t/foobar file isn't 10 bytes it's 11, so the
# previous tests on the magic number 10 failed.  rt.cpan.org #3838
my $foobar_size = -s 't/foobar';

my $f = $class->new;
isa_ok($f, $class);


# name
$f = $class->name( qr/\.t$/ );
is_deeply( [ sort $f->in('t') ],
           [ @tests ],
           "name( qr/\\.t\$/ )" );

$f = $class->name( 'foobar' );
is_deeply( [ $f->in('t') ],
           [ 't/foobar' ],
           "name( 'foobar' )" );

$f = $class->name( '*.t' );
is_deeply( [ sort $f->in('t') ],
          \@tests,
          "name( '*.t' )" );

$f = $class->name( 'foobar', '*.t' );
is_deeply( [ sort $f->in('t') ],
           [ @tests, 't/foobar' ],
           "name( 'foobar', '*.t' )" );

$f = $class->name( [ 'foobar', '*.t' ] );
is_deeply( [ sort $f->in('t') ],
           [ @tests, 't/foobar' ],
           "name( [ 'foobar', '*.t' ] )" );



# exec
$f = $class->exec(sub { length == 6 })->maxdepth(1);
is_deeply( [ $f->in('t') ],
           [ 't/foobar' ],
           "exec (short)" );

$f = $class->exec(sub { length > $foobar_size })->maxdepth(1);
is_deeply( [ $f->in('t') ],
           [ 't/File-Find-Rule.t' ],
           "exec (long)" );

is_deeply( [ find( maxdepth => 1, exec => sub { $_[2] eq 't/foobar' }, in => 't' ) ],
           [ 't/foobar' ],
           "exec (check arg 2)" );

# name and exec, chained
$f = $class
  ->exec(sub { length > $foobar_size })
  ->name( qr/\.t$/ );

is_deeply( [ $f->in('t') ],
           [ 't/File-Find-Rule.t' ],
           "exec(match) and name(match)" );

$f = $class
  ->exec(sub { length > $foobar_size })
  ->name( qr/foo/ )
  ->maxdepth(1);

is_deeply( [ $f->in('t') ],
           [ ],
           "exec(match) and name(fail)" );


# directory
$f = $class
  ->directory
  ->maxdepth(1)
  ->exec(sub { $_ !~ /(\.svn|CVS)/ }); # ignore .svn/CVS dirs

is_deeply( [ $f->in('t') ],
           [ qw( t t/lib  ) ],
           "directory autostub" );


# any/or
$f = $class->any( $class->exec( sub { length == 6 } ),
                  $class->name( qr/\.t$/ )
                        ->exec( sub { length > $foobar_size } )
                )->maxdepth(1);

is_deeply( [ sort $f->in('t') ],
           [ 't/File-Find-Rule.t', 't/foobar' ],
           "any" );

$f = $class->or( $class->exec( sub { length == 6 } ),
                 $class->name( qr/\.t$/ )
                       ->exec( sub { length > $foobar_size } )
               )->maxdepth(1);

is_deeply( [ sort $f->in('t') ],
           [ 't/File-Find-Rule.t', 't/foobar' ],
           "or" );


# not/none
$f = $class
  ->file
  ->not( $class->name( qr/^[^.]{1,8}(\.[^.]{0,3})?$/ ) )
  ->maxdepth(1)
  ->exec(sub { length == 6 || length > 10 });
is_deeply( [ $f->in('t') ],
           [ 't/File-Find-Rule.t' ],
           "not" );

# not as not_*
$f = $class
  ->file
  ->not_name( qr/^[^.]{1,8}(\.[^.]{0,3})?$/ )
  ->maxdepth(1)
  ->exec(sub { length == 6 || length > 10 });
is_deeply( [ $f->in('t') ],
           [ 't/File-Find-Rule.t' ],
           "not_*" );

# prune/discard (.svn demo)
# this test may be a little meaningless for a cpan release, but it
# fires perfectly in my dev sandbox
$f = $class->or( $class->directory
                        ->name(qr/(\.svn|CVS)/)
                        ->prune
                        ->discard,
                 $class->new->file );

is_deeply( [ sort $f->in('t') ],
           [ @tests, 't/foobar', 't/lib/File/Find/Rule/Test/ATeam.pm' ],
           "prune/discard .svn"
         );


# procedural form of the CVS demo
$f = find(or => [ find( directory =>
                        name      => qr/(\.svn|CVS)/,
                        prune     =>
                        discard   => ),
                  find( file => ) ]);

is_deeply( [ sort $f->in('t') ],
           [ @tests, 't/foobar', 't/lib/File/Find/Rule/Test/ATeam.pm' ],
           "procedural prune/discard .svn"
         );

# size (stat test)
is_deeply( [ find( maxdepth => 1, file => size => $foobar_size, in => 't' ) ],
           [ 't/foobar' ],
           "size $foobar_size (stat)" );

is_deeply( [ find( maxdepth => 1, file => size => "<= $foobar_size",
                   in => 't' ) ],
           [ 't/foobar' ],
           "size <= $foobar_size (stat)" );

is_deeply( [ find( maxdepth => 1, file => size => "<".($foobar_size + 1),
                   in => 't' ) ],
           [ 't/foobar' ],
           "size <($foobar_size + 1) (stat)" );

is_deeply( [ find( maxdepth => 1, file => size => "<1K",
                   exec => sub { length == 6 },
                   in => 't' ) ],
           [ 't/foobar' ],
           "size <1K (stat)" );

is_deeply( [ find( maxdepth => 1, file => size => ">3K", in => 't' ) ],
           [ 't/File-Find-Rule.t' ],
           "size >3K (stat)" );

# these next two should never fail.  if they do then the testing fairy
# went mad
is_deeply( [ find( file => size => ">3M", in => 't' ) ],
           [ ],
           "size >3M (stat)" );

is_deeply( [ find( file => size => ">3G", in => 't' ) ],
           [ ],
           "size >3G (stat)" );


#min/maxdepth

is_deeply( [ find( maxdepth => 0, in => 't' ) ],
           [ 't' ],
           "maxdepth == 0" );



my $rule = find( or => [ find( name => qr/(\.svn|CVS)/,
                               discard =>),
                         find(),
                        ],
                 maxdepth => 1 );

is_deeply( [ sort $rule->in( 't' ) ],
           [ 't', @tests, 't/foobar', 't/lib' ],
           "maxdepth == 1" );
is_deeply( [ sort $rule->in( 't/' ) ],
           [ 't', @tests, 't/foobar', 't/lib' ],
           "maxdepth == 1, trailing slash on the path" );

is_deeply( [ sort $rule->in( './t' ) ],
           [ 't', @tests, 't/foobar', 't/lib' ],
           "maxdepth == 1, ./t" );

is_deeply( [ sort $rule->in( './/t' ) ],
           [ 't', @tests, 't/foobar', 't/lib' ],
           "maxdepth == 1, .//t" );

is_deeply( [ sort $rule->in( './//t' ) ],
           [ 't', @tests, 't/foobar', 't/lib' ],
           "maxdepth == 1, .///t" );

is_deeply( [ sort $rule->in( './././///./t' ) ],
           [ 't', @tests, 't/foobar', 't/lib' ],
           "maxdepth == 1, ./././///./t" );

my @ateam_path = qw( t/lib
                     t/lib/File
                     t/lib/File/Find
                     t/lib/File/Find/Rule
                     t/lib/File/Find/Rule/Test
                     t/lib/File/Find/Rule/Test/ATeam.pm );

is_deeply( [ sort +find( or => [ find( name => qr/(\.svn|CVS)/,
                                       prune =>
                                       discard =>),
                                 find( ),
                               ],
                         mindepth => 1,
                         in => 't' ) ],
           [ @tests, 't/foobar', @ateam_path ],
           "mindepth == 1" );


is_deeply( [ sort +find( or => [ find( name => qr/(\.svn|CVS)/,
                                       discard =>),
                                 find(),
                               ],
                         maxdepth => 1,
                         mindepth => 1,
                         in => 't' ) ],
           [ @tests, 't/foobar', 't/lib' ],
           "maxdepth = 1 mindepth == 1" );

# extras
my $ok = 0;
find( extras => { preprocess => sub { $ok = 1 } }, in => 't' );
ok( $ok, "extras preprocess fired" );

#iterator
$f = find( or => [ find( name => qr/(\.svn|CVS)/,
                         prune =>
                         discard =>),
                   find(),
                 ],
           start => 't' );

{
my @found;
while ($_ = $f->match) { push @found, $_ }
is_deeply( [ sort @found ], [ 't', @tests, 't/foobar', @ateam_path ], "iterator" );
}

# negating in the procedural interface
is_deeply( [ find( file => '!name' => qr/^[^.]{1,8}(\.[^.]{0,3})?$/,
                   maxdepth => 1,
                   in => 't' ) ],
           [ 't/File-Find-Rule.t' ],
           "negating in the procedural interface" );

# grep
is_deeply( [ find( maxdepth => 1, file => grep => [ qr/bytes./, [ qr/.?/ ] ], in => 't' ) ],
           [ 't/foobar' ],
           "grep" );



# relative
is_deeply( [ find( 'relative', maxdepth => 1, name => 'foobar', in => 't' ) ],
           [ 'foobar' ],
           'relative' );



# bootstrapping extensions via import

use lib qw(t/lib);

eval { $class->import(':Test::Elusive') };
like( $@, qr/^couldn't bootstrap File::Find::Rule::Test::Elusive/,
      "couldn't find the Elusive extension" );

eval { $class->import(':Test::ATeam') };
is ($@, "",  "if you can find them, maybe you can hire the A-Team" );
can_ok( $class, 'ba' );
