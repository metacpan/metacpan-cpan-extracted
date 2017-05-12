#===============================================================================
#
#         FILE:  Diagram
#
#     ABSTRACT:  Encapsulate a go diagram
#
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#===============================================================================
#
#   Copyright (C) 2005 Reid Augustin reid@netchip.com
#                      1000 San Mateo Dr.
#                      Menlo Park, CA 94025 USA
#

=head1 SYNOPSIS

 use Games::Go::Sgf2Dg::Diagram

 my $diagram = Games::Go::Sgf2Dg::Diagram->new (options);
 $diagram->put($coords, 'white' | 'black', ? number ?);
 $diagram->mark($coords);
 $diagram->label($coords, 'a');
 $diagram->get($coords);
 my $new_diagram = $diagram->next;

=head1 DESCRIPTION

A Games::Go::Sgf2Dg::Diagram object represents a diagram similar to those
seen in go textbooks and magazines.  Most of the properties defined in SGF
FF[4] are supported.

The caller B<put>s 'white' or 'black' stones (possibly B<number>ed), on the
intersection selected by $coords.  The caller may B<mark> and B<label>
intersections and stones.

B<put>, B<mark>, B<label> and B<property> are 'actions'.  Actions are
provisional until the B<node> method is called.  If any provisioanl actions
cause a conflict, none of the actions associated with the node are applied,
and the B<node> method either calls a user-defined callback function, or
returns an error.

When a conflict occurs, the caller should dispose of the current
B<Diagram> by B<get>ting the information from each intersection and
doing something (like printing it).  Then the caller converts the
B<Diagram> to the starting point of the next diagram by calling the
B<clear> method.  Alternatively, the caller may save the current
B<Diagram> and create the starting point for the next diagram by
calling the B<next> method.  B<clear> and B<next> may also be called
at arbitrary times (for example, to launch a variation diagram).

'coords' may be any unique identifier for the intersection.  For
example:

    my $coords = 'qd';          # SGF format
    my $coords = 'a4';          # NNGS / IGS style coordinates
    my $coords = "$x,$y";       # real coordinates
    my $coords = 'George';      # as long as there's only one George

=cut

use strict;
require 5.001;

package Games::Go::Sgf2Dg::Diagram;
use Carp;

our $VERSION = '4.252'; # VERSION

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use PackageName ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

# Constants
use constant DEFAULT_MARK => 'TR';      # TRiangle mark property
######################################################
#
#       Class Variables
#
#####################################################

# the following are valid options to ->new.  they are also preserved
#       or copied during calls to ->clear and ->next (except hoshi,
#       black, and white)
# watch out for reference copies!
our %options = (hoshi             => [],
                black             => [],
                white             => [],
                coord_style       => 'normal',
                boardSizeX        => 19,
                boardSizeY        => 19,
                node              => 1,
                callback          => undef,
                enable_overstones => 1,
                overstone_eq_mark => 1);

######################################################
#
#       Public methods
#
#####################################################

=head1 NEW

=over 4

=item my $diagram = Games::Go::Sgf2Dg::Diagram-E<gt>B<new> (?options?)

=back

A B<new> Games::Go::Sgf2Dg::Diagram can take the following options:

=over 8

=item B<hoshi> =E<gt> ['coords', ...]

A reference to a list of coordinates where the Diagram should place
hoshi points.

=item B<black> =E<gt> ['coords', ...]

A reference to a list of coordinates where the Diagram should start
with black stones already in place.

=item B<white> =E<gt> ['coords', ...]

A reference to a list of coordinates where the Diagram should start
with white stones already in place.

=item B<coord_style> =E<gt> 'normal' | 'sgf' | numeric

Defines the coordinate translation system.  Note that while
B<Games::Go::Sgf2Dg::Diagram> doesn't use this coordinate system directly, sgf2dg
converters may call the coordinate translator methods B<xcoord> and
B<ycoord>, which rely on B<coord_style> and B<boardSizeX/Y> (below).

Legal values are:

=over 4

=item 'normal'

This is the standard coordinate system used for drawing diagrams: the
vertical coordinates start with 1 at the bottom and increase towards the
top edge.  The horizontal coordinates are letters starting with A on the
left, and increasing towards the right, but skipping over 'I'.  This is the
default coordinate style.

=item 'sgf'

Coordinates within SGF files are single letters, lower case first, then
upper case.  The origin (aa) is the top left corner.  'A' follows 'z', so
the point at (26, 27) translates to (zA).

=item numeric: '++' | '+-' | '-+' | '--'

Number coordinates can be either increasing or decreasing.  '++' starts
with (0, 0) in the upper left corner, '-+' has (0, 0) in the upper right
corner, etc.

=back

=item B<boardSizeX> =E<gt> number

=item B<boardSizeY> =E<gt> number

