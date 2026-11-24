package Google::Cloud::Securitycenter::V1::Exfiltration::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Exfiltration',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Exfiltration::Exfiltration'];

coerce 'Exfiltration',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Exfiltration::Exfiltration'->new($_) };

declare 'RepeatedExfiltration',
    as ArrayRef[Exfiltration()];

coerce 'RepeatedExfiltration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Exfiltration::Exfiltration'->new($_) } @$_ ] };

declare 'MapStringExfiltration',
    as HashRef[Exfiltration()];

declare 'ExfilResource',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Exfiltration::ExfilResource'];

coerce 'ExfilResource',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Exfiltration::ExfilResource'->new($_) };

declare 'RepeatedExfilResource',
    as ArrayRef[ExfilResource()];

coerce 'RepeatedExfilResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Exfiltration::ExfilResource'->new($_) } @$_ ] };

declare 'MapStringExfilResource',
    as HashRef[ExfilResource()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::Exfiltration::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
