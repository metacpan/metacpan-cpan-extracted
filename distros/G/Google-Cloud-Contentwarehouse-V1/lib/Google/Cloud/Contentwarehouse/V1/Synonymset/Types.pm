package Google::Cloud::Contentwarehouse::V1::Synonymset::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SynonymSet',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet'];

coerce 'SynonymSet',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet'->new($_) };

declare 'RepeatedSynonymSet',
    as ArrayRef[SynonymSet()];

coerce 'RepeatedSynonymSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet'->new($_) } @$_ ] };

declare 'MapStringSynonymSet',
    as HashRef[SynonymSet()];

declare 'Synonym',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet::Synonym'];

coerce 'Synonym',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet::Synonym'->new($_) };

declare 'RepeatedSynonym',
    as ArrayRef[Synonym()];

coerce 'RepeatedSynonym',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet::Synonym'->new($_) } @$_ ] };

declare 'MapStringSynonym',
    as HashRef[Synonym()];

1;

__END__

=head1 NAME

Google::Cloud::Contentwarehouse::V1::Synonymset::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
