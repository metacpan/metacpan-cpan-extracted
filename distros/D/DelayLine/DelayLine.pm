package DelayLine;

# $Id: DelayLine.pm,v 1.4 2000/07/22 11:53:48 lth Exp $

use strict;
use Carp;

use vars qw($VERSION);
$VERSION = '0.02';

my %fields = (
	      _LINE => [],
	      _BORN => undef,
	      DEBUG => 0,
	      DELAY => 0,
	     );

sub new {
    my ($proto, %args) = @_;

    # new() can be used as both class and object method
    my $class = ref($proto) || $proto;

    # build object
    my $self = bless {
		      %fields,
		     }, $class;

    # set creation time
    $self->{_BORN} = time();

    # parse arguments
    foreach my $arg (keys %args) {
	foreach my $attrib (grep {!/^_/} keys %fields) {
	    if ($arg =~ /^-?$attrib$/i) {
		$self->{$attrib} = delete $args{$arg};
	    }
	}
    }

    # complain about unknown arguments
    if (my @unknown = keys %args) {
	croak __PACKAGE__, ": Unknown argument",
	  (@unknown == 1 ? ' ' : 's '),
	    join(', ', map {"'$_'"} @unknown);
    }

    print STDERR "new\n"
      if $self->{DEBUG};

    $self;
}

# clone standard attribute accessor methods
for my $attrib (grep {!/^_/} keys %fields) {
    no strict "refs";
    *{lc $attrib} = sub {
        my $self = shift;
        my $prev = $self->{$attrib};
        $self->{$attrib} = shift if @_;
        $prev;
    }
}

sub in {
    my ($self, $obj, $delay) = @_;

    my $now = time();
    $delay = $self->delay unless defined $delay;

    my %entry = (
		 'OBJ' => $obj,
		 'DELAY' => $delay,
		 'INTIME' => $now,
		 'OUTTIME' => $now + $delay,
		);

    print STDERR __PACKAGE__, "::in obj='$obj' delay=$entry{DELAY} outtime=$entry{OUTTIME}\n"
      if $self->{DEBUG};

    # push new object onto delayline
    push @{$self->{_LINE}},  \%entry;

    # re-sort delayline according to outtime
    @{$self->{_LINE}} = sort {
	$a->{OUTTIME} <=> $b->{OUTTIME}
    } @{$self->{_LINE}};
}

sub out {
    my ($self) = @_;
    my $now = time();

    # return immediately if the DelayLine is empty
    unless (@{$self->{_LINE}}) {
	print STDERR __PACKAGE__, "::out now=$now empty\n"
	  if $self->{DEBUG};
	return;
    }

    # return overdue object
    if ($self->{_LINE}->[0]->{OUTTIME} <= $now) {
	my $obj = (shift @{$self->{_LINE}})->{OBJ};
	print STDERR __PACKAGE__, "::out now=$now obj='$obj'\n"
	  if $self->{DEBUG};
	return $obj;
    }

    # nothing ready yet
    print STDERR __PACKAGE__, "::out now=$now next=$self->{_LINE}->[0]->{OUTTIME}\n"
      if $self->{DEBUG};
    return;
}

1;

__END__


=head1 NAME

DelayLine - Simple time-delay data stucture

=head1 SYNOPSIS

    use DelayLine;

    my $dl = DelayLine->new(delay => $defaultdelay);

    $dl->in($item);

    [ ... ]

    if (my $ob = $dl->out()) {
        # do stuff with $ob
    }

=head1 DESCRIPTION

The C<DelayLine> is a simple two-port data structure, like a FIFO, but
with variable delay. Each object put into the input of the DelayLine
will appear on the output only after some pre-determined amount of
time has elapsed. This time can be set as a default for the DelayLine,
or can be individually overridden for each object put into the
DelayLine.

If the default delay time is set to zero, and is not overridden for
the individual objects, the DelayLine mimics a straightforward FIFO.

The DelayLine accepts any scalar value as input, including
references.

The DelayLine is a very useful component when building simple event
loops.

=head2 Methods

C<DelayLine> provides the following methods:

=over 4

=item DelayLine->new( [ delay => DELAY [, debug => DEBUG ]] )

Returns a newly created C<DelayLine> object.

The default delay is 0 seconds, unless an optional C<DELAY> time in
seconds is given.

Debugging is turned off by default. Setting DEBUG to true, enables
debugging output to STDOUT.

The parameter naming style is very flexible: the keyword can be in
lower, upper or mixed case, and can be optionally prefixed with a
dash. Thus, the following are all equivalent:

  $dl = DelayLine->new( -delay => 42 );
  $dl = DelayLine->new(  delay => 42 );
  $dl = DelayLine->new( -Delay => 42 );
  $dl = DelayLine->new(  DELAY => 42 );
  $dl = DelayLine->new( -deLaY => 42 );

C<new()> can be called as a class (static) or object method. Calling
C<new()> as an object method is only a convenience; no data from the
original DelayLine is carried over into the newly created object.

=item $DL->in( OBJ [, DELAY ] )

This method puts object C<OBJ> into DelayLine C<$DL>.

The object C<OBJ> can be any scalar value, including references.

The default delay as set in the C<new()> method is used, unless
overridden by setting C<DELAY>.

=item $DL->out()

This method fetches objects from the out from the DelayLine C<$DL>.

Returns the first of the timed-out objects, if any.

Returns C<undef> if the DelayLine is empty, of if no objects in the
DelayLine have timed out yet.

=item $DL->delay( [ DELAY ] )

Returns the current default delay setting of the DelayLine. If the
optional value DELAY is set, sets a new default delay value.

=item $DL->debug( [ DEBUG ] )

Returns the current debug setting of the DelayLine. If the
optional value DEBUG is set, sets a new debug value.

If the debug value is set (true), calling any of the 'active' methods
(C<in()> or C<out()> will yield a short debug message on STDERR.

=back

=head1 BUGS

This is a fairly simple module, so no serious bugs are
expected. Patches are welcome, though.

=head1 RELEASE HISTORY

=item v0.02 - 2000-jul-22

Fixed test for multiple unknown args.
Removed superfluous test output.
Streamlined debug output.

=item v0.01 - 2000-jul-13

Initial release.

=head1 COPYRIGHT

Copyright (c) 2000 Lars Thegler. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Lars Thegler <lars@thegler.dk>

=cut
