package Google::ProtocolBuffers::Dynamic::AddPragma;

use strict;
use warnings;

# protoc insertion points example

sub generate_codegen_request {
    my ($class, $request) = @_;
    my $response = Google::ProtocolBuffers::Dynamic::ProtocInterface::CodeGeneratorResponse->new;

    my ($output_file, $pragma);
    for my $parameter (split /,/, $request->get_parameter) {
        my ($key, $value) = split /=/, $parameter;

        if ($key eq 'package') {
            my $package = join '::', map ucfirst, split /\./, $value;
            ($output_file = $package) =~ s{::}{/}g;
        } elsif ($key eq 'pragma') {
            $pragma = join '::', split /\./, $value;
        }
    }

    $response->add_file(
        Google::ProtocolBuffers::Dynamic::ProtocInterface::CodeGeneratorResponse::File->new({
            # the filename needs to match the one produced by the perl-gpd plugin
            name            => "$output_file.pm",
            insertion_point => 'after_pragmas',
            content         => "use $pragma;",
        }),
    );

    return $response;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Google::ProtocolBuffers::Dynamic::AddPragma

=head1 VERSION

version 0.42

=head1 AUTHOR

Mattia Barbon <mattia@barbon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2016 by Mattia Barbon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
