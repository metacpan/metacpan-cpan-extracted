#!/usr/bin/perl -c

package MooseX::Types::PerlIOLayerStr;

=head1 NAME

MooseX::Types::PerlIOLayerStr - Type for PerlIO layer string

=head1 SYNOPSIS

  package My::Class;
  use Moose;
  use MooseX::Types::PerlIOLayerStr;
  has file => ( isa => 'Str' );
  has layer => ( isa => 'PerlIOLayerStr' );

  package main;
  my $fin = My::Class->new( file => 'Changelog', layer => ':utf8' );

=head1 DESCRIPTION

This module provides Moose type which represents PerlIO layer string.

=cut


use strict;
use warnings;

our $VERSION = '0.1004';

use Moose::Util::TypeConstraints;


subtype PerlIOLayerStr => (
    as 'Str',
    where { /^:/ },
    optimize_as {
        defined $_[0] && !ref($_[0])
        && $_[0] =~ /^:/
    },
);


1;


__END__

=head1 SEE ALSO

L<Moose::Util::TypeConstraints>, L<IO::Moose>, L<perlio>.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (C) 2007, 2008, 2009 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
