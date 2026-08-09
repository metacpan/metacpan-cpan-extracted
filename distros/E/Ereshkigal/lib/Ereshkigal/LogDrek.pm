package Ereshkigal::LogDrek;

use 5.006;
use strict;
use warnings;
use Exporter    qw( import );
use Sys::Syslog qw( closelog openlog syslog );

=pod

=head1 NAME

Ereshkigal::LogDrek - Exportable syslog helper shared by the Ereshkigal bins and modules.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

our @EXPORT_OK = qw( log_drek );

=head1 SYNOPSIS

    use Ereshkigal::LogDrek qw( log_drek );

    log_drek( 'info', 'started' );
    log_drek( 'err',  'something broke', $tracking_int );
    log_drek( 'info', 'banned 1.2.3.4', undef, 'kur-sshd' );

=head1 DESCRIPTION

This holds the C<log_drek> sub used by both C<ereshkigal> and C<kur> as well
as the various Ereshkigal modules for logging everything they do. It is a
plain function usable without new or the like being called, exported on
request, so everything can share one implementation instead of each carrying
their own copy.

=head1 EXPORTS

Nothing is exported by default. L</log_drek> is available via C<@EXPORT_OK>.

=head1 FUNCTIONS

=head2 log_drek

Writes a message to syslog.

    log_drek( $level, $message, $tracking_int, $ident );

C<$level> defaults to 'info' when undef or not a valid syslog level. When
C<$tracking_int> is defined it is prepended to the message as
C<< $tracking_int . ' : ' . $message >>. C<$ident> is the syslog ident to log
under and defaults to 'ereshkigal' when undef. Kur instances should pass
C<'kur-' . $name> so log lines are attributable per instance.

Logging failures are swallowed rather than propagated, with a best effort
print to STDERR instead, so logging can never take down the caller.

=cut

sub log_drek {
	my ( $level, $message, $tracking_int, $ident ) = @_;

	if ( !defined($level) ) {
		$level = 'info';
	}

	# syslog dies on priorities it does not recognize, so anything not a
	# valid level falls back to info
	my %valid_syslog_levels = (
		'emerg'   => 1,
		'alert'   => 1,
		'crit'    => 1,
		'err'     => 1,
		'warning' => 1,
		'notice'  => 1,
		'info'    => 1,
		'debug'   => 1,
	);
	if ( !defined( $valid_syslog_levels{$level} ) ) {
		$level = 'info';
	}

	if ( !defined($message) ) {
		$message = '';
	}
	chomp($message);

	if ( defined($tracking_int) ) {
		$message = $tracking_int . ' : ' . $message;
	}

	if ( !defined($ident) ) {
		$ident = 'ereshkigal';
	}

	# logging must never take down the caller, so failures talking to
	# syslog are swallowed, with a best effort print to STDERR instead
	eval {
		openlog( $ident, 'cons,pid', 'daemon' );
		syslog( $level, '%s', $message );
		closelog();
	};
	if ($@) {
		eval { print STDERR $ident . ' ' . $level . ': ' . $message . "\n"; };
	}

	return;
} ## end sub log_drek

1;
