package Linux::realtimed;

our $VERSION = '0.96';

=encoding utf8

=head1 NAME

Linux::realtimed - a drop-in daemon replacement for Incrond (see L<https://linux.die.net/man/8/incrond>).

=head1 SYNOPSIS

=begin text

root@hostname:~# ./realtimed 
realtimed rsyslog conf file /etc/rsyslog.d/realtimed.conf does not exist, creating it
created systemd service file at /etc/systemd/system/realtimed.service
already activated it via 'systemctl daemon-reload' command
exiting the program, from now on you can start it via 'systemctl start realtimed' and stop it with 'systemctl stop realtimed'
if you want to set the execution of this daemon at startup please use the command 'systemctl enable realtimed'
you can run the daemon also by simply running realtimed, but it is not advised since systemd won't monitor it
'systemctl reload realtimed' is not needed since realtimed detects and applies config changes automatically while running
the config changes are triggered when you close a config file, configuration change happens in realtime without losing incoming events
to get current running configuration in JSON format saved in dir /etc/realtimed just issue 'kill -s HUP $(cat /var/run/realtimed.pid)'

=end text

=head1 DESCRIPTION

This daemon is a drop-in replacement of Incrond compatible with its incrontab files (realtimed parses automatically Incrond tab files), that I was forced to write to overcome couple Incrond limitations:

=over 2

=item * dynamic recursive option

Incrond has an option to recursively monitor directories, (inotify does not manage automatically it) but it is unable to detect directories in monitored paths created B<after> the Incrond daemon is started.

=item * Incrond leaves zombies around, realtimed not

=item * realtimed creates automatically its own rsyslog and systemd entries and has a slew of other automated features (will integrage docs in 1.0 release)

=item * realtimed uses epoll instead of select

=back

the only drawback of realtimed is (for now) a slower fork, due to Perl interpreter overhead

=head1 NOTES

=head2 MINIMAL REQUIREMENTS

This daemon makes use of Linux inotify system call, so it is intended only for Linux kernel >= 2.6.13 and glibc >= 2.5

=head2 DEPENDENCIES

The dependencies are the wonderful Marc Lehmann's modules

=head1 SECURITY

The daemon needs of course to run as root, but all the child processes are ran accordingaly with incrontab files, that can specify different users.
Some checks are performed to be sure no user can pass malicious/tricky paths to monitor.

=head1 HELP and development

the author would be happy to receive suggestions and bug notification.
The code for this module is tracked on this L<GitHub page|https://github.com/ANSI-C/realtimed>.

=head1 LICENSE

This daemon is free software and is distributed under same terms as Perl itself.

=head1 COPYRIGHT

Copyright 2010-2038 by Anselmo Canfora.

=cut

1;
