package Test::Person;
use strict;

sub new
{   #
    my $class = shift;
    my %opts = @_;
    my $this = \%opts;
    bless $this, $class;
    return $this;
}

sub first_name
{   #
    my $this = shift;
    $this->{first_name} = $_[0] if $_[0];
    return $this->{first_name} if $this->{first_name};
}

sub last_name
{   #
    my $this = shift;
    $this->{last_name} = $_[0] if $_[0];
    return $this->{last_name} if $this->{last_name};
    
}

sub age
{   #
    my $this = shift;
    $this->{age} = $_[0] if $_[0];
    return $this->{age} if $this->{age};
     
}

1;
