use strict;
package Mail::Thread::Chronological;
use Mail::Thread ();
use Date::Parse qw( str2time );
use List::Util qw( max );
use vars qw/$VERSION/;
$VERSION = '1.22';

use constant debug => 0;

=head1 NAME

Mail::Thread::Chronological - rearrange Mail::Thread::Containers into a Chronological structure

=head1 SYNOPSIS

 use Mail::Thread;
 use Mail::Thread::Chronological;

 my $threader = Mail::Thread->new( @messages );
 my $lurker = Mail::Thread::Chronological->new;

 $threader->thread;

 for my $thread ($threader->rootset) {
     for my $row ( $lurker->arrange( $thread ) ) {
         my $container = grep { ref $_ } @$row;
         print join('', map { ref $_ ? '*' : $_ } @$row),
               "    ", $container->messageid, "\n";
     }
 }

=head1 DESCRIPTION

Given a Mail::Thread::Container, Mail::Thread::Chronological transforms the
tree structure into a 2-dimensional array representing the history of
a given thread in time.

The output is similar to that of the Lurker mail archiving system,
with a couple of small exceptions:

=over

=item Characters used

The grid is populated with the characters ' ' (space), '-', '+', '|',
'{', or Mail::Thread::Container objects.  Lurker uses [a-g], and
differentiates T-junctions from corners for you, this module assumes
you will do that for yourself.

The characters mean:

=over

=item space

empty cell

=item -

horizontal line

=item +

T junction or corner

=item |

vertical line

=item {

vertical line crossing over a horizontal line

=back

=item Vertical stream crossing is permitted

In the original lurker crossing a path vertically is not allowed, this
results in a lot of horizontal space being used.

=back

=head1 METHODS

=head2 new

your common or garden constructor

=cut

sub new { bless {}, $_[0] }

=head2 arrange

Returns an array of arrays representing the thread tree.

=cut


# identify the co-ordinates of something
sub _cell {
    my $cells = shift;
    my $find = shift;
    for (my $y = 0; $y < @$cells; ++$y) {
        for (my $x = 0; $x < @{ $cells->[$y] }; ++$x) {
            my $here = $cells->[$y][$x];
            return [$y, $x] if ref $here && $here == $find;
        }
    }
    return;
}

sub _draw_cells {
    my $cells = shift;
    # and again in their new state
    print map { $_ % 10 } 0..20;
    print "\n";
    for my $row (@$cells) {
        my $this;
        for (@$row) {
            $this = $_ if ref $_;
            print ref $_ ? '*' : $_ ? $_ : ' ';
        }
        print "\t", $this->messageid, "\n";
    }
    print "\n";
}

sub arrange {
    my $self = shift;
    my $thread = shift;

    # show them in the old order, and take a copy of the containers
    # with messages on while we're at it
    my @messages;
    $thread->iterate_down(
        sub {
            my ($c, $d) = @_;
            print '  ' x $d, $c->messageid, "\n" if debug;
            push @messages, $c if $c->message;
        } );

    # cells is the 2-d representation, row, col.  the first
    # message will be at [0][0], it's first reply, [0][1]
    my @cells;

    # okay, wander them in date order
    @messages = sort { $self->extract_time( $a ) <=>
                       $self->extract_time( $b ) } @messages;
    for (my $row = 0; $row < @messages; ++$row) {
        my $c = $messages[$row];
        # and place them in cells

        # the first one - [0][0]
        unless (@cells) {
            $cells[$row][0] = $c;
            next;
        }

        # look up our parent
        my $first_parent = $c->parent;
        while ($first_parent && !$first_parent->message) {
            $first_parent = $first_parent->parent;
        }

        unless ($first_parent && $first_parent->message &&
                  _cell(\@cells, $first_parent) ) {
            # just drop it randomly to one side, since it doesn't
            # have a clearly identifiable parent
            my $col = (max map { scalar @$_ } @cells );
            $cells[$row][$col] = $c;
            next;
        }
        my $col;
        my ($parent_row, $parent_col) = @{ _cell( \@cells, $first_parent ) };
        if ($first_parent->child == $c) {
            # if we're the first child, then we directly beneath
            # them
            $col = $parent_col;
        }
        else {
            # otherwise, we have to shuffle accross into the first
            # free column

            # okay, figure out what the max col is
            $col = my $max_col = (max map { scalar @$_ } @cells );

            # would drawing the simple horizontal line cross the streams?
            if (grep {
                ($cells[$parent_row][$_] || '') eq '|'
            } $parent_col+1..$max_col) {
                # we must not cross the streams (that would be bad).
                # if given this tree:
                # a + +
                # b | |
                #   c |
                #     d
                #
                # e arrives, and is a reply to b, we can't just do this:
                # a + +
                # b - - +
                #   c | |
                #     d |
                #       e
                #
                # it's messy and confusing.  instead we have to do
                # extra work so we end up at
                # a - + +
                # b + | |
                #   | c |
                #   |   d
                #   e

                print "Crossing the streams, horizontally\n" if debug;
                # we want to end up in $parent_col + 1 and
                # everything in that column needs to get shuffled
                # over one
                $col = $parent_col + 1;
                for my $r (@cells[0 .. $row - 1]) {
                    next if @$r < $col;
                    my $here = $r->[$col] || '';
                    # what to splice in
                    my $splice = $here =~/[+\-]/ ? '-' : ' ';
                    splice(@$r, $col, 0, $splice);
                }
                $col = $parent_col + 1;
            }

            # the path is now clear, add the line in
            for ($parent_col..$col) {
                $cells[$parent_row][$_] ||= '-';
            }
            $cells[$parent_row][$col] = '+';
        }

        # place the message
        $cells[$row][$col] = $c;
        # link with vertical dashes
        for ($parent_row+1..$row-1) {
            $cells[$_][$col] = ($cells[$_][$col] || '') eq '-' ? '{' : '|';
        }
        _draw_cells(\@cells) if debug;
    }

    # pad the rows with spaces
    my $maxcol = max map { scalar @$_ } @cells;
    for my $row (@cells) {
        $row->[$_] ||= ' ' for (0..$maxcol-1);
    }

    return @cells;
}

=head2 extract_time( $container )

Extracts the time from a Mail::Thread::Container, returned as epoch
seconds used to decide the order of adding messages to the rows.

=cut

sub extract_time {
    my $self = shift;
    my $container = shift;

    my $date = Mail::Thread->_get_hdr( $container->message, 'date' );
    return str2time( $date );
}

1;
__END__

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 SEE ALSO

L<Lurker|http://lurker.sourceforge.net/>, the application that seems
to have originated this form of time-based thread display.

L<Mail::Thread>, L<Mariachi>

=cut
