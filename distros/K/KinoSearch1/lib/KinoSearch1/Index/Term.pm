package KinoSearch1::Index::Term;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        field => undef,
        text  => undef,
    );
    __PACKAGE__->ready_get_set(qw( field text ));
}

sub new {
    croak("usage: KinoSearch1::Index::Term->new( field, text )")
        unless @_ == 3;
    return bless {
        field => $_[1],
        text  => $_[2],
        },
        __PACKAGE__;
}

# Alternate, internal constructor.
sub new_from_string {
    my ( $class, $termstring, $finfos ) = @_;
    my $field_num = unpack( 'n', bytes::substr( $termstring, 0, 2, '' ) );
    my $field_name = $finfos->field_name($field_num);
    return __PACKAGE__->new( $field_name, $termstring );
}

# Return an encoded termstring. Requires a FieldInfos to discover fieldnum.
sub get_termstring {
    confess('usage: $term->get_termstring($finfos)')
        unless @_ == 2;
    my ( $self, $finfos ) = @_;
    my $field_num = $finfos->get_field_num( $self->{field} );
    return unless defined $field_num;
    return pack( 'n', $field_num ) . $self->{text};
}

sub to_string {
    my $self = shift;
    return "$self->{field}:$self->{text}";
}

1;

__END__

__H__

#ifndef H_KINOSEARCH_INDEX_TERM
#define H_KINOSEARCH_INDEX_TERM 1

/* Field Number Length -- the number of bytes occupied by the field number at
 * the top of a TermString.  
 */

#define KINO_FIELD_NUM_LEN 2

#endif /* include guard */

__POD__

=head1 NAME

KinoSearch1::Index::Term - string of text associated with a field

=head1 SYNOPSIS

    my $foo_term   = KinoSearch1::Index::Term->new( 'content', 'foo' );
    my $term_query = KinoSearch1::Search::TermQuery->new( term => $foo_term );

=head1 DESCRIPTION

The Term is the unit of search.  It has two characteristics: a field name, and
term text.  

=head1 METHODS

=head2 new

    my $term = KinoSearch1::Index::Term->new( FIELD_NAME, TERM_TEXT );

Constructor.

=head2 set_text get_text set_field get_field

Getters and setters.

=head2 to_string

Returns a string representation of the Term object.

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut


