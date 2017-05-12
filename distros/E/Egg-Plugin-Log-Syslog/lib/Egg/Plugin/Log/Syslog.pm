package Egg::Plugin::Log::Syslog;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Syslog.pm 217 2007-11-07 00:49:15Z lushe $
#
use strict;
use warnings;
use Sys::Syslog qw/:DEFAULT setlogsock/;

our $VERSION = '0.01';

=head1 NAME

Egg::Plugin::Log::Syslog - Plugin for Sys::Syslog.

=head1 SYNOPSIS

  use Egg qw/ Log::Syslog /;

  # It writes it in the log.
  $e->slog(' log message ');

=head1 DESCRIPTION

It is a plugin to use Log::Syslog module.

=head1 CONFIGRATION

First of all, please set Syslog.

  # * It is a setting example for Linux.
  
  % vi /etc/syslog.conf
  local3.*    /var/log/myapp_log
  
  % /sbin/service syslog restart
  
  # Whether the setting became effective is confirmed.
  % logger -p local3.debug ' TEST OK!! '
  % tail /var/log/myapp_log

After the above-mentioned is set, the setting of plugin_syslog is added to the
 configuration of the project.

  plugin_syslog => {
    facility    => 'local3',
    handle      => 'MYAPPLOG',
    unix_socket => 1,
    level       => 'debug',
    },

It is as follows of each item.

=over 4

=item * facility

Name of log facility set to 'syslog.conf'.

=item * handle

Electronic alias when log is opened.

Default is a project name.

=item * unix_socket

setlogsock('unix') is issued when making it to true.

* There seems to be a thing that cannot be written well if this is not done
  according to the environment.

Default is false.

=item * level

It is a log level. It always writes it at the log level set by this.

=back

And, it might be good to put the setting of the following rotations on '/etc/logrotate.d'.

  /var/log/myapp_log {
    weekly
    missingok
    notifempty
  }

* I think that it should reactivate the WEB server and the database server after
  it rotates.

=head1 METHODS

=head2 slog ([LOG_MESSAGE])

LOG_MESSAGE is written the log.

  $e->slog(' myapp memo. ');

=cut

sub _setup {
	my($e)= @_;
	my $conf= $e->config->{plugin_syslog} ||= {};
	$conf->{facility} || die q{ I want setup 'facility'. };
	$conf->{handle}   ||= $e->namespace;
	$conf->{handle}=~s{\:+} [_]g;
	setlogsock('unix') if $conf->{unix_socket};
	openlog($conf->{handle}, 'cons,pid', $conf->{facility});
	my $level= $conf->{level} || 'debug';
	*slog= sub {
		my $egg= shift;
		syslog($level, ($_[0] || 'Internal error.'));
	  };
	$e->slog(">>> '$e->{namespace}' Logging start.");
	$e->next::method;
}
sub DESTROY {
	closelog();
}

1;

__END__

=head1 SEE ALSO

L<Sys::Syslog>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>http://egg.bomcity.com/E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

