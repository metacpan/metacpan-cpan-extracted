package IO::BufferedSelect2;

use strict;
use warnings;
use Linux::Inotify2;

=head1 NAME

IO::BufferedSelect2 - Line-buffered select interface with stream-reading facility

=head1 SYNOPSIS

    use IO::BufferedSelect2;
    my $bs = new IO::BufferedSelect2( { $fn1 => $fh1, $fn2 => $fh2 });
    # $fn1 is the filename. $fh1 is the already-opened filehandle of $fn1
    while(1)
    {
        my @ready = $bs->read_line(1);	# blocks if no data on any files
	my $more=0;
        foreach(@ready)
        {
            my ($fh, $line) = @$_;
            my $fh_name = ($fh == $fh1 ? "fh1" : "fh2");
	    if(defined($line)) {
              print "$fh_name: $line"; $more++;
            } else {
              print "$fh_name (hit EOF - waiting for more lines to arrive)\n";
            }
        }
	if(!$more) { print "Hit end on all - you can exit here if you don't expect the input files to grow\n"; }
    }

=head1 DEPENDENCIES

Linux::Inotify2;

=head1 DESCRIPTION

Update of C<IO::BufferedSelect> supporting "C<tail -f>" facility (ability to 
read from files which might be growing, like logs etc). Uses C<Linux::Inotify2>

The perl C<select> and linux C<inotify> system calls allow us to process
multiple streams simultaneously, blocking until one or more of them is ready for
reading or writing or when EOF is hit.  Unfortunately, this requires us to use
C<sysread> and C<syswrite> rather than Perl's buffered I/O functions.  In the 
case of reading, there are three issues with combining C<select> with C<readline>:
(1) C<select> might block but the data we want is already in Perl's input buffer,
ready to be slurped in by C<readline>; (2) C<select> might indicate that data is
available, but C<readline> will block because there isn't a full C<$/>-terminated
line available; and (3) C<select> might B<not> block (thus preventing us from
sleeping), even though there is no data to read (e.g. at C<EOF>, the end of a 
file, even if the file might be extended later) 

The purpose of this module is to implement a buffered version of the C<select>
interface that operates on I<lines>, rather than characters.  Given a set of
filehandles, it will block until a full line is available on one or more of
them.

Note that this module is currently limited, in that it only does C<select>
for readability, not writability or exceptions. C<$/> is the line separator.

=cut

our $VERSION = '1.1';

=head1 CONSTRUCTOR

=over

=item new ( HANDLES )

Create a C<BufferedSelect2> object for a set of filename+filehandle pairs.
Note that because this class buffers input from these filehandles internally,
you should B<only> use the C<BufferedSelect2> object for reading from them
(you shouldn't read from them directly or pass them to other BufferedSelect2
instances).

=back

=cut

sub new($%)
{
	my $class   = shift;
	my($handles)= @_;
	my $inotify = Linux::Inotify2->new;
	$inotify->watch($_, IN_MODIFY) foreach(keys(%{$handles}));
	$inotify->blocking(0);

	my $self = { handles  => $handles,
	             buffers  => { map { $_, '' } keys(%{$handles}) },
	             inotify  => $inotify,
	             eof      => { map { $_, 0 } keys(%{$handles}) }};

	return bless $self;
}

=head1 METHODS

=over

=item read_line

=item read_line ($blocking)

=item read_line ($blocking, %handles)

Block until a line is available on one of the filehandles.  If C<$blocking> is
C<undef>, it blocks indefinitely; otherwise, it returns only when new data 
becomes available.

If C<%handles> is specified, then only these filehandles will be considered;
otherwise, it will use all filehandles passed to the constructor.

Returns a list of pairs S<C<[$fh, $line]>>, where C<$fh> is a filehandle and
C<$line> is the line that was read (including the newline, ala C<readline>).  If
the filehandle reached EOF, one C<$line> of C<undef> will return; but you may 
B<keep reading> from this C<$fh>; as soon as more data arrives,  C<$line> will
again return it (and in future another C<undef> when EOF is again reached, etc.)

=cut

sub read_line($;$%)
{
	my $self = shift;
	my ($blocking, %handles) = @_;
        my $anyeof=0;

	for( my $is_first = 1 ; 1 ; $is_first = 0 )
	{
		# If we have any lines in buffers, return those first
		my @result = (); my $bits=''; my $notifies;

		foreach my $idx( keys %{$self->{handles}} )
		{
			next if %handles and not $handles{$idx};
			if( $self->{eof}->{$idx} )
			{
				$anyeof++; # so we know it's time to start calling inotify
			} else {
				vec($bits, fileno($self->{handles}->{$idx}), 1) = 1; # for subsequent select
			}

			if (( my $i=index($self->{buffers}->{$idx},$/))>=0) 
			{
				push @result, [ $self->{handles}->{$idx}, substr($self->{buffers}->{$idx},0,$i+length($/)) ];
				$self->{buffers}->{$idx}=substr($self->{buffers}->{$idx},$i+length($/));
			}
			elsif($self->{eof}->{$idx}==1)
			{
				# NOTE: partial lines will only return after next \n arrives
				push @result, [ $self->{handles}->{$idx}, undef ]; # let caller know (one time only) that we hit EOF
				$self->{eof}->{$idx}=2; # only send 1 undef back to them
			}
		}

		# Only give it one shot if $blocking is defined
		return @result if ( @result or (defined($blocking) and !$is_first) );

		local *check_events = sub {
			my @events=$self->{inotify}->read;
			foreach my $event (@events)
			{
				#print $event->fullname . " was modified\n" if $event->IN_MODIFY;
				if(($self->{eof}->{$event->fullname}) && ($event->IN_MODIFY)){
					$self->{eof}->{$event->fullname}=0;
					vec($bits, fileno($self->{handles}->{$event->fullname}), 1) = 1 unless(%handles and not $handles{$event->fullname});
				}
			}
		    return;
		};

		&check_events() if($anyeof); # updates $self->{eof} and $bits

		my $nr=select(my $read=$bits,undef,undef,0);
		if(!$nr) { # would block in any select with timeout
			return () unless($blocking);
			$self->{inotify}->blocking(1); # We want to block now
			&check_events(); # might change eofs for next call - note that this blocks forever if no files become readable
			$self->{inotify}->blocking(0);
		}

		# Read into $self->{buffers}
		foreach my $idx( keys %{$self->{handles}} )
                {
                        next if (( %handles and not $handles{$idx} ) || ( !vec( $read , fileno($self->{handles}->{$idx}),1 ) ));
			my $bytes = sysread $self->{handles}->{$idx}, $self->{buffers}->{$idx}, 1024, length $self->{buffers}->{$idx};
                        $self->{eof}->{$idx} = 1 if($bytes == 0);
		}

	}
}


1;

__END__

=back

=head1 SEE ALSO

L<IO::Select>
L<IO::BufferedSelect>

=head1 AUTHOR

Chris Drake, E<lt>cdrake@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

C<IO::BufferedSelect2> Copyright (C) 2021 by Chris Drake
C<IO::BufferedSelect> Copyright (C) 2007 by Antal Novak

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
