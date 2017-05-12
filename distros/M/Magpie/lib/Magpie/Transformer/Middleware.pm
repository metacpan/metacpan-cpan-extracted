package Magpie::Transformer::Middleware;
# ABSTRACT: Use Plack Middleware Handlers As Pipeline Components
$Magpie::Transformer::Middleware::VERSION = '1.163200';
use Moose;
extends 'Magpie::Transformer';
use Magpie::Constants;
use Try::Tiny;
use Plack::Response;
use Plack::Request;


__PACKAGE__->register_events( (qw(call_middleware)));

sub load_queue { return (qw( call_middleware )) }

has middleware_class => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

has middleware_args => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    default     => sub {{}},
);

sub call_middleware {
    my ($self, $ctxt) = @_;
	my $env = $self->request->env;
	my $current_resp = $self->response->finalize;
 	my $mw_class = Plack::Util::load_class($self->middleware_class, 'Plack::Middleware');
 	my $app = sub { $current_resp };
 	my $mw_args = $self->middleware_args;
 	my $mw = $mw_class->new( app => $app, %{$mw_args});
 	my $r = $mw->call($env);
 	my $new_resp = Plack::Response->new(@$r);
 	$self->plack_response( $new_resp );
 	$self->plack_request( Plack::Request->new($env) );
    return OK;
}

# SEEALSO: Magpie

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Magpie::Transformer::Middleware - Use Plack Middleware Handlers As Pipeline Components

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
