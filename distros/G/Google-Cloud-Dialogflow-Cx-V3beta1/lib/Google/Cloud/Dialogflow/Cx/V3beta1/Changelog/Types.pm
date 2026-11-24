package Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListChangelogsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsRequest'];

coerce 'ListChangelogsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsRequest'->new($_) };

declare 'RepeatedListChangelogsRequest',
    as ArrayRef[ListChangelogsRequest()];

coerce 'RepeatedListChangelogsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsRequest'->new($_) } @$_ ] };

declare 'MapStringListChangelogsRequest',
    as HashRef[ListChangelogsRequest()];

declare 'ListChangelogsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsResponse'];

coerce 'ListChangelogsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsResponse'->new($_) };

declare 'RepeatedListChangelogsResponse',
    as ArrayRef[ListChangelogsResponse()];

coerce 'RepeatedListChangelogsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsResponse'->new($_) } @$_ ] };

declare 'MapStringListChangelogsResponse',
    as HashRef[ListChangelogsResponse()];

declare 'GetChangelogRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::GetChangelogRequest'];

coerce 'GetChangelogRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::GetChangelogRequest'->new($_) };

declare 'RepeatedGetChangelogRequest',
    as ArrayRef[GetChangelogRequest()];

coerce 'RepeatedGetChangelogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::GetChangelogRequest'->new($_) } @$_ ] };

declare 'MapStringGetChangelogRequest',
    as HashRef[GetChangelogRequest()];

declare 'Changelog',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::Changelog'];

coerce 'Changelog',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::Changelog'->new($_) };

declare 'RepeatedChangelog',
    as ArrayRef[Changelog()];

coerce 'RepeatedChangelog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::Changelog'->new($_) } @$_ ] };

declare 'MapStringChangelog',
    as HashRef[Changelog()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
