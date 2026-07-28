package Google::Api::Documentation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Documentation',
    as InstanceOf['Google::Api::Documentation::Documentation'];

coerce 'Documentation',
    from HashRef, via { 'Google::Api::Documentation::Documentation'->new($_) };

declare 'RepeatedDocumentation',
    as ArrayRef[Documentation()];

coerce 'RepeatedDocumentation',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Documentation::Documentation'->new($_) } @$_ ] };

declare 'MapStringDocumentation',
    as HashRef[Documentation()];

declare 'DocumentationRule',
    as InstanceOf['Google::Api::Documentation::DocumentationRule'];

coerce 'DocumentationRule',
    from HashRef, via { 'Google::Api::Documentation::DocumentationRule'->new($_) };

declare 'RepeatedDocumentationRule',
    as ArrayRef[DocumentationRule()];

coerce 'RepeatedDocumentationRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Documentation::DocumentationRule'->new($_) } @$_ ] };

declare 'MapStringDocumentationRule',
    as HashRef[DocumentationRule()];

declare 'Page',
    as InstanceOf['Google::Api::Documentation::Page'];

coerce 'Page',
    from HashRef, via { 'Google::Api::Documentation::Page'->new($_) };

declare 'RepeatedPage',
    as ArrayRef[Page()];

coerce 'RepeatedPage',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Documentation::Page'->new($_) } @$_ ] };

declare 'MapStringPage',
    as HashRef[Page()];

1;

__END__

=head1 NAME

Google::Api::Documentation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
