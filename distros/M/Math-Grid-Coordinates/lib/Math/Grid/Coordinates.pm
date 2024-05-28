package Math::Grid::Coordinates;

use Mojo::Util qw/dumper/;

use Moo;
use Scalar::Util qw/looks_like_number/;
use List::MoreUtils qw/uniq/;
use Carp;

my $NUM = sub { local $_ = shift; !$_ || (looks_like_number($_) && $_ >= 0) };

has [ qw/grid_width grid_height/ ] => ( is => 'rwp', isa => sub { local $_ = shift; looks_like_number($_) && int($_) == $_ && $_ > 0 } );

has [ qw/page_width page_height/ ] => ( is => 'rwp', isa => $NUM );

# item size

has [ qw/item_width item_height/ ] => ( is => 'rwp', isa => $NUM );

has [ qw/gutter_h gutter_v border_l border_r border_t border_b/ ] => ( is => 'rwp', isa => $NUM );

has "gutter" => (is => 'rwp', isa => $NUM, trigger => sub {
		     my ($self, $g) = @_;
		     if (defined $g) { for (qw/gutter_h gutter_v/) { my $set = "_set_$_"; $self->$set($g) } }
		     if ($self->gutter_v != $self->gutter_h) { carp "Multiple gutters"; return undef }
		 });

has "border" => (is => 'rwp',
		 isa => $NUM,
		 trigger => sub {
		     my ($self, $b) = @_;
		     if (defined $b) { for (qw/border_l border_r border_t border_b/) { my $set = "_set_$_"; $self->$set($b) } }
		     if (1 < scalar uniq map { $self->$_ } qw/border_l border_r border_t border_b/) {
			 carp "Multiple borders"; return undef
		     }
		 });


has arrange => ( is => 'rw', isa => sub { !$_ || /^h$/i || /^v$/i } , default => sub { 'h' } );

# grid and page sizes
# total items and sizes
# gutter and border as percentage

# 10pw
# 10iw

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $opts;

    if ( !ref $_[0] ) {
	return $class->build_simple($orig, @_);
    }
    elsif ($_[0]->{page_height} && $_[0]->{page_width}) {
	return $class->build_from_page($orig, @_);
    }
    else {
	return $class->build_from_grid($orig, @_);
    }
};

sub build_simple {
    my $class = shift;
    my $orig = shift;

    my %h;
    my $mode = "grid";
    if ($_[0] eq 'page' || $_[0] eq 'grid') { $mode = shift @_ }
    @h{$mode . "_width", $mode . "_height", qw/item_width item_height gutter border/} = grep { /[^a-z]/i } @_;
    ($h{arrange}) = (grep { /^[h,v]i/ } @_) || ('h');

    my $opts = \%h;

    $opts = _handle_percentages($opts);
    $opts = _handle_shortcuts($opts);

    my $obj = $class->$orig($opts);
    return $obj;
}

sub _handle_percentages {
    my $opts = shift;
    for (grep { (/^gutter/ || /^border/) && ($opts->{$_} || "") =~ /(\d+)([pi])([wh])$/ } keys $opts->%*) {
	$opts->{$_} =~ /(\d+)([pi])([wh])$/;
	my $ref = join "_", ($2 eq "p" ? "page" : "item"), ($3 eq "w" ? "width" : "height");
	croak "$ref not defined yet: cannot calculate $_" unless defined $opts->{$ref};
	$opts->{$_} = ($1 / 100) * $opts->{$ref};
    }
    return $opts;
}

