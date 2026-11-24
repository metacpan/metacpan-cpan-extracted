package Google::Cloud::Gsuiteaddons::Logging::V1::GSuiteAddOnsLogEntry::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GSuiteAddOnsLogEntry',
    as InstanceOf['Google::Cloud::Gsuiteaddons::Logging::V1::GSuiteAddOnsLogEntry::GSuiteAddOnsLogEntry'];

coerce 'GSuiteAddOnsLogEntry',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::Logging::V1::GSuiteAddOnsLogEntry::GSuiteAddOnsLogEntry'->new($_) };

declare 'RepeatedGSuiteAddOnsLogEntry',
    as ArrayRef[GSuiteAddOnsLogEntry()];

coerce 'RepeatedGSuiteAddOnsLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::Logging::V1::GSuiteAddOnsLogEntry::GSuiteAddOnsLogEntry'->new($_) } @$_ ] };

declare 'MapStringGSuiteAddOnsLogEntry',
    as HashRef[GSuiteAddOnsLogEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Gsuiteaddons::Logging::V1::GSuiteAddOnsLogEntry::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
