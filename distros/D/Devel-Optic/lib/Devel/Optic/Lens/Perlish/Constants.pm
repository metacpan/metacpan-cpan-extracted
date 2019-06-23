package Devel::Optic::Lens::Perlish::Constants;
$Devel::Optic::Lens::Perlish::Constants::VERSION = '0.012';
# ABSTRACT: Useful constants for the Perlish lens

use strict;
use warnings;

use Exporter qw(import);

use constant {
    DEBUG => $ENV{DEVEL_OPTIC_DEBUG} ? 1 : 0
};

my %ast_nodes;
my %interpreter;
BEGIN {
    %ast_nodes = (
        OP_ACCESS       => DEBUG ? "OP_ACCESS" : 1,
        OP_HASHKEY      => DEBUG ? "OP_HASHKEY" : 2,
        OP_ARRAYINDEX   => DEBUG ? "OP_ARRAYINDEX" : 3,
        SYMBOL          => DEBUG ? "SYMBOL" : 4,
        STRING          => DEBUG ? "STRING" : 5,
        NUMBER          => DEBUG ? "NUMBER" : 6,
    );

    %interpreter = (
        NODE_TYPE => 0,
        NODE_PAYLOAD => 1,
        RAW_DATA_SAMPLE_SIZE => 10,
    );

    our @EXPORT_OK = (keys %ast_nodes, keys %interpreter);
    our %EXPORT_TAGS = (
        all => [keys %ast_nodes, keys %interpreter],
    );
}

use constant \%ast_nodes;
use constant \%interpreter;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Optic::Lens::Perlish::Constants - Useful constants for the Perlish lens

=head1 VERSION

version 0.012

=head1 AUTHOR

Ben Tyler <btyler@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Ben Tyler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
