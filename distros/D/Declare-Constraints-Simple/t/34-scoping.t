#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 13;

use Declare::Constraints::Simple-All;

my $profile = 
    And( IsHashRef,
         Scope( 'myscope',
                OnHashKeys( foo => Or( SetResult( qw(myscope FooInt),
                                                  IsInt ),
                                       IsDefined ),
                            bar => Message( 
                                     'Need either correct foo or bar',
                                     Or( IsDefined,
                                         IsValid( qw(myscope FooInt) )
                                     )))));

my $structure = { foo => 12,
                  bar => undef };

{   my $result = $profile->($structure);
    ok($result->is_valid, 'structure validates initially');
}

{   local $structure->{foo} = 'twelve';
    my $result = $profile->($structure);
    ok(!$result, 'dependency failed');
    is($result->message, 'Need either correct foo or bar', 
        'correct error message');
    is($result->path,
        'And.Scope.OnHashKeys[bar].Message.Or.IsValid[myscope:FooInt]',
        'correct failure path');

    local $structure->{bar} = "Foobar";
    my $result2 = $profile->($structure);
    ok($result2, 'reverse test passes');
}

my $constraint =
    Scope('foo',
      And(
        HasAllKeys( qw(cmd data) ),
        OnHashKeys( 
          cmd => Or( SetResult('foo', 'cmd_a',
                       IsEq('FOO_A')),
                     SetResult('foo', 'cmd_b',
                       IsEq('FOO_B')) ),
          data => Or( And( IsValid('foo', 'cmd_a'),
                           IsArrayRef( IsInt )),
                      And( IsValid('foo', 'cmd_b'),
                           IsRegex )) )));

my $cmdhash_a = {
    cmd  => 'FOO_A',
    data => [1 .. 5],
};
my $cmdhash_b = {
    cmd  => 'FOO_B',
    data => qr/foo/,
};

{   my $result = $constraint->($cmdhash_a);
    ok($result, 'example cmdhash_a passes');

    {   local $cmdhash_a->{cmd} = 'FOO_NONE';
        my $result = $constraint->($cmdhash_a);
        ok(!$result, 'unknown command fails');
        is($result->path,
            'Scope.And.OnHashKeys[cmd].Or.SetResult.IsEq',
            'correct path for failing command');
    }

    {   local $cmdhash_a->{data}[2] = 'foobar';
        my $result = $constraint->($cmdhash_a);
        ok(!$result, 'wrong data for command a fails');
        is($result->path,
            'Scope.And.OnHashKeys[data].Or.And.IsValid[foo:cmd_b]',
            'correct path for wrong data for cmd a');
    }
}

{   my $result = $constraint->($cmdhash_b);
    ok($result, 'example cmdhash_b passes');

    {   local $cmdhash_b->{data} = 23;
        my $result = $constraint->($cmdhash_b);
        ok(!$result, 'wrong data for command b fails');
        is($result->path,
            'Scope.And.OnHashKeys[data].Or.And.IsRegex',
            'correct path for wrong data for cmd a');
    }
}
