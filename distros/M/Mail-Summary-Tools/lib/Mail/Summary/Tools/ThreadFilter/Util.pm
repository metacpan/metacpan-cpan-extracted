#!/usr/bin/perl

package Mail::Summary::Tools::ThreadFilter::Util;

use strict;
use warnings;

use Sub::Exporter -setup => {
	exports => [qw/
		get_root_message guess_mailing_list
		thread_root last_in_thread any_in_thread all_in_thread
		negate
		mailing_list_is in_date_range
	/],
};

use Mail::ListDetector;
use Date::Range;
use DateTime::Format::Mail;

{
	package Date::Range::Forgiving;
	use base qw/Date::Range/;
	sub want_class { "UNIVERSAL" }
}

use Scalar::Util qw/reftype blessed/;

sub get_root_message ($) {
	my $thread = shift;
	my $message = $thread->message;
	$message = ($thread->threadMessages)[0] if !$message or $message->isDummy;

	die "Couldn't determine thread root!" if !$message or $message->isDummy;

	return $message;
}

sub negate ($) {
	my $filter = shift;
	return sub { not( $filter->( @_ ) ) };
}

sub thread_root ($) {
	my $filter = shift;

	return sub {
		my $thread = shift;
		$filter->( get_root_message( $thread ) );
	}
}

sub last_in_thread ($) {
	my $filter = shift;

	return sub {
		my $thread = shift;
		my $last = ($thread->threadMessages)[-1];
		$filter->( $last );
	}
}

sub any_in_thread ($) {
	my $filter = shift;
	return sub {
		my $thread = shift;

		my $match;
		$thread->recurse(sub {
			my $message = shift->message;
			return 1 if $message->isDummy;

			if ( $filter->( $message ) ) {
				$match = 1;
				return 0; # short circuit the recursion
			} else {
				return 1;
			}
		});

		return $match;
	}
}

sub all_in_thread ($) {
	my $filter = shift;

	return sub {
		my $thread = shift;

		my $match = 1;
		$thread->recurse(sub {
			my $message = shift->message;
			return 1 if $message->isDummy;

			unless ( $filter->( $message ) ) {
				$match = 0;
				return 0; # short circuit the recursion
			} else {
				return 1;
			}
		});

		return $match;
	}
}

sub guess_mailing_list ($) {
	my $message = shift;
	Mail::ListDetector->new( $message );
}

sub mailing_list_is ($) {
	my $matchsub = _munge_list_match(shift);
	return sub {
		my $message = shift;
		my $list = guess_mailing_list( $message );
		$list && $matchsub->( $list );
	}
}

sub _munge_list_match {
	my $match = shift;
	if    ( blessed($match) ) { return sub { $match->match( shift ) } }
	elsif ( ref($match) && reftype($match) eq "CODE" ) { return $match }
	else  { return sub { no warnings 'uninitialized'; shift->listname eq $match } }
}

sub in_date_range ($$) {
	my $range = Date::Range::Forgiving->new( @_ );

	return sub {
		my $message = shift;
		my $date_header = $message->head->get('Date')->unfoldedBody;
		my $date;

		$date_header =~ s/\s*<\S+@\S+>\s*$//; # seen numerous times

		my @errors;
		$date = eval { DateTime::Format::Mail->new->loose->parse_datetime( $date_header ) };
		push @errors, $@ if $@;
		$date ||= eval { DateTime::Format::DateManip->parse_datetime( $date_header ) };
		push @errors, $@ if $@;

        die "Error parsing date '$date_header': @errors" unless defined $date;

		return $range->includes( $date );
	}
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::ThreadFilter::Util - 

=head1 SYNOPSIS

	use Mail::Summary::Tools::ThreadFilter::Util;

=head1 DESCRIPTION

=cut


