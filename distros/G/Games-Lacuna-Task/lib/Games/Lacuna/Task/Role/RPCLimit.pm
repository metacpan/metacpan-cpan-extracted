package Games::Lacuna::Task::Role::RPCLimit;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose::Role;

has 'force' => (
    is              => 'rw',
    isa             => 'Bool',
    required        => 1,
    default         => 0,
    documentation   => 'Run action even if RPC limit is almost spent',
);

around 'run' => sub {
    my $orig = shift;
    my $self = shift;
    
    my $rpc_limit_hard = $self->get_stash('rpc_limit');
    my $rpc_limit_soft = int($rpc_limit_hard * 0.9);
    my $rpc_count = $self->get_stash('rpc_count');
    my $task_name = Games::Lacuna::Task::Utils::class_to_name($self);
    
    if ($rpc_count > $rpc_limit_soft
        && ! $self->force) {
        $self->log('warn',"Skipping action %s because RPC limit is almost reached (%i of %i)",$task_name,$rpc_count,$rpc_limit_hard);
    } elsif ($rpc_count >= $rpc_limit_hard) {
        $self->log('warn',"Skipping action %s because RPC limit is spent (%i)",$task_name,$rpc_limit_hard);
    } else {
        return $self->$orig(@_);
    }
};

no Moose::Role;
1;

=encoding utf8

=head1 NAME

Games::Lacuna::Role::RPCLimit - Skip tasks if 90% RPC limit is reached

=head1 SYNOPSIS

    package Games::Lacuna::Task::Action::MyTask;
    use Moose;
    extends qw(Games::Lacuna::Task::Action);
    with qw(Games::Lacuna::Task::Role::RPCLimit);

=cut