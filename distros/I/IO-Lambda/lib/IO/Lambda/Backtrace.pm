package IO::Lambda::Backtrace;
# $Id: Backtrace.pm,v 1.3 2010/01/01 14:49:02 dk Exp $
use strict;
use warnings;
use IO::Lambda qw(:constants :dev);

sub new
{
	my ( $class, $this, $caller) = @_;
	my @stacks = make_lambda_stacks($this);
	$caller = Carp::shortmess unless defined $caller;
	my @entry = ($this, $caller);
	unshift @$_, \@entry for @stacks;
	@stacks = [\@entry] unless @stacks;
	bless \@stacks, $class;
}

sub events2lambdas     { @$_ = map { [ $_-> [WATCH_OBJ], $_-> [WATCH_CALLER] ] } @$_ for @_; @_ }
sub make_event_tree    { map { [ $_, make_event_tree( $_->[WATCH_OBJ] ) ] } shift-> callers }
sub make_event_stacks  { tree2stacks   ( make_event_tree  ( shift )) }
sub make_lambda_stacks { events2lambdas( tree2stacks( make_event_tree( shift ))) }

sub tree2stacks
{
	my @tracks = @_;
	my (@finished, @current, @stack);
	while (@stack or @tracks) {
		if ( @tracks) {
			my $p = shift @tracks;
			push @stack, [ @current ], [ @tracks ]
				if @tracks;
			push @current, shift @$p;
			@tracks = @$p;
		} else {
			push @finished, [ @current ] if @current;
			@tracks  = @{ pop @stack };
			@current = @{ pop @stack };
		}
	}
	push @finished, [ @current ] if @current;
	return @finished;
}

sub as_text
{
	my $self = shift;
	my $out = '';
	my $ch  = 1;
	for ( @$self ) {
		my $depth = 0;
		for ( @$_ ) {
			$depth++;
			$out .= "\t #$ch/$depth: "
				if $IO::Lambda::DEBUG_CALLER;
			$out .= 'lambda(' . _o($_->[0]) . ')';
			$out .= " created at $_->[0]->{caller}"
				if $_->[0]->{caller};
			if ( $depth == 1) {
				$out .= " called";
				$out .= $_->[1];
			} elsif ( defined $_-> [1]) {
				$out .= " awaited";
				$out .= $_->[1];
			} elsif ( $IO::Lambda::DEBUG_CALLER)  {
				$out .= "\n";
			} else {
				$out .= " ";
			}
		}
		$out .= "\n";
		$ch++;
	}
	return $out;
}

sub cluck   { warn shift-> as_text }
sub confess { die  shift-> as_text }

1;

=pod

=head1 NAME

IO::Lambda::Backtrace - backtrace chains of events

=head1 DESCRIPTION

The module makes it easier to debug chains of events, when a lambda awaits for
another, this one in turn for another, etc etc. The class
C<IO::Lambda::Backtrace> represents a set of such stacks, because a lambda can
be awaited by more than one lambda. Each stack is an array of items where each
contains the caller lambda and the invocation point. The class provides helper
methods for printing this information in readable form.

The module relies on the debug information about invocation points collected by
C<IO::Lambda>. By default, there's very little information collected, so in
order to increase verbosity use C<IO::Lambda::DEBUG_CALLER> flag, either
directly or through C<$ENV{IO_LAMBDA_DEBUG} = 'caller'>. If the flag is set to
1, lambdas collect invocation points. If the flag is set to 2, then also the
additional perl stack trace is added.

=head1 SYNOPSIS

  use IO::Lambda;
  $IO::Lambda::DEBUG_CALLER = 1;

  lambda {
     ...
     warn this-> backtrace-> as_text;
  }

or from command line

   env IO_LAMBDA_DEBUG=caller=2 ./myscript

=head1 API

=over

=item new($lambda)

Extracts the information of the current chain of events and creates a new blessed reference of it.

=item as_text

Returns the backtrace information formatted as text, ready to display

=item cluck

Warns with the backtrace log

=item confess

Dies with the backtrace log

=back
 
=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

The ideas of backtracing threads of events, and implementing backtrace objects
passable through execition stack are proposed by Ben Tilly.

=cut
