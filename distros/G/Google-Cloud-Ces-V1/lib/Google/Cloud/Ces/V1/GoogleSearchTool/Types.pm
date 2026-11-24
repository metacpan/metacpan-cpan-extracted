package Google::Cloud::Ces::V1::GoogleSearchTool::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GoogleSearchTool',
    as InstanceOf['Google::Cloud::Ces::V1::GoogleSearchTool::GoogleSearchTool'];

coerce 'GoogleSearchTool',
    from HashRef, via { 'Google::Cloud::Ces::V1::GoogleSearchTool::GoogleSearchTool'->new($_) };

declare 'RepeatedGoogleSearchTool',
    as ArrayRef[GoogleSearchTool()];

coerce 'RepeatedGoogleSearchTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::GoogleSearchTool::GoogleSearchTool'->new($_) } @$_ ] };

declare 'MapStringGoogleSearchTool',
    as HashRef[GoogleSearchTool()];

declare 'PromptConfig',
    as InstanceOf['Google::Cloud::Ces::V1::GoogleSearchTool::GoogleSearchTool::PromptConfig'];

coerce 'PromptConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::GoogleSearchTool::GoogleSearchTool::PromptConfig'->new($_) };

declare 'RepeatedPromptConfig',
    as ArrayRef[PromptConfig()];

coerce 'RepeatedPromptConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::GoogleSearchTool::GoogleSearchTool::PromptConfig'->new($_) } @$_ ] };

declare 'MapStringPromptConfig',
    as HashRef[PromptConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::GoogleSearchTool::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
