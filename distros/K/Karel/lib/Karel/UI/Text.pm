package Karel::UI::Text;

=head1 NAME

Karel::UI::Text

=head1 DESCRIPTION

Simple text UI for Karel.

=head1 SUBROUTINES

=over 4

=cut

use warnings;
use strict;
use feature qw{ say };

use Karel::Robot;
use Karel::UI::Text::Robot;

=item main

Runs the application.

=cut

sub main {
    my $robot = 'Karel::Robot'->new;
    my $grid  = 'Karel::Grid'->new(x => 7, y => 7);
    $robot->set_grid($grid, 4, 4, 'N');

    'Moo::Role'->apply_roles_to_object($robot, 'Karel::UI::Text::Robot');

    while (1) {
        $robot->show;
        $robot->menu(undef,
                     [ [ Quit => sub { no warnings 'exiting'; last } ],
                       [ 'Run command'   => 'execute' ],
                       [ 'Load grid'     => 'load_grid_from_path' ],
                       [ 'Load commands' => 'load_commands_from_path' ],
                     ]);
    }
}

=back

=cut

__PACKAGE__
