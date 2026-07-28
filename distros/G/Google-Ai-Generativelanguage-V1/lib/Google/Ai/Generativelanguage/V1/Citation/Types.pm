package Google::Ai::Generativelanguage::V1::Citation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CitationMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1::Citation::CitationMetadata'];

coerce 'CitationMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::Citation::CitationMetadata'->new($_) };

declare 'RepeatedCitationMetadata',
    as ArrayRef[CitationMetadata()];

coerce 'RepeatedCitationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::Citation::CitationMetadata'->new($_) } @$_ ] };

declare 'MapStringCitationMetadata',
    as HashRef[CitationMetadata()];

declare 'CitationSource',
    as InstanceOf['Google::Ai::Generativelanguage::V1::Citation::CitationSource'];

coerce 'CitationSource',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::Citation::CitationSource'->new($_) };

declare 'RepeatedCitationSource',
    as ArrayRef[CitationSource()];

coerce 'RepeatedCitationSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::Citation::CitationSource'->new($_) } @$_ ] };

declare 'MapStringCitationSource',
    as HashRef[CitationSource()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1::Citation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
