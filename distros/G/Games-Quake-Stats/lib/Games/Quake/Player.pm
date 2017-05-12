#
# Player Object
#
#

package Player;

use strict;

##################################################
#  object constructor  
#
sub new {
    my $invocant = shift;
    my $class   = ref($invocant) || $invocant;
    my $self = {
        _name  => undef,   
	_stats => {},	    
	_times_fragged => 0,
	_total_frags  => 0,
	_skill        => 0,
        @_, # Override previous attributes
    };
    return bless $self, $class;
}


###############################################
# 
# accessor methods
#
###############################################
sub name {
    my $self = shift;
    if (@_) { $self->{_name} = shift }
    return $self->{_name};
}


sub stats {
    my $self = shift;
    if (@_) { $self->{_stats} = shift }
    return $self->{_stats};
}


sub times_fragged {
    my $self = shift;
    if (@_) { $self->{_times_fragged} = shift }
    return $self->{_times_fragged};
}

sub total_frags {
    my $self = shift;
    if (@_) { $self->{_total_frags} = shift }
    return $self->{_total_frags};
}


sub inc_times_fragged {
    my $self = shift;
    $self->{_times_fragged} = $self->{_times_fragged} + 1;
}



###############################################
# 
# update_stats
#
sub update_stats {
    my ($self, $fraggee_name) = @_;
    my $stats = $self->{_stats};
 
    my $fraggee = Player->new(
	_name => $fraggee_name,
	);
   
    my $found_player = $stats->{$fraggee_name};
    my $fragged_player;        

    if(!$found_player){
	$fragged_player = $fraggee;
	$fraggee->inc_times_fragged();
	$stats->{$fraggee_name} = $fraggee;
    }
    else{
	$fragged_player = $found_player;
	$found_player->inc_times_fragged();    
    }
    
    if( !($fragged_player->{_name} eq $self->{_name})){ 
	$self->{_total_frags} = $self->{_total_frags} + 1;
    }				
    return;
}



sub times_fragged_player
{
    my ($self, $playername) = @_;
    
    my $fraggee = Player->new(
	_name => $playername,
	);
    
    my $stats = $self->{_stats};
    my $found_player = $stats->{$playername};
    
    if(!$found_player){
	return 0;
    }
    else{
	return $found_player->times_fragged();
    }
}





1;  # load successful

