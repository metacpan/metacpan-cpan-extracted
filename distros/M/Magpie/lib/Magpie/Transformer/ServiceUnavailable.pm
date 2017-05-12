package Magpie::Transformer::ServiceUnavailable;
$Magpie::Transformer::ServiceUnavailable::VERSION = '1.163200';
use Moose;

# ABSTRACT: Use Plack Middleware Handlers As Pipeline Components

use Magpie::Constants;
use Plack::Response;
use Plack::Request;

extends 'Magpie::Transformer';

__PACKAGE__->register_events( (qw(available)) );

sub load_queue { return (qw( available )) }

has message => (
    isa     => 'Str',
    is      => 'ro',
    default => 'We are working as hard as we can already.'
);

has retry_after => ( isa => 'Str', is => 'ro', );

sub available {
    my ( $self, $ctxt ) = @_;
    my $HTTP_503 = HTTP::Throwable::Factory->new_exception(
        {   status_code => 503,
            retry_after => $self->retry_after,
            message     => $self->message,
        }
    );
    my $r        = $mw->call( $self->request->env );
    my $new_resp = Plack::Response->new(@$r);
    $self->plack_response($new_resp);
    $self->plack_request( Plack::Request->new($env) );
    return DONE;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Magpie::Transformer::ServiceUnavailable - Use Plack Middleware Handlers As Pipeline Components

=head1 VERSION

version 1.163200

=head1 AUTHORS

=over 4

=item *

Kip Hampton <kip.hampton@tamarou.com>

=item *

Chris Prather <chris.prather@tamarou.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Tamarou, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# SEEALSO: Magpie
