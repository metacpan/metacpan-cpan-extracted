package Decl::Semantics::Text;

use warnings;
use strict;

use base qw(Decl::Node);

=head1 NAME

Decl::Semantics::Text - implements a section of text (presumed human-readable)

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Text doesn't do anything, except that it can output itself.  Later, there will be a generalized output mechanism, but that's still
on the drawing board, so really, text just ... holds text.

=head2 defines(), tags_defined()

Called by Decl::Semantics during import, to find out what xmlapi tags this plugin claims to implement.
The asterisk means indented lines will all be put into the body of this tag even if not surrounded by curly braces.

=cut

sub defines { ('text'); }
our %build_handlers = ( text => { node => sub { Decl::Semantics::Text->new (@_) }, body => 'none' } );
sub tags_defined { Decl->new_data(<<EOF); }
text (body=text)
EOF

=head2 parse_body

When used outside the parser, a Text.pm node can have any tag - but it still doesn't ever parse its body.

It has ambiguous callability.

=cut

sub parse_body {
   my ($self) = @_;
   $self->{callable} = '?';
}

=head2 go

When called, Text writes to itself.  By default, that propagates up the tree until an output handler is found.

=cut

sub go {
   my ($self) = @_;
   if ($self->label) {
      $self->write($self->label);
   } else {
      $self->write($self->body);
   }
}

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-decl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Decl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Decl::Semantics::Text
