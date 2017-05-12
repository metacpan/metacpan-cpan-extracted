#
# This file is part of HTML-FormFu-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package HTML::FormFu::ExtJS::Element::Image;
BEGIN {
  $HTML::FormFu::ExtJS::Element::Image::VERSION = '0.090';
}

use base "HTML::FormFu::ExtJS::Element::_Field";

use strict;
use warnings;
use utf8;

sub render {
	my $class = shift;
	my $self = shift;
	my $super = $class->SUPER::render($self);
	return { %{$super}, html => "<img src='".$self->src."'>" };
	
	
}

1;


__END__
=pod

=head1 NAME

HTML::FormFu::ExtJS::Element::Image

=head1 VERSION

version 0.090

=head1 DESCRIPTION

Insert an image specified in C<src>.

=head1 NAME

HTML::FormFu::ExtJS::Element::Image - Image element

=head1 SEE ALSO

L<HTML::FormFu::Element::Image>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Moritz Onken, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

