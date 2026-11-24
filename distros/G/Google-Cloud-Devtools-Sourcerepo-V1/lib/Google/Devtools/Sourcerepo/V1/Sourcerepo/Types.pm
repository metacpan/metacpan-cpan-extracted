package Google::Devtools::Sourcerepo::V1::Sourcerepo::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Repo',
    as InstanceOf['Google::Devtools::Sourcerepo::V1::Sourcerepo::Repo'];

coerce 'Repo',
    from HashRef, via { 'Google::Devtools::Sourcerepo::V1::Sourcerepo::Repo'->new($_) };

declare 'RepeatedRepo',
    as ArrayRef[Repo()];

coerce 'RepeatedRepo',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Sourcerepo::V1::Sourcerepo::Repo'->new($_) } @$_ ] };

declare 'MapStringRepo',
    as HashRef[Repo()];

declare 'MirrorConfig',
    as InstanceOf['Google::Devtools::Sourcerepo::V1::Sourcerepo::MirrorConfig'];

coerce 'MirrorConfig',
    from HashRef, via { 'Google::Devtools::Sourcerepo::V1::Sourcerepo::MirrorConfig'->new($_) };

declare 'RepeatedMirrorConfig',
    as ArrayRef[MirrorConfig()];

coerce 'RepeatedMirrorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Sourcerepo::V1::Sourcerepo::MirrorConfig'->new($_) } @$_ ] };

declare 'MapStringMirrorConfig',
    as HashRef[MirrorConfig()];

declare 'GetRepoRequest',
    as InstanceOf['Google::Devtools::Sourcerepo::V1::Sourcerepo::GetRepoRequest'];

coerce 'GetRepoRequest',
    from HashRef, via { 'Google::Devtools::Sourcerepo::V1::Sourcerepo::GetRepoRequest'->new($_) };

declare 'RepeatedGetRepoRequest',
    as ArrayRef[GetRepoRequest()];

coerce 'RepeatedGetRepoRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Sourcerepo::V1::Sourcerepo::GetRepoRequest'->new($_) } @$_ ] };

declare 'MapStringGetRepoRequest',
    as HashRef[GetRepoRequest()];

declare 'ListReposRequest',
    as InstanceOf['Google::Devtools::Sourcerepo::V1::Sourcerepo::ListReposRequest'];

coerce 'ListReposRequest',
    from HashRef, via { 'Google::Devtools::Sourcerepo::V1::Sourcerepo::ListReposRequest'->new($_) };

declare 'RepeatedListReposRequest',
    as ArrayRef[ListReposRequest()];

coerce 'RepeatedListReposRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Sourcerepo::V1::Sourcerepo::ListReposRequest'->new($_) } @$_ ] };

declare 'MapStringListReposRequest',
    as HashRef[ListReposRequest()];

declare 'ListReposResponse',
    as InstanceOf['Google::Devtools::Sourcerepo::V1::Sourcerepo::ListReposResponse'];

coerce 'ListReposResponse',
    from HashRef, via { 'Google::Devtools::Sourcerepo::V1::Sourcerepo::ListReposResponse'->new($_) };

declare 'RepeatedListReposResponse',
    as ArrayRef[ListReposResponse()];

coerce 'RepeatedListReposResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Sourcerepo::V1::Sourcerepo::ListReposResponse'->new($_) } @$_ ] };

declare 'MapStringListReposResponse',
    as HashRef[ListReposResponse()];

declare 'CreateRepoRequest',
    as InstanceOf['Google::Devtools::Sourcerepo::V1::Sourcerepo::CreateRepoRequest'];

coerce 'CreateRepoRequest',
    from HashRef, via { 'Google::Devtools::Sourcerepo::V1::Sourcerepo::CreateRepoRequest'->new($_) };

declare 'RepeatedCreateRepoRequest',
    as ArrayRef[CreateRepoRequest()];

coerce 'RepeatedCreateRepoRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Sourcerepo::V1::Sourcerepo::CreateRepoRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRepoRequest',
    as HashRef[CreateRepoRequest()];

declare 'DeleteRepoRequest',
    as InstanceOf['Google::Devtools::Sourcerepo::V1::Sourcerepo::DeleteRepoRequest'];

coerce 'DeleteRepoRequest',
    from HashRef, via { 'Google::Devtools::Sourcerepo::V1::Sourcerepo::DeleteRepoRequest'->new($_) };

declare 'RepeatedDeleteRepoRequest',
    as ArrayRef[DeleteRepoRequest()];

coerce 'RepeatedDeleteRepoRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Sourcerepo::V1::Sourcerepo::DeleteRepoRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRepoRequest',
    as HashRef[DeleteRepoRequest()];

1;

__END__

=head1 NAME

Google::Devtools::Sourcerepo::V1::Sourcerepo::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
