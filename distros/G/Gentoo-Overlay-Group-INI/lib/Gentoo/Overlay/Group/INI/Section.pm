use strict;
use warnings;

package Gentoo::Overlay::Group::INI::Section;
BEGIN {
  $Gentoo::Overlay::Group::INI::Section::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Overlay::Group::INI::Section::VERSION = '0.2.2';
}

# ABSTRACT: Storage container for Parsed/Decoded Config::MVP sections.


use Moose;
extends 'Config::MVP::Section';


sub construct {
  my ($self)    = @_;
  my $class     = $self->package;
  my (%payload) = %{ $self->payload };
  return $class->new(%payload);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Gentoo::Overlay::Group::INI::Section - Storage container for Parsed/Decoded Config::MVP sections.

=head1 VERSION

version 0.2.2

=head1 DESCRIPTION

Parsed Sections are blessed into this class structure.

=head1 METHODS

=head2 construct

  my $object = $section->construct();

Inflates the Object specification ( this section ) into the target object.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
