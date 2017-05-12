#!perl -w
use strict;
use Test::More tests => 6;
use File::Slurp::Tree;
use POSIX qw(strftime);

use File::Find::Rule::CVS;

# make a dummy sandbox
my $now = time;
my $past = $now - 60;
my $path = 't/sandbox';
spew_tree( $path => {
    CVS => {
        Entries => join( "",
                         map { # yuck
                             join( "/",
                                   '',
                                   $_->[0], $_->[1],
                                   strftime('%a %b %e %H:%M:%S %Y',
                                            gmtime $_->[2]),
                                   '', '' ) . "\n"
                         } ( [ 'same', '1.1',     $past ],
                             [ 'modified', '1.2', $past ]
                            )
                        ),

    },
    modified => "make like I'm modified\n",
    same     => "and I'll pretend to be the same\n",
    unknown  => "cvs won't know about me\n",
});
ok( utime( $past, $past, "$path/same" ),     "touch same" );
ok( utime( $now,  $now,  "$path/modified" ), "touch modified" );

is_deeply( [ find( file => cvs_modified => relative => in => $path ) ],
           [ 'modified' ],
          "cvs_modified" );

is_deeply( [ find( maxdepth => 1, file => cvs_unknown => relative => in => $path ) ],
           [ 'unknown' ],
          "cvs_unknown" );

is_deeply( [ find( file => cvs_version => '>1.1', relative => in => $path ) ],
           [ 'modified' ],
          "cvs_version" );

is_deeply( [ find( file => cvs_version => '1.2', relative => in => $path ) ],
           [ 'modified' ],
          "cvs_version" );
