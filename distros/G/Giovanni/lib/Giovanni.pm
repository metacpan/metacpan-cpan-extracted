package Giovanni;

use 5.010;
use Mouse;
use Mouse::Util;
use Net::OpenSSH;
use Sys::Hostname;
use Cwd;
use Giovanni::Stages;

extends 'Giovanni::Stages';


our $VERSION = '1.9';

has 'debug' => (
    is        => 'rw',
    isa       => 'Bool',
    required  => 1,
    default   => 0,
    predicate => 'is_debug',
);

has 'hostname' => (
    is      => 'rw',
    isa     => 'Str',
    default => hostname(),
);

has 'repo' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => cwd(),
);

has 'scm' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'git',
);

has 'deploy_to' => (
    is      => 'rw',
    isa     => 'Str',
    default => '/var/www',
);

has 'user' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'deploy',
);

has 'version' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'v1',
);

has 'error' => (
    is  => 'rw',
    isa => 'Str',
);

has 'config' => (
    is       => 'rw',
    required => 1,
);

has 'notifyer' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'jabber',
);


sub deploy {
    my ($self) = @_;

    # load SCM plugin
    $self->load_plugin($self->scm);
    my $tag = $self->tag();
    my $ssh = $self->_get_ssh_conn;
    $self->process_stages($ssh, 'deploy');
}

sub rollback {
    my ($self, $offset) = @_;

    my $ssh = $self->_get_ssh_conn;
    $self->process_stages($ssh, 'rollback');
}

sub process_stages {
    my ($self, $ssh, $mode) = @_;

    my $conf_key = ($mode eq 'restart' ? 'deploy' : $mode);
    my @stages = split(/\s*,\s*/, $self->config->{$conf_key});
    foreach my $stage (@stages) {
        if($mode eq 'restart'){
            next unless $stage =~ m/restart/;
            $self->process_hosts($ssh, $stage, $mode);

        } else {
            $self->process_hosts($ssh, $stage, $mode);

            # if one host produced an error while restarting, rollback all
            if ($self->error and ($stage =~ m/^restart/i) and ($mode eq 'deploy')) {
                $self->log('ERROR', $self->error);
                $self->process_stages($ssh, 'rollback');
                return;
            }
        }
    }
}

sub process_hosts {
    my ($self, $ssh, $stage, $mode) = @_;

    my @hosts = split(/\s*,\s*/, $self->config->{hosts});
    foreach my $host (@hosts) {
        $self->log($ssh->{$host}, "running $stage");
        $self->$stage($ssh->{$host});
    }
}

sub _get_ssh_conn {
    my ($self) = @_;

    my @hosts = split(/\s*,\s*/, $self->config->{hosts});
    my $ssh;
    foreach my $host (@hosts) {
        my $conn = $host;
        $conn = ($self->config->{user} || $self->user) . '@' . $host;
        $ssh->{$host} = Net::OpenSSH->new($conn, async => 1);
    }

    # trigger noop command to check for connection
    foreach my $host (@hosts) {
        $ssh->{$host}->test('echo')
            or confess "could not connect to $host: " . $ssh->{$host}->error;
        $self->log($host, 'connected');
    }
    return $ssh;
}

sub restart {
    my ($self) = @_;

    my $ssh = $self->_get_ssh_conn;
    $self->process_stages($ssh, 'restart');
}

sub load_plugin {
    my ($self, $plugin) = @_;

    my $plug = 'Giovanni::Plugins::' . ucfirst(lc($plugin));
    unless (Mouse::Util::is_class_loaded($plug)) {
        print STDERR "Loading $plugin Plugin\n" if $self->is_debug;
        with($plug);    # or confess "Could not load Plugin: '$plugin'\n";
    }

    return;
}

sub log {
    my ($self, $host, $log) = @_;

    return unless $log;

    my $name;
    given ($host) {
        when (ref $host eq 'Net::OpenSSH') { $name = $host->get_host; }
        default { $name = $host; }
    }
    chomp($log);
    print STDERR "[" . $name . "] " . $log . $/;

    return;
}

sub notify {
    my ($self, $ssh, $conf) = @_;

    # load notify plugin
    $self->load_plugin($self->notifyer);
    $self->send_notify($ssh, $conf);
    return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Giovanni

=head1 VERSION

version 1.12

=head1 SYNOPSIS

Giovanni is a Perl replacement for the idea behind Capistrano. It is a
deployment system that can be used comfortably from the commandline to
check out code, restart systems and notify.
The system is currently used with git and manages some Catalyst and
Mojolicious apps and notifies via Jabber. It supports timestamped
rollouts (ie have the last 5 versions of your code on the server and link
to the currently running one) and plain git repositories. It tries to
detect problems in the deployment process and rolls back. It supports
manual rollbacks, two restart modes and does all that without any code
on the server. All you need is a working ssh setup with ssh-keys that
handle the login. 
We also use it with Jenkins to automatically deploy
code that successfully completed the test suite.

Giovanni comes with a commandline tool called gio. Check the gio manpage
for the config file format.

=head1 NAME

Giovanni - a Perl based deployment system

=head1 VERSION

Version 1.9

=head1 AUTHOR

Lenz Gschwendtner, C<< <norbu09 at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-giovanni at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Giovanni>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Giovanni

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Giovanni>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Giovanni>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Giovanni>

=item * Search CPAN

L<http://search.cpan.org/dist/Giovanni/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Lenz Gschwendtner.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Lenz Gschwendtner <mail@norbu09.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by ideegeo Group Limited.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