B<boardSizeX/Y> are used by the coordinate translation methods (B<xcoord>
and B<ycoord> to calculate the appropriate coordinate string.

=item B<callback> =E<gt> \&user_defined_callback

A reference to a user defined callback function.  The user callback
is called (with a reference to the B<Diagram> as the only argument)
when B<node> is called after conflict is detected.

The user callback should either save the current B<Diagram> and
call <next>, or flush the B<Diagram> (by printing for example) and
call <clear>.

If the user callback is defined, a call to B<node> always returns
non-zero (the current node number).

=item B<enable_overstones> =E<gt> true | false

If true (default), overstones are enabled and may be created by
the B<Diagram> during a call to the B<put> method.  The user must be
prepared to deal with overstones information in response to a
call to the B<get> method.

=back

=cut

sub new {
    my ($proto, %args) = @_;

    my $my = {};
    bless($my, ref($proto) || $proto);
    $my->{number} = {};
    $my->{property} = {};
    $my->{name} = [];
    $my->{offset} = 0;
    foreach (keys(%options)) {
        $my->{$_} = $options{$_};  # transfer default options
    }
    # transfer user args
    foreach (keys(%args)) {
        croak("I don't understand option $_\n") unless(exists($options{$_}));
        $my->{$_} = $args{$_};  # transfer user option
    }
    foreach my $type (qw(hoshi black white)) {
        next unless (exists($my->{$type}));
        my $coordList =  delete($my->{$type});
        for (my $ii = 0; $ii < @{$coordList}; $ii++) {
            $my->{board}{$coordList->[$ii]}{$type} = $my->{node};
            $my->{board}{$coordList->[$ii]}{color} = $type;
            if (($type eq 'white') and
                exists($my->{board}{$coordList->[$ii]}{black})) {
                carp("Black and white on the same intersection (at $coordList->[$ii]");
            }
        }
    }
    $my->{coord_style} = 'normal' unless (defined($my->{coord_style}));
    $my->{actions} = [];        # no actions yet
    $my->{actions_done} = 0;    # no actions done yet
    $my->{provisional} = 1;     # make all actions provisional
    return($my);
}

=head1 METHODS

=over 4

=item $diagram-E<gt>B<clear>

Clears the B<Diagram>.  All B<mark>s, B<label>s, and B<number>s are
removed from the stones and intersections.  All B<capture>d stones
are removed, and all overstones are deleted (at which point, the
B<Diagram> is in the same state as a B<new> B<Diagram>).  Pending
actions that were not applied due to conflicts are now applied to
the B<clear>ed B<Diagram>.

The following options are preserved:

=over 4

=item *

node    (gets incremented)

=item *

callback

=item *

enable_overstones

=back

=cut

sub clear {
    my ($my) = @_;

# print "clear\n";
    my $actions = delete($my->{actions});       # save pending actions
    foreach my $key (keys(%{$my})) {
        next if (($key eq 'board') or
                 exists($options{$key}));
        delete($my->{$key});
    }
    my %new_board;
    # make a new board, keeping only hoshi and un-numbered stones
    foreach my $coords (keys(%{$my->{board}})) {
        my $int = $my->{board}{$coords};   # intersection
        $new_board{$coords}{hoshi} = $int->{hoshi} if(exists($int->{hoshi}));
        my $stone = $my->game_stone($int);
        $new_board{$coords}{$stone} = 0 if (defined($stone));
    }
    delete($my->{board});
    $my->{board} = \%new_board;
    if (@{$actions}) {
        foreach(@{$actions}) {
            &{$_}($my);             # call the closures
        }
    }
    $my->{node}++;
    $my->{actions} = [];        # no actions yet
    $my->{actions_done} = 0;    # no actions done yet
    $my->{provisional} = 1;     # make all actions provisional
    return $my;
}

=item $diagram-E<gt>B<force_conflict(? $msg ?)>

Set the conflict flag to force pending actions to be flushed and a new
$diagram created.  It's a good idea to pass a short $msg explaining the
conflict is being created.  $msg is printed in -verbose mode of sgf2dg.  If
no $msg is defined, a generic (and probably not very helpful) message is
produced.

=cut

sub force_conflict {
    my ($my, $msg) = @_;

    $my->{conflict} = defined($msg) ? $msg : 'forced conflict';
}

=item my $pending_count = $diagram-E<gt>B<actions_pending>

Returns the number of actions that would be executed if B<node> were called.

=cut

sub actions_pending {
    my ($my) = @_;

    return (scalar(@{$my->{actions}}));
}

=item my $done_count = $diagram-E<gt>B<actions_done>

Returns the number of actions that have been done for the current $diagram.

=cut

sub actions_done {
    my ($my) = @_;

    return ($my->{actions_done});
}

=item my $nextDiagram = $diagram-E<gt>B<next>

Creates a new B<Diagram> object starting from the current
B<Diagram>.  $nextDiagram is the starting point for the next
B<Diagram> in a series, or for a variation.

As with the B<clear> method, all B<capture>d stones are removed, and
all overstones are deleted.  Pending actions that were not
applied due to conflicts are now applied to the B<next> B<Diagram>.

The following options are preserved:

=over 4

=item *

node    (gets incremented)

=item *

callback

=item *

enable_overstones

=item *

=back

=cut

sub next {
    my ($my) = @_;

    my (@hoshi, @black, @white);
# print "next\n";
    foreach my $coords (keys(%{$my->{board}})) {
        my $int = $my->{board}{$coords};        # intersection
        if (exists($int->{hoshi})) {
            push(@hoshi, $coords);
        }
        my $stone = $my->game_stone($int);
        next unless(defined($stone));
        push(@white, $coords) if($stone eq 'white');
        push(@black, $coords) if($stone eq 'black');
    }
    my %o;
    foreach my $key (keys(%options)) {
        next if (($key eq 'black') or
                 ($key eq 'white') or
                 ($key eq 'hoshi') or
                 ($key eq 'node'));
        $o{$key} = $my->{$key}; # watch out for reference copies!
    }
    my $next = Games::Go::Sgf2Dg::Diagram->new(
        hoshi    => \@hoshi,
        white    => \@white,
        black    => \@black,
        %o,
        );
    foreach(@{$my->{actions}}) {
        &{$_}($next);           # call the closures on new Diagram
    }
    $next->node;                # and complete them
    return $next;
}

=item $diagram-E<gt>B<hoshi(@hoshi_coords)>

Adds the coords listed in @hoshi_coords to any existing hoshi
points.  In array context, returns the list of coords that are hoshi
points.  In scalar context, returns a reference to the list.

=cut

sub hoshi {
    my ($my, @new_hoshi) = @_;

    foreach(@new_hoshi) {
        $my->{board}{$_}{hoshi} = $my->{node};
    }
    my @hoshi;
    foreach (keys(%{$my->{board}})) {
        push (@hoshi, $_) if (exists($my->{board}{$_}{hoshi}));
    }
    return wantarray ? @hoshi : \@hoshi;
}

=item $diagram-E<gt>B<node>

All actions (B<put>, B<mark>, B<label> and B<property>) are
provisional until B<node> is called.  This makes a collection of
actions atomic.  A B<Diagram> node is analogous to a Smart Go Format
(SGF) node.  If there are no conflicts with the collected
provisional actions, B<node> incorporates them into the B<Diagram>
and returns non-zero (the current node number).

If there is a conflict and a user B<callback> is defined, B<node>
calls the callback with a reference to the B<Diagram> ($diagram) as
the only argument.  The user callback should either flush the
B<Diagram> and call B<clear> (to reuse the B<Diagram>) or save the
current B<Diagram>, and call B<next> (to generate a new B<Diagram>).

If there is a conflict and no user B<callback> is defined, B<node>
returns 0.  The user should either:

=over 4

=item *

flush the current B<Diagram> and call $diagram-E<gt>B<clear>
to continue working with the current B<Diagram>, or:

=item *

save the current B<Diagram> (and call $diagram-E<gt>B<next> to
create a new B<Diagram> to continue working with)

=back

Calling either B<next> or B<clear> causes the pending collection of
conflicting actions to be incorporated into the resulting
B<Diagram>.

=cut

sub node {
    my ($my) = @_;

# print "node $my->{node}\n";
    if ($my->{conflict}) {
        if (exists($my->{callback})) {
# print "calling callback\n";
            &{$my->{callback}}($my, $my->{conflict});
            delete($my->{conflict});
            return $my->{node};
        }
        return 0;               # conflict: user needs to do something
    }
    $my->{provisional} = 0;     # make all actions actual
    foreach(@{$my->{actions}}) {
        &{$_}($my);             # call the closures
    }
    $my->{actions_done} += @{$my->{actions}};
    $my->{actions} = [];        # clear actions list
    $my->{provisional} = 1;     # make all actions provisional
    return ++$my->{node};
}

=item $diagram-E<gt>B<put> ('coords', 'black' | 'white',  ? number ? )

B<put> a black or white stone on the B<Diagram> at B<coords>.  The
stone color is must be 'black' or 'white' (case insensitive, 'b' and
'w' also work).  Optional B<number> is the number on the stone.  If
not defined, the stone is un-numbered (which is probably a mistake
except at the very start of a B<Diagram>.

B<put>ting can cause any of the following conflicts:

=over 4

=item *

stone is numbered and number is already used

=item *

stone is numbered and the intersection is already labeled

=back

In certain situations, (notably ko and snapbacks but also some other
capturing situations), B<put> stones may become overstones.
overstones are stones played on an intersection that contains a
stone that has been B<capture>d, but not yet removed from the
B<Diagram>.  There are two kinds of overstones: normal and
B<mark>ed, depending on the state of the underlying (B<capture>d but
not yet removed) stone.

If the underlying stone is B<number>ed, B>mark>ed or B<label>ed, the
overstone is normal and there will be no conflicts (unless the number is
already used!).

If the underlying stone is un-B<number>ed and un-B<label>ed, the
B<Diagram> attempts to convert it into a B<mark>ed stone.  If the
conversion succeeds, the overstone becomes a marked overstone,
and there is no conflict.

The conversion of the underlying stone causes a conflict if:

=over 4

=item *

a stone of the same color as the underlying stone has already
been converted elsewhere in the B<Diagram>, or

=item *

a mark of the same color as the underlying stone exists elsewhere in the
B<Diagram>.

=back

See the B<get> method for details of how overstone information is
returned.

=cut

sub put {
    my ($my, $coords, $color, $num) = @_;

    return 0 unless($my->_checkArgs('put', \$coords, \$color, \$num));
    my $num_msg = defined($num) ? " at move $num" : '';
    $my->{board}{$coords} = {} unless defined($my->{board}{$coords});
    my $int = $my->{board}{$coords};    # intersection
    if (exists($int->{$color}) and              # same color and
        ((not defined($num) and
          not exists($int->{number})) or        # both unnumbered or
         (defined($num) and
          exists($int->{number}) and            # both the same number
          ($num == $int->{number})))) {
        return $my->{node};                     # it's exactly the same
    }
    if (defined($my->game_stone($coords))) {    # must not be a stone here now
        my $err = "coords = $coords, new color = $color,\nalready here: ";
        $err .= $my->game_stone($coords) . ' ';
        if(exists($int->{overstones})) {
            my $ii = scalar(@{$int->{overstones}}) - 2; # get last two entries
            $err .= $int->{overstones}[$ii + 1];        # number of last stone played
        } elsif (exists $int->{number}) {
            $err .= $int->{number};
        } else {
            $err .= '(numberless)';
        }
        carp("can't 'put' a stone on top of a stone: $err");
        return 0;
    }
    if ($my->{provisional}) {
        push (@{$my->{actions}}, sub { $_[0]->put($coords, $color, $num); } );
    }
    my $makeOverStone = (exists($int->{white}) or       # stone already here?
                         exists($int->{black}));        #   make an overstone
    if ($makeOverStone) {
        $my->_overstone($coords, $color, $num)
    } elsif ((defined($num) and                 # new stone is numbered?
              (exists($my->{number}{$num}) or   # already used number?
               exists($int->{mark}) or          # mark already here?
               exists($int->{label})))) {       # label already here?
# print "put conflict $color$num_msg\n";
        $my->{conflict} = 'put: number, mark or label conflict';
        return 0;
    }
    unless ($my->{provisional}) {
        if (defined($num)) {
            $int->{number} = $num unless($makeOverStone);
            $my->{number}{$num} = $my->{node};
        }
        delete($int->{capture});
        unless ($makeOverStone) {
            $int->{$color} = $my->{node};
            $int->{color} = $color;
        }
    }
    return $my->{node};
}

# convert $color move $num to overstone, and use stone at $coords as its
# understone (mark it if necessary)
sub _overstone {
    my ($my, $coords, $color, $num) = @_;

    unless($my->{enable_overstones} and     # must be enabled,
           defined($num)) {                 # overstones must be numbered
# print "overstone 0 conflict $color\n";
        $my->{conflict} = 'overstone: number not defined';
        return 0;
    }
    my $int = $my->{board}{$coords};
    my $underColor = exists($int->{black}) ? 'black' : 'white';
    if (exists($int->{number}) or
        exists($int->{label})) {
        # we can use the number/label for referencing the understone
    } elsif (exists($int->{mark})) {        # intersection already marked?
        # if there is exactly one mark of this type and color, we can use
        #   it.  otherwise, it's a conflict
        if (exists ($my->{mark_count}{$int->{mark}}) and
            exists ($my->{mark_count}{$int->{mark}}{$int->{color}}) and
            ($my->{mark_count}{$int->{mark}}{$int->{color}} != 1)) {
# print "overstone conflict $color $num\n";
            $my->{conflict} = 'overstone: mark conflict';
            return 0;
        }
    } else {
        # understone isn't numbered, labeled, or marked.
        # convert it to a marked stone
        unless($my->{provisional}) {
            $int->{mark} = DEFAULT_MARK;
            $my->{mark}{DEFAULT_MARK}{$underColor} = $my->{node};
            $my->{mark_count}{DEFAULT_MARK}{$underColor}++;
        }
    }
    unless($my->{provisional}) {
        push(@{$my->{overlist}}, $int) unless(exists($int->{overstones})); # list of all overstones in the diagram
        push(@{$int->{overstones}}, $color, $num);  # list of all overstones for this intersection
        delete($int->{capture});
    }
}

=item $diagram-E<gt>B<renumber>($coords, $color, $old_num, $new_num);

Changes the number of a stone already on the board.  $color, and
$old_num must match the existing color and number for the stone at
$coords ($old_num or $new_num may be undef for an un-numbered
stone).  Only the displayed stone is compared for the match,
overstones (B<game_stone>s) are not considered.

Fails and returns 0 if:

=over 4

=item *

there is no diagram stone on the intersection, or

=item *

$color or $old_num don't match, or

=item *

$new_num is already used, or

=item *

a B<property> item exists for $old_num and $new_num is undef

=back

If none of the above, B<renumber> sets the new number and returns 1.

=cut

sub renumber {
    my ($my, $coords, $color, $old_num, $new_num) = @_;

    return 0 unless($my->_checkArgs('renumber', \$coords, \$color, \$old_num));
    return 0 unless($my->_checkArgs('renumber', \$coords, \$color, \$new_num));
    $my->{board}{$coords} = {} unless defined($my->{board}{$coords});
    my $int = $my->{board}{$coords};    # intersection
    return 0 if (not exists($int->{$color}) or
                 (defined($new_num) and
                  exists($my->{number}{$new_num})) or
                 (defined($old_num) and
                  exists($my->{property}{$old_num}) and
                  not defined ($new_num)));
    return 0 unless((not defined($old_num) and
                     not exists($int->{number})) or
                    (defined($old_num) and
                     defined($int->{number}) and
                     ($old_num == $int->{number})));
    delete($my->{number}{$old_num}) if(defined($old_num));
    if (defined($new_num)) {
        $int->{number} = $new_num;
        $my->{number}{$new_num} = $my->{node};
        if(defined($old_num) and
           exists($my->{property}{$old_num})) {
            $my->{property}{$new_num} = delete($my->{property}{$old_num});
        }
    } else {
        delete($int->{number});
    }
    return 1;
}

=item my $offset = $diagram-E<gt>B<offset>($new_offset);

Set a new offset for the diagram if $new_offset is defined.  Returns
the current value of the offset, or 0 if no offset has been set.

Note that B<Diagram> doesn't use the offset for anything, but
external programs (like a converter) can use it to adjust the
numbering.

=cut

sub offset {
    my ($my, $new_offset) = @_;

    $my->{offset} = $new_offset if(defined($new_offset));
    return $my->{offset};
}


sub _checkArgs {
    my ($my, $name, $coords, $color, $num) = @_;

    my $num_msg = defined($$num) ? " at move $$num" : '';
    unless(defined($$coords)) {
        carp("'$name' expects a '\$coords' argument$num_msg");
        return 0;
    }
    my $c = $$color;
    $c = 'undef' unless defined($c);
    $c = lc $c;
    $c = 'black' if ($c eq 'b');
    $c = 'white' if ($c eq 'w');
    if (($c ne 'white') and
        ($c ne 'black')) {
        carp("'$name' expects 'white' or 'black', not $$color$num_msg");
        return 0;
    }
    if (defined($$num) and
        ($$num =~ /\D/)) {
        carp("'$name' expects number or undef for $$color stone, not $$num$num_msg");
        return 0;
    }
    $$color = $c;       # normalize color
    return 1;
}

=item $diagram-E<gt>B<label>('coords', 'text');

Place a label on an intersection.  B<text> may be any text, but notice that
long strings may overflow a stone or intersection.  If 'text' is empty ('')
any existing label is removed.

The same label can be applied to several intersections only if they
are all labeled within a single B<node>.

If the intersection or stone is already labeled, or occupied by a
marked, or numbered stone, or if the label has already been used
outside the labeling group, B<label> causes a conflict.

=cut

sub label {
    my ($my, $coords, $label) = @_;

    unless(defined($coords)) {
        carp("'label' expects a '\$coords' argument");
        return 0;
    }
    return unless (defined($label));
    if ($my->{provisional}) {
# print "provisional ";
        push (@{$my->{actions}}, sub { $_[0]->label($coords, $label); } );
    }
# print "label $coords with $label\n";
    $my->{board}{$coords} = {} unless defined($my->{board}{$coords});
    my $int = $my->{board}{$coords};    # intersection
    if ($label eq '') {
        delete $int->{label};
        return $my->{node};
    }
    if ((exists($int->{label}) and
         ($int->{label} ne $label)) or              # different label already here?
        exists($int->{mark}) or                     # a mark?
        exists($int->{number}) or                   # a number?
        (exists($my->{label}{$label}) and           # label already used?
         ($my->{label}{$label} != $my->{node}))) {  # outside labeling group?
# print "label conflict $coords $label\n";
        $my->{conflict} = 'label: mark, number, or previous label conflict';
        return 0;
    }
    unless ($my->{provisional}) {
        $int->{label} = $label;
        $int->{$label} = $my->{node};
        $my->{label}{$label} = $my->{node};
    }
    return $my->{node};
}

=item $diagram-E<gt>B<mark>('coords', ? 'mark_type' ?);

Place a mark on a stone or intersection.  The 'mark_type' can be any text,
but is usually the SGF property:

=over 4

=item CR  circle

=item MA  an X mark

=item SQ  square

=item TR  triangle

=back

If 'mark_type' is not supplied (or undef), MA is assumed.

The B<mark> raises a conflict if:

=over 4

=item *

the intersection is already B<label>led or numbered, or

=item *

the same color and 'mark_type' already exists in the B<Diagram> for a
previous node (possibly from creating an understone).

=back

=cut

sub mark {
    my ($my, $coords, $mark_type) = @_;

    unless(defined($coords)) {
        carp("'mark' expects a '\$coords' argument");
        return 0;
    }
    if ($my->{provisional}) {
        push (@{$my->{actions}}, sub { $_[0]->mark($coords, $mark_type); } );
    }
# print "put $mark_type mark $coords\n";
    $my->{board}{$coords} = {} unless defined($my->{board}{$coords});
    my $int = $my->{board}{$coords};    # intersection
    my $color = 'empty';
    $color = 'white' if (exists($int->{white}));
    $color = 'black' if (exists($int->{black}));
    if (exists($int->{label}) or        # label already here?
        exists($int->{number}) or       # number already here?

        (exists($my->{mark}{$mark_type}{$color}) and                # type/color already used?
         ($my->{mark}{$mark_type}{$color} != $my->{node}))) {       # outside group?
        $my->{conflict} = 'mark: label or number conflict';
        return 0;
    }
    unless ($my->{provisional}) {
        $int->{mark} = $mark_type;
        $my->{mark}{$mark_type}{$color} = $my->{node};  # flag global mark on this node
        $my->{mark_count}{$mark_type}{$color}++;        # count marks of each type and color
    }
    return $my->{node};
}

=item my $diagram-E<gt>B<territory> ($propID, $coords);

$propID should be one of 'TB', 'TW', or undef.  B<territory> marks the
intersection $coords as being white or black territory (see 'TB', 'TW' in
the B<get> method below).  If $number is undef, any previous territory
marking is removed.

=cut

sub territory {
    my ($my, $propID, $coords) = @_;

    unless(defined($coords)) {
        carp("'territory' expects '\$propID', and '\$coords' arguments");
        return 0;
    }
    if ($my->{provisional}) {
        push (@{$my->{actions}}, sub { $_[0]->territory($propID, $coords); } );
    } else {
        $my->{board}{$coords} = {} unless defined($my->{board}{$coords});
        if (defined($propID)) {
            $my->{board}{$coords}{$propID} = $propID;   # mark the intersection
        } else {
            delete($my->{board}{$coords}{$propID});     # unmark the intersection
        }
    }
}

=item my $diagram-E<gt>B<view> ($coords);

If $coords is defined, then the game-level VW property is set, and the
intersection at $coords is marked as viewable (hash key is 'VW').  If
$coords is '' or undef, then the game-level VW property is deleted, and the VW
mark is removed from all intersections.

=cut

sub view {
    my ($my, $coords) = @_;

    if ($my->{provisional}) {
        push (@{$my->{actions}}, sub { $_[0]->view($coords); } );
    } else {
        if (defined($coords) and
            ($coords ne '')) {
            $my->{property}{0}{VW} = (1);   # set game-level viewable property
            $my->{board}{$coords}{VW} = 1;  # mark the intersection as viewable
        } else {
            delete ($my->{property}{0}{VW});        # remove game-level viewable property
            foreach (keys(%{$my->{board}})) {
                delete($my->{board}{$_}{VW});  # remove all viewable marks
            }
        }
    }
}

=item my $nameListRef = $diagram-E<gt>B<name> (? name, ... ?)

Adds B<name>(s) to the current B<Diagram>.  Names accumulate by
getting pushed onto a list.

In array context, B<name> returns the current name list.  In scalar
context, B<name> returns a reference to the list of names.

=cut

sub name {
    my ($my, @names) = @_;

    if (defined($names[0])) {
        push (@{$my->{name}}, @names);
    }
    return wantarray ? @{$my->{name}} : $my->{name};
}

=item $diagram-E<gt>B<property> ($number, $propName, $propValue, ? $propValue... ?);

=item my $prop_ref = $diagram-E<gt>B<property> ($number);

=item my $all_props_ref = $diagram-E<gt>B<property> ();

If $propName and $propVal are defined, pushes them onto the
collection of properties associated with move $number.

Note that B<renumber>ing a move also B<renumber>s the properties.

If $number and $propName are defined and $propValue is not ( or is empty),
the $propName property is removed.

If $number is defined and $propName/$propValue are not, B<property>
returns a reference to the (possibly empty) hash of property IDs and
property Values associated with the move number:

    my $prop_ref = $diagram->property($number);
    my $prop_value = $prop_ref->{$propID}->[$idx];

If $number is not defined, returns a reference to the (possibly
empty) hash of properties stored in the B<Diagram>.  Hash keys are
the move number, and each hash value is in turn a hash.  The keys of
the property hashes are (short) property IDs and the hash values are
lists of property values for each property ID:

    my $all_prop_ref = $diagram->property();
    my $prop_value = $all_props_ref->{$moveNumber}->{$propID}->[$idx]

B<property> (when $propName and $propValue are defined) is an action
(it is provisional until B<node> is called) because properties are
associated with a node in the SGF.  However, B<property> never
causes a conflict.

Note that sgf2dg stores the following properties:

        propID          number  propVal          comment
        ------          ------  -------
    Move properties
        W[] or W[tt]    move    'pass'           white pass
        B[] or B[tt]    move    'pass'           black pass
        KO              move     ''              force move
        PL[W|B]         move     'W' | 'B'       set player
    Node annotation properties
        C[text]         move     text            move comment
        DM[dbl]         move     0 | 1           Even position
        GB[dbl]         move     0 | 1           Good for black
        GW[dbl]         move     0 | 1           Good for white
        HO[dbl]         move     0 | 1           Hotspot
        UC[dbl]         move     0 | 1           Unclear
        N[stxt]         move     simple_text     Name (node name)
        V[real]         move     real            Value (estimated game score)
    Move annotation properties
        BM[dbl]         move     0 | 1           Bad move
        DO              move     ''              Doubtful move
        IT              move     ''              Interesting move
        TE[dbl]         move     0 | 1           Tesuji (good move)
    Markup properties
        AR[c_pt]        move     'pt:pt'         Arrow
        DD[elst]        move     'pt?'           Dim points: DD[] clears
        LN[c_pt]        move     'pt:pt'         Line
        SL[lst]         move     'pt'            Select points (markup unknown)
    Root properties
        AP[stxt:stxt]   0        'stxt:stxt'     Application_name:version
        CA[stxt]        0        'charset'       character set
        FF[1-4]         0        0 - 4           FileFormat
        GM[1-16]        0        0 - 16          Game
        ST[0-3]         0        0 - 3           How to show variations (style?)
    Game info properties
        AN[stxt]        0        simple_text     Annotater (name)
        BT[stxt]        0        simple_text     Black team
        WT[stxt]        0        simple_text     White team
        CP[stxt]        0        simple_text     Copyright
        ON[stxt]        0        simple_text     Opening information
        OT[stxt]        0        simple_text     Overtime description (byo-yomi)
        PC[stxt]        0        simple_text     Place game was played
        RE[stxt]        0        simple_text     Result
        RO[stxt]        0        simple_text     Round
        RU[stxt]        0        simple_text     Rules
        SO[stxt]        0        simple_text     Source
        US[stxt]        0        simple_text     User/program who entered the game
        GC[text]        0        text            Game comment
        TM[real]        0        real_number     Time limits
    Timing properties
        BL[real]        move     real_number     BlackLeft (time)
        WL[real]        move     real_number     WhiteLeft (time)
        OB[num]         move     number          Black moves left (after this move)
        OW[num]         move     number          White moves left
    Go-specific properties
        HA[num]         0        number          Handicap
        KM[real]        0        real_number     Komi
    Misc. properties
        PM[num]         move     number          Print mode - see FF4 spec
        BS[stext]       move     stext           BlackSpecies (deprecated)
        WS[stext]       move     stext           WhiteSpecies (deprecated)
        FG[pt:stext]    move     bitmask:stext   Figure: see FF4 spec

=cut

sub property {
    my ($my, $number, $propId, @propVals) = @_;

    $my->{property} = {} unless(exists($my->{property}));
    if (defined($propId)) {
        if ($my->{provisional}) {
            push (@{$my->{actions}}, sub { $_[0]->property($number, $propId, @propVals); } );
        } else {
            if (@propVals) {
                push(@{$my->{property}{$number}{$propId}}, @propVals);
            } else {
                delete($my->{property}{$number}{$propId});
            }
        }
    }
    return ($my->{property}{$number} || {}) if (defined($number));
    return $my->{property};
}


=item @title_lines = $diagram-E<gt>B<gameProps_to_title> (\&emph_sub)

B<gameProps_to_title> converts game (node 0) properties extracted from the
SGF file.  The properties are scanned in the order listed here:

=over 4

=item GN GameName

=item EV EVent

=item RO ROund (joined to EVent)

=item DT DaTe

=item PC PlaCe

=item PW PlayerWhite "White:"

=item WR WhiteRank (joined to PW)

=item PB PlayerBlack "Black"

=item BR BlackRank (joined to PB)

=item KM KoMi "Komi:"

=item RU RUles "Rules:"

=item TM TiMe "Time:"

=item OT OverTime (byo-yomi) "Byo-yomi:"

=item RE REsult "Result:"

=item AN ANnotator "Annotated by:"

=item SO Source "Source:"

=item US USer "Entered by:"

=item CP CoPyright

=item GC GameComment

=back

For each property that is found, a line is added to the @title_lines return
array.  If the property has a string in double-quotes in the list above,
that string (plus one space) is prefixed to the property text.  In
addition, if \&emph_sub is defined, the prefix is passed to &$emph_sub to
make those portions appear emphasized in the title lines.  Example:

    my @title = $diagram->gameProps_to_title(sub { "{\\bf $_[0]}" });

wraps portions of the title line in TeX's bold-face (bf) style.

=cut

# pairs: first is short property ID, second is a prefix (which may be
# emphasized)
my @game_titles = (
            'GN', '',               # GameName
            'EV', '',               # Event and Round number
            'DT', '',               # DaTe
            'PC', '',               # PlaCe
            'PW', 'White:',         # PlayerWhite and WhiteRank
            'PB', 'Black:',         # PlayerBlack and BlackRank
            'KM', 'Komi:',          # KoMi
            'RU', 'Rules:',         # RUles
            'TM', 'Time:',          # TiMe constraints
            'OT', 'Byo-yomi:',      # OverTime
            'RE', 'Result:',        # REsult
            'AN', 'Annotated by:',  # ANnotater
            'SO', 'Source:',        # SOurce?
            'US', 'Entered by:',    # USer
            'CP', '',               # CoPyright
            'GC', '',               # GameComment
            );

sub gameProps_to_title {
    my ($my, $emph_sub) = @_;

    my %hash;
    my $gprops = $my->property(0);              # game properties are at node 0
    foreach my $key (keys(%{$gprops})) {
        my $short = $key;
        $short =~ s/[^A-Z]//g;                  # delete everything but upper case letters
        my $text = join('', @{$gprops->{$key}});
        $text =~ s/\n//gm;                      # should be simpletext already...
        $text =~ s/0*$// if ($short eq 'KM');   # remove ugly trailing zeros on komi supplied by IGS
        $hash{$short} = $text;
    }
    if (exists($hash{WR})) {
        if (exists($hash{PW})) {
            $hash{PW} = "$hash{PW} $hash{WR}";  # join name and rank
        } else {
            $hash{PW} = $hash{WR};              # rank only?
        }
    }
    if (exists($hash{BR})) {
        if (exists($hash{PB})) {
            $hash{PB} = "$hash{PB} $hash{BR}";  # join name and rank
        } else {
            $hash{PB} = $hash{BR};              # rank only?
        }
    }
    if (exists($hash{RO})) {
        if (exists($hash{EV})) {
            $hash{EV} = "$hash{EV} - $hash{RO}";# join event and round
        } else {
            $hash{EV} = $hash{RO};              # round only?
        }
    }

    $emph_sub = sub { return shift } unless(defined($emph_sub));
    my @lines;
    for (my $ii = 0; $ii < @game_titles; $ii += 2) {
        my $prop = $game_titles[$ii];
        next unless (exists $hash{$prop} and
                     $hash{$prop} ne '');
        my $pre = $game_titles[$ii + 1];
        if ($pre ne '') {
            $pre = &$emph_sub($pre);
            $pre .= ' ';
        }
        push @lines, "$pre$hash{$prop}";
    }
    return @lines;
}




=item $diagram-E<gt>B<capture> ('coords')

Captures the stone at the intersection.

Note that B<capture> has no visible affect on the diagram.  Rather,
it marks the stone so that it is removed when creating the B<next>
B<Diagram>.

B<capture> is not considered an action because it cannot cause a
conflict or change the visible status of the board.

=cut

sub capture {
    my ($my, $coords) = @_;

    unless(defined($coords)) {
        carp("'capture' expects a '\$coords' argument");
        return 0;
    }
    my $stone = $my->game_stone($coords);
    unless (defined($stone)) {
        carp("'capture(\$coords=$coords)' called, but there's no stone here");
        return undef;
    }
    my $int = $my->{board}{$coords};    # intersection
    $int->{capture} = $my->{node};
    return $my->{node};
}

=item $diagram-E<gt>B<remove> ('coords')

Removes the stone at the intersection.

Unlike B<capture>, B<remove> changes the visible status of the
B<Diagram>: the stone is deleted, along with all marks and letters
(only the 'hoshi', if any, is retained).

B<remove> is typically used at the start of a variation to remove
any stones that are improperly placed for the variation.  It is
closely related to the AddEmpty (AE) SGF property.

=cut

sub remove {
    my ($my, $coords) = @_;

    unless(defined($coords)) {
        carp("'remove' expects a '\$coords' argument");
        return 0;
    }
    my $int = $my->{board}{$coords};    # intersection
    foreach (keys(%{$int})) {
        delete($int->{$_}) unless($_ eq 'hoshi');
    }
    return $my->{node};
}

=item my $stone = $diagram-E<gt>B<game_stone>(coords | $intersection);

Returns 'black' or 'white' if there is a stone currently on the coords or
intersection (a reference to an intersection, such as is returned by
$diagram-E<gt>B<get>) , otherwise returns undef.

Note that the return value is determined by the game perspective, not the
diagram perspective.  If a stone is B<put> and later B<capture>d,
B<game_stone> returns undef even though the diagram should still show the
original stone.  If a white stone is B<put> and later B<capture>d, and then
a black stone is B<put>, B<game_stone> returns 'black', and B<get>
indicates that a white stone should be displayed on the diagram.

Note also that since B<put> is provisional until B<node> is called.  If you
use B<game_stone> to check for liberties and captures, it must be done
I<after> the call to B<node> that realizes the B<put>.

=cut

sub game_stone {
    my ($my, $int) = @_;

    unless(defined($int)) {
        carp("'game_stone' expects a 'coords' or \$intersection argument");
        return 0;
    }
    if (ref($int) ne 'HASH') {
        $int = $my->{board}{$int};
    }
    return undef unless(defined($int));
    return undef if(exists($int->{capture}));          # well, it *was* here a moment ago...
    # check overstone history
    if(exists($int->{overstones})) {
        my $ii = scalar(@{$int->{overstones}}) - 2;     # get last two entries
        return($int->{overstones}[$ii]);                # last color played
    }
    return 'black' if (exists($int->{black}));
    return 'white' if (exists($int->{white}));
    return undef;
}

=item $diagram-E<gt>B<get> ('coords')

Return the current status of the intersection.  Status is returned
as a reference to a hash.  The keys of the hash indicate the items
of interest, and the values of the hash are the indices where the
item was applied, except where noted below.

Only keys that have been applied are returned - an empty hash means
an empty intersection.

The hash keys can be any of:

=over 4

=item 'hoshi'

This intersection is a hoshi point.  Note that since hoshi points
are determined at B<new> time, the value of this hash entry is
always 0.  This key is returned even if a stone has been placed on
the intersection.

=item 'white'

The color of a stone at this intersection.

=item 'black'

The color of a stone at this intersection.

=item 'number'

The hash value is the number on the stone.  The node for
B<number> is found in the 'black' or 'white' hash value.

=item 'capture'

The stone on this intersection has been B<capture>d, the
intersection is currently empty from the perspective of the game.

=item 'mark'

The intersection or stone is marked.  The value indicates the type of mark,
usually the SGF property:

=over 4

=item CR  circle

=item MA  an X mark

=item SQ  square

=item TR  triangle

=back

=item 'label'

The intersection has been labeled.  The value indicates the text of the
label.

=item 'overstones'

If this hash entry exists it means that one or more stones were overlayed
on the stone that is currently displayed on this intersection of the
B<Diagram>.

The hash value is a reference to an array of color/number pairs.
The colors and numbers were passed to the B<put> method which
decided to convert the stone into an overstone.

This is typically seen as notes to the side of the diagram saying
something like "black 33 was played at the marked white stone".  In
this example. the information returned by B<get> describes 'the
marked white stone', while 'black' will be the first item in the
'overstones' array, and '33' will be the second:

    $diagram->get($coords) == {white => node_number,
                               overstones => ['black', 33],
                               ...}

=item 'TB' or 'TW'

Intersection has been marked as black or white territory with a TB or TW
property.

=item 'view'

Set when the intersection is marked with a VW view property.  Relates to
the VW game B<property>:

    if ((not $diagram->property(0)->VW) or      # no game-level VieW property
         $intersection->{view}) {               # this intersection is viewable
       # display this intersection
    }

=back

The hash reference returned by B<get> points to the data in the
B<Diagram> object - don't change it unless you know what you are
doing.

=cut

sub get {
    my ($my, $coords) = @_;

    unless(defined($coords)) {
        carp("'get' expects a '\$coords' argument");
        return {};
    }
    return $my->{board}{$coords} || {};
}

=item my $coord_string = $diagram-E<gt>B<xcoord>($x)

=item my $coord_string = $diagram-E<gt>B<ycoord>($y)

Returns a string to display for a given $x or $y coordinate.  The string
returned depends not only on the $x or $y value, but also on the
B<coords_style> and B<boardSizeX/Y> configuration options,

=cut

sub xcoord {
    my ($my, $x) = @_;

    $x--;
    if (lc($my->{coord_style}) eq 'sgf') {
        if ($x <= 26) {
            return chr($x + ord 'a');
        } elsif ($x <= 52) {
            return chr($x + ord 'A');
        } else {
            return '';
        }
    } elsif ($my->{coord_style} eq '++' or
             $my->{coord_style} eq '+-') {
        return "$x";
    } elsif ($my->{coord_style} eq '-+' or
             $my->{coord_style} eq '--') {
        my $c = $my->{boardSizeX} - $x - 1;
        return "$c";
    } else {    # normal
        return substr('ABCDEFGHJKLMNOPQRSTUVWXYZ', $x % 25, 1) x (1 + int($x / 25));
    }
}

sub ycoord {
    my ($my, $y) = @_;

    $y--;
    if (lc($my->{coord_style}) eq 'sgf') {
        return $my->xcoord($y + 1);       # same translation
    } elsif ($my->{coord_style} eq '++' or
             $my->{coord_style} eq '-+') {
        return "$y";
    } elsif ($my->{coord_style} eq '+-' or
             $my->{coord_style} eq '--') {
        my $c = $my->{boardSizeY} - $y - 1;
        return "$c"
    } else {    # normal
        my $c = $my->{boardSizeY} - $y;
        return "$c"
    }
}

=item my $first_number = $diagram-E<gt>B<first_number>

Returns the lowest number B<put> on the B<Diagram>, or 0 if no
numbered stones have been B<put>.

=cut

sub first_number {
    my ($my) = @_;

    my $first;
    foreach my $num (keys(%{$my->{number}})) {
        $first = $num unless(defined($first));
        $first = $num if ($num < $first);
    }
    $first = 0 unless(defined($first));
    return $first;
}

=item my $last_number = $diagram-E<gt>B<last_number>

Returns the highest number B<put> on the B<Diagram>, or 0 if no
numbered stones have been B<put>.

=cut

sub last_number {
    my ($my) = @_;

    my $last = 0;
    foreach my $num (keys(%{$my->{number}})) {
        $last = $num if ($num > $last);
    }
    return $last;
}

=item my $parentDiagram = $diagram-E<gt>B<parent> (? $parent ?)

If $parent is defined, sets the B<parent> for this diagram.

Always returns the current value of B<parent> (possibly undef).

=cut

sub parent {
    my ($my, $new) = @_;

    $my->{parent} = $new if (defined($new));
    return $my->{parent};
}

=item my $move_number = $diagram-E<gt>B<var_on_move> (? $new_number ?)

If $new_number is defined, sets the B<var_on_move> for this diagram.
This is intended to be used in conjunction with the <Bparent>
information to title diagrams such as

    my $title = "Variation 2 on move " .
                $diagram->var_on_move .
                " in " .
                $diagram->parent->name;

Always returns the current value of B<var_on_move> (possibly undef).

=cut

sub var_on_move {
    my ($my, $new) = @_;

    $my->{var_on_move} = $new if (defined($new));
    return $my->{var_on_move};
}

=item my $overListRef = $diagram-E<gt>B<getoverlist>

Returns a reference to the list of intersections with overstones.
The list members are the same intersection hash references returned
by the B<get> method.

The list is sorted by the order the intersections first had an
overstone B<put> on.  If there are no intersections with overstones,
returns a reference to an empty list.

=cut

sub getoverlist {
    my ($my) = @_;

    return($my->{overlist}) if (exists($my->{overlist}));
    return [];
}

=item my $user = $diagram-E<gt>B<user> ( ? $new_user ? )

If $new_user is defined, sets the B<user> value for the B<Diagram>.
Note that the B<user> is not used within B<Diagram>, but can be used
by external code for any purpose.  Most useful is probably if
$new_user is a reference to a hash of user-defined items of
interest.

Returns the current B<user> value (default is undef).

=cut

sub user {
    my ($my, $user) = @_;

    $my->{user} = $user if(defined($user));
    return $my->{user};
}

1;

__END__

=back

=head1 SEE ALSO

=over 0

=item L<sgf2dg>(1)

Script to convert SGF format files to Go diagrams

=back

=head1 BUGS

With the current architecture, conflicts within a node are not
detected.  I think this would probably be malformed SGF.  This
deficiency could be fixed by adding a 'shadow' diagram to which
provisional actions are applied.

