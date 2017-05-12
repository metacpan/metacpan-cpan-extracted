
package GD::Graph::Hooks;

use strict;
use Carp;
use GD::Graph::axestype;
use constant {
    POST_INIT => 0,
    PRE_TEXT  => 0,

    POST_TEXT  => 1,
    PRE_AXIS   => 1,

    POST_AXIS  => 2,
    PRE_DATA   => 2,

    POST_DATA  => 3,
    PRE_VALUES => 3,

    POST_VALUES => 4,
    PRE_LEGEND  => 4,

    POST_LEGEND  => 5,
    PRE_RETURN   => 5,
};

sub validate {
    my $slot = shift;
    $slot >= 0 and $slot <= 5;
}

our $VERSION = "1.0003";

{
    no warnings; # hackery below, no warnings in here thanks

    *GD::Graph::axestype::add_hook = sub {
        my $this = shift;
        my $slot = int shift; croak "slot unknown" unless validate($slot);
        my $code = shift;
        my $hook = ref($code) eq "CODE" ? $code : sub { eval $code };

        push @{$this->{_hooks}{$slot}}, $hook;
    };

    *GD::Graph::axestype::call_hooks = sub {
        my $this = shift;
        my $slot = shift;

        return unless exists $this->{_hooks}{$slot};

        for my $f (@{$this->{_hooks}{$slot}}) {
            $f->( $this, @$this{qw(graph left right top bottom gdta_x_axis gdta_y_axis)} );
        }
    };

    *GD::Graph::axestype::plot = sub {
        my $self = shift;
        my $data = shift;

        $self->check_data($data)            or return;
        $self->init_graph()                 or return;
        $self->setup_text()                 or return;
        $self->setup_legend();
        $self->setup_coords()               or return;
        $self->call_hooks(POST_INIT);
        $self->draw_text();
        $self->call_hooks(POST_TEXT);
        unless (defined $self->{no_axes}) {
            $self->draw_axes();
            $self->draw_ticks()             or return;
        }
        $self->call_hooks(POST_AXIS);
        $self->draw_data()                  or return;
        $self->call_hooks(POST_DATA);
        $self->draw_values()                or return;
        $self->call_hooks(POST_VALUES);
        $self->draw_legend();
        $self->call_hooks(POST_LEGEND);

        return $self->{graph}
    };
}

1;

__END__

=encoding utf-8

=head1 NAME

GD::Graph::Hooks - Kludgey way to add callback hooks to GD::Graph

=head1 SYNOPSIS

    use GD::Graph::Hooks;
    use GD::Graph::lines;

    my @data;
    for( 0 .. 100 ) { push @{$data[0]}, $_; push @{$data[1]}, $_ + 3*(rand 5); }

    # compute a naive biased moving average
    my (@mv_avg, @last);
    for my $i ( 0 .. $#{ $data[1] }) {
        push @last, $data[1][$i];
        if( @last > 4 ) {
            shift @last while @last > 5;
            my $sum = 0;
               $sum += $_ for @last;
            $mv_avg[$i] = ($sum / @last);
        }
    }

    my $graph = GD::Graph::lines->new(1500,500);

    $graph->add_hook( 'GD::Graph::Hooks::PRE_DATA' => sub {
        my ($gobj, $gd, $left, $right, $top, $bottom, $gdta_x_axis) = @_;
        my $clr = $gobj->set_clr(0xaa, 0xaa, 0xaa);

        my $x = 10;
        while ( $x < $#{ $data[1] }-10 ) {
            # compute line endpoints from a datapoint
            my @lhs = $gobj->val_to_pixel($x+1,  $data[1][$x]);

            # to a predicted endpoint, based on the moving average
            my @rhs = $gobj->val_to_pixel($x+11, $data[1][$x] + 10*($mv_avg[$x] - $mv_avg[$x-1]));

            print "adding line from data point (@lhs) to value predicted by mv_avg (@rhs)\n";

            $gd->line(@lhs,@rhs,$clr);

            $x += 10;
        }
    });

    my $gd = $graph->plot(\@data);

    my $fname = "/tmp/example.png";
    open my $img, '>', $fname or die $!;
    binmode $img;
    print $img $gd->png;
    close $img;

    print "example written to $fname\n";

Possible hook names follow.  This documentation is sparse because you either
got what you needed above already or you'll need to go source diving anyway.
The hooks appear as pairs because they are just different names for the same
event.

=over

=item POST_INIT / PRE_TEXT

=item POST_TEXT / PRE_AXIS

=item POST_AXIS / PRE_DATA

=item POST_DATA / PRE_VALUES

=item POST_VALUES / PRE_LEGEND

=item POST_LEGEND / PRE_RETURN

=back

=head1 AUTHOR

Paul Miller C<< <jettero@cpan.org> >>

I am using this software in my own projects...  If you find bugs, please please
please let me know.  I do use RT.

=head1 COPYRIGHT

Copyright © 2015 Paul Miller

=head1 LICENSE

This is released under the Artistic License. See L<perlartistic>.

=head1 SEE ALSO

perl(1), L<GD::Graph>

=cut
