package Log::Saftpresse::Plugin::Apache;

use Moose;

# ABSTRACT: plugin to parse apache logs
our $VERSION = '1.6'; # VERSION

extends 'Log::Saftpresse::Plugin';

with 'Log::Saftpresse::Plugin::Role::CounterUtils';

has 'format' => ( is => 'rw', isa => 'Str', default => 'vhost_combined');

has 'detect_browser' => ( is => 'rw', isa => 'Bool', default => 1);
has 'detect_search' => ( is => 'rw', isa => 'Bool', default => 1);

use Log::Saftpresse::Log4perl;
use URI;

sub process {
	my ( $self, $event ) = @_;
	my $program = $event->{'program'};
	if( ! defined $program || $program ne 'apache' ) {
		return;
	}

	if( $self->format eq 'vhost_combined' ) {
		$self->parse_vhost_combined( $event );
	} elsif( $self->format eq 'combined' ) {
		$self->parse_combined( $event );
	} else {
		return;
	}

	if( $self->detect_browser
			&& $self->_browser_detect_installed
			&& defined $event->{'agent'} ) {
		$self->_detect_browser( $event );
	}
	if( $self->detect_search
			&& defined $event->{'referer'} ) {
		$self->_detect_search( $event );
	}

	$self->incr_host_one($event, 'total' );
	$self->count_fields_occur( $event, 'vhost', 'code' );
	$self->count_fields_value( $event, 'size' );

	return;
}

has '_browser_detect_installed' => ( is => 'ro', isa => 'Bool', lazy => 1,
	default => sub {
		eval { require HTTP::BrowserDetect }; 
		if( $@ ) {
			$log->warn('HTTP::BrowserDetect is not installed. disabled detect_browser in Apache plugin! ('.$@.')');
			return 0;
		}
		return 1;
	},
);

sub _detect_search {
	my ( $self, $event ) = @_;
	my %search;
	my $u = URI->new( $event->{'referer'} );
	my %q = $u->query_form;

	if( defined $q{'q'} ) {
		$search{'keywords'} = [ split(/\s+/, $q{'q'}) ];
		$search{'engine'} = $u->host;
	}

	if( scalar %search ) {
		$event->{'search'} = \%search;
	}

	return;
}

sub _detect_browser {
	my ( $self, $event ) = @_;
	my $b = HTTP::BrowserDetect->new( $event->{'agent'} );

	$event->{'browser'} = {
		$b->browser ? ( 'browser' => $b->browser ) : (),
		$b->browser_version ? ('version' => $b->browser_version) : (),
		$b->os ? ( 'os' => $b->os ) : (),
		$b->robot ? ('robot' => $b->robot) : (),
		$b->mobile ? ( 'mobile' => $b->mobile ) : (),
	};

	return;
}

sub parse_vhost_combined {
	my ( $self, $event, $msg ) = @_;
	if( ! defined $msg ) {
		$msg = $event->{'message'};
	}
	my ( $vhost, $port, $combined ) = 
		$msg =~ /^([^:]+):(\d+) (.*)$/;
	if( ! defined $vhost ) {
		return;
	}
	$event->{'vhost'} = $vhost;
	$event->{'port'} = $port;

	$self->parse_combined( $event, $combined );

	return;
}

sub parse_combined {
	my ( $self, $event, $msg ) = @_;
	if( ! defined $msg ) {
		$msg = $event->{'message'};
	}

	my ( $ip, $ident, $user, $ts, $request, $code, $size, $referer, $agent ) = 
		$msg =~ /^(\S+) (\S+) (\S+) \[([^\]]+)\] "([^"]+)" (\d+) (\d+) "([^"]+)" "([^"]+)"$/;
	if( ! defined $ip ) {
		return;
	}
	my $time;
	eval { $time = Time::Piece->strptime($ts, "%d/%b/%Y:%H:%M:%S %z"); };
	my ( $method, $uri, $proto ) = split(' ', $request );

	@$event{'client_ip', 'ident', 'user', 'time', 'method', 'uri', 'proto', 'code', 'size', 'referer', 'agent'}
		= ( $ip, $ident, $user, $time, $method, $uri, $proto, $code, $size, $referer, $agent);

	# remove empty fields (content "-")
	foreach my $key ( 'ident', 'user', 'referer' ) {
		if( $event->{$key} eq '-' ) {
			delete $event->{$key};
		}
	}

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::Apache - plugin to parse apache logs

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
