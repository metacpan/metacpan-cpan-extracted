### 10-env.t ##################################################################
# This file tests the role for copying %ENV ready for use in a staged command

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

package Test::Env;

use Moose;

with 'HPCI::Env';

package main;

use Test::More tests => 10;

use Test::Exception;

{
	my $env = Test::Env->new;
	ok( ! $env->has_any_env, 'with no args, should say no env provided' );
}

{
	my $env = Test::Env->new( env_retain => ['NOT_IN_MY_BACK_ENV'] );
	ok( $env->has_any_env, 'with an arg, should say env is provided' );
	is_deeply( $env->env, { }, 'with retain bad name, should return empty list' );
}

{
	my $env = Test::Env->new( env_retain => ['PATH'] );
	is_deeply( $env->env, { PATH => $ENV{PATH} }, 'with retain, should return specified list' );
}

{
	my $env = Test::Env->new( env_remove => ['NOT_IN_MY_BACK_ENV'] );
	is_deeply( $env->env, \%ENV, 'with remove bad name, should return entire \%ENV' );
}

{
	my $env = Test::Env->new( env_remove => ['PATH'] );
	my %res = map { $_ => $ENV{$_} } grep { ! /^PATH$/ } keys %ENV;
	is_deeply( $env->env, \%res, 'with remove, should return %ENV missing the specified list' );
}

{
	my $set = {'PATH' => 'mypath'};
	my $env = Test::Env->new( env_set => $set );
	my %res = %ENV;
	$res{PATH} = 'mypath';
	is_deeply( $env->env, \%res, 'with set alone, %ENV modified' );
}

{
	my $set = {'PATH' => 'mypath'};
	my $env = Test::Env->new( env_retain => ['PATH'], env_set => $set );
	is_deeply( $env->env, $set, 'with set along with retain' );
}

{
	sub path_prefix {
		my $key = shift;
		my $val = shift;
		return "mypath:$val";
	}
	my $set = {'PATH' => \&path_prefix};
	my $env = Test::Env->new( env_retain => ['PATH'], env_set => $set );
	is_deeply( $env->env, { PATH => "mypath:$ENV{PATH}" }, 'with set along with retain' );
}

{
	my $start = {FOO => 'fu', BAR => 'iron'};
	my $set   = {BAZ => 'aar'};
	my $env   = Test::Env->new( env_source => $start, env_retain => [qw(PATH SHELL FOO)], env_set => $set );
	is_deeply( $env->env, { FOO => 'fu', BAZ => 'aar' }, 'with source, retain, set should not use %ENV' );
}

1;
