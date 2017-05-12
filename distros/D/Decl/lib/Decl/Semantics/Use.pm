package Decl::Semantics::Use;

use warnings;
use strict;

use base qw(Decl::Node);

=head1 NAME

Decl::Semantics::Use - imports a module.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

In its simplest form, a "use" tag looks exactly like Perl's native "use" statement:

   use Word::Declarative;
   
The semicolon on the end is optional, and is there because you're going to type it no matter what I say, and there's no reason the tag shouldn't
understand perfectly well what you mean.

The reason we need this at all is that if we import a semantic domain in filter mode, but still need a second semantic domain, then without
a "use" tag we'd have no way to import the second domain.  Similarly, if we define an extension of, say, "dpl" to invoke a declarative Perl
script in Windows, then we're in filter mode right from the get-go, and also need a declarative module import option.

But the tag can be used for more than that - just not yet.  It's the logical place to set up how to handle non-declarative modules as well.
I can see two ways that could be useful: first is that modules imported this way would also be imported for all the code snippets in the tree, and
second might be specifying a tag structure for some object-oriented but not declarative module.  If it's simple, you could probably specify
everything you need in a declarative structure and bypass the hassle of writing your own semantic domain module.

I could see the "use" tag as being able to override parsers, set up tag aliases if there are collisions, and so on.  It's the logical place
to put all this stuff.

=head2 defines(), tags_defined()

Called by Decl::Semantics during import, to find out what xmlapi tags this plugin claims to implement.

=cut
sub defines { ('use'); }
sub tags_defined { Decl->new_data(<<EOF); }
use (body=vanilla)
EOF

=head2 post_build()

After the tag is built, we'll do our work - this has to happen during the build phase because it affects the semantics of the rest of our tags.
And in fact it's worse than that: by the time this C<use> tag is built, the other tags have already been assigned classes.  So after building,
we have to scan the siblings of the C<use> node and reassign them if necessary.  A pain, but unavoidable without changing some of the basic
parser logic to a less logical approach.

=cut

sub post_build {
   my ($self) = @_;

   my $module = $self->name;
   $module =~ s/;$//;   
   eval "use $module;";
   if ($@) {
      warn $@;
   } else {
      push @Decl::semantic_classes, $module;
      my $root = $self->root;
      $root->initiate_semantic_class($module);
            
      # Scan our siblings
      my $on = 0;
      my $index = -1;
      my @p = $self->{parent}->nodes;
      foreach my $sib ($self->{parent}->nodes) {
         $index += 1;
         unless ($on) {
            $on = 1 if $sib == $self;
            next;
         }
         my $newnode = $root->remakenode($sib);
         $self->{parent}->replace_node ($sib, $newnode);
      }
      @p = $self->{parent}->nodes;
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

1; # End of Decl::Semantics::Use
