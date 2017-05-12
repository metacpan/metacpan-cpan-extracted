package KinoSearch1::Document::Doc;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # special member - used to keep track of boost
        _kino_boost => 1,
    );
}

sub set_value {
    my ( $self, $field_name, $value ) = @_;
    carp("undef supplied to set_value") unless defined $value;
    $self->{$field_name}->set_value($value);
}

sub get_value {
    return $_[0]->{ $_[1] }->get_value;
}

sub get_field { $_[0]->{ $_[1] } }

sub boost_field {
    $_[0]->{ $_[1] }->set_boost( $_[2] );
}

sub set_boost { $_[0]->{_kino_boost} = $_[1] }
sub get_boost { $_[0]->{_kino_boost} }

# set the analyzer for a field
sub set_analyzer {
    $_[0]->{ $_[1] }->set_analyzer( $_[2] );
}

sub add_field {
    my ( $self, $field ) = @_;
    croak("argument to add_field must be a KinoSearch1::Document::Field")
        unless $field->isa('KinoSearch1::Document::Field');
    $self->{ $field->get_name } = $field;
}

# retrieve all fields
sub get_fields {
    return grep {ref} values %{ $_[0] };
}

# Return the doc as a hashref, with the field names as hash keys and the
# field # values as values.
sub to_hashref {
    my $self = shift;
    my %hash;
    $hash{ $_->get_name } = $_->get_value for grep {ref} values %$self;
    return \%hash;
}

1;

__END__

=head1 NAME

KinoSearch1::Document::Doc - a document

=head1 SYNOPSIS

    my $doc = $invindexer->new_doc;
    $doc->set_value( title    => $title );
    $doc->set_value( bodytext => $bodytext );
    $invindexer->add($doc);

=head1 DESCRIPTION

A Doc object is akin to a row in a database, in that it is made up of several
fields, each of which has a value.

Doc objects are only created via factory methods of other classes.  

=head1 METHODS

=head2 set_value get_value

    $doc->set_value( title => $title_text );
    my $text = $doc->get_value( 'title' );

C<set_value> and C<get_value> are used to modify and access the values of the
fields within a Doc object.

=head2 set_boost get_boost

    $doc->set_boost(2.5);

C<boost> is a scoring multiplier.  Setting boost to something other than 1
causes a document to score better or worse against a given query relative to
other documents.

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut
