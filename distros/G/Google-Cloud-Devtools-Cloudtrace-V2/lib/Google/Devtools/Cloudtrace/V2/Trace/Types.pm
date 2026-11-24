package Google::Devtools::Cloudtrace::V2::Trace::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Span',
    as InstanceOf['Google::Devtools::Cloudtrace::V2::Trace::Span'];

coerce 'Span',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V2::Trace::Span'->new($_) };

declare 'RepeatedSpan',
    as ArrayRef[Span()];

coerce 'RepeatedSpan',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V2::Trace::Span'->new($_) } @$_ ] };

declare 'MapStringSpan',
    as HashRef[Span()];

declare 'SpanKind',
    as (Int | Str);

declare 'Attributes',
    as InstanceOf['Google::Devtools::Cloudtrace::V2::Trace::Span::Attributes'];

coerce 'Attributes',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V2::Trace::Span::Attributes'->new($_) };

declare 'RepeatedAttributes',
    as ArrayRef[Attributes()];

coerce 'RepeatedAttributes',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V2::Trace::Span::Attributes'->new($_) } @$_ ] };

declare 'MapStringAttributes',
    as HashRef[Attributes()];

declare 'AttributeMapEntry',
    as InstanceOf['Google::Devtools::Cloudtrace::V2::Trace::Span::Attributes::AttributeMapEntry'];

coerce 'AttributeMapEntry',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V2::Trace::Span::Attributes::AttributeMapEntry'->new($_) };

declare 'RepeatedAttributeMapEntry',
    as ArrayRef[AttributeMapEntry()];

coerce 'RepeatedAttributeMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V2::Trace::Span::Attributes::AttributeMapEntry'->new($_) } @$_ ] };

declare 'MapStringAttributeMapEntry',
    as HashRef[AttributeMapEntry()];

declare 'TimeEvent',
    as InstanceOf['Google::Devtools::Cloudtrace::V2::Trace::Span::TimeEvent'];

coerce 'TimeEvent',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V2::Trace::Span::TimeEvent'->new($_) };

declare 'RepeatedTimeEvent',
    as ArrayRef[TimeEvent()];

coerce 'RepeatedTimeEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V2::Trace::Span::TimeEvent'->new($_) } @$_ ] };

declare 'MapStringTimeEvent',
    as HashRef[TimeEvent()];

declare 'Annotation',
    as InstanceOf['Google::Devtools::Cloudtrace::V2::Trace::Span::TimeEvent::Annotation'];

coerce 'Annotation',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V2::Trace::Span::TimeEvent::Annotation'->new($_) };

declare 'RepeatedAnnotation',
    as ArrayRef[Annotation()];

coerce 'RepeatedAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V2::Trace::Span::TimeEvent::Annotation'->new($_) } @$_ ] };

declare 'MapStringAnnotation',
    as HashRef[Annotation()];

declare 'MessageEvent',
    as InstanceOf['Google::Devtools::Cloudtrace::V2::Trace::Span::TimeEvent::MessageEvent'];

coerce 'MessageEvent',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V2::Trace::Span::TimeEvent::MessageEvent'->new($_) };

declare 'RepeatedMessageEvent',
    as ArrayRef[MessageEvent()];

coerce 'RepeatedMessageEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V2::Trace::Span::TimeEvent::MessageEvent'->new($_) } @$_ ] };

declare 'MapStringMessageEvent',
    as HashRef[MessageEvent()];

declare 'Type',
    as (Int | Str);

declare 'TimeEvents',
    as InstanceOf['Google::Devtools::Cloudtrace::V2::Trace::Span::TimeEvents'];

coerce 'TimeEvents',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V2::Trace::Span::TimeEvents'->new($_) };

declare 'RepeatedTimeEvents',
    as ArrayRef[TimeEvents()];

coerce 'RepeatedTimeEvents',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V2::Trace::Span::TimeEvents'->new($_) } @$_ ] };

declare 'MapStringTimeEvents',
    as HashRef[TimeEvents()];

