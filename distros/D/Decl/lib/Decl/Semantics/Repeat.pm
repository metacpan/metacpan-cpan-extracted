package Decl::Semantics::Repeat;

use warnings;
use strict;

use base qw(Decl::Node);
use Decl::Semantics::Code;

=head1 NAME

Decl::Semantics::Repeat - implements a repeated node

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

The "repeat" node repeats its children at its own hierarchical level.  It's essentially a loop at build time, a quick way to build structure
based on data retrieved.  The C<foreach>/C<select> nodes are convenient abbreviations for the long-form C<repeat>.  Whereas the C<repeat>
node has separate children for its query and repetition text and thus has a place to put parameters, code, and other things to refine the
repetition process, the C<foreach>/C<select> nodes just treat their lines as SQL/data queries directly for brevity's sake.

=head2 defines(), tags_defined()

Called by Decl::Semantics during import, to find out what xmlapi tags this plugin claims to implement.

=cut
sub defines { ('repeat', 'select', 'foreach'); }
#our %build_handlers = ( select  => { node => sub { Decl::Semantics::Repeat->new (@_) }, body => 'none' },
#                        foreach => { node => sub { Decl::Semantics::Repeat->new (@_) }, body => 'none' }, );
sub tags_defined { Decl->new_data(<<EOF); }
repeat
select
foreach
EOF
                        
=head2 decode_line

The select/foreach node is the first to parse its line differently from the standard.  It treats its entire line as an SQL query (or
a data query, depending) - it uses the same syntax as the ^foreach/^select command in embedded Perl.

The only exception is that to make the expression of the body easier, it I<always> uses C<fetchrow_hashref> to retrieve the values from each
row.  The hash keys are then used to determine what should be replaced in the body for each child built.

=cut

sub decode_line {
   my ($self) = @_;
   return $self->SUPER::decode_line if $self->is('repeat');
   $self->{query} = "select " . $self->{line};
}

=head2 parse_body

Same thing.  The select/foreach node doesn't want to parse its body.  Normally, we'd just mark that in build_handlers, but if we do that,
we can't macroinsert the results (because there wouldn't be any body parser there, either...  Yes, this was a confusing couple of hours.)

=cut

sub parse_body {
   my ($self) = @_;
   return $self->SUPER::parse_body if $self->is('repeat');
}

=head2 post_build

Here is where we actually do the work of instantiating our true children, based on the body given us and repeating over the results of the
query passed in.  The repeat body is either the direct body of this tag, or the body of the "text" tag below it, depending on whether this
is a "repeat" or a "foreach"/"select" construct.

=cut

sub post_build {
   my ($self) = @_;
   
   my $body = $self->{body}; # TODO: or the text body
   
   my $d = $self->find_context('database');
   my $dbh = $self->find_context('database')->dbh;
   my $sth = $dbh->prepare($self->{query});
   $sth->execute();
   my @children = ();
   $self->{group} = 1;
   while (my $row = $sth->fetchrow_hashref) {
      my $child = $body;
      foreach my $field (keys %$row) {
         $child =~ s/\$$field/$$row{$field}/gmx;
      }
      push @children, $self->macroinsert ($child);
   }
   $self->{children} = \@children;
}

=head2 go

Finally, at runtime, we just execute by calling each of our macroinserted children.  Et voila!

=cut

sub go {
   my $self = shift;
   my $return;

   foreach (@{$self->{children}}) {
      $return = $_->go (@_);
   }
   return $return;
}

=head2 nodes

We override C<nodes> to permit group shenanigans.

=cut

sub nodes { grep { (defined $_[1] ? $_->is($_[1]) : 1) } @{$_[0]->{children}} }

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

1; # End of Decl::Semantics::Repeat
