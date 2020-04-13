package Mail::TLSRPT::Pragmas;
# ABSTRACT: Setup system wide pragmas
our $VERSION = '1.20200413.1'; # VERSION
use 5.20.0;
use strict;
use warnings;
require feature;
use Import::Into;

use Carp;
use English;
use JSON;
use Types::Standard;
use Type::Utils;

use open ':std', ':encoding(UTF-8)';


sub import {
  strict->import;
  warnings->import;
  feature->import($_) for ( qw{ postderef signatures } );
  warnings->unimport($_) for ( qw{ experimental::postderef experimental::signatures } );

  Carp->import::into(scalar caller);
  Types::Standard->import::into(scalar caller, qw{ Str Int HashRef ArrayRef Enum } );
  Type::Utils->import::into(scalar caller, qw{ class_type } );
  English->import::into(scalar caller);
  JSON->import::into(scalar caller);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::TLSRPT::Pragmas - Setup system wide pragmas

=head1 VERSION

version 1.20200413.1

=head1 SYNOPSIS

Included in all other modules to setup common pragmas and imports

=head1 DESCRIPTION

Setup system wide pragmas

=head1 METHODS

=head2 I<import()>

Import standard pragmas and imports into current namespace

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
