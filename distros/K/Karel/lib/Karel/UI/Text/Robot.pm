package Karel::UI::Text::Robot;

=head1 NAME

Karel::UI::Text::Robot

=head1 DESCRIPTION

The role used by L<Karel::UI::Text> to introduce methods to interact
with the user and show the grid.

=head1 METHODS

=over 4

=cut

use warnings;
use strict;
use feature qw{ say };

use Cwd;

use Moo::Role;
requires qw{ grid x y direction cover run step is_running knowledge };


=item cls

Clears the screen.

=cut

sub cls {
    system 'MSWin32' eq $^O ? 'cls' : 'clear';
}


=item $robot->menu($default, [ [ $command => \&callback ], ... ])

Display a menu listing commands, run the callback associated with the
selected item.

=cut

sub menu {
    my ($robot, $default, $choices) = @_;
    my $reply = ' ';
    until ($reply =~ /^[0-9]*$/ && $reply && $reply <= @$choices) {
        my $i = 1;
        my $line_length = @$choices > 20 ? 0 : undef;
        for my $choice (@$choices) {
            if (defined $line_length) {
                my $item = $i++ . ") $choice->[0] ";
                if ($line_length + length $item > 80) {
                    print "\n";
                    $line_length = 0;
                }
                print $item;
                $line_length += length $item;

            } else {
                say $i++, ") $choice->[0]";
            }
        }
        print "\n" if defined $line_length;
        say "Default: $default" if defined $default;
        chomp( $reply = <> );
        $reply = $default if q() eq $reply && $default;
    }
    my $action = $choices->[$reply-1][1];
    $robot->$action()
}

=item $robot->show

Draw the grid with the robot.

=cut

sub show {
    my ($robot) = @_;
    cls();
    my $grid = $robot->grid;
    for my $y (0 .. $grid->y + 1) {
        for my $x (0 .. $grid->x + 1) {
            if ($x == $robot->x && $y == $robot->y) {
                print { N => '^',
                        E => '>',
                        S => 'v',
                        W => '<' }->{ $robot->direction };
            } else {
                print $grid->at($x, $y);
            }
        }
        print "\n";
    }
    say '[', $robot->cover, ']';
}

=item $robot->load_grid_from_path($path)

List the files in the given path, load grid from the selected one. If
a directory is selected, show its contents.

=cut

sub load_grid_from_path {
    my ($robot, $path) = @_;
    $path = getcwd() unless $path;
    chdir $path;
    my @files = grep './' ne $_, glob ".*/ */ *.kg";
    $robot->menu(undef, [ map {
                              my $f = $_;
                              [ $f => sub { my $r = shift;
                                            if (-f $f) {
                                                $r->load_grid( file => $f );
                                            } elsif (-d $f) {
                                                $r->load_grid_from_path($f)
                                            }
                                        } ]
                              } @files ]);
}

=item $robot->load_commands($file)

Load commands from the given file.

=cut

sub load_commands {
    my ($robot, $file) = @_;
    my $contents = do {
        open my $IN, '<', $file or croak $!;
        local $/;
        <$IN> };
    $robot->learn($contents);
}

=item $robot->load_commands_from_path($path)

List the files in the given path. Load commands from the selected
one. If a directory is selected, show its contents.

=cut

sub load_commands_from_path {
    my ($robot, $path) = @_;
    $path = getcwd() unless $path;
    chdir $path;
    my @files = grep './' ne $_, glob ".*/ */ *.krl";
    $robot->menu(undef, [ map {
                              my $f = $_;
                              [ $f => sub { my $r = shift;
                                            if (-f $f) {
                                                $r->load_commands($f);
                                            } elsif (-d $f) {
                                                $r->load_commands_from_path($f)
                                            }
                                        } ]
                              } @files ]);
}

=item execute

Show all the possible commands as a C<menu>, run the selected one.

=cut

sub execute {
    my ($robot) = @_;
    my @commands = sort keys %{ $robot->knowledge || {} };
    push @commands, qw( left forward drop-mark pick-mark );
    $robot->menu(undef, [ map {
                                  my $cmd = $_;
                                  [ $cmd => sub {
                                        $robot->run($cmd);
                                        $robot->step while $robot->is_running;
                                    } ]
                              } @commands ]);
}

=back

=cut

__PACKAGE__
