package Log::Progress;
$Log::Progress::VERSION = '0.13';
use Moo 2;
use Carp;
use IO::Handle; # for 'autoflush'
use JSON;

# ABSTRACT: Conveniently write progress messages to logger or file handle


has to         => ( is => 'rw', isa => \&_assert_valid_output, default => sub { \*STDERR },
                    trigger => sub { delete $_[0]{_writer} } );
sub squelch    {
	my $self= shift;
	if (@_) { $self->_squelch(shift); $self->_calc_precision_squelch() }
	$self->{squelch};
}
sub precision  {
	my $self= shift;
	if (@_) { $self->_precision(shift); $self->_calc_precision_squelch() }
	$self->{precision};
}
has step_id    => ( is => 'rw', default => sub { $ENV{PROGRESS_STEP_ID} },
                    trigger => sub { delete $_[0]{_writer} } );

has current    => ( is => 'rw' );
has total      => ( is => 'rw' );

has _writer    => ( is => 'lazy' );
has _squelch   => ( is => 'rw', init_arg => 'squelch' );
has _precision => ( is => 'rw', init_arg => 'precision' );
has _last_progress => ( is => 'rw' );

sub BUILD {
	shift->_calc_precision_squelch();
}

sub _calc_precision_squelch {
	my $self= shift;
	my $squelch= $self->_squelch;
	my $precision= $self->_precision;
	if (!defined $squelch && !defined $precision) {
		$squelch= .01;
		$precision= 2;
	} else {
		# calculation for digit length of number of steps
		defined $precision or $precision= int(log(1/$squelch)/log(10) + .99999);
		defined $squelch or $squelch= 1/(10**$precision);
	}
	$self->{squelch}= $squelch;
	$self->{precision}= $precision;
}

sub _assert_valid_output {
	my $to= shift;
	my $type= ref $to;
	$type && (
		$type eq 'GLOB'
		or $type eq 'CODE'
		or $type->can('print')
		or $type->can('info')
	) or die "$to is not a file handle, logger object, or code reference";
}

sub _build__writer {
	my $self= shift;
	
	my $prefix= "progress: ".(defined $self->step_id? $self->step_id.' ' : '');
	my $to= $self->to;
	my $type= ref $to;
	$to->autoflush(1) if $type eq 'GLOB' or $type->can('autoflush');
	return ($type eq 'GLOB')? sub { print $to $prefix.join('', @_)."\n"; }
		:  ($type eq 'CODE')? sub { $to->($prefix.join('', @_)); }
		:  ($type->can('print'))? sub { $to->print($prefix.join('', @_)."\n"); }
		:  ($type->can('info'))? sub { $to->info($prefix.join('', @_)); }
		: die "unhandled case";
}


sub at {
	my ($self, $current, $total, $message)= @_;
	if (defined $total) {
		$self->total($total);
	} else {
		$total= $self->total;
		$total= 1 unless defined $total;
	}
	$self->current($current);
	my $progress= $total? $current / $total : 0;
	my $sq= $self->squelch;
	my $formatted= sprintf("%.*f", $self->precision, int($progress/$sq + .0000000001)*$sq);
	return if defined $self->_last_progress
	      and abs($formatted - $self->_last_progress)+.0000000001 < $sq;
	$self->_last_progress($formatted);
	if ($total != 1) {
		$formatted= (int($current) == $current)? "$current/$total"
			: sprintf("%.*f/%d", $self->precision, $current, $total);
	}
	$self->_writer->($formatted . ($message? " - $message":''));
}

# backward compatibility with version <= 0.03
sub progress {
	my ($self, $current, $total, $message)= @_;
	$total= 1 unless defined $total;
	$self->at($current, $total, $message);
}


sub inc {
	my ($self, $offset, $message)= @_;
	$offset= 1 unless defined $offset;
	$self->at(($self->current || 0) + $offset, undef, $message);
}


sub data {
	my ($self, $data)= @_;
	ref $data eq 'HASH' or croak "data must be a hashref";
	$self->_writer->(JSON->new->ascii->encode($data));
}


