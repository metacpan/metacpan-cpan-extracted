package Devel::Monitor::Hash;
use strict;
use warnings;
 
use Devel::Monitor::Common qw(:all);
 
our $id = 0;
 
sub TIEHASH {
    my ($class, $varRef, $id, $isCode) = @_;
    my $self = {};
    bless($self => $class);
    $self->{Devel::Monitor::Common::F_VAR()} = {%$varRef};
    if ($id) {
        $self->{Devel::Monitor::Common::F_ID()} = $id;
    } else {
        $self->{Devel::Monitor::Common::F_ID()} = 'hash_'.++$id;
    }
    $self->{Devel::Monitor::Common::F_IS_CODE()} = $isCode;
    if ($isCode) {
        Devel::Monitor::Common::printMsg("MONITOR CODE HASH : ".$self->{Devel::Monitor::Common::F_ID()}."\n");
    } else {
        Devel::Monitor::Common::printMsg("MONITOR HASH : ".$self->{Devel::Monitor::Common::F_ID()}."\n");
    }
    return $self;
}
 
sub DESTROY {
    my $self = shift;
    if ($self->{Devel::Monitor::Common::F_IS_CODE()}) {    
        Devel::Monitor::Common::printMsg("DESTROY CODE HASH : ".$self->{Devel::Monitor::Common::F_ID()}."\n") unless $self->{Devel::Monitor::Common::F_UNMONITORED()};
    } else {
        Devel::Monitor::Common::printMsg("DESTROY HASH : ".$self->{Devel::Monitor::Common::F_ID()}."\n") unless $self->{Devel::Monitor::Common::F_UNMONITORED()};
    }
}
 
sub unmonitor {
   my ($varRef) = @_;
   my $hashRef;
   {
       my $self = tied %$varRef;
       $hashRef = $self->{Devel::Monitor::Common::F_VAR()};
       $self->{Devel::Monitor::Common::F_UNMONITORED()} = 1;
       Devel::Monitor::Common::printMsg("UNMONITOR HASH : ".$self->{Devel::Monitor::Common::F_ID()}."\n");
   }
   untie %$varRef;
   %$varRef = %$hashRef;
}
 
#Copy/Pasted from Tie::Hash.pm
#Added "->{Devel::Monitor::Common::F_VAR()}"
sub STORE    { $_[0]->{Devel::Monitor::Common::F_VAR()}->{$_[1]} = $_[2] }
sub FETCH    { $_[0]->{Devel::Monitor::Common::F_VAR()}->{$_[1]} }
sub FIRSTKEY { my $a = scalar keys %{$_[0]->{Devel::Monitor::Common::F_VAR()}}; each %{$_[0]->{Devel::Monitor::Common::F_VAR()}} }
sub NEXTKEY  { each %{$_[0]->{Devel::Monitor::Common::F_VAR()}} }
sub EXISTS   { exists $_[0]->{Devel::Monitor::Common::F_VAR()}->{$_[1]} }
sub DELETE   { delete $_[0]->{Devel::Monitor::Common::F_VAR()}->{$_[1]} }
sub CLEAR    { %{$_[0]->{Devel::Monitor::Common::F_VAR()}} = () }
sub SCALAR   { scalar %{$_[0]->{Devel::Monitor::Common::F_VAR()}} }
 
1;