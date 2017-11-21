package IPC::Pleather;
# ABSTRACT: Easy to use concurrency primitives inspired by Cilk
$IPC::Pleather::VERSION = '0.01';

use strict;
use warnings;
use AnyEvent;
use AnyEvent::Util qw(fork_call);
use IPC::Semaphore;
use IPC::SysV qw(IPC_PRIVATE S_IRUSR S_IWUSR IPC_CREAT IPC_NOWAIT);
use Keyword::Declare;
use Guard;

#-------------------------------------------------------------------------------
# IPC
#-------------------------------------------------------------------------------
our $PID = $$;
our $SEM = IPC::Semaphore->new(IPC_PRIVATE, 1, S_IRUSR|S_IWUSR|IPC_CREAT);
our $DEPTH = 0;

our $SEMGUARD = guard {
  $SEM->remove;
  undef $SEM;
};

sset($AnyEvent::Util::MAX_FORKS);

sub sset { $SEM->setval(0, $_[0]) }
sub sdec { $SEM->op(0, -1, IPC_NOWAIT) }
sub sinc { $SEM->op(0,  1, IPC_NOWAIT) }

sub spawn {
  my ($code, @args) = @_;

  if (!$AnyEvent::CondVar::Base::WAITING && sdec) {
    my $cv = AE::cv;

    fork_call {
      ++$DEPTH;
      my ($code, @args) = @_;
      $code->(@args);
    } $code, @args,
    sub {
      if (@_) {
        $cv->send(@_);
      }
      else {
        eval{ $cv->send($code->(@args)) };
        $@ && $cv->croak($@);
      }
      sinc;
    };

    return $cv;
  }
  else {
    return $code->(@args);
  }
}

#-------------------------------------------------------------------------------
# Keyword expansions
#-------------------------------------------------------------------------------
sub import {
  keyword sync (ScalarVar $var)
  {{{
    <{$var}> = ((ref(<{$var}>) || '') eq 'AnyEvent::CondVar') ? <{$var}>->recv : <{$var}>;
  }}}

  keyword spawn (VarDecl $var, '=', Block $block, CommaList $arg_list, ';')
  {{{
    <{$var}> = IPC::Pleather::spawn(sub <{$block}>, <{$arg_list}>);
  }}}

  keyword spawn (VarDecl $var, '=', Ident $sub, '(', CommaList $arg_list, ')', ';')
  {{{
    spawn <{$var}> = { <{$sub}>(@_) } <{$arg_list}>;
  }}}

  keyword spawn (VarDecl $var, '=', Ident $sub, Var|Statement|CommaList $arg_or_args, ';')
  {{{
    spawn <{$var}> = <{$sub}>(<{$arg_or_args}>);
  }}}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Pleather - Easy to use concurrency primitives inspired by Cilk

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use IPC::Pleather;

  sub fib {
    my $n = shift;
    return $n if $n < 2;

    spawn my $x = fib($n - 1);
    spawn my $y = fib($n - 2);

    sync $x;
    sync $y;

    return $x + $y;
  }

=head1 DESCRIPTION

C has L<Cilk|http://supertech.csail.mit.edu/cilk/>, Perl has Pleather.

IPC::Pleather adopts two keywords from Cilk, C<spawn> and C<sync>. C<spawn>
signals that the block or expression I<may> be executed concurrently. C<sync>
denotes a merge point, waiting until the spawned expression is completely
resolved.

=head1 KEYWORDS

=head2 spawn

Declares a variable whose value may or may not be executed in a forked process.
Some care is taken to guarantee a fixed cap on the total number of forks.
Recursive calls to spawn via the spawned expression (as in the Fibonacci
example in the L</SYNOPSIS>) are bound by the same maximum.

The forking mechanism is implemented using L<AnyEvent::Util/fork_call>,
allowing the maximum number of processes to be controlled either by setting
C<$AnyEvent::Util::MAX_FORKS> or with the C<PERL_ANYEVENT_MAX_FORKS>
environmental variable.

C<spawn> accepts several different expression syntaxes.

  # Block with optional arguments
  spawn my $var = {...} $arg1, $arg2, $arg3;

  # Subroutine call
  spawn my $var = do_stuff($arg1, $arg1 + $arg2, ...);

The latter syntax expands to the former, and all expressions in the argument
list are evaluated in the subprocess (or not, as the case may be), rather than
in the process from which they were spawned.

=head2 sync

Causes the process to block until the specified variable is fully resolved.
For spawned variables which executed in a forked process, a L<condition
variable|AnyEvent/CONDITION VARIABLES> is used to synchronize the result. When
executed locally, the result is immediately assigned to the variable and the
call to C<sync> is essentially a no-op.

=head1 SEE ALSO

=over

=item L<The Cilk Project|http://supertech.csail.mit.edu/cilk/>

=back

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
