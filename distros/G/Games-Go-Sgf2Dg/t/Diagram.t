#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Go-Diagram.t'

#########################

use strict;
use IO::File;
use Test::More tests => 28;

BEGIN {
    use_ok('Games::Go::Sgf2Dg::Diagram')
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my ($diagram, $conflict);

sub conflictCallback {
    $conflict++;
}

##
## create diagram object:
##
eval { $diagram = Games::Go::Sgf2Dg::Diagram->new(
                    hoshi             => ['ba', 'cd'],
                    black             => ['ab'],
                    white             => ['dd', 'cd'],
                    callback          => \&conflictCallback,
                    enable_overstones => 1,
                    overstone_eq_mark => 1); };
is( $@, '',                                     'new Diagram object'  );
isa_ok( $diagram, 'Games::Go::Sgf2Dg::Diagram',         '   diagram is the right class'  );

is_deeply( $diagram->get('aa'), {
},                                              'initial get(aa)' );
is_deeply( $diagram->get('ba'), {
    color => 'hoshi',
    hoshi => 1,
},                                              'initial get(ba)' );
is_deeply( $diagram->get('dd'), {
    color => 'white',
    white => 1,
},                                              'initial get(dd)' );
is_deeply( $diagram->get('cd'), {
    hoshi => 1,
    color => 'white',
    white => 1,
},                                              'initial get(cd)' );
is_deeply( $diagram->get('ab'), {
    color => 'black',
    black => 1,
},                                              'initial get(ab)' );
is ( $diagram->put('ee', 'B', 3), 1,            'put black on ee' );
is_deeply( $diagram->get('ee'), {
},                                              'get(ee) (pre-node)' );
is ( $diagram->node, 2,                         'node 2' );
is_deeply( $diagram->get('ee'), {
    color => 'black',
    'black' => 1,
    'number' => 3
},                                              'get(ee) (post-node)' );
is ( $diagram->mark('ba', 'TR'), 2,             'mark ba' );
is ( $diagram->label('dd', 'w'), 2,             'mark dd' );
is ( $diagram->node, 3,                         'node 3' );
is_deeply( $diagram->get('ba'), {
    'hoshi' => 1,
    color => 'hoshi',
    'mark' => 'TR'
},                                              'get(ba) (post-node)' );
is_deeply( $diagram->get('dd'), {
    'label' => 'w',
    'w'     => 2,
    color => 'white',
    'white' => 1,
},                                              'get(dd) (post-node)' );
is ( $diagram->label('ee', 'a'), 0,             'mark ee' );
is ( $conflict, undef,                          'conflictCallback not called yet' );
is ( $diagram->node, 3,                         'node 3(conflict)' );
is ( $conflict, 1,                              'conflictCallback called' );
is_deeply ( $diagram->clear, {
   'actions' => [],
   'board' => {
      'ab' => {
         'black' => 0 },
      'ba' => {
         'hoshi' => 1 },
      'cd' => {
         'hoshi' => 1,
         'white' => 0 },
      'dd' => {
         'white' => 0 },
      'ee' => {
         'a' => 3,
         'black' => 0,
         'label' => 'a' },
     },
   'boardSizeX' => 19,
   'boardSizeY' => 19,
   'coord_style' => 'normal',
   'callback' => \&conflictCallback,
   'enable_overstones' => 1,
   'label' => {
      'a' => 3 },
   'node' => 4,
   'overstone_eq_mark' => 1,
   'provisional' => 1,
   'actions_done' => 0,
},                                              'clear diagram' );
is ( $diagram->renumber('cd', 'w', undef, 22), 1,
                                                'renumber cd' );
is ( $diagram->capture('dd'), 4,                'put overstone on dd' );
is ( $diagram->node, 5,                         'node 4' );
is ( $diagram->put('dd', 'Black', 24), 5,       'put overstone on dd' );
is ( $diagram->node, 6,                         'node 5' );
is_deeply ( $diagram, {
   'actions' => [],
   'board' => {
      'ab' => {
         'black' => 0 },
      'ba' => {
         'hoshi' => 1 },
      'cd' => {
         'hoshi' => 1,
         'number' => 22,
         'white' => 0 },
      'dd' => {
         'mark' => 'TR',
         'overstones' => [ 'black', 24],
         'white' => 0 },
      'ee' => {
         'a' => 3,
         'black' => 0,
         'label' => 'a' },
     },
   'boardSizeX' => 19,
   'boardSizeY' => 19,
   'coord_style' => 'normal',
   'callback' => \&conflictCallback,
   'enable_overstones' => 1,
   'label' => {
      'a' => 3 },
   'mark' => {
      'DEFAULT_MARK' => {
          'white' => 5},
       },
   'mark_count' => {
      'DEFAULT_MARK' => {
          'white' => 1},
       },
   'node' => 6,
   'number' => {
      22 => 4,
      24 => 5},
   'overlist' => [  {
         'mark' => 'TR',
         'overstones' => [ 'black', 24],
         'white' => 0 },
       ],
   'overstone_eq_mark' => 1,
   'provisional' => 1,
   'actions_done' => 1,
},                                              'overstone' );

##
## end of tests
##

__END__
