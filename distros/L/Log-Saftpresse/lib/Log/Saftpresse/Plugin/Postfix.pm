package Log::Saftpresse::Plugin::Postfix;

use Moose;

# ABSTRACT: plugin to parse analyse postfix logging
our $VERSION = '1.6'; # VERSION


extends 'Log::Saftpresse::Plugin';

has 'saftsumm_mode' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'message_detail' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'smtpd_warn_detail' => ( is => 'rw', isa => 'Int', default => 0 );

has 'reject_detail' => ( is => 'rw', isa => 'Int', default => 0 );
has 'bounce_detail' => ( is => 'rw', isa => 'Int', default => 0 );
has 'deferred_detail' => ( is => 'rw', isa => 'Int', default => 0 );

has 'ignore_case' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'rej_add_from' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'extended' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'uucp_mung' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'verp_mung' => ( is => 'rw', isa => 'Int', default => 0 );

has 'tls_stats' => ( is => 'rw', isa => 'Bool', default => 1 );

with 'Log::Saftpresse::Plugin::Role::CounterUtils';
with 'Log::Saftpresse::Plugin::Role::Tracking';

with 'Log::Saftpresse::Plugin::Postfix::Service';
with 'Log::Saftpresse::Plugin::Postfix::QueueID';
with 'Log::Saftpresse::Plugin::Postfix::Messages';
with 'Log::Saftpresse::Plugin::Postfix::Rejects';
with 'Log::Saftpresse::Plugin::Postfix::Recieved';
with 'Log::Saftpresse::Plugin::Postfix::Delivered';
with 'Log::Saftpresse::Plugin::Postfix::Smtp';
with 'Log::Saftpresse::Plugin::Postfix::Smtpd';
with 'Log::Saftpresse::Plugin::Postfix::Tls';

use Time::Piece;

sub process {
	my ( $self, $stash, $notes ) = @_;
	my $program = $stash->{'program'};

	if( ! defined $program || $program !~ /^postfix\// ) {
		return;
	}

  $self->get_tracking_id('pid', $stash, $notes);

	$self->process_service( $stash, $notes );
	if( ! defined $stash->{'service'} ) {
		return;
	}
	$self->process_queueid( $stash, $notes );

	$self->process_messages( $stash, $notes );
	$self->process_rejects( $stash, $notes );
	$self->process_recieved( $stash, $notes );
	$self->process_delivered( $stash, $notes );
	$self->process_smtp( $stash, $notes );
	$self->process_smtpd( $stash, $notes );
	if( $self->tls_stats ) {
		$self->process_tls( $stash, $notes );
	}

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::Postfix - plugin to parse analyse postfix logging

=head1 VERSION

version 1.6

=head1 Description

This plugin parses and analyzes postfix logging.

=head1 Synopsis

  <Plugin postfix>
    module = "postfix"
  </Plugin>

=head1 Options

=over

=item saftsumm_mode (default: 0)

If enabled the plugin will generate additional counters for per_hr,
per_wdays and per_day values required for saftsumm output.

=item message_detail (default: 0)

By default the plugin will trimm messages used by deferred_detail,
smtpd_warn_detail and reject_detail.

If enabled the full message will be used instead of the trimmed string.

=item smtpd_warn_detail (default: 0)

Enable generation of counters for smtpd warning messages.

=item reject_detail (default: 0)

Enable generation of counters per reject message.

=item bounce_detail (default: 0)

Enable generation of counters per bounce message.

=item deferred_detail (default: 0)

Enable generation of counters per deferral reason.

=item ignore_case (default: 0)

Enable to ignore case in addresses.

This will lower case all addresses.

=item rej_add_from (default: 0)

Include from address in reject messages statistics generated
by reject_detail.

=item extended (default: 0)

Remember From: address across log lines.

TODO: check what it really does.

=item uucp_mung (default: 0)

Convert uucp addresses.

=item verp_mung (default: 0)

Replace VERPs with placeholder.

=item tls_stats (default: 1)

Enable/disable TLS statistics.

=back

=head1 Input

This plugin expects a log line with

  program => /^postfix/

and log messages generate by the postfix MTA in 'message'.

=head1 Output

The plugin will add the following fields if applicable:

  * size
  * from
  * to
  * relay
  * delay
  * status
  * forwarded
  * postfix_level
  * queue_id
  * client_host
  * client_ip
  * reject_type
  * reject_reason
  * connection_time
  * client

=head1 Counters

The plugin generates the following counters:

  <host>.conn.total
  <host>.conn.per_domain.<domain>
  <host>.conn.busy.total
  <host>.conn.busy.per_domain.<domain>
  <host>.incoming.total
  <host>.reject.total.reject
  <host>.bounced.total
  <host>.recieved.by_sender.<sender>
  <host>.recieved.by_domain.<domain>
  <host>.recieved.total
  <host>.recieved.size.by_sender.<sender>
  <host>.recieved.size.by_domain.<domain>
  <host>.recieved.size.total
  <host>.tls_msg.smtpd.cipher.<tls_cipher>
  <host>.tls_msg.smtpd.keylen.<tls_keylen>
  <host>.tls_msg.smtpd.total
  <host>.tls_msg.smtpd.level.<tls_level>
  <host>.tls_msg.smtpd.proto.<tls_version>
  <host>.tls_msg.smtp.cipher.<tls_cipher>
  <host>.tls_msg.smtp.keylen.<tls_keylen>
  <host>.tls_msg.smtp.total
  <host>.tls_msg.smtp.level.<tls_level>
  <host>.tls_msg.smtp.proto.<tls_procol>
  <host>.deferred.max_delay.by_domain.<domain>
  <host>.deferred.by_domain.<domain>
  <host>.deferred.total
  <host>.tls_conn.smtpd.cipher.<tls_cipher>
  <host>.tls_conn.smtpd.keylen.<tls_keylen>
  <host>.tls_conn.smtpd.total
  <host>.tls_conn.smtpd.level.<tls_level>
  <host>.tls_conn.smtpd.proto.<tls_proto>
  <host>.tls_conn.smtp.cipher.<tls_cipher>
  <host>.tls_conn.smtp.keylen.<tls_keylen>
  <host>.tls_conn.smtp.total
  <host>.tls_conn.smtp.level.<tls_level>
  <host>.tls_conn.smtp.proto.<tls_proto>
  <host>.sent.delay.by_domain.<domain>
  <host>.sent.max_delay.by_domain.<domain>
  <host>.sent.by_domain.<domain>
  <host>.sent.total
  <host>.sent.size.by_domain.<domain>
  <host>.sent.size.total
  <host>.sent.size.by_rcpt.<recipient>
  <host>.sent.by_rcpt.<recipient>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
