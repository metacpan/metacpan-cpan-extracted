#!/usr/local/bin/perl -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class, $var) = @_;
    return bless { var => $var }, $class;
}

sub PRINT  {
    my($self) = shift;
    ${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}

my $Original_File = 'lib/Getargs/Original.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 34 lib/Getargs/Original.pm

# damn lexical scoping in pod2test...
use vars qw|$dollar_zero @orig_argv|;

# stick a couple of things onto @ARGV
push @ARGV, qw|foo bar baz|;

# stash away our $0 and @ARGV for testing purposes
$dollar_zero = $0;
@orig_argv = @ARGV;

# use the module then clear out @ARGV
use_ok('Getargs::Original');
undef @ARGV;

# make sure that the program was stored
my $rx = qr/$dollar_zero/;
like( Getargs::Original->program, $rx, 'program name looks correct');

# make sure the args were stored
is_deeply( scalar Getargs::Original->args, \@orig_argv, 'args look correct');


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 121 lib/Getargs/Original.pm

Getargs::Original->resolved(0);
my $expected = File::Spec->rel2abs($0);
is( Getargs::Original->program, $expected,
    'program without base dir set is correct');
Getargs::Original->resolved(0);
Getargs::Original->base_dir('foo');
$expected = File::Spec->catfile('foo', File::Spec->abs2rel($0, 'foo'));
is( Getargs::Original->program, $expected,
    'program with base dir set is correct');
Getargs::Original->resolved(0);
Getargs::Original->base_dir('/opt/foo/');
$expected = File::Spec->catfile('/opt/foo/', File::Spec->abs2rel($0, '/opt/foo/'));
is( Getargs::Original->program, $expected,
    'program with base dir set is correct');


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 177 lib/Getargs/Original.pm
Getargs::Original->clear_resolved;
Getargs::Original->clear_base_dir;
my $expected = File::Spec->rel2abs($0);
is( Getargs::Original->program, $expected, '$0 is correct');

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 202 lib/Getargs/Original.pm
is_deeply( scalar Getargs::Original->args, \@orig_argv, 'args are correct');

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 222 lib/Getargs/Original.pm

# base dir shouldn't be defined yet
ok( ! defined Getargs::Original->base_dir, 'base dir not defined');

# set and test
Getargs::Original->base_dir('foo');
ok( defined Getargs::Original->base_dir, 'base dir is defined');
is( Getargs::Original->base_dir(), 'foo', 'base dir set to foo');


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 243 lib/Getargs/Original.pm

# reset state
Getargs::Original->resolved(0);
is( Getargs::Original->resolved, 0, '$0 has not been resolved');

# cause $0 to be resolved
Getargs::Original->argv;

# make sure things are now resolved
is( Getargs::Original->resolved, 1, '$0 has been resolved');


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

