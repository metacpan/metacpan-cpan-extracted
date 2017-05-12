package MARC::SubjectMap::Field;

use strict;
use warnings;
use Carp qw( croak );
use MARC::SubjectMap::XML qw( startTag endTag element emptyElement );

=head1 NAME

MARC::SubjectMap::Field - represent field/subfield combinations to examine

=head1 SYNOPSIS

=head1 DESCRIPTION

The MARC::SubjectMap configuration includes information about which
field/subfield combinations to examine. This is contained in the configuration
as a list of MARC::SubjectMap::Field objects which individually bundle up the
information.

=head1 METHODS

=head2 new()

The constructor. Optionally you can supply tag, translate and copy during the
constructor call instead of using the setters.

    my $f = MARC::Subject::Field->new( { tag => '650', copy => ['a','b'] } )

=cut 

sub new {
    my ( $class, $args ) = @_;
    $args = {} unless ref($args) eq 'HASH';
    my $self = bless $args, ref($class) || $class;
    # set up defaults
    $self->{translate} = [] unless exists $self->{translate};
    $self->{copy} = [] unless exists $self->{copy};
    $self->{sourceSubfield} = 'a' unless exists $self->{sourceSubfield};
    $self->{indicator1} = undef unless exists $self->{indicator1};
    $self->{indicator2} = undef unless exists $self->{indicator2};
    return $self;
}

=head2 tag()

Returns the tag for the field, for example: 600 or 650.

=cut

sub tag {
    my ($self,$tag) = @_;
    if ($tag) { $self->{tag} = $tag };
    return $self->{tag};
}

=head2 translate()

Gets a list of subfields to translate in the field.

=cut 

sub translate {
    return @{ shift->{translate} };
}

=head2 addTranslate() 

Adds a subfield to translate.

=cut 

sub addTranslate {
    my ($self,$subfield) = @_;
    croak( "can't both translate and copy subfield $subfield" )
        if grep { $subfield eq $_ } $self->copy();
    push( @{ $self->{translate} }, $subfield ) if defined($subfield);
}

=head2 copy()

Gets a list of subfields to copy in the field.

=cut

sub copy {
    return @{ shift->{copy} };
}

=head2 addCopy() 

Adds a subfield to copy.

=cut

sub addCopy {
    my ($self,$subfield) = @_;
    croak( "can't both copy and translate subfield $subfield" )
        if grep { $subfield eq $_ } $self->translate();
    push( @{ $self->{copy} }, $subfield ) if defined($subfield);
}

=head2 sourceSubfield()

When a new subfield is constructed for this field the $2 or source for 
the heading will be determined by the source for a particular subfield
rule that was used when building the new field. Since subfield components
could potentially have different sources sourceSubfield() lets you 
specify which subfield to pull the source from. If unspecified sourceSubfield()
will always return 'a'.

=cut

sub sourceSubfield {
    my ($self,$subfield) = @_;
    if ($subfield) { $self->{sourceSubfield} = $subfield };
    return $self->{sourceSubfield};
}

=head2 indicator1()

Specify a value to limit by for the 1st indicator. Using this will mean
that *only* fields with 1st indicator of this value will get processed.
By default records will not be limited if this value is unspecified.

=head2 indicator2()

Same as indicator1() but for the 2nd indicator.

=cut

sub indicator1 {
    my ($self,$indicator) = @_;
    if ( defined $indicator) { $self->{indicator1} = $indicator };
    return $self->{indicator1};
}

sub indicator2 {
    my ($self,$indicator) = @_;
    if ( defined $indicator) { $self->{indicator2} = $indicator };
    return $self->{indicator2};
}

sub toXML {
    my $self = shift;

    # get the attrs into an array with defined order (instead of hash)
    my @attrs = ( tag => $self->tag() );
    push( @attrs, indicator1 => $self->indicator1() ) 
        if defined $self->indicator1();
    push( @attrs, indicator2 => $self->indicator2() )
        if defined $self->indicator2();

    my $xml = startTag( "field", @attrs )."\n";
    map { $xml .= element("copy",$_)."\n" } $self->copy();
    map { $xml .= element("translate",$_)."\n" } $self->translate();
    $xml .= element("sourceSubfield", $self->sourceSubfield()) . "\n";
    $xml .= endTag("field")."\n";
    return $xml;
}

1;
