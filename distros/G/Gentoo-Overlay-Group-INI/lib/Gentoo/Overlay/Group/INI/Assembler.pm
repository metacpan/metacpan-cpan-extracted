use strict;
use warnings;

package Gentoo::Overlay::Group::INI::Assembler;
BEGIN {
  $Gentoo::Overlay::Group::INI::Assembler::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Overlay::Group::INI::Assembler::VERSION = '0.2.2';
}

# ABSTRACT: Glue record for Config::MVP


use Moose;
extends 'Config::MVP::Assembler';


sub expand_package {
  return "Gentoo::Overlay::Group::INI::Section::$_[1]";
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Gentoo::Overlay::Group::INI::Assembler - Glue record for Config::MVP

=head1 VERSION

version 0.2.2

=head1 DESCRIPTION

This is a glue layer. We pass Config::MVP an instance of this class, and it tells Config::MVP
that top level section declarations are to be expanded as children of Gentoo::Overlay::Group::INI::Section::

=head1 METHODS

=head2 expand_package

  ini file:

[Moo]

-->

  $asm->expand_package('Moo'); # Gentoo::Overlay::Group::INI::Section::Moo

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
