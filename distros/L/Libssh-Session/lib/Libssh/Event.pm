
package Libssh::Event;

use strict;
use warnings;
use Exporter qw(import);
use XSLoader;

our $VERSION = '0.1';

XSLoader::load('Libssh::Session', $VERSION);

use constant SSH_OK => 0;
use constant SSH_ERROR => -1;
use constant SSH_AGAIN => -2;
use constant SSH_EOF => -127;

our @EXPORT_OK = qw(
);
our @EXPORT = qw();
our %EXPORT_TAGS = ( 'all' => [ @EXPORT, @EXPORT_OK ] );

my $err;

sub set_err {
    my ($self, %options) = @_;
    
    $err = $options{msg};
    if ($self->{raise_error}) {
        die $err;
    }
    if ($self->{print_error}) {
        warn $err;
    }
}

sub error {
    my ($self, %options) = @_;
    
    return $err;
}

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    $self->{raise_error} = 0;
    $self->{print_error} = 0;
    $self->{ssh_event} = ssh_event_new();
    $self->{session_fds} = {};
    if (!defined($self->{ssh_event})) {
        $self->set_err(msg => 'ssh_event_new failed: cannot init event');
        return undef;
    }
    
    return $self;
}

sub option_raise_error {
    my ($self, %options) = @_;
    
    $self->{raise_error} = $options{value};
    return 0;
}

sub option_print_error {
    my ($self, %options) = @_;
    
    $self->{print_error} = $options{value};
    return 0;
}

sub options {
    my ($self, %options) = @_;

    foreach my $key (keys %options) {
        my $ret;

        my $func = $self->can("option_" . lc($key));
        if (defined($func)) {
            $ret = $func->($self, value => $options{$key});
        } else {
            $self->set_err(msg => sprintf("option '%s' is not supported", $key));
            return 0;
        }
        if ($ret != 0) {
            $self->set_err(msg => sprintf("option '%s' failed: %s", $key)) if ($ret < 0);
            return 0;
        }
    }
    
    return 1;
}

sub add_session {
    my ($self, %options) = @_;
    
    if (!defined($options{session})) {
        return undef;
    }
    
    my $fd = $options{session}->get_fd();
    $self->{session_fds}->{$fd} = $options{session};
    ssh_event_add_session($self->{ssh_event}, $options{session}->get_session());
}

sub add_channel_exit_status_callback {
    my ($self, %options) = @_;
    
    ssh_channel_exit_status_callback(${$options{channel}}, "mon user data");
}

sub dopoll {
    my ($self, %options) = @_;
    
    return ssh_event_dopoll($self->{ssh_event}, $options{timeout});
}

sub DESTROY {
    my ($self) = @_;

    if (defined($self->{ssh_event})) {
        foreach (keys %{$self->{session_fds}}) {
            ssh_event_remove_session($self->{ssh_event}, $self->{session_fds}->{$_}->get_session());            
        }
        
        ssh_event_free($self->{ssh_event});
    }    
}

1;

__END__

=head1 NAME

Libssh::Event - Support for events via libssh.

=head1 SYNOPSIS

  !/usr/bin/perl

  use strict;
  use warnings;
  use Libssh::Session qw(:all);
  

=head1 DESCRIPTION

C<Libssh::Event> is a perl interface to the libssh (L<http://www.libssh.org>)
library. It doesn't support all the library. It's working in progress.

=head1 METHODS

=over 4

=item new

Create new Event object:

    my $event = Libssh::Event->new();

=item error ( )

Returns the last error message; returns undef if no error.

=back

=cut