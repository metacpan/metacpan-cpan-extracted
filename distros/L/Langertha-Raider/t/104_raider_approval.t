#!/usr/bin/env perl
# ABSTRACT: An approval covers exactly the call it was given for (ADR 0005, F20, k124)
use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS qw( JSON );
use Langertha::Raider::Approval;

# ADR 0005: approvals are bound to session, run, tool, canonical arguments and
# policy revision; a change invalidates them. Fixture F20: the tool arguments
# change after the approval -- the old approval no longer counts. Pure logic,
# no raid, no engine.

my $class = 'Langertha::Raider::Approval';

sub call_for {
  my ( %over ) = @_;
  return {
    name      => 'write_file',
    source    => 'engine:1',
    arguments => { path => 'lib/Foo.pm', content => 'package Foo; 1;' },
    %over
  };
}

sub in_context {
  my ( %over ) = @_;
  return (
    session_id      => 's-20260930-abc',
    run_id          => 'r3',
    policy_revision => 'rev-7',
    call            => call_for(),
    %over
  );
}

my $approval = $class->for_call( in_context() );

subtest 'the approval carries its binding' => sub {
  isa_ok $approval, $class;
  is $approval->session_id,      's-20260930-abc', 'session_id';
  is $approval->run_id,          'r3',             'run_id';
  is $approval->tool,            'write_file',     'tool';
  is $approval->source,          'engine:1',       'source';
  is $approval->policy_revision, 'rev-7',          'policy_revision';
  like $approval->arguments_sha256, qr/\A[0-9a-f]{64}\z/, 'arguments_sha256 is a sha256 hex digest';
  is $approval->arguments_sha256,
    $class->digest_arguments( call_for()->{arguments} ),
    'arguments_sha256 is the digest of the call arguments';
};

subtest 'an identical call is covered' => sub {
  ok $approval->covers( in_context() ), 'same session, run, tool, source, arguments and revision';
  ok $approval->covers( in_context( call => call_for(
    arguments => { path => 'lib/Foo.pm', content => 'package Foo; 1;' },
  ) ) ), 'arguments rebuilt as a fresh hash';
};

subtest 'any change of a bound field invalidates' => sub {
  ok !$approval->covers( in_context( session_id => 's-other' ) ),      'other session';
  ok !$approval->covers( in_context( run_id => 'r4' ) ),               'other run';
  ok !$approval->covers( in_context( policy_revision => 'rev-8' ) ),   'other policy revision';
  ok !$approval->covers( in_context( call => call_for( name => 'edit_file' ) ) ), 'other tool';
  ok !$approval->covers( in_context( call => call_for( source => 'engine:2' ) ) ), 'same tool name, other source';
  ok !$approval->covers( in_context( call => call_for( source => 'inline' ) ) ),   'same tool name, inline source';
};

subtest 'F20: arguments changed after the approval' => sub {
  ok !$approval->covers( in_context( call => call_for(
    arguments => { path => 'lib/Foo.pm', content => 'package Foo; system("rm -rf /"); 1;' },
  ) ) ), 'changed value';
  ok !$approval->covers( in_context( call => call_for(
    arguments => { path => 'lib/Foo.pm', content => 'package Foo; 1;', mode => '0755' },
  ) ) ), 'added key';
  ok !$approval->covers( in_context( call => call_for(
    arguments => { path => 'lib/Foo.pm' },
  ) ) ), 'removed key';
  ok !$approval->covers( in_context( call => call_for( arguments => {} ) ) ), 'emptied';
  ok !$approval->covers( in_context( call => call_for( arguments => undef ) ) ), 'no arguments at all';

  # The same hash, changed in place after the approval was taken: the
  # approval holds a digest, not a reference, so the change is seen.
  my $call = call_for();
  my $taken = $class->for_call( in_context( call => $call ) );
  ok $taken->covers( in_context( call => $call ) ), 'covers before the change';
  $call->{arguments}{path} = '/etc/passwd';
  ok !$taken->covers( in_context( call => $call ) ), 'not after an in-place change';
};

subtest 'key order does not matter' => sub {
  my %args;
  $args{$_} = uc $_ for qw( zeta alpha mu beta omega );
  my %reversed;
  $reversed{$_} = uc $_ for reverse sort keys %args;
  is $class->digest_arguments( \%args ), $class->digest_arguments( \%reversed ),
    'hashes built in different insertion orders digest alike';
  my $taken = $class->for_call( in_context( call => call_for( arguments => \%args ) ) );
  ok $taken->covers( in_context( call => call_for( arguments => \%reversed ) ) ), 'and are covered';
};

