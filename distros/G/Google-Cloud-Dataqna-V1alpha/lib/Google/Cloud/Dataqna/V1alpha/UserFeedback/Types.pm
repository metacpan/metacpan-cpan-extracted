package Google::Cloud::Dataqna::V1alpha::UserFeedback::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UserFeedback',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::UserFeedback::UserFeedback'];

coerce 'UserFeedback',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::UserFeedback::UserFeedback'->new($_) };

declare 'RepeatedUserFeedback',
    as ArrayRef[UserFeedback()];

coerce 'RepeatedUserFeedback',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::UserFeedback::UserFeedback'->new($_) } @$_ ] };

declare 'MapStringUserFeedback',
    as HashRef[UserFeedback()];

declare 'UserFeedbackRating',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Dataqna::V1alpha::UserFeedback::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
