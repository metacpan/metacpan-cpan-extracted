package Devel::IntelliPerl::Editor;
our $VERSION = '0.04';

use Moose;

has editor => ( isa => 'Str', is => 'ro', required => 1 );

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Devel::IntelliPerl::Editor - Base class for editor integration

=head1 VERSION

version 0.04

=head1 METHODS

=head2 editor

Every subclass needs to specify this value.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Moritz Onken, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut