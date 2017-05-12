package MARC::SubjectMap::Rule;

use strict;
use warnings;
use base qw( Class::Accessor );
use MARC::SubjectMap::XML qw( element startTag endTag );

=head1 NAME

MARC::SubjectMap::Rule - a transformation rule

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 new() 

The constructor which can be passed a hash of values to ues in the
new object. Valid keys are field, subfield, original, translation 
and source.

=cut

sub new {
    my ($class,$parms) = @_;
    $parms->{original} = _normalize($parms->{original}) 
        if exists $parms->{original};
    return $class->SUPER::new($parms);
}

=head2 field()

=head2 subfield()

=head2 original()

=head2 translation()

=head2 source()

=cut 

my @fields = qw( field subfield source );

__PACKAGE__->mk_accessors( @fields );

sub original {
    my ($self,$text) = @_;
    if ( defined $text ) { 
        $self->{original} = _normalize($text);
    }
    return $self->{original};
}

sub translation {
    my ($self,$text) = @_;
    if ( defined $text ) { 
        $self->{translation} = _normalize($text);
    }
    return $self->{translation};
}

sub _normalize {
    my $text = shift;
    return unless defined $text;
    $text =~ s/\.$//;
    $text =~ s/ +$//;
    return $text;
}

sub toString {
    my $self = shift;
    my @chunks = ();
    foreach my $field ( @fields ) {
        push( @chunks, "$field: " . exists($self->{$field}) ? 
            $self->{field} : "" );
    }
    return join( "; ", @chunks ); 
}

sub toXML {
    my $self = shift;
    my $xml = startTag( "rule", field => $self->field(), 
        subfield => $self->subfield() ) . "\n";
    $xml .= element( "original", $self->original() ) . "\n";
    $xml .= element( "translation", $self->translation() ) . "\n";
    $xml .= element( "source", $self->source() ) . "\n";
    $xml .= endTag( "rule" ) . "\n";
    return $xml;
}

1;

