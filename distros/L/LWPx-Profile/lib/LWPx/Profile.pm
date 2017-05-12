package LWPx::Profile;
$LWPx::Profile::VERSION = '0.2';
use strict;
use warnings;
no warnings 'redefine';

use LWP::UserAgent;
use Time::HiRes;

=head1 NAME

LWPx::Profile - Basic Timing of HTTP Requests

=head1 VERSION

version 0.2

=head1 SYNOPSIS

	use LWP::UserAgent;
	use LWPx::Profile;
	
	my $ua = LWP::UserAgent;
	
	LWPx::Profile::start_profile();
	foreach my $url (@sites) {
		$ua->get($url);
	}
	my $results = LWPx::Profile::stop_profile;


=head1 DESCRIPTION

This module provides a basic profiling framework for looking at how long
HTTP requests with LWP took to complete.  The data structure returned by
C<stop_profile> is a hashref of request-string => stats pairs.  For example:


	'GET http://www.google.com/
	User-Agent: libwww-perl/6.08

	' => {
		'shortest_duration' => '0.111438989639282',
		'time_of_first_sample' => '1424211134.8376',
		'longest_duration' => '0.202037811279297',
		'count' => 3,
		'total_duration' => '0.436195850372314',
		'time_of_last_sample' => '1424211135.07221',
		'first_duration' => '0.202037811279297'
	};


In this example, there have been three requests for http://www.google.com/.

=cut

our $original_lwp_ua_request;
our %timings;

sub start_profiling {
	_wrap_request_sub();
}

sub stop_profiling {
	*LWP::UserAgent::request = $original_lwp_ua_request;
	my %copy = %timings;
	%timings = ();
	
	return \%copy;
}

sub _wrap_request_sub {
	$original_lwp_ua_request = \&LWP::UserAgent::request;
	
	*LWP::UserAgent::request = sub {
		my ($ua, $req, @args) = @_;
		
		my $start = Time::HiRes::time();
		my $resp  = $original_lwp_ua_request->($ua, $req, @args);
		my $end   = Time::HiRes::time();
	
		my $duration = $end - $start;	
		if (my $data = $timings{$req->as_string}) {
			$data->{count}++;
			$data->{total_duration}     += $duration;
			$data->{time_of_last_sample} = $end;
			
			if ($duration < $data->{shortest_duration}) {
				$data->{shortest_duration} = $duration;
			}
			
			if ($duration > $data->{longest_duration}) {
				$data->{longest_duration} = $duration
			}
		}
		else {
			$timings{$req->as_string} = {
				count                => 1,
				total_duration       => $duration,
				first_duration       => $duration,
				shortest_duration    => $duration,
				longest_duration     => $duration,
				time_of_first_sample => $end,
				time_of_last_sample  => $end,
			};
		}
		
		return $resp;
	};
}

=head1 TODO

=over 2

=item *

The docs are pretty middling at the moment.

=back

=head1 AUTHORS

    Chris Reinhardt
    crein@cpan.org
    
=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<LWP::UserAgent>, perl(1)

=cut

1;
__END__
