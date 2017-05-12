package Mail::Decency::Core::Child;

use Moose;
extends 'Mail::Decency::Core::Meta';

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Scalar::Util qw/ weaken /;

=head1 NAME

Mail::Decency::Policy::Core

=head1 SYNOPSIS

    use Mail::DecencyPolicy;
    use Mail::DecencyPolicy::AWL;
    
    my $policy = Mail::DecencyPolicy->new( {
        config => '/etc/pdp/config'
    } );
    
    my $server = POE::Component::Server::Postfix->new(
        port    => 12345,
        host    => '127.0.0.1',
        filter  => 'Plain',
        handler => $policy->get_handler()
    );
    POE::Kernel->run;

=head1 DESCRIPTION

Base class for all policies

Postfix:DecencyPolicy is a bunch of policy servers which c

Base class for all decency policy handlers.

=cut


use overload '""' => \&get_name;

=head1 CLASS ATTRIBUTES

=cut

has name   => ( is => 'rw', isa => 'Str', required => 1 );
has server => ( is => 'rw', isa => 'Mail::Decency::Core::Server', required => 1, weak_ref => 1 );


=head1 METHODS

=head2 get_handlers

Return handlers as a single sub-ref

=cut

sub get_handlers {
    my ( $self ) = @_;
    
    # check wheter having config!
    die "No config has been set\n"
        unless $self->has_config;
    
    weaken( my $self_weak = $self );
    return sub {
        return $self_weak->handle( @_ );
    };
}


=head2 handle


=cut

sub handle {
    die "Handler has to be defined for child module ". ( ref( shift ) ). "\n";
}



=head2 get_name

Used for the overloaded string context

=cut

sub get_name {
    return shift->name;
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;
