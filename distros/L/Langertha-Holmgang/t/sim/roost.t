#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Langertha::Holmgang::Sim::Roost;
use Holmgang::TestSim qw( sims clone diff );

# Roost as an answer world without a device (k43, new, no model in
# cai-platform). Claims: it is a built-in answer world with three tools;
# survey_roost shows dragons, perches (free or taken) and larder and changes
# nothing; feed_dragon takes one basket out of the larder and appends it to
# the dragon's meals, whatever the dragon eats; move_dragon sets the perch,
# one dragon per perch, without comparing wingspan and span; names match
# without case and surrounding white space; every refused call answers
# "Error: ..." and changes nothing. The roost here is invented for this test.

my $R = 'Langertha::Holmgang::Sim::Roost';

subtest 'contract' => sub {
  ok( $R->does('Langertha::Holmgang::Role::AnswerWorld'), 'an answer world' );
  is( $R->device_type, 'roost', 'type roost' );
  ok( sims()->is_answer_world('roost'), 'built into the registry' );
  is_deeply( [ sort keys %{ sims()->world_tools('roost') } ], [qw( feed_dragon move_dragon survey_roost )], 'the three tools' );
  is_deeply( sims()->world_tools('roost')->{feed_dragon}, [qw( dragon food )], 'required parameters of feed_dragon' );
  is_deeply( sims()->world_tools('roost')->{move_dragon}, [qw( dragon perch )], 'required parameters of move_dragon' );
  is_deeply( sims()->world_tools('roost')->{survey_roost}, [], 'survey_roost needs none' );
};

my $start = {
  nest => {
    type    => 'roost',
    dragons => {
      cinder => { wingspan => 11, perch => 'tall-pine', eats => [qw( turnips )], meals => [] },
      gale   => { wingspan => 7,  perch => 'rock-shelf', eats => [qw( turnips kelp )] },
      pebble => { wingspan => 5,  eats => [] },
    },
    perches => {
      'tall-pine'  => { span => 12 },
      'rock-shelf' => { span => 8 },
      'cave-mouth' => { span => 6 },
    },
    larder => { turnips => 1, kelp => 0 },
  },
};

my $state;
sub fresh { $state = clone($start) }
sub t { my ( $name, %a ) = @_; return sims()->tool_call( $state, roost => $name, \%a ) }

subtest 'survey_roost' => sub {
  fresh();
  my ( $o, $ok ) = t('survey_roost');
  ok( $ok, 'answers' );
  is( $o, join( "\n",
    'Dragons:',
    '- cinder: wingspan 11, perch tall-pine, eats turnips, meals none',
    '- gale: wingspan 7, perch rock-shelf, eats turnips, kelp, meals none',
    '- pebble: wingspan 5, perch none, eats none, meals none',
    'Perches:',
    '- cave-mouth: span 6, free',
    '- rock-shelf: span 8, gale',
    '- tall-pine: span 12, cinder',
    'Larder:',
    '- kelp: 0 baskets',
    '- turnips: 1 basket',
  ), 'dragons, perches and larder, sorted' );
  is_deeply( [ diff( $start, $state ) ], [], 'changes nothing' );
  my ( $e ) = sims()->tool_call( { nest => { type => 'roost' } }, roost => 'survey_roost', {} );
  is( $e, "Dragons:\n- none\nPerches:\n- none\nLarder:\n- empty", 'an empty roost' );
};

