package Lim::RPC::TLS;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(weaken);

use AnyEvent::TLS ();
use Net::SSLeay ();

use Lim ();

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;
our $INSTANCE;

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {
        logger => Log::Log4perl->get_logger($class),
    };
    bless $self, $class;
    weaken($self->{logger});

    eval {
        if (!defined Lim::Config->{rpc}->{tls}->{key_file}) {
            $@ = 'No key_file set';
        }
        elsif (!defined Lim::Config->{rpc}->{tls}->{cert_file}) {
            $@ = 'No cert_file set';
        }
        else {
            $self->{tls_ctx} = AnyEvent::TLS->new(%{Lim::Config->{rpc}->{tls}});
        }
    };
    if ($@) {
        Lim::OBJ_DEBUG and $self->{logger}->debug('Unable to initialize TLS context, will not use TLS/SSL: ', $@);
        $self->{tls_ctx} = undef;
    }

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
}

END {
    undef($INSTANCE);
}

=head2 instance

=cut

sub instance {
    $INSTANCE ||= Lim::RPC::TLS->new;
}

=head2 tls_ctx

=cut

sub tls_ctx {
    $_[0]->{tls_ctx};
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Lim

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::RPC::TLS
