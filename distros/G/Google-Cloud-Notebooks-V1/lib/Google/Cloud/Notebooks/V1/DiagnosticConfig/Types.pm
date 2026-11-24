package Google::Cloud::Notebooks::V1::DiagnosticConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DiagnosticConfig',
    as InstanceOf['Google::Cloud::Notebooks::V1::DiagnosticConfig::DiagnosticConfig'];

coerce 'DiagnosticConfig',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::DiagnosticConfig::DiagnosticConfig'->new($_) };

declare 'RepeatedDiagnosticConfig',
    as ArrayRef[DiagnosticConfig()];

coerce 'RepeatedDiagnosticConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::DiagnosticConfig::DiagnosticConfig'->new($_) } @$_ ] };

declare 'MapStringDiagnosticConfig',
    as HashRef[DiagnosticConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Notebooks::V1::DiagnosticConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
