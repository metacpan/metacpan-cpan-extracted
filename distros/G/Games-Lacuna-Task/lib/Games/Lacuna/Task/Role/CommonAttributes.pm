package Games::Lacuna::Task::Role::CommonAttributes;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use MooseX::Role::Parameterized;

parameter 'attributes' => (
    isa      => 'ArrayRef[Str]',
    required => 1,
);

role {
    my $p = shift;

    if ('dispose_percentage' ~~ $p->attributes) {
        has 'dispose_percentage' => (
            isa     => 'Int',
            is      => 'rw',
            required=>1,
            default => 80,
            documentation => 'Dispose waste if waste storage is n-% full',
        );
    }

    if ('start_building_at' ~~ $p->attributes) {
        has 'start_building_at' => (
            isa     => 'Int',
            is      => 'rw',
            required=> 1,
            default => 0,
            documentation => 'Upgrade buildings if there are less than N buildings in the build queue',
        );
    }
    
    if ('plan_for_hours' ~~ $p->attributes) {
        has 'plan_for_hours' => (
            isa     => 'Num',
            is      => 'rw',
            required=> 1,
            default => 1,
            documentation => 'Plan N hours ahead',
        );
    }
    
    if ('keep_waste_hours' ~~ $p->attributes) {
        has 'keep_waste_hours' => (
            isa     => 'Num',
            is      => 'rw',
            required=> 1,
            default => 24,
            documentation => 'Keep enough waste for N hours',
        );
    }
    
    if ('target_planet' ~~ $p->attributes) {
        has 'target_planet' => (
            is      => 'rw',
            isa     => 'Str',
            required=> 1,
            documentation => 'Target planet (Name, ID or Coordinates)  [Required]',
        );
        
        has 'target_planet_data' => (
            isa             => 'HashRef',
            is              => 'rw',
            traits          => ['NoGetopt'],
            lazy_build      => 1,
        );
        method '_build_target_planet_data' => sub {
            my ($self) = @_;
            my $target_planet;
            given ($self->target_planet) {
                when (/^\d+$/) {
                    $target_planet = $self->get_body_by_id($_);
                }
                when (/^(?<x>-?\d+),(?<y>-?\d+)$/) {
                    $target_planet = $self->get_body_by_xy($+{x},$+{y});
                }
                default {
                    $target_planet = $self->get_body_by_name($_);
                }
            }
            unless (defined $target_planet) {
                $self->abort('Could not find target planet "%s"',$self->target_planet);
            }
            return $target_planet;
        };
    }
    
    if ('mytarget_planet' ~~ $p->attributes) {
        has 'target_planet' => (
            is      => 'rw',
            isa     => 'Str',
            required=> 1,
            documentation => 'Target planet [Required]',
        );
        
        has 'target_planet_data' => (
            isa             => 'HashRef',
            is              => 'rw',
            traits          => ['NoGetopt'],
            lazy_build      => 1,
        );
        method '_build_target_planet_data' => sub {
            my ($self) = @_;
            my $target_planet = $self->my_body_status($self->target_planet);
            unless (defined $target_planet) {
                $self->abort('Could not find target planet "%s"',$self->target_planet);
            }
            return $target_planet;
        };
    }
    
    if ('home_planet' ~~ $p->attributes) {
        has 'home_planet' => (
            is      => 'rw',
            isa     => 'Str',
            required=> 1,
            documentation => 'Home planet  [Required]',
        );
        
        has 'home_planet_data' => (
            isa             => 'HashRef',
            is              => 'rw',
            traits          => ['NoGetopt'],
            lazy_build      => 1,
        );
        method '_build_home_planet_data' => sub {
            my ($self) = @_;
            my $home_planet = $self->my_body_status($self->home_planet);
            unless (defined $home_planet) {
                $self->abort('Could not find home planet "%s"',$self->home_planet);
            }
            return $home_planet;
        };
    }
};

1;

=encoding utf8

=head1 NAME

Games::Lacuna::Role::CommonAttributes - Attributes utilized by multiple actions

=head1 SYNOPSIS

 package Games::Lacuna::Task::Action::MyTask;
 use Moose;
 extends qw(Games::Lacuna::Task::Action);
 with 'Games::Lacuna::Task::Role::CommonAttributes' => { attributes => ['dispose_percentage'] };

=head1 DESCRIPTION

The following accessors and helper methods are available on request

=head2 home_planet

Own planet. Planet stast can be accessed via the C<home_planet_data> method.

=head2 target_planet

Foreign planet. Planet stast can be accessed via the C<target_planet_data> 
method.

=head2 dispose_percentage

Dispose waste if waste storage is n-% full

=head2 start_building_at

Upgrade buildings if there are less than N buildings in the build queue

=head2 plan_for_hours

Plan N hours ahead

=head2 keep_waste_hours

Keep enough waste for N hours',

=cut