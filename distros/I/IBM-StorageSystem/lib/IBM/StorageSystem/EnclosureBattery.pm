package IBM::StorageSystem::EnclosureBattery;

use strict;
use warnings;

use Carp qw(croak);

our @ATTR = qw(enclosure_id:battery_id enclosure_id battery_id status charging_status recondition_needed percent_charged end_of_life_warning);

foreach my $attr ( @ATTR ) { 
        {   
                no strict 'refs';
                *{ __PACKAGE__ .'::'. $attr } = sub {
                        my( $self, $val ) = @_; 
                        $self->{$attr} = $val if $val;
                        return $self->{$attr}
                }   
        }   
}

sub new {
        my( $class, %args ) = @_; 
        my $self = bless {}, $class;
        defined $args{'enclosure_id:battery_id'} or croak __PACKAGE__ . ' constructor failed: mandatory enclosure_id:battery_id argument not supplied';

        foreach my $attr ( @ATTR ) { $self->{$attr} = $args{$attr} }

        return $self
}

1;

