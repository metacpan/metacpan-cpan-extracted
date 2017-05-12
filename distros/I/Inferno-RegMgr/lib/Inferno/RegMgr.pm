package Inferno::RegMgr;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v1.0.0';

use Scalar::Util qw( weaken refaddr );
use IO::Stream;     # to import consts like CONNECTED
use EV;


use constant RETRY => 1;    # sec, delay between re-connections


sub new {
    my ($class, $reg) = @_;
    my $self = {
        registry        => $reg,
        is_connected    => 0,
        io              => undef,
        t               => undef,
        tasks           => {},
    };
    bless $self, $class;
    $self->_open_event();
    return $self;
}

sub _open_event {
    my ($self) = @_;
    weaken( my $this = $self );
    $self->{io} = $self->{registry}->open_event({
        cb      => sub { $this->_cb_event(@_) },
    });
    weaken( $self->{io} );
    return;
}

sub _cb_event {
    my ($self, $e, $err) = @_;
    if ($e & CONNECTED) {
        $self->{is_connected} = 1;
        for my $task (values %{ $self->{tasks} }) {
            $task->START();
        }
    }
    if ($e & IN) {
        for my $task (values %{ $self->{tasks} }) {
            $task->REFRESH();
        }
    }
    if ($e & EOF) {
        $self->{is_connected} = 0;
        for my $task (values %{ $self->{tasks} }) {
            $task && $task->STOP();
        }
    }
    if ($e & EOF || $err) {
        weaken( my $this = $self );
        $self->{t} = EV::timer RETRY, 0, sub { $this->_open_event() };
    }
    return;
}

sub attach {
    my ($self, $task) = @_;
    croak 'already attached' if defined $task->{manager};
    weaken( $task->{manager} = $self );
    $self->{tasks}{ refaddr($task) } = $task;
    if ($self->{is_connected}) {
        $task->START();
    }
    return;
}

sub detach {
    my ($self, $task) = @_;
    croak 'not attached to this manager' if $task->{manager} != $self;
    if ($self->{is_connected}) {
        $task->STOP();
    }
    undef $task->{manager};
    delete $self->{tasks}{ refaddr($task) };
    return;
}

sub DESTROY {
    my ($self) = @_;
    for my $task (values %{ $self->{tasks} }) {
        # $task can be already freed if DESTROY called while global destruction
        $task && $self->detach($task);
    }
    if (defined $self->{io}) {
        $self->{io}->close();
    }
    $self->{t} = undef;
    return;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Inferno::RegMgr - Keep connection to OS Inferno's registry(4) and it tasks


=head1 VERSION

This document describes Inferno::RegMgr version v1.0.0


=head1 SYNOPSIS

    use EV;
    use Inferno::RegMgr;
    use Inferno::RegMgr::TCP;
    use Inferno::RegMgr::Service;
    use Inferno::RegMgr::Lookup;
    use Inferno::RegMgr::Monitor;

    my $conn = Inferno::RegMgr::TCP->new({ host => '127.0.0.1' });
    my $regmgr = Inferno::RegMgr->new( $conn );

    my $srv1 = Inferno::RegMgr::Service->new({
        name => 'srv1',
        attr => \%attr1,
    });
    my $srv2 = Inferno::RegMgr::Service->new({
        name => 'srv2',
        attr => \%attr2,
    });
    $regmgr->attach( $srv1 );
    $regmgr->attach( $srv2 );

    $regmgr->detach( $srv1 );   # some time later

    $regmgr->attach(
        Inferno::RegMgr::Lookup->new({attr=>\%srchattr,cb=>\&srch});
    );

    my $mon  = Inferno::RegMgr::Monitor->new({
        attr   => \%monitorattr,
        cb_add => \&registered,
        cb_del => \&unregistered,
    });
    $regmgr->attach( $mon );

    EV::loop;


=head1 DESCRIPTION

Using OS Inferno registry(4) is simple, but in case connection to registry
become broken (because of network issues or even registry restart) you
have to manually reconnect to registry and restore state (register your
services once again, find out changes in services you're using now, etc.).
Inferno::RegMgr will do this work for you automatically.

Inferno::RegMgr has plugin-based architecture. There two plugin types:
connection (which handle I/O to registry server) and task (like
registering your service or searching for services).

 Connection plugins:
    Inferno::RegMgr::TCP
 Task plugins:
    Inferno::RegMgr::Service
    Inferno::RegMgr::Lookup
    Inferno::RegMgr::Monitor

When you creating new Inferno::RegMgr object, you should provide
connection plugin, which will be used to access registry. Next you can
attach/detach to this Inferno::RegMgr object any amount of any task
plugins. Inferno::RegMgr will guarantee all these tasks will work when
connection to registry is available, and task's state will be
automatically restored after reconnecting to registry server.

This is EV-based module, so you have to run EV::loop in your code to use this
module.


=head1 INTERFACE 

=over

=item new( $connection_plugin )

Create new Inferno::RegMgr object, configured to use $connection_plugin to
access registry. (All task plugins attached to this object also will use
that connection plugin.)

If you lose all references to returned Inferno::RegMgr object all attached
tasks will be stopped and detached, all memory used by all plugins will be
freed (unless you will keep references to some plugins).

Return Inferno::RegMgr object.


=item attach( $task_plugin )

Attached plugin will start working as soon as connection to registry will
be available. Reference to this plugin will be stored in Inferno::RegMgr
object until that plugin will be detach()ed.

You need to keep reference to attached task plugin only if you wanna stop
(detach()) it later or if that plugin object provide additional features.

Return nothing.


=item detach( $task_plugin )

Given $task_plugin should be same as used in attach() method before.
It will be stopped and detached (but it still may keep some state, which
will may be reused if that plugin will be attach()ed again).

Return nothing.


=back


=head1 FOR PLUGIN DEVELOPERS

=head2 CONNECTION PLUGIN INTERFACE

=over

=item open_new()

=item update()

=item open_find()

=item open_event()

These methods must be provided by connection plugin. Their parameters and
return values listed at L<Inferno::RegMgr::TCP>.

=back

=head2 TASK PLUGIN INTERFACE

=over

=item {manager}

This property will be set in plugin object to reference to Inferno::RegMgr
object in attach(), and will be set to undef in detach(). Plugin should
use it to access Inferno::RegMgr object it attached to.

Usually plugin need Inferno::RegMgr object to access it property
{registry}, which contain reference to connection plugin object used to
access registry.  Another uses of Inferno::RegMgr object from task plugin
is to detach() itself or attach() another task plugins.

=item START()

=item STOP()

=item REFRESH()

These methods must be provided by task plugin. Their doesn't has
parameters and doesn't return anything. Inferno::RegMgr will call START()
when connection to registry become available, STOP() when connection to
registry lost, and REFRESH() when registry state changes (new service
registered, server change it attributes, service unregistered).

=back


=head1 DIAGNOSTICS

=over

=item C<< already attached >>

You're trying to attach() object which is already attached to this or another
Inferno::RegMgr object.

=item C<< not attached to this manager >>

You're trying to detach() object which isn't attached to this
Inferno::RegMgr object.

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-Inferno-RegMgr/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-Inferno-RegMgr>

    git clone https://github.com/powerman/perl-Inferno-RegMgr.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=Inferno-RegMgr>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Inferno-RegMgr>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Inferno-RegMgr>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Inferno-RegMgr>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/Inferno-RegMgr>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009-2010 by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
