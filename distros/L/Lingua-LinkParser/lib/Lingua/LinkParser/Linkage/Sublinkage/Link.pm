package Lingua::LinkParser::Linkage::Sublinkage::Link;
use strict;
use vars qw($VERSION);

$VERSION = '1.17';

sub new {
    my ($class,$index,$subindex,$linkage,$label,$linkword) = @_;
    my $self = {};
    bless $self, $class;
    $self->{index} = $index;
    $self->{subindex} = $index - 1;
    $self->{linkage}  = $linkage;
    $self->{linklabel}= $label || '';
    $self->{linkword} = $linkword || '';
    return $self;
}

# these methods and hash data are only used when a link object
# is created from a word object.

sub linklabel    { $_[0]->{linklabel} }
sub linkword     { (split(/:/, $_[0]->{linkword}))[1] }
sub linkposition { (split(/:/, $_[0]->{linkword}))[0] }

sub length {
    my $self = shift;
    Lingua::LinkParser::linkage_set_current_sublinkage($self->{linkage}, $self->{subindex});
    return Lingua::LinkParser::linkage_get_link_length($self->{linkage}, $self->{index});
}

sub lword {
    my $self = shift;
    Lingua::LinkParser::linkage_set_current_sublinkage($self->{linkage}, $self->{subindex});
    return Lingua::LinkParser::linkage_get_link_lword($self->{linkage}, $self->{index});
}

sub rword {
    my $self = shift;
    Lingua::LinkParser::linkage_set_current_sublinkage($self->{linkage}, $self->{subindex});
    return Lingua::LinkParser::linkage_get_link_rword($self->{linkage}, $self->{index});
}

sub label {
    my $self = shift;
    Lingua::LinkParser::linkage_set_current_sublinkage($self->{linkage}, $self->{subindex});
    return Lingua::LinkParser::linkage_get_link_label($self->{linkage}, $self->{index});
}
      
sub llabel {
    my $self = shift;
    Lingua::LinkParser::linkage_set_current_sublinkage($self->{linkage}, $self->{subindex});
    return Lingua::LinkParser::linkage_get_link_llabel($self->{linkage}, $self->{index});
}

sub rlabel {
    my $self = shift;
    Lingua::LinkParser::linkage_set_current_sublinkage($self->{linkage}, $self->{subindex});
    return Lingua::LinkParser::linkage_get_link_rlabel($self->{linkage}, $self->{index});
}

sub num_domains {
    my $self = shift;
    Lingua::LinkParser::linkage_set_current_sublinkage($self->{linkage}, $self->{subindex});
    return Lingua::LinkParser::linkage_get_link_num_domains($self->{linkage}, $self->{index});
}

sub domain_names {
    my $self = shift;
    Lingua::LinkParser::linkage_set_current_sublinkage($self->{linkage}, $self->{subindex});
    return Lingua::LinkParser::call_linkage_get_link_domain_names($self->{linkage}, $self->{index});
}

1;

