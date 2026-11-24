package Google::Devtools::Resultstore::V2::Configuration::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Configuration',
    as InstanceOf['Google::Devtools::Resultstore::V2::Configuration::Configuration'];

coerce 'Configuration',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Configuration::Configuration'->new($_) };

declare 'RepeatedConfiguration',
    as ArrayRef[Configuration()];

coerce 'RepeatedConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Configuration::Configuration'->new($_) } @$_ ] };

declare 'MapStringConfiguration',
    as HashRef[Configuration()];

declare 'Id',
    as InstanceOf['Google::Devtools::Resultstore::V2::Configuration::Configuration::Id'];

coerce 'Id',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Configuration::Configuration::Id'->new($_) };

declare 'RepeatedId',
    as ArrayRef[Id()];

coerce 'RepeatedId',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Configuration::Configuration::Id'->new($_) } @$_ ] };

declare 'MapStringId',
    as HashRef[Id()];

declare 'ConfigurationAttributes',
    as InstanceOf['Google::Devtools::Resultstore::V2::Configuration::ConfigurationAttributes'];

coerce 'ConfigurationAttributes',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Configuration::ConfigurationAttributes'->new($_) };

declare 'RepeatedConfigurationAttributes',
    as ArrayRef[ConfigurationAttributes()];

coerce 'RepeatedConfigurationAttributes',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Configuration::ConfigurationAttributes'->new($_) } @$_ ] };

declare 'MapStringConfigurationAttributes',
    as HashRef[ConfigurationAttributes()];

1;

__END__

=head1 NAME

Google::Devtools::Resultstore::V2::Configuration::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
