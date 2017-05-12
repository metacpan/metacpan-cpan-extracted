####################################################################
package MTDB::Serializer::Storable;
BEGIN {$la=2; @MTDB::Serializer::Storable::ISA = qw(MTDB::Serializer) }

use Storable;


sub new {
    my $self = shift->SUPER::new();
    $self->DumpMeth(shift);
    # Storable doesn't honor other attributes
    $self;
}

#
# Serialize a reference to supplied value
#
sub serialize {
    my $self = shift;
    my $dumpmeth = $self->{'_dumpsub_'};
    &$dumpmeth(\$_[0]);
}

#
# Deserialize and de-reference
#
sub deserialize {
    my $obj = Storable::thaw($_[1]);		# Does not care whether portable
    defined($obj) ? $$obj : undef;
}

#
# Change dump method when portability is requested
#
sub DumpMeth {
    my $self = shift;
    $self->{'_dumpsub_'} = 
      ($_[0] && $_[0] eq 'portable' ? \&Storable::nfreeze : \&Storable::freeze);
    $self->_attrib('dumpmeth', @_);
}

1;
