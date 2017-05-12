package KinoSearch1::Search::Hit;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params / members
        id       => undef,
        score    => undef,
        searcher => undef,
        # members
        doc     => undef,
        hashref => undef,
    );
    __PACKAGE__->ready_get(qw( id score ));
}

sub get_doc {
    my $self = shift;
    $self->{doc} ||= $self->{searcher}->fetch_doc( $self->{id} );
    return $self->{doc};
}

sub get_field_values {
    my $self = shift;
    if ( !defined $self->{hashref} ) {
        if ( !defined $self->{doc} ) {
            $self->get_doc;
        }
        $self->{hashref} = $self->{doc}->to_hashref;
    }
    return $self->{hashref};
}

1;

__END__

=head1 NAME

KinoSearch1::Search::Hit - successful match against a Query

=head1 DESCRIPTION 

A Hit object is a storage vessel which holds a Doc, a floating point score,
and an integer document id.

=head1 METHODS

=head2 get_doc

    my $doc = $hit->get_doc;

Return the Hit's KinoSearch1::Document::Doc object.

=head2 get_score

    my $score = $hit->get_score;

Return the Hit's score.

=head2 get_id

    my $doc_number = $hit->get_id;

Return the Hit's document number.  Note that this document number is not
permanent, and will likely become invalid the next time the index is updated.

=head2 get_field_values 

    my $hashref = $hit->get_field_values;

Return the values of the Hit's constituent fields as a hashref.

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

