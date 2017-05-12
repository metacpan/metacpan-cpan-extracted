package MARC::Detrans::Name;

use strict;
use warnings;
use base qw( Class::Accessor );
use Carp qw( croak );

=head1 NAME

MARC::Detrans::Name - A single name mapping

=head1 SYNOPSIS

    use MARC::Detrans::Name;
    my $name = MARC::Detrans::Name->new(
        from => '$aNicholas $bI, $cEmperor of Russia, $d1796-1855',
        to   => '$a^[(NnIKOLAJ^[s, $bI, $c^[(NiMPERATOR^[s ^[(NwSEROSSIJSKIJ^[s, $d1796-1855' 
    );

=head1 DESCRIPTION

MARC::Detrans::Rule represents a single non-standard detransliteration mapping
for a MARC field. For example personal names often have non-standard 
transliterations, so to get them back to the original script a non-rules based
detransliteration has to occur. 

MARC::Detrans::Name and MARC::Detrans::Names aid in this process by allowing you
to create a single mapping of one field to another, and then adding them to a
rule set.

=head1 METHODS

=head2 new()

The constructor which you must pass the from and to parameters, which 
define what name will be transformed. 

=cut 

sub new {
    my ($class,%args) = @_;
    croak( "must supply from parameter" ) if ! exists $args{from};
    croak( "must supply to parameter" ) if ! exists $args{to};
    ## convert ^ESC to 0x1B since XML can't contain this character
    $args{to} =~ s/\^ESC/\x1B/g;
    return $class->SUPER::new( \%args );
}

=head2 from()

=head2 to()

=cut

MARC::Detrans::Name->mk_accessors( qw(
    from
    to
) );

1;
