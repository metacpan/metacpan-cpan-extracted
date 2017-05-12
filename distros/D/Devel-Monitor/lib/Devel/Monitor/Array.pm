package Devel::Monitor::Array;
use strict;
use warnings;

use Devel::Monitor::Common qw(:all);
 
our $id = 0;
 
sub TIEARRAY {
    my ($class, $varRef, $id, $isCode) = @_;
    my $self = {};
    bless($self => $class);
    $self->{Devel::Monitor::Common::F_VAR()} = [@$varRef];
    if ($id) {
        $self->{Devel::Monitor::Common::F_ID()} = $id;
    } else {
        $self->{Devel::Monitor::Common::F_ID()} = 'array_'.++$id;
    }
    $self->{Devel::Monitor::Common::F_IS_CODE()} = $isCode;
    if ($isCode) {
        Devel::Monitor::Common::printMsg("MONITOR CODE ARRAY : ".$self->{Devel::Monitor::Common::F_ID()}."\n");
    } else {
        Devel::Monitor::Common::printMsg("MONITOR ARRAY : ".$self->{Devel::Monitor::Common::F_ID()}."\n");   
    }
    return $self;
}
 
sub DESTROY {
    my $self = shift;
    if ($self->{Devel::Monitor::Common::F_IS_CODE()}) {
        Devel::Monitor::Common::printMsg("DESTROY CODE ARRAY : ".$self->{Devel::Monitor::Common::F_ID()}."\n") unless $self->{Devel::Monitor::Common::F_UNMONITORED()};
    } else {
        Devel::Monitor::Common::printMsg("DESTROY ARRAY : ".$self->{Devel::Monitor::Common::F_ID()}."\n") unless $self->{Devel::Monitor::Common::F_UNMONITORED()};
    }
}
 
sub unmonitor {
   my ($varRef) = @_;
   my $arrayRef;
   {
       my $self = tied @$varRef;
       $arrayRef = $self->{Devel::Monitor::Common::F_VAR()};
       $self->{Devel::Monitor::Common::F_UNMONITORED()} = 1;
       Devel::Monitor::Common::printMsg("UNMONITOR ARRAY : ".$self->{Devel::Monitor::Common::F_ID()}."\n");
   }
   untie @$varRef;
   @$varRef = @$arrayRef;
}
 
#Copy/Pasted from Tie::StdArray into Tie::Array.pm
#Added "->{Devel::Monitor::Common::F_VAR()}"
sub FETCHSIZE { scalar @{$_[0]->{Devel::Monitor::Common::F_VAR()}} }
sub STORESIZE { $#{$_[0]->{Devel::Monitor::Common::F_VAR()}} = $_[1]-1 }
sub STORE     { $_[0]->{Devel::Monitor::Common::F_VAR()}->[$_[1]] = $_[2] }
sub FETCH     { $_[0]->{Devel::Monitor::Common::F_VAR()}->[$_[1]] }
sub CLEAR     { @{$_[0]->{Devel::Monitor::Common::F_VAR()}} = () }
sub POP       { pop(@{$_[0]->{Devel::Monitor::Common::F_VAR()}}) }
sub PUSH      { my $o = shift; push(@{$o->{Devel::Monitor::Common::F_VAR()}},@_) }
sub SHIFT     { shift(@{$_[0]->{Devel::Monitor::Common::F_VAR()}}) }
sub UNSHIFT   { my $o = shift; unshift(@{$o->{Devel::Monitor::Common::F_VAR()}},@_) }
sub EXISTS    { exists $_[0]->{Devel::Monitor::Common::F_VAR()}->[$_[1]] }
sub DELETE    { delete $_[0]->{Devel::Monitor::Common::F_VAR()}->[$_[1]] }
sub EXTEND    { }
sub SPLICE {
    my $ob  = shift;
    my $sz  = $ob->FETCHSIZE;
    my $off = @_ ? shift : 0;
    $off   += $sz if $off < 0;
    my $len = @_ ? shift : $sz-$off;
    return splice(@{$ob->{Devel::Monitor::Common::F_VAR()}},$off,$len,@_);
}

1;