package Log::Saftpresse::Plugin::PostfixGeoStats;

use Moose;

# ABSTRACT: plugin to build postfix statistics from geoip info
our $VERSION = '1.6'; # VERSION

extends 'Log::Saftpresse::Plugin';
with 'Log::Saftpresse::Plugin::Role::CounterUtils';

sub process {
	my ( $self, $stash ) = @_;
	my $cc = $stash->{'geoip_cc'};;
	my $service = $stash->{'service'};
	my $message = $stash->{'message'};
	my $program = $stash->{'program'};

	if( ! defined $program || $program !~ /^postfix\// ) {
		return;
	}
	if( defined $cc && $stash->{'service'} eq 'smtpd' &&
			$message =~ /client=/ ) {
		$self->incr_host_one( $stash, 'client', $cc);
	}

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::PostfixGeoStats - plugin to build postfix statistics from geoip info

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
