package Magpie::Error::Simplified;
$Magpie::Error::Simplified::VERSION = '1.163200';
use Moose::Role;

# A simple role to work around HTTP::Throwable's over-helpfulness

sub body { shift->reason }

sub body_headers {
    my ($self, $body) = @_;
    return [
        'Content-Length' => length $body,
    ];
}

sub as_string { shift->body }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Magpie::Error::Simplified

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
