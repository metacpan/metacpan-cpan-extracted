package Google::Devtools::Resultstore::V2::Action::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExecutionStrategy',
    as (Int | Str);

declare 'TestCaching',
    as (Int | Str);

declare 'Action',
    as InstanceOf['Google::Devtools::Resultstore::V2::Action::Action'];

coerce 'Action',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Action::Action'->new($_) };

declare 'RepeatedAction',
    as ArrayRef[Action()];

coerce 'RepeatedAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Action::Action'->new($_) } @$_ ] };

declare 'MapStringAction',
    as HashRef[Action()];

declare 'Id',
    as InstanceOf['Google::Devtools::Resultstore::V2::Action::Action::Id'];

coerce 'Id',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Action::Action::Id'->new($_) };

declare 'RepeatedId',
    as ArrayRef[Id()];

coerce 'RepeatedId',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Action::Action::Id'->new($_) } @$_ ] };

declare 'MapStringId',
    as HashRef[Id()];

declare 'BuildAction',
    as InstanceOf['Google::Devtools::Resultstore::V2::Action::BuildAction'];

coerce 'BuildAction',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Action::BuildAction'->new($_) };

declare 'RepeatedBuildAction',
    as ArrayRef[BuildAction()];

coerce 'RepeatedBuildAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Action::BuildAction'->new($_) } @$_ ] };

declare 'MapStringBuildAction',
    as HashRef[BuildAction()];

declare 'TestAction',
    as InstanceOf['Google::Devtools::Resultstore::V2::Action::TestAction'];

coerce 'TestAction',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Action::TestAction'->new($_) };

declare 'RepeatedTestAction',
    as ArrayRef[TestAction()];

coerce 'RepeatedTestAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Action::TestAction'->new($_) } @$_ ] };

declare 'MapStringTestAction',
    as HashRef[TestAction()];

declare 'ActionAttributes',
    as InstanceOf['Google::Devtools::Resultstore::V2::Action::ActionAttributes'];

coerce 'ActionAttributes',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Action::ActionAttributes'->new($_) };

declare 'RepeatedActionAttributes',
    as ArrayRef[ActionAttributes()];

coerce 'RepeatedActionAttributes',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Action::ActionAttributes'->new($_) } @$_ ] };

declare 'MapStringActionAttributes',
    as HashRef[ActionAttributes()];

declare 'InputFileInfo',
    as InstanceOf['Google::Devtools::Resultstore::V2::Action::InputFileInfo'];

coerce 'InputFileInfo',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Action::InputFileInfo'->new($_) };

declare 'RepeatedInputFileInfo',
    as ArrayRef[InputFileInfo()];

coerce 'RepeatedInputFileInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Action::InputFileInfo'->new($_) } @$_ ] };

declare 'MapStringInputFileInfo',
    as HashRef[InputFileInfo()];

declare 'LocalTestTiming',
    as InstanceOf['Google::Devtools::Resultstore::V2::Action::LocalTestTiming'];

coerce 'LocalTestTiming',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Action::LocalTestTiming'->new($_) };

declare 'RepeatedLocalTestTiming',
    as ArrayRef[LocalTestTiming()];

coerce 'RepeatedLocalTestTiming',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Action::LocalTestTiming'->new($_) } @$_ ] };

declare 'MapStringLocalTestTiming',
    as HashRef[LocalTestTiming()];

declare 'RemoteTestAttemptTiming',
    as InstanceOf['Google::Devtools::Resultstore::V2::Action::RemoteTestAttemptTiming'];

coerce 'RemoteTestAttemptTiming',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Action::RemoteTestAttemptTiming'->new($_) };

declare 'RepeatedRemoteTestAttemptTiming',
    as ArrayRef[RemoteTestAttemptTiming()];

coerce 'RepeatedRemoteTestAttemptTiming',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Action::RemoteTestAttemptTiming'->new($_) } @$_ ] };

declare 'MapStringRemoteTestAttemptTiming',
    as HashRef[RemoteTestAttemptTiming()];

declare 'RemoteTestTiming',
    as InstanceOf['Google::Devtools::Resultstore::V2::Action::RemoteTestTiming'];

coerce 'RemoteTestTiming',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Action::RemoteTestTiming'->new($_) };

declare 'RepeatedRemoteTestTiming',
    as ArrayRef[RemoteTestTiming()];

coerce 'RepeatedRemoteTestTiming',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Action::RemoteTestTiming'->new($_) } @$_ ] };

declare 'MapStringRemoteTestTiming',
    as HashRef[RemoteTestTiming()];

declare 'TestTiming',
    as InstanceOf['Google::Devtools::Resultstore::V2::Action::TestTiming'];

coerce 'TestTiming',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Action::TestTiming'->new($_) };

declare 'RepeatedTestTiming',
    as ArrayRef[TestTiming()];

coerce 'RepeatedTestTiming',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Action::TestTiming'->new($_) } @$_ ] };

declare 'MapStringTestTiming',
    as HashRef[TestTiming()];

declare 'TestWarning',
    as InstanceOf['Google::Devtools::Resultstore::V2::Action::TestWarning'];

coerce 'TestWarning',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Action::TestWarning'->new($_) };

declare 'RepeatedTestWarning',
    as ArrayRef[TestWarning()];

coerce 'RepeatedTestWarning',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Action::TestWarning'->new($_) } @$_ ] };

declare 'MapStringTestWarning',
    as HashRef[TestWarning()];

1;

__END__

=head1 NAME

Google::Devtools::Resultstore::V2::Action::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
