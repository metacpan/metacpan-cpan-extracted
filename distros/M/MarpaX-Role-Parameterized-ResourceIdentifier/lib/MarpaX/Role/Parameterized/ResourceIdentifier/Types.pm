use strict;
use warnings FATAL => 'all';

package MarpaX::Role::Parameterized::ResourceIdentifier::Types;

# ABSTRACT: Type tools for Resource Identifiers as per RFC3986 and RFC3987

our $VERSION = '0.003'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Type::Library
  -base,
  -declare => qw /Common Generic/;
use Scalar::Util qw/blessed/;
use Types::Standard -all;
use Type::Utils -all;
use Data::Printer 0.36
  colored       => 1,
  print_escapes => 1,
  escape_chars  => 'nonascii',
  indent        => 4,   # to make sure our forced_indent is ok
  deparse       => 1;   # To make sure we have this version at least, for np
use Data::Dumper;
use Import::Into;
use Term::ANSIColor qw/colored/;

our $HAVE_SYS__INFO = eval 'use Sys::Info; 1' || 0;
eval 'use Win32::Console::ANSI; 1' if _is_windows();

our $TO_STRING = sub {
  my (@fields) = $_[0]->FIELDS;
  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Useqq = 1;
  my $rc = Data::Dumper->new([map { $_[0]->$_ } @fields], [@fields])->Dump;
  $rc
};

our $_data_printer = sub {
  my $self = shift;
  Data::Printer->import;

  my $value = np(%{$self->TO_HASH});
  my $label = colored($self->TYPE||'struct', 'bold yellow');

  #
  # This is heuristic, but a priori we will always be three indentations
  # level below -;
  #
  my $forced_indent = '    ' x 4;
  $value =~ s/^/$forced_indent/msg;

  sprintf('%s%s', $label, $value);
};

use MooX::Struct -rw,
  StructCommon => [ output         => [ isa => Str,           default => sub {    '' } ], # Parse tree value
                    scheme         => [ isa => Str|Undef,     default => sub { undef } ],
                    opaque         => [ isa => Str,           default => sub {    '' } ],
                    fragment       => [ isa => Str|Undef,     default => sub { undef } ],
                    TO_STRING      => sub { goto &$TO_STRING },
                    _data_printer  => sub { goto &$_data_printer }
                  ],
  StructGeneric => [ -extends => ['StructCommon'],
                     hier_part     => [ isa => Str|Undef,     default => sub { undef } ],
                     query         => [ isa => Str|Undef,     default => sub { undef } ],
                     segment       => [ isa => Str|Undef,     default => sub { undef } ],
                     authority     => [ isa => Str|Undef,     default => sub { undef } ],
                     path          => [ isa => Str,           default => sub {    '' } ], # Never undef per construction
                     relative_ref  => [ isa => Str|Undef,     default => sub { undef } ],
                     relative_part => [ isa => Str|Undef,     default => sub { undef } ],
                     userinfo      => [ isa => Str|Undef,     default => sub { undef } ],
                     host          => [ isa => Str|Undef,     default => sub { undef } ],
                     port          => [ isa => Str|Undef,     default => sub { undef } ],
                     ip_literal    => [ isa => Str|Undef,     default => sub { undef } ],
                     ipv4_address  => [ isa => Str|Undef,     default => sub { undef } ],
                     reg_name      => [ isa => Str|Undef,     default => sub { undef } ],
                     ipv6_address  => [ isa => Str|Undef,     default => sub { undef } ],
                     ipv6_addrz    => [ isa => Str|Undef,     default => sub { undef } ],
                     ipvfuture     => [ isa => Str|Undef,     default => sub { undef } ],
                     zoneid        => [ isa => Str|Undef,     default => sub { undef } ],
                     segments      => [ isa => ArrayRef[Str], default => sub {    [] } ],
                     TO_STRING      => sub { goto &$TO_STRING },
                     _data_printer  => sub { goto &$_data_printer }
                   ];

#
# A little bit painful: MooX::Struct thingies are anonymous classes
#
class_type Common, { class => blessed(StructCommon->new) };
class_type Generic, { class => blessed(StructGeneric->new) };

sub _is_windows {
  my $rc;

  if ($HAVE_SYS__INFO) {
    my $info = Sys::Info->new;
    my $os   = $info->os();
    $rc = $os->is_windows;
  } else {
    if ($^O =~ /win32/i) {
      $rc = 1;
    } else {
      $rc = 0;
    }
  }

  $rc
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Role::Parameterized::ResourceIdentifier::Types - Type tools for Resource Identifiers as per RFC3986 and RFC3987

=head1 VERSION

version 0.003

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
