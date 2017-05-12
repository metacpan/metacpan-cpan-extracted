package Magpie::Constants;
$Magpie::Constants::VERSION = '1.163200';
# ABSTRACT: Common Handler Control Constants;

use constant {
    OK            => 100,
    DECLINED      => 199,
    DONE          => 299,
    OUTPUT        => 300,
    SERVER_ERROR  => 500,
    HANDLER_ERROR => 501,
    QUEUE_ERROR   => 502,
};

use Sub::Exporter -setup => {
    exports => [
        qw(OK DECLINED DONE OUTPUT SERVER_ERROR HANDLER_ERROR QUEUE_ERROR),
        HTTP_METHODS => sub {
            my ( $class, $name, $arg, $col ) = @_;

            sub () {
                qw(GET POST PUT DELETE HEAD OPTIONS TRACE PATCH CONNECT),
                    @{ $arg{extra_http_methods} // [] },
                    @{ $col{extra_http_methods} // [] };
            };
        },
    ],
    groups => [
        default => [
            qw(OK DECLINED DONE OUTPUT SERVER_ERROR HANDLER_ERROR QUEUE_ERROR HTTP_METHODS)
        ],
    ],
    collectors => [qw(extra_http_methods)]
};

# SEEALSO: Magpie, Magpie::Component, Magpie::Event

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Magpie::Constants - Common Handler Control Constants;

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
