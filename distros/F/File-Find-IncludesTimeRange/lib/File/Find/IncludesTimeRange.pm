package File::Find::IncludesTimeRange;

use 5.006;
use strict;
use warnings;
use Time::Piece;

=head1 NAME

File::Find::IncludesTimeRange - Takes a array of time stamped items(largely meant for use with files) returns ones that include the specified time range.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use File::Find::IncludesTimeRange;
    usexs Time::Piece;
    use Data::Dumper;

    my @files=(
        'daemonlogger.1677468390.pcap',
        'daemonlogger.1677468511.pcap',
        'daemonlogger.1677468632.pcap',
        'daemonlogger.1677468753.pcap',
        'daemonlogger.1677468874.pcap',
        'daemonlogger.1677468995.pcap',
        'daemonlogger.1677469116.pcap',
        'daemonlogger.1677469237.pcap',
        'daemonlogger.1677469358.pcap',
        'daemonlogger.1677469479.pcap',
        'daemonlogger.1677469600.pcap',
        'daemonlogger.1677469721.pcap',
        );

    print Dumper(\@files);

    my $start=Time::Piece->strptime('1677468620', '%s');
    my $end=Time::Piece->strptime(  '1677468633', '%s');

    my $found=File::Find::IncludesTimeRange->find(
                                                  items=>\@files,
                                                  start=>$start,
                                                  end=>$end,
                                                  regex=>'(?<timestamp>\d\d\d\d\d\d+)(\.pcap|(?<subsec>\.\d+)\.pcap)$',
                                                  strptime=>'%s',
                                                 );

    print Dumper($found);

=head1 SUBROUTINES

=head2 find

Searches through a list of items , finds the ones that appear to be timestamped.
It will then sort the found time stamps and return the ones that include the
specified time periods.

There following options are taken.

    - items :: A array ref of items to examine.

    - start :: A Time::Piece object set to the start time.

    - end :: A Time::Piece object set to the end time.

    - regex :: A regex to use for matching the files. Requires uses of the named
               group 'timestamp' for capturing the timestamp. If it includes micro
               seconds in it, since Time::Piece->strptime does not handle those,
               those can be captured via the group 'subsec'. They will then be
               appended to to the epoch time of any parsed timestamp for sorting
               purposes.
        - Default :: (?<timestamp>\d\d\d\d\d\d+)(\.pcap|(?<subsec>\.\d+)\.pcap)$

    - strptime :: The format for use with L<Time::Piece>->strptime.
        - Default :: %s

=cut

sub find {
	my ( $blank, %opts ) = @_;

	# some basic error checking
	if ( !defined( $opts{start} ) ) {
		die('$opts{start} is undef');
	}
	elsif ( !defined( $opts{end} ) ) {
		die('$opts{end} is undef');
	}
	elsif ( !defined( $opts{items} ) ) {
		die('$opts{items} is undef');
	}
	elsif ( ref( $opts{start} ) ne 'Time::Piece' ) {
		die('$opts{start} is not a Time::Piece object');
	}
	elsif ( ref( $opts{end} ) ne 'Time::Piece' ) {
		die('$opts{end} is not a Time::Piece object');
	}
	elsif ( ref( $opts{items} ) ne 'ARRAY' ) {
		die('$opts{items} is not a ARRAY');
	}elsif ( $opts{start} > $opts{end} ) {
		die('$opts{start} is greater than $opts{end}');
	}

	if (!defined($opts{strptime}) ) {
		$opts{strptime}='%s';
	}

	if (!defined($opts{regex})) {
		$opts{regex}='(?<timestamp>\d\d\d\d\d\d+)(\.pcap|(?<subsec>\.\d+)\.pcap)$';
	}

	my $start = $opts{start}->epoch;
	my $end   = $opts{end}->epoch;

	my $found          = {};
	my $timestamp_save = {};
	foreach my $item ( @{ $opts{items} } ) {
		if ( $item =~ /$opts{regex}/ ) {
			my $subsec        = '';
			my $timestamp_raw = $+{timestamp};
			if ( defined( $+{subsec} ) ) {
				$subsec = $+{subsec};
			}

			my $timestamp;
			eval { $timestamp = Time::Piece->strptime( $timestamp_raw, $opts{strptime} ); };
			if ( !$@ && defined($timestamp) ) {
				my $full_timestamp = $timestamp->epoch . $subsec;
				if ( !defined( $found->{$full_timestamp} ) ) {
					$found->{$full_timestamp}          = [];
					$timestamp_save->{$full_timestamp} = $timestamp;
				}
				push( @{ $found->{$full_timestamp} }, $item );
			}
		}
	}

	my @found_timestamps = sort( keys( %{$found} ) );
	my $previous_timestamp;
	my $previous_found;
	my $previous_t;
	my @timestamp_to_return;
	foreach my $current_timestamp (@found_timestamps) {
		my $t = $timestamp_save->{$current_timestamp};

		if ( ( $opts{start} <= $t ) && ( $t <= $opts{end} ) ) {
			push( @timestamp_to_return, $current_timestamp );

			# if we find one that it is between, but not equal, then add the previous as that contains the start
			if ( defined($previous_timestamp) && !$previous_found && ( $opts{start} != $t ) ) {
				$previous_found = 1;
				push( @timestamp_to_return, $previous_timestamp );
			}elsif (!$previous_found && ( $opts{start} == $t ) ) {
				$previous_found = 1;
			}
		}

		# if the time period falls between when two files was created, we will find 
		if (!$previous_found && defined($previous_timestamp) && ( $opts{end} < $t )) {
			$previous_found=1;
			push( @timestamp_to_return, $previous_timestamp );
		}

		$previous_timestamp = $current_timestamp;
		$previous_t         = $t;
	}

	my $to_return=[];
	# the second sort is needed as if 
	foreach my $item (sort(@timestamp_to_return)) {
		foreach my $file (@{ $found->{$item} }) {
			push(@{ $to_return }, $file);
		}
	}

	return $to_return;
}

=head1 AUTHOR

Zane C. Bower-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-find-includestimerange at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Find-IncludesTimeRange>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Find::IncludesTimeRange


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Find-IncludesTimeRange>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/File-Find-IncludesTimeRange>

=item * Search CPAN

L<https://metacpan.org/release/File-Find-IncludesTimeRange>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bower-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of File::Find::IncludesTimeRange
