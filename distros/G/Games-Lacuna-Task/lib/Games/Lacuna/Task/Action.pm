package Games::Lacuna::Task::Action;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;

with qw(Games::Lacuna::Task::Role::Client
    Games::Lacuna::Task::Role::Logger
    Games::Lacuna::Task::Role::Helper
    MooseX::Getopt);

use Games::Lacuna::Task::Utils qw(class_to_name);
use Try::Tiny;

has '+configdir' => (
    required        => 1,
);

sub BUILD {}

sub execute {
    my ($self) = @_;
    
    my $client = $self->client();
    
    # Call lazy builder
    $client->client;
    
    my $command_name = class_to_name($self);
    
    try {
        local $SIG{INT} = sub {
            $self->abort('Aborted by user');
        };
        local $SIG{__WARN__} = sub {
            my $warning = $_[0];
            chomp($warning)
                unless ref ($warning); # perl 5.14 ready
            $self->log('warn',$warning);
        };
        $self->run();
    } catch {
        $self->log('error',"An error occured while processing action %s: %s",$command_name,$_);
    };
    
    return;
}

sub run {
    my ($self) = @_;
    
    $self->abort('Abstract method <run> called in %s',__PACKAGE__);
    return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;


=encoding utf8

=head1 NAME

Games::Lacuna::Task::Action - Abstract action base class

=head1 SYNOPSIS

    package Games::Lacuna::Task::Action::MyAction;
    
    use Moose;
    extends qw(Games::Lacuna::Task::Action);

=head1 DESCRIPTION

All actions need to inherit from this class an implement a C<run> method
or cosume a role that implements this method (such as 
L<Games::Lacuna::Task::Role::PlanetRun>)

=cut