sub _handle_shortcuts {
    my $opts = shift;

    for (qw/border_l border_r border_t border_b/) { $opts->{$_} //= $opts->{border} }
    for (qw/gutter_h gutter_v/) { $opts->{$_} //= $opts->{gutter} }
    for (qw/gutter gutter_h gutter_v border border_l border_r border_t border_b/) { $opts->{$_} //= 0 }

    return $opts;
}

sub _handle_conflicts {
    my $opts = shift;
    croak "cannot set both page_width and item_width at grid creation stage" if $opts->{page_width} && $opts->{item_width};
    croak "cannot set both page_height and item_height at grid creation stage" if $opts->{page_height} && $opts->{item_height};
}

sub build_from_grid {
    my $class = shift;
    my $orig = shift;
    my $opts = shift;

    $opts = _handle_percentages($opts);
    $opts = _handle_shortcuts($opts);

    $opts->{page_height} = ($opts->{border_t} + $opts->{gutter_v} * ($opts->{grid_height} - 1) + $opts->{item_height} * $opts->{grid_height} + $opts->{border_b});
    $opts->{page_width}  = ($opts->{border_l} + $opts->{gutter_h} * ($opts->{grid_width}  - 1) + $opts->{item_width}  * $opts->{grid_width} + $opts->{border_r});
 
    return $class->$orig($opts);
}

sub build_from_page {
    my $class = shift;
    my $orig = shift;
    my $opts = shift;

    $opts = _handle_percentages($opts);
    $opts = _handle_shortcuts($opts);

    my $avail_v = $opts->{page_height} - ($opts->{border_t} + $opts->{gutter_v} * ($opts->{grid_height} - 1) + $opts->{border_b});
    my $avail_h = $opts->{page_width}  - ($opts->{border_l} + $opts->{gutter_h} * ($opts->{grid_width}  - 1) + $opts->{border_r});

    # print $avail_h, $avail_v;

    $opts->{item_width}  = $avail_h / $opts->{grid_width};
    $opts->{item_height} = $avail_v / $opts->{grid_height};

    return $class->$orig($opts);
}


around [ qw/page_width page_height/ ] => sub {
    my $orig = shift;
    my $self = shift;
    croak "Page size can only be set at grid creation" if @_;
    return $orig->($self, @_);
};


sub total_height {
    my $self = shift;
    return $self->border_t + $self->item_height * $self->grid_height + $self->gutter_v * ($self->grid_height - 1) + $self->border_b;
};

sub total_width {
    my $self = shift;
    return $self->border_l + $self->item_width * $self->grid_width + $self->gutter_h * ($self->grid_width - 1) + $self->border_r
};

sub bbox {
    my $self = shift;
    my ($w, $h) = ($self->total_width, $self->total_height);
    return wantarray ? ($w, $h) : [ $w, $h ];
}

sub sequence {
    my $self = shift;
    my ($gw, $gh) = map { $self->$_ } qw/grid_width grid_height/; 
    my @sequence;

    if (lc($self->arrange) eq 'v') {
	for my $x (0..$gw-1) { for my $y (0..$gh-1) { push @sequence, [$x, $y] } }
    } else {
	for my $y (0..$gh-1) { for my $x (0..$gw-1) { push @sequence, [$x, $y] } }
    }
    return @sequence;
}

sub position {
    my $self = shift;

    my ($x, $y) = @_;
    my ($iw, $ih, $gt_h, $gt_v, $bl, $bt) = map { $self->$_ } qw/item_width item_height gutter_h gutter_v border_l border_t/; 
    # print ($x, $y, $iw, $ih, $gt_h, $gt_v, $bl, $bt);
    return (
	    ($bl + $iw * $x + $gt_h * $x),
	    ($bt + $ih * $y + $gt_v * $y)
	   )
}

sub positions {
    my $self = shift;

    # first assign positions in terms of page coordinates
    my @grid = $self->sequence;

    # then calculate and assign the actual position
    my @pos = map {
	[ $self->position(@$_) ]
    } @grid;

    return @pos;
}

sub block {
    my $self = shift;
    my ($x, $y, $w, $h) = @_;

    my ($iw, $ih, $gt_h, $gt_v, $bl, $bt) = map { $self->$_ } qw/item_width item_height gutter_h gutter_v border_l border_t/; 

    my ($x_pos, $y_pos) = (
			   $bl + $iw * $x + $gt_h * $x,
			   $bt + $ih * $y + $gt_v * $y,
			  );

    my ($width, $height) = (
			   $iw * $w + $gt_h * ($w - 1),
			   $ih * $h + $gt_v * ($h - 1),
			   );

    return ($x_pos, $y_pos, $width, $height)
}

sub guides {
    my $self = shift;
    my @guides;
    my ($h, $w, $ih, $iw) = map { $self->$_ } qw/page_height page_width item_height item_width/;

    for (0..$self->grid_width-1) {
	my $p = [ $self->position($_, 0) ]->[0];
	push @guides, [ [ $p, 0 ], [ $p, $h ] ];
	push @guides, [ [ $p + $iw, 0 ], [ $p + $iw, $h ] ];
    }
    for (0..$self->grid_height-1) {
	my $p = [ $self->position(0, $_) ]->[1];
	push @guides, [ [ 0, $p ], [ $w, $p ] ];
	push @guides, [ [ 0, $p + $ih ], [ $w, $p + $ih ] ];
    }
    return @guides;
}

sub marks {
    my $self = shift;
    my $l = shift || 12;

    my @marks = $self->guides;

    for my $m (@marks) {
	if ($m->[0][0] == $m->[1][0]) {
	    $m->[0][1] -= $l;
	    $m->[1][1] += $l;
	}
	elsif ($m->[0][1] == $m->[1][1]) {
	    $m->[0][0] -= $l;
	    $m->[1][0] += $l;
	}
    }
    return @marks
}


sub calculate {
    my $self = shift;

    my $avail_v = $self->page_height - ($self->border_t + $self->gutter_v * ($self->grid_height - 1) + $self->border_b);
    my $avail_h = $self->page_width  - ($self->border_l + $self->gutter_h * ($self->grid_width  - 1) + $self->border_r);

    $self->item_width($avail_h / $self->grid_width);
    $self->item_height($avail_v / $self->grid_height);

    return $self;
}


sub numbers {
    my $self = shift;
    return (1..($self->grid_width * $self->grid_height))
}

sub repage {
    my $self = shift;
    my $opts = shift;
    my $prev = $self->to_hash;

    for (grep { !(defined $opts->{$_}) } keys $opts->%*) { delete $prev->{$_} }
    for (grep {  (defined $opts->{$_}) } keys $opts->%*) { $prev->{$_} = $opts->{$_} }

    my $clone = $self = Math::Grid::Coordinates->new($prev);
    for (qw/item_height border_r gutter grid_width border_t border_l page_width border page_height gutter_v grid_height gutter_h border_b item_width/) {
	my $setter = "_set_$_";
	$self->$setter($clone->$_)
    }
    $self->arrange($clone->arrange);
    return $self;
}


sub to_hash {
    my $self = shift;
    my @keys = qw/grid_width grid_height border_r border_b border_t border_l gutter_v gutter_h item_height item_width page_height page_width arrange/;
    return { map { $_ =>($self->$_ || 0) } @keys };
    return { $self->%* };
}


1;

#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

Math::Grid::Coordinates - create geometric grids

=head1 SYNOPSYS

 use Math::Grid::Coordinates;

 my $grid = Math::Grid::Coordinates->new($grid_width, $grid_height, $item_width, $item_height, $gutter, $border, $arrangement);

=head1 DESCRIPTION

Math::Grid::Coordinates creates an array of x-y positions for items of a given height and width arranged in a grid. This is used to create grid layouts on a page, or repeate items on a number of pages of the same size.

=head1 REQUIRES

L<Moo> 

=head1 INITIALIZING THE GRID

The grid can be initialized by setting page size, the number of the items and the gutters and borders, like so:

 my $grid = Math::Grid::Coordinates->new({ page_width => 210, page_height => 297, grid_width => 2, grid_height => 3, gutter => 6, border => 12 });

in which case the item size is calculated.

It can also be initialized by setting item size, the number of the items and the gutters and borders, like so:

 my $grid = Math::Grid::Coordinates->new({ item_width => 210, item_height => 297, grid_width => 2, grid_height => 3, gutter => 6, border => 12 });

Gutters and borders can be percentages of page width or height like so:

 my $grid = Math::Grid::Coordinates->new({ item_width => 210, item_height => 297, grid_width => 2, grid_height => 3, gutter => 2pw, border => 4pw });


=head1 METHODS

=head2 bbox

 $grid->bbox();

Returns the total bounding box of the grid 

=head2 numbers

 $grid->numbers();

Returns the sequence item numbers, with the top left item as item 1.

 +---------+---------+---------+---------+
 |         |         |         |         |
 |    1    |    2    |    3    |    4    |
 |         |         |         |         |
 +---------+---------+---------+---------+
 |         |         |         |         |
 |    5    |    6    |    7    |    8    |
 |         |         |         |         |
 +---------+---------+---------+---------+
 |         |         |         |         |
 |    9    |   10    |   11    |   12    |
 |         |         |         |         |
 +---------+---------+---------+---------+

=head2 sequence

 $grid->sequence();

Returns the sequence of x-y grid item coordinates, with the top left item as item C<[0, 0]>, the next one (assuming a horizontal arrangement) being C<[1, 0]> etc. 

 +---------+---------+---------+---------+
 |         |         |         |         |
 | [0, 0]  | [0, 1]  | [0, 2]  | [0, 3]  |
 |         |         |         |         |
 +---------+---------+---------+---------+
 |         |         |         |         |
 | [1, 0]  | [1, 1]  | [1, 2]  | [1, 3]  |
 |         |         |         |         |
 +---------+---------+---------+---------+
 |         |         |         |         |
 | [2, 0]  | [2, 1]  | [2, 2]  | [2, 3]  |
 |         |         |         |         |
 +---------+---------+---------+---------+

=head2 position

 $grid->position(0, 0);

Returns the position of item as an array of x and y coordinates.

=head2 block

 $grid->block($x, $y, $width, $height);

Returns the position and size of item as an array of x and y coordinates, and width and height.

=head2 positions

 $grid->positions();

Returns the sequence of x-y grid coordinates.

=head2 total_height

 $grid->total_height();

The total height of the grid

=head2 total_width

 $grid->total_width();

The total width of the grid

=head2 calculate

 $grid->calculate();

Calculates item width and height based on page size, borders, gutters and item count

=head2 guides

 $grid->guides();

Returns start and end coordinates of layout guides

=head2 marks

 $grid->marks($length);

Returns start and end coordinates of layout marks (short lines outside page)

=head1 To do

=over 4

=item *

Allow for bottom or top start of grid

=back

=cut
