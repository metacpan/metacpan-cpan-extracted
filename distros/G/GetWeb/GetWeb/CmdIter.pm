package GetWeb::CmdIter;

use GetWeb::Cmd;

use Carp;
use strict;

sub new
{
    my $type = shift;
    my $self = {CMD_ARRAY => [],
	        ERROR_ARRAY => []};
    bless($self,$type);
}

sub _paCmd
{
    shift -> {CMD_ARRAY};
}

sub _paError
{
    shift -> {ERROR_ARRAY};
}

sub pushCmd
{
    my $self = shift;
    my $cmd = shift;

    # return if $cmd -> isEmpty;

    my $paCmd = $self -> _paCmd;
    push(@$paCmd,$cmd);
}

sub isEmpty
{
    my $self = shift;
    my $paCmd = $self -> _paCmd;
    return 0 if @$paCmd;
    
    my $paError = $self -> _paError;
    return 0 if @$paError;

    1;
}

sub pushError
{
    my $self = shift;
    my $error = shift;

    my $paError = $self -> _paError;
    push(@$paError,$error);
}

sub pushIter
{
    my $self = shift;
    my $iter = shift;

    my $paOwnCmd = $self -> _paCmd;
    my $paOwnError = $self -> _paError;
    my $paOtherCmd = $iter -> _paCmd;
    my $paOtherError = $iter -> _paError;

    push(@$paOwnCmd,@$paOtherCmd);
    push(@$paOwnError,@$paOtherError);
}

sub next
{
    my $self = shift;

    my $paCmd = $self -> _paCmd;
    my $cmd = shift @$paCmd;
    return $cmd if defined $cmd;

    my $paError = $self -> _paError;
    my $error = shift @$paError;
    die $error if defined $error;
    
    undef;
}    

1;
