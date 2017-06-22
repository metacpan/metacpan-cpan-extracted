package Data::DTO::GELF::Types;

# ABSTRACT: Special types for log level conversion
our $VERSION = '1.7'; # VERSION 1.7
our $VERSION=1.7;
use MooseX::Types -declare => [
    qw(
        LogLevel

        )
];

use MooseX::Types::Moose qw/Int Str/;

use Readonly;
Readonly my %LOGLEVEL_MAP => (
    DEBUG     => 0,
    INFO      => 1,
    NOTICE    => 2,
    WARNING   => 3,
    ERROR     => 4,
    CRITICAL  => 5,
    ALERT     => 6,
    EMERGENCY => 8
);

subtype LogLevel, as Int;

coerce LogLevel, from Str, via { $LOGLEVEL_MAP{ uc $_ } // $_; };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::DTO::GELF::Types - Special types for log level conversion

=head1 VERSION

version 1.7

=head1 AUTHOR

Brandon "Dimentox Travanti" Husbands <xotmid@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Brandon "Dimentox Travanti" Husbands.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
