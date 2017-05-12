package Magpie::Dispatcher::RequestMethod;
$Magpie::Dispatcher::RequestMethod::VERSION = '1.163200';
#ABSTRACT: INCOMPLETE - Placeholder for future Dispatcher Role
use Moose::Role;
use Magpie::Constants;
sub events { (qw(method_not_allowed), HTTP_METHODS) };

sub load_queue {
    my $self   = shift;
    my $method = $self->plack_request->method;
    if ( scalar grep { $_ eq $method } HTTP_METHODS ) {
        return $method;
    }
    return 'method_not_allowed';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Magpie::Dispatcher::RequestMethod - INCOMPLETE - Placeholder for future Dispatcher Role

=head1 VERSION

version 1.163200

#SEEALSO: Magpie

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
