#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal::Kit::Run;

{
	package Held;
	sub new { my ($class, %can) = @_; return bless { %can, log => [] }, $class }
	sub can {
		my ($self, $method) = @_;
		return ref $self && exists $self->{$method} ? $self->SUPER::can($method) : undef
			if $method eq 'leave_raw' || $method eq 'restore';
		return $self->SUPER::can($method);
	}
	sub leave_raw { my ($self) = @_; push @{$self->{log}}, 'leave_raw'; die "broken\n" if $self->{broken}; return $self }
	sub restore { my ($self) = @_; push @{$self->{log}}, 'restore'; return $self }
}

{
	package Loud;
	sub new { my ($class, $to) = @_; return bless { to => $to }, $class }
	sub leave_raw { my ($self) = @_; syswrite $self->{to}, "given back\n"; return }
}

subtest 'a body that returns' => sub {
	plan tests => 6;
	my $keys = Held->new(leave_raw => 1);
	my $screen = Held->new(restore => 1);
	my $both = Held->new(leave_raw => 1, restore => 1);

	my $scalar = Game::Terminal::Kit::Run::guard(sub { return wantarray ? 'list' : 'scalar' }, $keys, $screen, $both);
	is $scalar, 'scalar', 'the body is called in scalar context for a scalar';
	is_deeply $keys->{log}, ['leave_raw'], 'the keys were given back';
	is_deeply $screen->{log}, ['restore'], 'the screen was given back';
	is_deeply $both->{log}, ['leave_raw', 'restore'], 'a thing with both had both';

	my @list = Game::Terminal::Kit::Run::guard(sub { return (1, 2, 3) }, $keys);
	is_deeply \@list, [1, 2, 3], 'a list comes back as a list';
	is Game::Terminal::Kit::Run::guard(sub { return }), undef, 'nothing held and nothing returned is fine';
};

subtest 'a body that dies' => sub {
	plan tests => 5;
	my $keys = Held->new(leave_raw => 1);
	my $error = { code => 7 };
	my $lived = eval { Game::Terminal::Kit::Run::guard(sub { die $error }, $keys); 1 };
	ok !$lived, 'the error is thrown again';
	is $@, $error, 'and is the same error';
	is_deeply $keys->{log}, ['leave_raw'], 'after the keys were given back';

	my $broken = Held->new(leave_raw => 1, broken => 1);
	my $after = Held->new(restore => 1);
	is Game::Terminal::Kit::Run::guard(sub { 'fine' }, $broken, 'not an object', undef, $after), 'fine',
		'a thing that cannot be given back does not spoil the result';
	is_deeply $after->{log}, ['restore'], 'nor stop the next from being given back';
};

subtest 'the signal handlers are borrowed' => sub {
	plan tests => 4;
	my $mine = sub { };
	local $SIG{INT} = $mine;
	local $SIG{TERM} = 'IGNORE';
	my $inside;
	Game::Terminal::Kit::Run::guard(sub { $inside = $SIG{INT} });
	ok ref $inside eq 'CODE' && $inside != $mine, 'a different handler while the body runs';
	is $SIG{INT}, $mine, 'and the old one afterwards';
	is $SIG{TERM}, 'IGNORE', 'an ignored signal is ignored again';
	eval { Game::Terminal::Kit::Run::guard(sub { die "no\n" }) };
	is $SIG{INT}, $mine, 'the old one after an error too';
};

subtest 'an interrupt gives the terminal back and still interrupts' => sub {
	plan skip_all => 'no fork or no signals here' if $^O eq 'MSWin32';
	plan tests => 3;
	pipe my $read, my $write or die $!;
	my $pid = fork;
	die "cannot fork: $!" unless defined $pid;
	unless ($pid) {
		close $read;
		Game::Terminal::Kit::Run::guard(sub { kill 'INT', $$; sleep 5; syswrite $write, "carried on\n" }, Loud->new($write));
		syswrite $write, "returned\n";
		exit 0;
	}
	close $write;
	my $said = do { local $/; <$read> };
	waitpid $pid, 0;
	is $said, "given back\n", 'the keys were given back once and the body went no further';
	is $? & 127, 2, 'the process died of the interrupt';
	is $? >> 8, 0, 'not of an exit';
};

done_testing;
