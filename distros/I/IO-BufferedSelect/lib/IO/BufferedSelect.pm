package IO::BufferedSelect;

use strict;
use warnings;
use IO::Select;

=head1 NAME

IO::BufferedSelect - Line-buffered select interface

=head1 SYNOPSIS

    use IO::BufferedSelect;
    my $bs = new BufferedSelect($fh1, $fh2);
    while(1)
    {
        my @ready = $bs->read_line();
        foreach(@ready)
        {
            my ($fh, $line) = @$_;
            my $fh_name = ($fh == $fh1 ? "fh1" : "fh2");
            print "$fh_name: $line";
        }
    }

=head1 DESCRIPTION

The C<select> system call (and the C<IO::Select> interface) allows us to process
multiple streams simultaneously, blocking until one or more of them is ready for
reading or writing.  Unfortunately, this requires us to use C<sysread> and
C<syswrite> rather than Perl's buffered I/O functions.  In the case of reading,
there are two issues with combining C<select> with C<readline>: (1) C<select>
might block but the data we want is already in Perl's input buffer, ready to
be slurped in by C<readline>; and (2) C<select> might indicate that data is
available, but C<readline> will block because there isn't a full
C<$/>-terminated line available.

The purpose of this module is to implement a buffered version of the C<select>
interface that operates on I<lines>, rather than characters.  Given a set of
filehandles, it will block until a full line is available on one or more of
them.

Note that this module is currently limited, in that (1) it only does C<select>
for readability, not writability or exceptions; and (2) it does not support
arbitrary line separators (C<$/>): lines must be delimited by newlines.

=cut

our $VERSION = '1.0';

=head1 CONSTRUCTOR

=over

=item new ( HANDLES )

Create a C<BufferedSelect> object for a set of filehandles.  Note that because
this class buffers input from these filehandles internally, you should B<only>
use the C<BufferedSelect> object for reading from them (you shouldn't read from
them directly or pass them to other BufferedSelect instances).

=back

=cut

sub new($@)
{
	my $class   = shift;
	my @handles = @_;

	my $self = { handles  => \@handles,
	             buffers  => [ map { '' } @handles ],
	             eof      => [ map { 0 } @handles ],
	             selector => new IO::Select( @handles ) };

	return bless $self;
}

=head1 METHODS

=over

=item read_line

=item read_line ($timeout)

=item read_line ($timeout, @handles)

Block until a line is available on one of the filehandles.  If C<$timeout> is
C<undef>, it blocks indefinitely; otherwise, it returns after at most
C<$timeout> seconds.

If C<@handles> is specified, then only these filehandles will be considered;
otherwise, it will use all filehandles passed to the constructor.

Returns a list of pairs S<C<[$fh, $line]>>, where C<$fh> is a filehandle and
C<$line> is the line that was read (including the newline, ala C<readline>).  If
the filehandle reached EOF, then C<$line> will be undef.  Note that "reached
EOF" is to be interpreted in the buffered sense: if a filehandle is at EOF but
there are newline-terminated lines in C<BufferedSelect>'s buffer, C<read_line>
will continue to return lines until the buffer is empty.

=cut

sub read_line($;$@)
{
	my $self = shift;
	my ($timeout, @handles) = @_;

	# Convert @handles to a "set" of indices
	my %use_idx = ();
	if(@handles)
	{
		foreach my $idx( 0..$#{$self->{handles}} )
		{
			$use_idx{$idx} = 1 if grep { $_ == $self->{handles}->[$idx] } @handles;
		}
	}
	else
	{
		$use_idx{$_} = 1 foreach( 0..$#{$self->{handles}} );
	}

	for( my $is_first = 1 ; 1 ; $is_first = 0 )
	{
		# If we have any lines in buffers, return those first
		my @result = ();

		foreach my $idx( 0..$#{$self->{handles}} )
		{
			next unless $use_idx{$idx};

			if($self->{buffers}->[$idx] =~ s/(.*\n)//)
			{
				push @result, [ $self->{handles}->[$idx], $1 ];
			}
			elsif($self->{eof}->[$idx])
			{
				# NOTE: we discard any unterminated data at EOF
				push @result, [ $self->{handles}->[$idx], undef ];
			}
		}

		# Only give it one shot if $timeout is defined
		return @result if ( @result or (defined($timeout) and !$is_first) );

		# Do a select(), optionally with a timeout
		my @ready = $self->{selector}->can_read( $timeout );

		# Read into $self->{buffers}
		foreach my $fh( @ready )
		{
			foreach my $idx( 0..$#{$self->{handles}} )
			{
				next unless $fh == $self->{handles}->[$idx];
				next unless $use_idx{$idx};
				my $bytes = sysread $fh, $self->{buffers}->[$idx], 1024, length $self->{buffers}->[$idx];
				$self->{eof}->[$idx] = 1 if($bytes == 0);
			}
		}
	}
}


1;

__END__

=back

=head1 SEE ALSO

L<IO::Select>

=head1 AUTHOR

Antal Novak, E<lt>afn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Antal Novak

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
