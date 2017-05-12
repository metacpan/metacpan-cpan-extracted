package Log::Progress::Parser;
$Log::Progress::Parser::VERSION = '0.11';
use Moo 2;
use JSON;

# ABSTRACT: Parse progress data from a file


has input     => ( is => 'rw' );
has input_pos => ( is => 'rw' );
has state     => ( is => 'rw', default => sub { {} } );
*status= *state;  # alias, since I changed the API
has sticky_message => ( is => 'rw' );
has on_data   => ( is => 'rw' );


sub parse {
	my $self= shift;
	my $fh= $self->input;
	if (!ref $fh) {
		my $input= $fh;
		undef $fh;
		open $fh, '<', \$input or die "open(scalar): $!";
	}
	if ($self->input_pos) {
		seek($fh, $self->input_pos, 0)
			or die "seek: $!";
	}
	# TODO: If input is seekable, then seek to end and work backward
	#  Substeps will make that rather complicated.
	my $pos;
	my %parent_cleanup;
	local $_;
	while (<$fh>) {
		last unless substr($_,-1) eq "\n";
		$pos= tell($fh);
		next unless $_ =~ /^progress: (([[:alpha:]][\w.]*) )?(.*)/;
		my ($step_id, $remainder)= ($2, $3);
		my $state= $self->step_state($step_id, 1, \my @state_parent);
		# First, check for progress number followed by optional message
		if ($remainder =~ m,^([\d.]+)(/(\d+))?( (.*))?,) {
			my ($num, $denom, $message)= ($1, $3, $5);
			if (defined $message) {
				$message =~ s/^- //; # "- " is optional syntax
				$state->{message}= $message;
			} else {
				$state->{message}= '' if !defined $state->{message} or !$self->sticky_message;
			}
			$state->{progress}= $num+0;
			if (defined $denom) {
				$state->{current}= $num;
				$state->{total}= $denom;
				$state->{progress} /= $denom;
			}
			if ($state->{contribution}) {
				# Need to apply progress to parent nodes at end
				$parent_cleanup{$state_parent[$_]}= [ $_, $state_parent[$_] ]
					for 0..$#state_parent;
			}
		}
		elsif ($remainder =~ m,^\(([\d.]+)\) (.*),) {
			my ($contribution, $title)= ($1, $2);
			$title =~ s/^- //; # "- " is optional syntax
			$state->{title}= $title;
			$state->{contribution}= $contribution+0;
		}
		elsif ($remainder =~ /^\{/) {
			my $data= JSON->new->decode($remainder);
			$state->{data}= !defined $self->on_data? $data
				: $self->on_data->($self, $step_id, $data);
		}
		else {
			warn "can't parse progress message \"$remainder\"\n";
		}
	}
	# Mark file position for next call
	$self->input_pos($pos);
	# apply child progress contributions to parent nodes
	for (sort { $b->[0] <=> $a->[0] } values %parent_cleanup) {
		my $state= $_->[1];
		$state->{progress}= 0;
		for (values %{$state->{step}}) {
			$state->{progress} += $_->{progress} * $_->{contribution}
				if $_->{progress} && $_->{contribution};
		}
	}
	return $self->state;
}


sub step_state {
	my ($self, $step_id, $create, $path)= @_;
	my $state= $self->state;
	if (defined $step_id and length $step_id) {
		for (split /\./, $step_id) {
			push @$path, $state if $path;
			$state= ($state->{step}{$_} or do {
				return undef unless $create;
				my $idx= scalar(keys %{$state->{step}});
				$state->{step}{$_}= { idx => $idx };
			});
		}
	}
	$state;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Progress::Parser - Parse progress data from a file

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  open my $fh, "<", $logfile or die;
  my $parser= Log::Progress::Parser->new(input => $fh);
  $parser->parse;

A practical application:

  # Display a 40-character progress bar at 1-second intervals
  $|= 1;
  while (1) {
    $parser->parse;
    printf "\r%3d%%  [%-40s] ",
      $parser->state->{progress}*100,
      "#" x int($parser->state->{progress}*40);
    last if $parser->state->{progress} >= 1;
    sleep 1;
  }
  print "\n";

=head1 DESCRIPTION

This module parses
L<progress messages|http://github.com/nrdvana/Log-Progress/blob/master/README.md>
from a file handle or string.
Repeated calls to the L</parse> method will continue parsing the file
where it left off, making it relatively efficient to repeatedly call
L</parse> on a live log file.

=head1 ATTRIBUTES

=head2 input

This is a seekable file handle or scalar of log text from which the progress
data will be parsed.  Make sure to set the utf-8 layer on the file handle if
you want to read progress messages that are more than just ascii.

=head2 input_pos

Each call to parse makes a note of the start of the final un-finished line, so
that the next call can pick up where it left off, assuming the file is growing
and the file handle is seekable.

=head2 state

This is a hashref of data describing the progress found in the input.

  {
    progress => $number_between_0_and_1,
    message  => $current_progress_messsage,  # empty string if no message
    current  => $numerator,   # only present if progress was a fraction
    total    => $denominator, #
    step     => { $step_id => \%step_state, ... },
    data     => \%data,       # most recent JSON data payload, decoded
  }

Substeps may additionally have the keys:

    idx          => $order_of_declaration,   # useful for sorting
    title        => $name_of_this_step,
    contribution => $percent_of_parent_task, # can be undef

=head2 sticky_message

Defaults to false.  If set to true, then progress lines lacking a message will
not clear the message of a previous progress line.

=head2 on_data

Optional coderef to handle JSON data discovered on input.  The return value
of this coderef will be stored in the L</data> field of the current step.

For example, you might want to combine all the data instead of overwriting it:

  my $parser= Log::Progress::Parser->new(
    on_data => sub {
      my ($parser, $step_id, $data)= @_;
      my $prev_data= $parser->step_state($step_id)->{data} || {};
      return Hash::Merge::merge( $prev_data, $data );
    }
  );

=head1 METHODS

=head2 parse

Read (any additional) L</input>, and return the L</state> field, or die trying.

  my $state= $parser->parse;

Sets L</input_pos> just beyond the end of the final complete line of text, so
that the next call to L</parse> can follow a growing log file.

=head2 step_state

  my $state= $parser->step_state($step_id, $create_if_missing);
  my $state= $parser->step_state($step_id, $create_if_missing, \@path_out);

Convenience method to traverse L</state> to get the data for a step.
If the second paramter is false, this returns undef if the step is not yet
defined.  Else it creates a new state node, with C<idx> initialized.

If you pass the third parameter C<@path_out> it will receive a list of the
parent nodes of the returned state node.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
