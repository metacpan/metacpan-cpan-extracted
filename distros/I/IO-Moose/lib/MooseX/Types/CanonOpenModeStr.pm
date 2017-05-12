#!/usr/bin/perl -c

package MooseX::Types::CanonOpenModeStr;

=head1 NAME

MooseX::Types::CanonOpenModeStr - Type for canonical open mode string

=head1 SYNOPSIS

  package My::Class;
  use Moose;
  use MooseX::Types::CanonOpenModeStr;
  has file => ( isa => 'Str' );
  has mode => ( isa => 'CanonOpenModeStr', coerce => 1 );

  package main;
  # This will be coerced
  my $fin  = My::Class->new( file => '/etc/passwd', mode => 'r' );
  # This is native mode
  my $fout = My::Class->new( file => '/tmp/pwdnew', mode => '>' );

=head1 DESCRIPTION

This module provides Moose type which represents Perl-style canonical open
mode string (i.e. "+>").

=cut


use strict;
use warnings;

our $VERSION = '0.1004';

use Moose::Util::TypeConstraints;


subtype CanonOpenModeStr => (
    as 'Str',
    where { /^\+?(<|>>?)$/ },
    optimize_as {
        defined $_[0] && !ref($_[0])
        && $_[0] =~ /^\+?(<|>>?)$/
    },
);

coerce CanonOpenModeStr => (
    from OpenModeStr =>
        via {
            local $_ = $_;
            s/^r(\+?)$/$1</;
            s/^w(\+?)$/$1>/;
            s/^a(\+?)$/$1>>/;
            $_;
        }
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
