#!/usr/bin/perl -c

package IO::Moose;

=head1 NAME

IO::Moose - Reimplementation of IO::* with improvements

=head1 SYNOPSIS

  use IO::Moose 'Handle', 'File';  # loads IO::Moose::* modules

  $passwd = IO::Moose::File->new( file => '/etc/passwd' )->slurp;

=head1 DESCRIPTION

C<IO::Moose> provides a simple mechanism to load several modules in one go.

C<IO::Moose::*> classes provide an interface mostly compatible with L<IO>.
The differences:

=over

=item *

It is based on L<Moose> object framework.

=item *

It uses L<Exception::Base> for signaling errors. Most of methods are throwing
exception on failure.

=item *

The modifiers like C<input_record_separator> are supported on per file handler
basis.

=item *

It also implements additional methods like C<say>, C<slurp>.

=back

=for readme stop

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.1004';

use Class::MOP;


use Exception::Base (
    '+ignore_package' => [ __PACKAGE__ ],
);


## no critic qw(RequireArgUnpacking)

=head1 IMPORTS

=over

=item use IO::Moose [I<modules>]

Loads a modules from C<IO::Moose::*> hierarchy.  I.e. C<Handle> parameter
loads C<IO::Moose::Handle> module.

  use IO::Moose 'Handle', 'File';  # loads IO::Moose::Handle and ::File.

If I<modules> list is empty, it loads following modules at default:

=over

=item * L<IO::Moose::Handle>

=item * L<IO::Moose::File>

=back

=cut

sub import {
    shift;

    my @modules = @_ ? @_ : qw{ Handle File };

    Class::MOP::load_class($_) foreach ( map { 'IO::Moose::' . $_ } @modules );

    return 1;
};


1;


=back

=begin umlwiki

= Component Diagram =

[              <<library>>           {=}
                IO::Moose
 ---------------------------------------
 IO::Moose
 IO::Moose::Handle
 IO::Moose::Seekable
 IO::Moose::File
 MooseX::Types::OpenModeStr
 MooseX::Types::CanonOpenModeStr
 MooseX::Types::OpenModeWithLayerStr
 MooseX::Types::PerlIOLayerStr
 <<type>> OpenModeStr
 <<type>> CanonOpenModeStr
 <<type>> OpenModeWithLayerStr
 <<type>> PerlIOLayerStr
                                        ]

[<<type>> OpenModeStr] ---|> [<<type>> Str]

[<<type>> CanonOpenModeStr] ---|> [<<type>> ModeStr]

[<<type>> OpenModeWithLayerStr] ---|> [<<type>> Str]

[<<type>> PerlIOLayerStr] ---|> [<<type>> Str]

= Class Diagram =

[ <<utility>>
   IO::Moose
 ------------
 ------------ ]

[IO::Moose] ---> <<use>> [Class::MOP]

=end umlwiki

=head1 SEE ALSO

L<IO>, L<Moose>.

=head1 BUGS

The API is not stable yet and can be changed in future.

=for readme continue

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright 2008, 2009 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
