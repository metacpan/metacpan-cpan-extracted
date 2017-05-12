package Magpie::Error;
$Magpie::Error::VERSION = '1.163200';
use Moose;
extends 'HTTP::Throwable::Factory';

sub roles_for_no_ident {
    my ($self, $ident) = @_;
    return qw(
        HTTP::Throwable::Role::Generic
    );
}

sub extra_roles {
    return qw(
        Magpie::Error::Simplified
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Magpie::Error

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
