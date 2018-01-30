=head1 NAME

Devel::PerlySense::CallTree - A tree of method calls

=head1 DESCRIPTION


=cut

package Devel::PerlySense::CallTree;
$Devel::PerlySense::CallTree::VERSION = '0.0219';
use strict;
use warnings;
use utf8;

use Moo;
use Path::Tiny;
use List::AllUtils qw/ min /;
use Tree::Parser;

use Devel::PerlySense::CallTree::Caller;



=head1 PROPERTIES

=head2 source

The call-tree source with callers indented above their targets.

=cut
has source => ( is => "ro", required => 1 );

=head2 callers

Arrayref with Caller objects from the ->source

=cut
has callers => ( is => "lazy" );
sub _build_callers {
    my $self = shift;
    return [
        grep { defined $_->id }
        map { Devel::PerlySense::CallTree::Caller->new({ line => $_ }) }
        reverse split("\n", $self->source)
    ];
}

=head2 unique_callers



=cut
has package_callers => ( is => "lazy" );
sub _build_package_callers {
    my $self = shift;
    my $package_callers = {};
    my %seen;
    for my $caller (@{$self->callers}) {
        $seen{ $caller->id }++ and next;
        my $callers = $package_callers->{ $caller->package } ||= [];
        push(@$callers, $caller);
    }
    return $package_callers;
}

has method_called_by_caller => ( is => "lazy" );
sub _build_method_called_by_caller { +{ } }

sub BUILD {
    my $self = shift;
    $self->assign_called_by();
}

sub assign_called_by {
    my $self = shift;

    my $tree_parser = Tree::Parser->new( $self->callers );
    $tree_parser->setParseFilter(
        sub {
            my ($line_iterator) = @_;
            my $caller = $line_iterator->next();
            return (
                int( $caller->indentation / 4 ),
                $caller,
            );
        });
    my $tree = $tree_parser->parse();

    $self->walk_tree(undef, $tree);

    return $self->method_called_by_caller;
}

sub walk_tree {
    my $self = shift;
    my ($parent_caller, $tree) = @_;
    for my $tree_node ( @{$tree->getAllChildren} ) {
        my $caller = $tree_node->getNodeValue;
        $self->method_called_by($parent_caller, $caller);
        $self->walk_tree($caller, $tree_node);
    }
}

sub method_called_by {
    my $self = shift;
    my ($target, $called) = @_;
    $target or return;
    $self->method_called_by_caller->{ $target->caller }->{ $called->caller }++;
}

1;




__END__



=encoding utf8

=head1 AUTHOR

Johan Lindstrom, C<< <johanl@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-devel-perlysense@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-PerlySense>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
