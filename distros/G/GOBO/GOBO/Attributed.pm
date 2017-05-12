=head1 NAME

GOBO::Attribute

=head1 SYNOPSIS

=head1 DESCRIPTION

A role for any kind of entity that can be attributed to some source (annotated). Here 'entity' includes GOBO::Statement objects

=head2 TBD

Is this over-abstraction? This could be simply mixed in with Statement

=cut

package GOBO::Attributed;
use DateTime::Format::ISO8601;
use Moose::Role;
use strict;

use Moose::Util::TypeConstraints;
require DateTime;

subtype 'Date'
    => as 'Object'
    => where { $_->isa('DateTime') };

coerce 'Date'
    => from 'Str'
    => via {
        if (/(\d\d\d\d)(\d\d)(\d\d)/) {
            DateTime->new(year=>$1,month=>$2,day=>$3);
        }
        elsif (/(\d\d):(\d\d):(\d\d\d\d)\s+(\d\d):(\d\d+)/) {
            # date tags in obo headers follow this convention
            DateTime->new(year=>$3,month=>$2,day=>$1,hour=>$4,minute=>$5);
        }
        elsif (/(\d\d):(\d\d):(\d\d\d\d)/) {
            DateTime->new(year=>$3,month=>$2,day=>$1);
        }
        elsif (/\d\d\d\d\-/) {
            DateTime::Format::ISO8601->parse_datetime( $_ );
        }
        else {
            undef;
        }
};

has version => ( is=>'rw', isa=>'Str');
has source => ( is=>'rw', isa=>'GOBO::Node', coerce=>1);
has provenance => ( is=>'rw', isa=>'GOBO::Node', coerce=>1);
has date => ( is=>'rw', isa=>'Date', coerce=>1); 
has xrefs => ( is=>'rw', isa=>'ArrayRef[Str]'); # TODO -- make these nodes?
has alt_ids => ( is=>'rw', isa=>'ArrayRef[Str]'); 
has is_anonymous => ( is=>'rw', isa=>'Bool'); 
has comment => ( is=>'rw', isa=>'Str');  # TODO - multivalued?
has subsets => ( is=>'rw', isa=>'ArrayRef[GOBO::Node]'); 
has property_value_map => ( is=>'rw', isa=>'HashRef'); 
has created_by => ( is=>'rw', isa=>'Str'); 
has creation_date => ( is=>'rw', isa=>'Date', coerce=>1); 


sub add_xrefs {
    my $self = shift;
    $self->xrefs([]) unless $self->xrefs;
    foreach (@_) {
        push(@{$self->xrefs},ref($_) ? @$_ : $_);
    }
    $self->_make_xrefs_unique();
    return;
}

sub _make_xrefs_unique {
    my $self = shift;
    my $xrefs = $self->xrefs;
    my %xref_h = map { ($_ => $_) } @$xrefs;
    $self->xrefs([values %xref_h]);
    return;
}

sub date_compact {
    my $self = shift;
    my $date = $self->date;
    if ($date) {
        return sprintf("%04d%02d%02d",$date->year(),$date->month(),$date->day());
    }
}

sub add_subsets {
    my $self = shift;
    $self->subsets([]) unless $self->subsets;
    foreach (@_) {
        push(@{$self->subsets},ref($_) && ref($_) eq 'ARRAY' ? @$_ : $_);
    }
    return;
}

sub add_alt_ids {
    my $self = shift;
    $self->alt_ids([]) unless $self->alt_ids;
    foreach (@_) {
        push(@{$self->alt_ids},ref($_) && ref($_) eq 'ARRAY' ? @$_ : $_);
    }
    return;
}

sub set_property_value {
    my $self = shift;
    my ($p,$v) = @_;
    $self->property_value_map({}) unless $self->property_value_map;
    $self->property_value_map->{$p} = $v;
    return;
}

sub add_property_value {
    my $self = shift;
    my ($p,$v) = @_;
    $self->property_value_map({}) unless $self->property_value_map;
    push(@{$self->property_value_map->{$p}}, $v);
    return;
}

sub get_property_value {
    my $self = shift;
    my ($p) = @_;
    my $map = $self->property_value_map || {};
    return $map->{$p};
}

1;

