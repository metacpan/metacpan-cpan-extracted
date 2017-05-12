package Decl::Semantics::POD;

use warnings;
use strict;

use base qw(Decl::Node);

=head1 NAME

Decl::Semantics::POD - implements POD documentation in a declarative framework.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Obviously, POD documentation doesn't *do* anything, but we'll be able to scan the tree for POD documentation and get it all out in sequence.
The main benefit from the POD module is to permit convenient indentation for POD code, like this:

   pod head2 "Explanatory title"
      This function will do all kinds of neat stuff
      and here's an example of how to use it:
      
         (code POD will see as indented)
         
      And then we finish our explanation.
      
   do { some code }

The text that POD sees will automatically have =head2 and =cut added to the start and end, and will be de-indented to the lowest indentation level
in the text defined as POD.

=head2 defines(), tags_defined()

Called by Decl::Semantics during import, to find out what xmlapi tags this plugin claims to implement.
The asterisk means indented lines will all be put into the body of this tag even if not surrounded by curly braces.

=cut

sub defines { ('pod'); }
our %build_handlers = ( pod => { node => sub { Decl::Semantics::POD->new (@_) }, body => 'none' } );
sub tags_defined { Decl->new_data(<<EOF); }
pod (body=text)
EOF

=head2 extract

This is the only POD-specific function provided; it extracts the POD documentation.  If we do a C<search_first ('pod')> on the root of the tree,
we can get a sequential list of all POD nodes, so C<join "\n\n", map { $_->extract() } search_first ('pod')> gives us the POD for the whole tree.

=cut

sub extract {
   my $self = shift;
   my $ret = '';
   
   if ($self->name) {
      $ret .= "=" . $self->name . " " . $self->label . "\n\n";
   }
   $ret .= $self->body;
   $ret .= "\n=cut\n";
   return $ret;
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

1; # End of Decl::Semantics::POD
