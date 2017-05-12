package Decl::Semantics::Template;

use warnings;
use strict;

use base qw(Decl::Node);

=head1 NAME

Decl::Semantics::Template - implements a template

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Templates...

=head2 defines(), tags_defined()

Called by Decl::Semantics during import, to find out what tags this plugin claims to implement.

=cut

sub defines { ('template'); }
sub tags_defined { Decl->new_data(<<EOF); }
template
EOF

=head2 parse_body

The template has ambiguous callability.  Parse_body probably isn't where to indicate it, though.

=cut

sub parse_body {
   my ($self) = @_;
   $self->{callable} = '?';
}

=head2 go

When called, Template writes to itself.  By default, that propagates up the tree until an output handler is found.

=cut

sub go {
   my ($self) = @_;
   $self->write($self->express);
}

=head2 express

The C<express> function is where the template is sent to a template engine.  If a node is supplied for context, it's
used as the value source; otherwise, the template itself is taken as the value source.  A hashref can also be passed
into the express call as a value source, or an arrayref of different sources to be queried one after the other.

=cut

sub express {
   my ($self, $values) = @_;

   $values = $self unless $values;
   $Decl::template_engine->express($self->body, $values);
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

1; # End of Decl::Semantics::Template
