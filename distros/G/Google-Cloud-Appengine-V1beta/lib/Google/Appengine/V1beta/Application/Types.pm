package Google::Appengine::V1beta::Application::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Application',
    as InstanceOf['Google::Appengine::V1beta::Application::Application'];

coerce 'Application',
    from HashRef, via { 'Google::Appengine::V1beta::Application::Application'->new($_) };

declare 'RepeatedApplication',
    as ArrayRef[Application()];

coerce 'RepeatedApplication',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Application::Application'->new($_) } @$_ ] };

declare 'MapStringApplication',
    as HashRef[Application()];

declare 'ServingStatus',
    as (Int | Str);

declare 'DatabaseType',
    as (Int | Str);

declare 'IdentityAwareProxy',
    as InstanceOf['Google::Appengine::V1beta::Application::Application::IdentityAwareProxy'];

coerce 'IdentityAwareProxy',
    from HashRef, via { 'Google::Appengine::V1beta::Application::Application::IdentityAwareProxy'->new($_) };

declare 'RepeatedIdentityAwareProxy',
    as ArrayRef[IdentityAwareProxy()];

coerce 'RepeatedIdentityAwareProxy',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Application::Application::IdentityAwareProxy'->new($_) } @$_ ] };

declare 'MapStringIdentityAwareProxy',
    as HashRef[IdentityAwareProxy()];

declare 'FeatureSettings',
    as InstanceOf['Google::Appengine::V1beta::Application::Application::FeatureSettings'];

coerce 'FeatureSettings',
    from HashRef, via { 'Google::Appengine::V1beta::Application::Application::FeatureSettings'->new($_) };

declare 'RepeatedFeatureSettings',
    as ArrayRef[FeatureSettings()];

coerce 'RepeatedFeatureSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Application::Application::FeatureSettings'->new($_) } @$_ ] };

declare 'MapStringFeatureSettings',
    as HashRef[FeatureSettings()];

declare 'UrlDispatchRule',
    as InstanceOf['Google::Appengine::V1beta::Application::UrlDispatchRule'];

coerce 'UrlDispatchRule',
    from HashRef, via { 'Google::Appengine::V1beta::Application::UrlDispatchRule'->new($_) };

declare 'RepeatedUrlDispatchRule',
    as ArrayRef[UrlDispatchRule()];

coerce 'RepeatedUrlDispatchRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Application::UrlDispatchRule'->new($_) } @$_ ] };

declare 'MapStringUrlDispatchRule',
    as HashRef[UrlDispatchRule()];

1;

__END__

=head1 NAME

Google::Appengine::V1beta::Application::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
