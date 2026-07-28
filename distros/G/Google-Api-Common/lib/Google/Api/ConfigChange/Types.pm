package Google::Api::ConfigChange::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ChangeType',
    as (Int | Str);

declare 'ConfigChange',
    as InstanceOf['Google::Api::ConfigChange::ConfigChange'];

coerce 'ConfigChange',
    from HashRef, via { 'Google::Api::ConfigChange::ConfigChange'->new($_) };

declare 'RepeatedConfigChange',
    as ArrayRef[ConfigChange()];

coerce 'RepeatedConfigChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::ConfigChange::ConfigChange'->new($_) } @$_ ] };

declare 'MapStringConfigChange',
    as HashRef[ConfigChange()];

declare 'Advice',
    as InstanceOf['Google::Api::ConfigChange::Advice'];

coerce 'Advice',
    from HashRef, via { 'Google::Api::ConfigChange::Advice'->new($_) };

declare 'RepeatedAdvice',
    as ArrayRef[Advice()];

coerce 'RepeatedAdvice',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::ConfigChange::Advice'->new($_) } @$_ ] };

declare 'MapStringAdvice',
    as HashRef[Advice()];

1;

__END__

=head1 NAME

Google::Api::ConfigChange::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
