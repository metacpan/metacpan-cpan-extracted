package Devel::KYTProf::Profiler::AWS::CLIWrapper;
use strict;
use warnings;
use utf8;

use AWS::CLIWrapper;

our $VERSION = "0.01";

sub apply {
    Devel::KYTProf->add_prof(
        'AWS::CLIWrapper',
        '_execute',
        sub {
            my ($orig, $self, $service, $operation, @args) = @_;

            return [
                '%s %s',
                ['service', 'operation'],
                {
                    service   => $service,
                    operation => $operation,
                },
            ];
        },
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

Devel::KYTProf::Profiler::AWS::CLIWrapper - KYTProf prolifer for AWS::CLIWrapper

=head1 SYNOPSIS

    use Devel::KYTProf;
    Devel::KYTProf->apply_prof('AWS::CLIWrapper');

=head1 DESCRIPTION

Devel::KYTProf::Profiler::AWS::CLIWrapper is KYTProf profiler for AWS::CLIWrapper.

=head1 LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

papix E<lt>mail@papix.netE<gt>

=cut