declare 'Link',
    as InstanceOf['Google::Devtools::Cloudtrace::V2::Trace::Span::Link'];

coerce 'Link',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V2::Trace::Span::Link'->new($_) };

declare 'RepeatedLink',
    as ArrayRef[Link()];

coerce 'RepeatedLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V2::Trace::Span::Link'->new($_) } @$_ ] };

declare 'MapStringLink',
    as HashRef[Link()];

declare 'Type',
    as (Int | Str);

declare 'Links',
    as InstanceOf['Google::Devtools::Cloudtrace::V2::Trace::Span::Links'];

coerce 'Links',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V2::Trace::Span::Links'->new($_) };

declare 'RepeatedLinks',
    as ArrayRef[Links()];

coerce 'RepeatedLinks',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V2::Trace::Span::Links'->new($_) } @$_ ] };

declare 'MapStringLinks',
    as HashRef[Links()];

declare 'AttributeValue',
    as InstanceOf['Google::Devtools::Cloudtrace::V2::Trace::AttributeValue'];

coerce 'AttributeValue',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V2::Trace::AttributeValue'->new($_) };

declare 'RepeatedAttributeValue',
    as ArrayRef[AttributeValue()];

coerce 'RepeatedAttributeValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V2::Trace::AttributeValue'->new($_) } @$_ ] };

declare 'MapStringAttributeValue',
    as HashRef[AttributeValue()];

declare 'StackTrace',
    as InstanceOf['Google::Devtools::Cloudtrace::V2::Trace::StackTrace'];

coerce 'StackTrace',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V2::Trace::StackTrace'->new($_) };

declare 'RepeatedStackTrace',
    as ArrayRef[StackTrace()];

coerce 'RepeatedStackTrace',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V2::Trace::StackTrace'->new($_) } @$_ ] };

declare 'MapStringStackTrace',
    as HashRef[StackTrace()];

declare 'StackFrame',
    as InstanceOf['Google::Devtools::Cloudtrace::V2::Trace::StackTrace::StackFrame'];

coerce 'StackFrame',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V2::Trace::StackTrace::StackFrame'->new($_) };

declare 'RepeatedStackFrame',
    as ArrayRef[StackFrame()];

coerce 'RepeatedStackFrame',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V2::Trace::StackTrace::StackFrame'->new($_) } @$_ ] };

declare 'MapStringStackFrame',
    as HashRef[StackFrame()];

declare 'StackFrames',
    as InstanceOf['Google::Devtools::Cloudtrace::V2::Trace::StackTrace::StackFrames'];

coerce 'StackFrames',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V2::Trace::StackTrace::StackFrames'->new($_) };

declare 'RepeatedStackFrames',
    as ArrayRef[StackFrames()];

coerce 'RepeatedStackFrames',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V2::Trace::StackTrace::StackFrames'->new($_) } @$_ ] };

declare 'MapStringStackFrames',
    as HashRef[StackFrames()];

declare 'Module',
    as InstanceOf['Google::Devtools::Cloudtrace::V2::Trace::Module'];

coerce 'Module',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V2::Trace::Module'->new($_) };

declare 'RepeatedModule',
    as ArrayRef[Module()];

coerce 'RepeatedModule',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V2::Trace::Module'->new($_) } @$_ ] };

declare 'MapStringModule',
    as HashRef[Module()];

declare 'TruncatableString',
    as InstanceOf['Google::Devtools::Cloudtrace::V2::Trace::TruncatableString'];

coerce 'TruncatableString',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V2::Trace::TruncatableString'->new($_) };

declare 'RepeatedTruncatableString',
    as ArrayRef[TruncatableString()];

coerce 'RepeatedTruncatableString',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V2::Trace::TruncatableString'->new($_) } @$_ ] };

declare 'MapStringTruncatableString',
    as HashRef[TruncatableString()];

1;

__END__

=head1 NAME

Google::Devtools::Cloudtrace::V2::Trace::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