subtest 'feed_dragon' => sub {
  fresh();
  my ( $o, $ok ) = t( feed_dragon => dragon => ' Gale ', food => 'TURNIPS' );
  ok( $ok, 'fed, names without case and white space' );
  is( $o, 'gale ate a basket of turnips. Left in the larder: 0 baskets.', '... output' );
  is_deeply( $state->{nest}{dragons}{gale}{meals}, ['turnips'], '... meals created and appended' );
  is( $state->{nest}{larder}{turnips}, 0, '... one basket taken' );
  is_deeply( [ map { $_->{path} } diff( $start, $state ) ], [ [qw( nest dragons gale meals )], [qw( nest larder turnips )] ],
    '... and nothing else changed' );

  my $before = clone($state);
  ( $o, $ok ) = t( feed_dragon => dragon => 'cinder', food => 'turnips' );
  is_deeply( [ $o, $ok ], [ 'Error: no turnips left in the larder.', 0 ], 'none left: refused' );
  ( $o, $ok ) = t( feed_dragon => dragon => 'cinder', food => 'kelp' );
  is_deeply( [ $o, $ok ], [ 'Error: no kelp left in the larder.', 0 ], 'zero baskets: refused' );
  ( $o, $ok ) = t( feed_dragon => dragon => 'cinder', food => 'acorns' );
  is_deeply( [ $o, $ok ], [ "Error: the larder has no 'acorns'.", 0 ], 'unknown food: refused' );
  ( $o, $ok ) = t( feed_dragon => dragon => 'smaug', food => 'turnips' );
  is_deeply( [ $o, $ok ], [ "Error: there is no dragon called 'smaug'.", 0 ], 'unknown dragon: refused' );
  ( $o, $ok ) = t( feed_dragon => dragon => [], food => 'turnips' );
  is_deeply( [ $o, $ok ], [ "Error: there is no dragon called ''.", 0 ], 'a reference as name: refused' );
  is_deeply( [ diff( $before, $state ) ], [], 'refused calls changed nothing' );

  fresh();
  ( $o, $ok ) = t( feed_dragon => dragon => 'cinder', food => 'turnips' );
  ok( $ok, 'a food the dragon eats' );
  fresh();
  $state->{nest}{larder}{kelp} = 2;
  ( $o, $ok ) = t( feed_dragon => dragon => 'cinder', food => 'kelp' );
  ok( $ok, 'a food it does not eat: fed all the same, the world does not judge' );
  is_deeply( $state->{nest}{dragons}{cinder}{meals}, ['kelp'], '... and recorded' );
  t( feed_dragon => dragon => 'cinder', food => 'kelp' );
  is_deeply( $state->{nest}{dragons}{cinder}{meals}, [qw( kelp kelp )], 'meals keep their order and repeats' );
};

subtest 'move_dragon' => sub {
  fresh();
  my ( $o, $ok ) = t( move_dragon => dragon => 'Gale', perch => 'Cave-Mouth' );
  ok( $ok, 'moved, names without case' );
  is( $o, 'gale flew to cave-mouth.', '... output' );
  is( $state->{nest}{dragons}{gale}{perch}, 'cave-mouth', '... perch set' );
  is_deeply( [ map { $_->{path} } diff( $start, $state ) ], [ [qw( nest dragons gale perch )] ], '... nothing else changed' );

  ( $o, $ok ) = t( move_dragon => dragon => 'pebble', perch => 'rock-shelf' );
  ok( $ok, 'the perch gale left is free' );
  is( $state->{nest}{dragons}{pebble}{perch}, 'rock-shelf', '... a dragon on the ground takes it' );

  fresh();
  ( $o, $ok ) = t( move_dragon => dragon => 'cinder', perch => 'cave-mouth' );
  ok( $ok, 'wingspan 11 onto span 6: not compared' );

  fresh();
  my $before = clone($state);
  ( $o, $ok ) = t( move_dragon => dragon => 'gale', perch => 'tall-pine' );
  is_deeply( [ $o, $ok ], [ 'Error: tall-pine is taken by cinder.', 0 ], 'a taken perch: refused, naming who sits there' );
  ( $o, $ok ) = t( move_dragon => dragon => 'gale', perch => 'moon' );
  is_deeply( [ $o, $ok ], [ "Error: there is no perch called 'moon'.", 0 ], 'unknown perch: refused' );
  ( $o, $ok ) = t( move_dragon => dragon => 'smaug', perch => 'cave-mouth' );
  is_deeply( [ $o, $ok ], [ "Error: there is no dragon called 'smaug'.", 0 ], 'unknown dragon: refused' );
  is_deeply( [ diff( $before, $state ) ], [], 'refused calls changed nothing' );

  ( $o, $ok ) = t( move_dragon => dragon => 'cinder', perch => 'tall-pine' );
  is_deeply( [ $o, $ok ], [ 'cinder is already on tall-pine.', 1 ], 'its own perch: answered, nothing to do' );
  is_deeply( [ diff( $before, $state ) ], [], '... changes nothing' );
};

subtest 'unknown tool' => sub {
  fresh();
  my ( $o, $ok ) = sims()->simulator('roost')->tool( $state->{nest}, 'burn_village', {} );
  is_deeply( [ $o, $ok ], [ "Error: unknown tool 'burn_village'.", 0 ], 'a name not in tools: error' );
};

done_testing;