sub substep {
	my ($self, $step_id, $step_contribution, $title)= @_;
	length $title or croak "sub-step title is required";
	
	$step_id= $self->step_id . '.' . $step_id
		if defined $self->step_id and length $self->step_id;
	
	my $sub_progress= ref($self)->new(
		to        => $self->to,
		squelch   => $self->_squelch,
		precision => $self->_precision,
		step_id   => $step_id,
	);
	
	if ($step_contribution) {
		$sub_progress->_writer->(sprintf("(%.*f) %s", $self->precision, $step_contribution, $title));
	} else {
		$sub_progress->_writer->("- $title");
	}
	
	return $sub_progress;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Progress - Conveniently write progress messages to logger or file handle

=head1 SYNOPSIS

  my $progress= Log::Progress->new(to => \*STDERR); # The default
  $progress->squelch(.1); # only emit messages every 10%
  my $max= 1000;
  $progress->at(0, $max);
  for (my $i= 1; $i <= $max; $i++) {
    # do the thing
    ...;
    $progress->at($i);
  }
  
  # or, if you don't have a loop variable:
  $progress->at(0, scalar @things);
  for (@things) {
    ...;
    $progress->inc;  # "++" would be fun, but L<overload> causes object cloning
  }

=head1 DESCRIPTION

This module assists with writing
L<progress messages|http://github.com/nrdvana/Log-Progress/blob/master/README.md>
to your log file, which can then be parsed with L<Log::Progress::Parser>.
It can write to file handles, log objects (like L<Log::Any>),
or custom coderefs.

Note that this module enables autoflush if you give it a file handle.

=head1 ATTRIBUTES

=head2 to

The destination for progress messages.  It can be one of:

=over

=item File Handle (or object with C<print> method)

The C<print> method is used, and passed a single newline-terminated string.

If the object also has a method C<autoflush>, this module calls it
before writing any messages.  (to avoid that behavior, use a coderef instead)

=item Logger object (with C<info> method)

The progress messages are passed to the C<info> method, without a terminating
newline.

=item coderef

The progress messages are passed as the only argument, without a terminating
newline.  The return value becomes the return value of the call to L</progress>
and should probably be a boolean to match behavior of C<IO::Handle::print>.

  sub { my ($progress_message)= @_; ... }

=back

=head2 precision

The progress number is written as text, with L</precision> digits after the
decimal point.  The default precision is 2.  This default corresponds with a
default L</squelch> of 0.01, so that calls to C<< ->at >> with less
than 1% change from the previous call are suppressed.

If you set only one of C<precision> or C<squelch>, the other will default to
something appropriate.  For example, setting C<precision> to C<5> results in
a C<squelch> of C<.00001>.  Likewise a squelch of C<1/60> gives a precision
of C<2>.

Once set, C<precision> will not receive a default value from changes to C<squelch>.
(but you can un-define it to restore that behavior)

=head2 squelch

You can prevent spamming your log file with tiny progress updates using
C<squelch>, which limits progress messages to one per some fraction of overall
progress.  For example, the default C<squelch> of C<.01> will only emit at most
C<101> progress messages.  (assuming your progress is non-decreasing)

If you set C<squelch> but not C<precision>, the second will use a sensible default.
See example in L</precision>

Once set, C<squelch> will not receive a default value from changing C<precision>.
(but you can un-define it to restore that behavior)

=head2 step_id

If this object is reporting the progress of a sub-step, set this ID to
the step name.

The default value for this field comes from C<$ENV{PROGRESS_STEP_ID}>, so that
programs that perform simple progress reporting can be nested as child
processes of a larger job without having to specifically plan for that ability
in the child process.

=head2 current

The current progress fraction numerator.  Used by L</inc>.
Setting this attribute directly bypasses the printing of progress.

=head2 total

The progress fraction denominator.  Used by L</inc> and L</at>.
Setting this attribute directly bypasses the printing of progress.

=head1 METHODS

=head2 at

  $p->at( $current, $total );
  $p->at( $current, $total, $message );

Report progress (but only if the progress since the last output is greater
than L<squelch>).  Message is optional.

If C<$total> is undefined, it uses any previous value of C<$total>, else C<1>.
If the total is exactly '1', then this will print C<$current>
as a formatted decimal.  Otherwise it prints the fraction of C<$current>/C<$total>.
When using fractional form, the decimal precision is omitted if C<$current> is
a whole number.

This function stores C<$current> and C<$total> for later calls.

=head2 progress

Backward-compatible name for L</at>, but doesn't preserve previous C<$total>.

=head2 inc

  $progress->inc;               # increment by 1
  $progress->inc(5)             # increment by 5
  $progress->inc(1, $message);  # increment by 1 and include a message

Increment the numerator of the progress, and print if it is greater than
L</squelch>.

=head2 data

If you want to write any progress-associated data, use this method.
The data must be a hashref.  It gets encoded as pure-ascii JSON.

=head2 substep

  $progress_obj= $progress->substep( $id, $contribution, $title );

Create a named sub-step progress object, and declare it on the output.

C<$id> and C<$title> are required.  The C<$contribution> rate (a multiplier
for applying the sub-step's progress to the parent progress bar) is
recommended but not required.

Note that the sub-step gets declared on the output stream each time you call
this method, but it isn't harmful to do so multiple times for the same step.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.13

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
