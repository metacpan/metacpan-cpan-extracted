package Forest::Tree::Writer::ASCIIWithBranches;
use Moose;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

with 'Forest::Tree::Writer',
     'Forest::Tree::Roles::HasNodeFormatter';

sub as_string {
    my ($self) = @_;

    my $out = '';
    my @vert_dashes;

    $self->tree->traverse(sub {
        my $t = shift;
        $out .= $self->_process_node($t, \@vert_dashes);
    });

    return $out;
}

sub _process_node {
    my ($self, $t, $vert_dashes) = @_;

    my $depth         = $t->depth;
    my $sibling_count = $t->is_root ? 1 : $t->parent->child_count;

    my @indent = map {
        $vert_dashes->[$_] || "    "
    } 0 .. $depth - 1;

    @$vert_dashes = (
        @indent,
        ($sibling_count == 1
            ? ("    ")
            : ("   |"))
    );

    if ($sibling_count == ($t->get_index_in_siblings + 1)) {
        $vert_dashes->[$depth] = "    ";
    }

    return ((join "" => @indent[1 .. $#indent])
            . ($depth ? "   |---" : "")
            . $self->format_node($t)
            . "\n");
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Forest::Tree::Writer::ASCIIWithBranches - A slightly more complex ASCII writer

=head1 SYNOPSIS

  use Forest::Tree::Writer::ASCIIWithBranches;

  my $w = Forest::Tree::Writer::ASCIIWithBranches->new(tree => $tree);

  print $w->as_string; # outputs ....
  # root
  #    |---1.0
  #    |   |---1.1
  #    |   |---1.2
  #    |       |---1.2.1
  #    |---2.0
  #    |   |---2.1
  #    |---3.0
  #    |---4.0
  #        |---4.1
  #            |---4.1.1

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2014 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