subtest 'nested arguments are canonical' => sub {
  my $one = { edits => [ { old => 'a', new => 'b', opts => { z => 1, a => [ 2, { y => 3, x => 4 } ] } } ], path => 'x' };
  my $two = { path => 'x', edits => [ { opts => { a => [ 2, { x => 4, y => 3 } ], z => 1 }, new => 'b', old => 'a' } ] };
  is $class->digest_arguments($one), $class->digest_arguments($two), 'deep key order does not matter';

  my $swapped = { path => 'x', edits => [ { old => 'a', new => 'b', opts => { z => 1, a => [ { y => 3, x => 4 }, 2 ] } } ] };
  isnt $class->digest_arguments($one), $class->digest_arguments($swapped), 'array order does matter';

  my $deep = { path => 'x', edits => [ { old => 'a', new => 'b', opts => { z => 1, a => [ 2, { y => 3, x => 5 } ] } } ] };
  isnt $class->digest_arguments($one), $class->digest_arguments($deep), 'a change deep down counts';
};

subtest 'scalars compare by their string form; booleans and null stay apart' => sub {
  my $d = sub { $class->digest_arguments( { v => $_[0] } ) };

  is $d->(5), $d->('5'), '5 and "5" are the same argument';
  my $num = 5;
  my $str = "$num";                        # num now also carries a string form
  my $numified = '5';
  my $sum = $numified + 0;                 # "5" now also carries a number form
  is $d->($num), $d->('5'), 'a number used as a string digests like before';
  is $d->($numified), $d->(5), 'a string used as a number digests like before';

  isnt $d->(5), $d->(6), '5 and 6 differ';
  isnt $d->('1.0'), $d->('1'), '"1.0" and "1" differ (compared as strings)';
  isnt $d->(JSON->true), $d->(1), 'true and 1 differ';
  isnt $d->(JSON->true), $d->('true'), 'true and "true" differ';
  isnt $d->(JSON->false), $d->(0), 'false and 0 differ';
  isnt $d->(JSON->false), $d->(''), 'false and "" differ';
  isnt $d->(undef), $d->(''), 'null and "" differ';
  isnt $d->(undef), $d->(JSON->false), 'null and false differ';
  is $d->( JSON::MaybeXS->new->decode('true') ), $d->(JSON->true), 'decoded true is true';

  isnt $class->digest_arguments( { v => [] } ), $class->digest_arguments( { v => {} } ), '[] and {} differ';
  isnt $class->digest_arguments( [ 'a', 'b' ] ), $class->digest_arguments( { a => 'b' } ), 'list and hash differ';
};

subtest 'unicode arguments' => sub {
  my $d = $class->digest_arguments( { text => "Stra\x{df}e \x{2603}" } );
  like $d, qr/\A[0-9a-f]{64}\z/, 'wide characters digest';
  is $class->digest_arguments( { text => "Stra\x{df}e \x{2603}" } ), $d, 'and digest alike again';
};

subtest 'the approval is not changed by being checked, and is read-only' => sub {
  my $before = $approval->arguments_sha256;
  $approval->covers( in_context( run_id => 'r9' ) );
  is $approval->arguments_sha256, $before, 'unchanged after a failed check';
  like dies { $approval->run_id('r4') }, qr/read-only|Cannot assign/i, 'run_id cannot be reset';
};

subtest 'fail loud on what cannot be bound' => sub {
  for my $field (qw( session_id run_id policy_revision )) {
    like dies { $class->for_call( in_context( $field => undef ) ) }, qr/\Q$field\E/,
      'for_call croaks without '.$field;
  }
  like dies { $class->for_call( in_context( call => call_for( name => undef ) ) ) }, qr/tool/,
    'for_call croaks without a tool name';
  like dies { $class->for_call( in_context( call => call_for( source => undef ) ) ) }, qr/source/,
    'for_call croaks without a tool source';
  like dies { $class->for_call( in_context( call => undef ) ) }, qr/call/,
    'for_call croaks without a call';
  like dies { $class->digest_arguments( { cb => sub { 1 } } ) }, qr/arguments/,
    'code refs in arguments croak';
  like dies { $class->digest_arguments( { obj => bless {}, 'K124::Thing' } ) }, qr/arguments/,
    'objects in arguments croak';

  ok !$approval->covers( in_context( call => call_for( source => undef ) ) ),
    'covers is false for a call with no source';
  ok !$approval->covers( in_context( run_id => undef ) ), 'covers is false without a run id';
  like dies { $approval->covers( in_context( call => 'write_file' ) ) }, qr/call/,
    'covers croaks on a call that is not a hash';
};

done_testing;
