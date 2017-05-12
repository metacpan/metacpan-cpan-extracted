package MHA::AWS::Shutdown;

use strict;
use warnings;
use parent "MHA::AWS";
use Log::Minimal;
use Net::SSH qw/ ssh /;

sub _command_stop {
    my $self = shift;

    my $res = $self->ec2("stop-instances", {
        instance_ids => $self->host_instance_id,
    });
    infof "result: %s", ddf $res;
    my $timeout = time + $MHA::AWS::API_APPLIED_TIMEOUT;
    my $last_state;
 STOP:
    while ( time < $timeout ) {
        $res = $self->ec2("describe-instances", {
            instance_ids => $self->host_instance_id,
        });
        my $instance = $res->{Reservations}->[0]->{Instances}->[0];
        $last_state = $instance->{State}->{Name};
        if ( $last_state eq "stopped" ) {
            infof "instance stopped.";
            return 1;
        }
        sleep $MHA::AWS::CHECK_INTERVAL;
    }
    if ( $last_state eq "stopping" ) {
        infof "instance is stopping state, but timeout %d sec reached. detected as it was stopped!", $MHA::AWS::API_APPLIED_TIMEOUT;
        return 1;
    }
    critf "TIMEOUT: %d sec. Can't confirm stop-instances: %s", $MHA::AWS::API_APPLIED_TIMEOUT, $self->host_instance_id;
    return;
}

sub _command_stopssh {
    my $self = shift;

    my $target = sprintf "%s\@%s", $self->ssh_user, $self->host;
    my $command = q{
      killall -9 mysqld_safe mysqld
      for i in 1 2 3; do
        sleep 1
        pid=`pidof mysqld`
        if [ "x$pid" = "x" ]; then
          exit 0
        fi
      done
      exit 1
    };
    infof "ssh %s %s", $target, $command;
    my $r = ssh($target, $command);
    infof "exit code: %d", $r;
    return $r == 0 ? 1 : undef;
}

sub _command_status {
    my $self = shift;

    my $res = $self->ec2("describe-instances", {
        instance_ids => $self->host_instance_id,
    });
    my $instance = $res->{Reservations}->[0]->{Instances}->[0];
    if ( $instance->{State}->{Name} eq "running" ) {
        infof "instance is running.";
        return 1;
    }
    else {
        critf "instance state != running. %s", ddf $instance->{State};
    }
    return;
}

1;
