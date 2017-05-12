package Devel::Monitor::Scalar;
use strict;
use warnings;
  
use Devel::Monitor::Common qw(:all);

our $id = 0;
 
sub TIESCALAR {
    my ($class, $varRef, $id, $isCode) = @_;
    my $self = {};
    bless($self => $class);
    $self->{Devel::Monitor::Common::F_VAR()} = $$varRef;
    if ($id) {
        $self->{Devel::Monitor::Common::F_ID()} = $id;
    } else {
        $self->{Devel::Monitor::Common::F_ID()} = 'scalar_'.++$id;
    }
    $self->{Devel::Monitor::Common::F_IS_CODE()} = $isCode;
    if ($isCode) {    
        Devel::Monitor::Common::printMsg("MONITOR CODE SCALAR : ".$self->{Devel::Monitor::Common::F_ID()}."\n");
    } else {
        Devel::Monitor::Common::printMsg("MONITOR SCALAR : ".$self->{Devel::Monitor::Common::F_ID()}."\n");
    }
    return $self;
}
 
sub DESTROY {
    my $self = shift;
    if ($self->{Devel::Monitor::Common::F_IS_CODE()}) {
        Devel::Monitor::Common::printMsg("DESTROY CODE SCALAR : ".$self->{Devel::Monitor::Common::F_ID()}."\n") unless $self->{Devel::Monitor::Common::F_UNMONITORED()};
    } else {
        Devel::Monitor::Common::printMsg("DESTROY SCALAR : ".$self->{Devel::Monitor::Common::F_ID()}."\n") unless $self->{Devel::Monitor::Common::F_UNMONITORED()};
    }
}
 
sub unmonitor {
   my ($varRef) = @_;
   my $scalarRef;
   {
       my $self = tied $$varRef;
       $scalarRef = $self->{Devel::Monitor::Common::F_VAR()};
       $self->{Devel::Monitor::Common::F_UNMONITORED()} = 1;
       Devel::Monitor::Common::printMsg("UNMONITOR SCALAR : ".$self->{Devel::Monitor::Common::F_ID()}."\n");
   }
   untie $$varRef;
   $$varRef = $$scalarRef;
}
 
#Copy/Pasted from Tie::StdScalar into Tie::Scalar.pm
#Added "->{Devel::Monitor::Common::F_VAR()}"
sub FETCH { return $_[0]->{Devel::Monitor::Common::F_VAR()}; }
sub STORE {
    $_[0]->{Devel::Monitor::Common::F_VAR()} = $_[1];
    # Should we do this ?
    # if ($_[1] =~ /HASH/) {
        # Devel::Monitor::monitor($_[0]->{Devel::Monitor::Common::F_ID()}.'::hash' => \$_[1]);
    # }
    # elsif ($_[1] =~ /ARRAY/) {
        # Devel::Monitor::monitor($_[0]->{Devel::Monitor::Common::F_ID()}.'::array' => \$_[1]);
    # }
}

1;