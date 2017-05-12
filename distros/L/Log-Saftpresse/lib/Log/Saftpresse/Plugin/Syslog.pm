package Log::Saftpresse::Plugin::Syslog;

use Moose;

# ABSTRACT: syslog server input plugin for saftpresse
our $VERSION = '1.6'; # VERSION

extends 'Log::Saftpresse::Plugin';

use Time::Piece;

sub process {
	my ( $self, $stash ) = @_;
	my $line = $stash->{'message'};
	if( ! defined $line ) {
		return;
	}
	$line =~ s/[\r\n]*$//;
	my $event = $self->parse_rfc3164_line( $line );
	if( defined $event ) {
		$self->incr_one('events', 'by_host', $event->{'host'} );
		$self->incr_one('events', 'by_program', $event->{'program'} );
		@$stash{ keys %$event } = values %$event;
	}

	return;
}

has priorities => (
	is => 'ro', isa => 'ArrayRef', lazy => 1,
	default => sub { [
		'emerg',
		'alert',
		'crit',
		'error',
		'warn',
		'notice',
		'info',
		'debug',
	] },
);

has facilities => (
	is => 'ro', isa => 'ArrayRef', lazy => 1,
	default => sub { [
		'kernel',
		'user',
		'mail',
		'daemon',
		'auth',
		'syslog',
		'printer',
		'news',
		'uucp',
		'cron',
		'authpriv',
		'ftp',
		'ntp',
		'audit',
		'alert',
		'clock',
		'local0',
		'local1',
		'local2',
		'local3',
		'local4',
		'local5',
		'local6',
		'local7',
	] },
);

sub parse_rfc3164_line {
	my ( $self, $line ) = @_;
	my ( $d, $time_str, $host, $proc, $pid, $message ) =
		$line =~ m/^<(\d+)>([A-Z][a-z]{2} [\d ]\d \d\d:\d\d:\d\d|\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d+\+\d\d:\d\d) ([^ ]+) ([^\[]+)(?:\[(\d+)\])?: (.*)$/;
	if( ! defined $d || ! defined $time_str || ! defined $host || ! defined $proc || ! defined $message ) {
		return;
	}
	my $priority = $self->priorities->[ $d & 7 ];
	my $facility = $self->facilities->[ $d >> 3 ];

	my $time;
	if( $time_str =~ /^\d{4}-\d\d-\d\dT/ ) { # like 2015-05-29T15:15:55.716831+02:00
		$time_str =~ s/\.\d{6}//; # remove microseconds
		$time_str =~ s/:(\d\d)$/$1/; # remove : from zone
		eval { $time = Time::Piece->strptime($time_str, "%Y-%m-%dT%H:%M:%S%z"); };
	} elsif( $time_str =~ /^[A-Z][a-z]{2} / ) { # like May 29 15:27:32
		eval { $time = Time::Piece->strptime($time_str, "%b %e %H:%M:%S"); };
		my $now = Time::Piece->new;                                              
		# guess year
		if( $time->mon > $now->mon ) {
			# Time::Piece->year is ro :-/
			$time->[5] = $now->[5] - 1;
		} else {
			$time->[5] = $now->[5];
		}
	} else {
		return; # unknown date format :-/
	}

	return {
		defined $priority ? (priority => $priority) : (),
		defined $facility ? (facility => $facility) : (),
		time => $time,
		host => $host,
		program => $proc,
		defined $pid ? ( pid => $pid ) : (),
		message => $message,
	};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::Syslog - syslog server input plugin for saftpresse

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
