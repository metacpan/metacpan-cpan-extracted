package Google::Actions::Sdk::V2::ConfigFile::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ConfigFiles',
    as InstanceOf['Google::Actions::Sdk::V2::ConfigFile::ConfigFiles'];

coerce 'ConfigFiles',
    from HashRef, via { 'Google::Actions::Sdk::V2::ConfigFile::ConfigFiles'->new($_) };

declare 'RepeatedConfigFiles',
    as ArrayRef[ConfigFiles()];

coerce 'RepeatedConfigFiles',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ConfigFile::ConfigFiles'->new($_) } @$_ ] };

declare 'MapStringConfigFiles',
    as HashRef[ConfigFiles()];

declare 'ConfigFile',
    as InstanceOf['Google::Actions::Sdk::V2::ConfigFile::ConfigFile'];

coerce 'ConfigFile',
    from HashRef, via { 'Google::Actions::Sdk::V2::ConfigFile::ConfigFile'->new($_) };

declare 'RepeatedConfigFile',
    as ArrayRef[ConfigFile()];

coerce 'RepeatedConfigFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ConfigFile::ConfigFile'->new($_) } @$_ ] };

declare 'MapStringConfigFile',
    as HashRef[ConfigFile()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::ConfigFile::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
