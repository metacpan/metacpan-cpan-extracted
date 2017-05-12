package MARC::Detrans::Names;

use strict;
use warnings;

=head1 NAME

MARC::Detrans::Names - A set of non-standard authority mappings

=head1 SYNOPSIS

    use MARC::Detrans::Names
    my $names = MARC::Detrans::Names->new();
    $names->addName( 
        from => '$aNicholas $bI, $cEmperor of Russia, $d1796-1855',
        to  => '$a^[(NnIKOLAJ^[s, $bI, $c^[(NiMPERATOR^[s ^[(NwSEROSSIJSKIJ^[s, $d1796-1855'
    );

=head1 DESCRIPTION

Often times personal names are transliterated in non-standard ways, so 
in order to get back to the original script it's necessary to have
non-standard mappings. MARC::Detrans::Names allows you to map the
transliterated name back to it's original. 

=head1 METHODS

=head2 new()

=cut 

sub new {
    my $class = shift;
    my $self = bless {}, ref($class) || $class;
    $self->{storage} = {};
    return $self;
}

=head2 addName()

You must pass in a MARC::Detrans::Name object that you want to have added
to the names mapping.

=cut

sub addName {
    my ($self,$name) = @_;
    my $from = $name->from();
    my $to = $name->to();

    ## squash space and remove indicators
    $from =~ s/ //g;
    $from =~ s/\$.//g;

    ## create a list of subfield data, suitable for easily 
    ## passing to MARC::Field->new()
    my @chunks = split /\$/, $to;
    my @subfields = ();
    foreach my $chunk ( @chunks ) { 
        ## first chunk will be empty
        next if $chunk eq ''; 
        my $subfield = substr( $chunk,0,1 );
        my $data = substr( $chunk,1 );
        push( @subfields, $subfield, $data );
    }

    $self->{storage}{$from} = \@subfields; 
}

=head2 convert()

Pass in a MARC::Field object and you'll get back an array ref of 
modified subfield data which could be used to create a new field. 
If there is no mapping for a particular MARC::Field then you'll get
back undef.

=cut

sub convert {
    my ($self,$field) = @_;

    ## make the hash key
    my $from = $field->as_string();
    $from =~ s/ //g;

    ## do the lookup, and return 
    return $self->{storage}{$from};
}

1;
