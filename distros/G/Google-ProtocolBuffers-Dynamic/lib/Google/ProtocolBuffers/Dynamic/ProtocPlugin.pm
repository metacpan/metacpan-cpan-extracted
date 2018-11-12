package Google::ProtocolBuffers::Dynamic::ProtocPlugin;

use strict;
use warnings;
use Google::ProtocolBuffers::Dynamic::ProtocInterface;

sub import {
    my ($class, %args) = @_;
    my $generator = $args{run};
    eval "require $generator; 1"
        or die "Error loding plugin '$generator': $@";

    binmode STDIN;
    binmode STDOUT;

    my $input = do {
        local $/;
        readline STDIN;
    };
    my $codegen_request = Google::ProtocolBuffers::Dynamic::ProtocInterface::CodeGeneratorRequest->decode($input);
    my $codegen_response;

    eval {
        my $code = $generator->generate_codegen_request($codegen_request);

        $codegen_response = Google::ProtocolBuffers::Dynamic::ProtocInterface::CodeGeneratorResponse->encode($code);

        1;
    } or do {
        my $error = $@ || "Zombie error";

        $codegen_response = Google::ProtocolBuffers::Dynamic::ProtocInterface::CodeGeneratorResponse->encode({
            error => $error,
        });
    };

    print STDOUT $codegen_response;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Google::ProtocolBuffers::Dynamic::ProtocPlugin

=head1 VERSION

version 0.23

=head1 AUTHOR

Mattia Barbon <mattia@barbon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2016 by Mattia Barbon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
