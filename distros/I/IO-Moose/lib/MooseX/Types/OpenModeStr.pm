#!/usr/bin/perl -c

package MooseX::Types::OpenModeStr;

=head1 NAME

MooseX::Types::OpenModeStr - Type for open mode string

=head1 SYNOPSIS

  package My::Class;
  use Moose;
  use MooseX::Types::OpenModeStr;
  has file => ( isa => 'Str' );
  has mode => ( isa => 'OpenModeStr' );

  package main;
  my $fin  = My::Class->new( file => '/etc/passwd', mode => 'r' );
  my $fout = My::Class->new( file => '/tmp/pwdnew', mode => 'w' );

=head1 DESCRIPTION

This module provides Moose type which represents open mode string.  It can be
Perl-style canonical mode string (i.e. "+>") or C-style mode string (i.e.
"w+").

=cut


use strict;
use warnings;

our $VERSION = '0.1004';

use Moose::Util::TypeConstraints;


subtype OpenModeStr => (
    as 'Str',
    where { /^([rwa]\+?|\+?(<|>>?))$/ },
    optimize_as {
        defined $_[0] && !ref($_[0])
        && $_[0] =~ /^([rwa]\+?|\+?(<|>>?))$/
    },
);


1;


__END__

=head1 SEE ALSO

L<Moose::Util::TypeConstraints>, L<IO::Moose>.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (C) 2007, 2008, 2009 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
