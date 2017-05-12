package LucyX::Search::AnyTermCompiler;
use strict;
use warnings;
use base qw( Lucy::Search::Compiler );
use Carp;
use Lucy::Search::ORQuery;
use Lucy::Search::TermQuery;
use Data::Dump qw( dump );

our $VERSION = '0.006';

my $DEBUG = $ENV{LUCYX_DEBUG} || 0;

# inside out vars
my ( %searcher, %ORCompiler, %ORQuery, %subordinate );

sub DESTROY {
    my $self = shift;
    delete $ORQuery{$$self};
    delete $ORCompiler{$$self};
    delete $searcher{$$self};
    delete $subordinate{$$self};
    $self->SUPER::DESTROY;
}

=head1 NAME

LucyX::Search::AnyTermCompiler - Lucy query extension

=head1 SYNOPSIS

    # see Lucy::Search::Compiler

=head1 METHODS

This class isa Lucy::Search::Compiler subclass. Only new
or overridden methods are documented.

=cut

=head2 new( I<args> )

Returns a new Compiler object.

=cut

sub new {
    my $class    = shift;
    my %args     = @_;
    my $searcher = $args{searcher} || $args{searchable};
    if ( !$searcher ) {
        croak "searcher required";
    }

    my $subordinate = delete $args{subordinate};
    my $self        = $class->SUPER::new(%args);
    $searcher{$$self}    = $searcher;
    $subordinate{$$self} = $subordinate;

    return $self;
}

=head2 make_matcher( I<args> )

Returns a Lucy::Search::ORMatcher object.

make_matcher() creates a Lucy::Search::ORQuery internally using all
the terms associated with the parent AnyTermQuery field value,
and returns the ORQuery's Matcher.

=cut

sub make_matcher {
    my ( $self, %args ) = @_;

    my $parent = $self->get_parent;
    my $field  = $parent->get_field;

    # Retrieve low-level components
    my $seg_reader = $args{reader} or croak "reader required";
    my $lex_reader = $seg_reader->obtain("Lucy::Index::LexiconReader");
    my $lexicon    = $lex_reader->lexicon( field => $field );

    $DEBUG and warn "field:$field\n";

    if ( !$lexicon ) {

        #warn "no lexicon for field:$field";
        return;
    }

    # create ORQuery for all terms associated with $field
    my @terms;
    while ( defined( my $lex_term = $lexicon->get_term ) ) {

        $DEBUG and warn sprintf( "\n lex_term='%s'\n",
            ( defined $lex_term ? $lex_term : '[undef]' ),
        );

        if ( !defined $lex_term || !length $lex_term ) {
            last unless $lexicon->next;
            next;
        }

        push @terms,
            Lucy::Search::TermQuery->new(
            term  => $lex_term,
            field => $field,
            );

        last unless $lexicon->next;
    }

    return if !@terms;

    $DEBUG and warn dump \@terms;

    my $or_query = Lucy::Search::ORQuery->new( children => \@terms, );
    $ORQuery{$$self} = $or_query;
    my $or_compiler = $or_query->make_compiler(
        searcher => $searcher{$$self},
        boost    => ( $args{boost} || 0 ),
    );
    $ORCompiler{$$self} = $or_compiler;
    return $or_compiler->make_matcher(%args);

}

=head2 get_child_compiler

Returns the child ORCompiler, or undef if not defined.

=cut

sub get_child_compiler {
    my $self = shift;
    return $ORCompiler{$$self};
}

=head2 get_weight

Delegates to ORCompiler child.

=cut

sub get_weight {
    my $self = shift;
    return $self->get_child_compiler
        ? $self->get_child_compiler->get_weight(@_)
        : $self->SUPER::get_weight(@_);
}

=head2 get_similarity

Delegates to ORCompiler child.

=cut

sub get_similarity {
    my $self = shift;
    return $self->get_child_compiler
        ? $self->get_child_compiler->get_similarity(@_)
        : $self->SUPER::get_similarity(@_);
}

=head2 normalize

Delegates to ORCompiler child.

=cut

sub normalize {
    my $self = shift;
    return $self->get_child_compiler
        ? $self->get_child_compiler->normalize(@_)
        : $self->SUPER::normalize(@_);
}

=head2 sum_of_squared_weights

Delegates to ORCompiler child.

=cut

sub sum_of_squared_weights {
    my $self = shift;
    return $self->get_child_compiler
        ? $self->get_child_compiler->sum_of_squared_weights(@_)
        : $self->SUPER::sum_of_squared_weights(@_);
}

=head2 highlight_spans

Delegates to ORCompiler child.

=cut

sub highlight_spans {
    my $self = shift;
    return $self->get_child_compiler
        ? $self->get_child_compiler->highlight_spans(@_)
        : $self->SUPER::highlight_spans(@_);
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lucyx-search-wildcardquery at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LucyX-Search-NullTermQuery>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LucyX::Search::NullTermQuery


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LucyX-Search-NullTermQuery>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LucyX-Search-NullTermQuery>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LucyX-Search-NullTermQuery>

=item * Search CPAN

L<http://search.cpan.org/dist/LucyX-Search-NullTermQuery/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2013 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
