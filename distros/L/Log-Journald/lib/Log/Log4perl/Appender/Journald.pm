=head1 NAME

Log::Log4perl::Appender::Journald - Journald appender for Log4perl

=head1 SYNOPSIS

  use Log::Log4perl;

  my $log4perl_conf = <<EOC;
  log4perl.rootLogger = DEBUG, Journal
  log4perl.appender.Journal = Log::Log4perl::Appender::Journald
  log4perl.appender.Journal.layout = Log::Log4perl::Layout::NoopLayout
  EOC

  Log::Log4perl->init(\$log4perl_conf);
  Log::Log4perl::MDC->put(HELLO => 'World');
  my $logger = Log::Log4perl->get_logger('log4perl.rootLogger');
  $logger->info("Time to die.");
  $logger->error("Time to err.");

=head1 DESCRIPTION

This module provides a L<Log::Log4Perl> appender that directs log messages to
L<systemd-journald.service(8)> via L<Log::Journald>. It makes use of the
structured logging capability, appending Log4perl MDCs with each message.

=cut

package Log::Log4perl::Appender::Journald;

our @ISA = qw/Log::Log4perl::Appender/;

use warnings;
use strict;

use Log::Journald;
use Log::Log4perl::MDC;

sub new
{
	bless {}, shift;
}

sub log
{
	my $self = shift;
	my %params = @_;
	my $mdc = Log::Log4perl::MDC->get_context();
	my %log;

	while (my ($key, $value) = each %params) {
		$log{uc $key} = $value;
	}

	# Add MDCs
	while (my ($key, $value) = each %$mdc) {
		$log{uc $key} = $value;
	}

	# Rename
	$log{PRIORITY} = delete $log{LEVEL};

	Log::Journald::send (%log) or warn $!;
}

1;

=head1 SEE ALSO

=over

=item *

L<Log::Journald> -- Journal daemon client bindings.

=item *

L<Log::Log4perl> -- A logging framework

=back

=head1 COPYRIGHT

Copyright 2014 Lubomir Rintel

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHORS

Lubomir Rintel, L<< <lkundrak@v3.sk> >>

The code is hosted on GitHub L<http://github.com/lkundrak/perl-Log-Journald>.
Bug fixes and feature enhancements are always welcome.
