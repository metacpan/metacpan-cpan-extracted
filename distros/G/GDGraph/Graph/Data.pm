#==========================================================================
#              Copyright (c) 1995-2000 Martien Verbruggen
#--------------------------------------------------------------------------
#
#   Name:
#       GD::Graph::Data.pm
#
# $Id: Data.pm,v 1.22 2007/04/26 03:16:09 ben Exp $
#
#==========================================================================

package GD::Graph::Data;

($GD::Graph::Data::VERSION) = '$Revision: 1.22 $' =~ /\s([\d.]+)/;

use strict;
use GD::Graph::Error;

@GD::Graph::Data::ISA = qw( GD::Graph::Error );

=head1 NAME

GD::Graph::Data - Data set encapsulation for GD::Graph

=head1 SYNOPSIS

use GD::Graph::Data;

=head1 DESCRIPTION

This module encapsulates the data structure that is needed for GD::Graph
and friends. An object of this class contains a list of X values, and a
number of lists of corresponding Y values. This only really makes sense
if the Y values are numerical, but you can basically store anything.
Undefined values have a special meaning to GD::Graph, so they are
treated with care when stored.

Many of the methods of this module are intended for internal use by
GD::Graph and the module itself, and will most likely not be useful to
you. Many won't even I<seem> useful to you...

=head1 EXAMPLES

  use GD::Graph::Data;
  use GD::Graph::bars;

  my $data = GD::Graph::Data->new();

  $data->read(file => '/data/sales.dat', delimiter => ',');
  $data = $data->copy(wanted => [2, 4, 5]);

  # Add the newer figures from the database
  use DBI;
  # do DBI things, like connecting to the database, statement
  # preparation and execution

  while (@row = $sth->fetchrow_array)
  {
      $data->add_point(@row);
  }

  my $chart = GD::Graph::bars->new();
  my $gd = $chart->plot($data);

or for quick changes to legacy code

  # Legacy code builds array like this
  @data = ( [qw(Jan Feb Mar)], [1, 2, 3], [5, 4, 3], [6, 3, 7] );

  # And we quickly need to do some manipulations on that
  my $data = GD::Graph::Data->new();
  $data->copy_from(\@data);

  # And now do all the new stuff that's wanted.
  while (@foo = bar_baz())
  {
      $data->add_point(@foo);
  }

=head1 METHODS

=head2 $data = GD::Graph::Data->new()

Create a new GD::Graph::Data object.

=cut

# Error constants
use constant ERR_ILL_DATASET    => 'Illegal dataset number';
use constant ERR_ILL_POINT      => 'Illegal point number';
use constant ERR_NO_DATASET     => 'No data sets set';
use constant ERR_ARGS_NO_HASH   => 'Arguments must be given as a hash list';

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = [];
    bless $self => $class;
    $self->copy_from(@_) or return $self->_move_errors if (@_);
    return $self;
}

sub DESTROY
{
    my $self = shift;
    $self->clear_errors();
}

sub _set_value
{
    my $self = shift;
    my ($nd, $np, $val) = @_;

    # Make sure we have empty arrays in between
    if ($nd > $self->num_sets)
    {
        # XXX maybe do this with splice
        for ($self->num_sets .. $nd - 1)
        {
            push @{$self}, [];
        }
    }
    $self->[$nd][$np] = $val;

    return $self;
}

=head2 $data->set_x($np, $value);

Set the X value of point I<$np> to I<$value>. Points are numbered
starting with 0. You probably will never need this. Returns undef on
failure.

=cut

sub set_x
{
    my $self = shift;
    $self->_set_value(0, @_);
}

=head2 $data->get_x($np)

Get the X value of point I<$np>. See L<"set_x">.

=cut

sub get_x
{
    my $self = shift;
    my $np   = shift;
    return $self->_set_error(ERR_ILL_POINT)
        unless defined $np && $np >= 0;

    $self->[0][$np];
}

=head2 $data->set_y($nd, $np, $value);

Set the Y value of point I<$np> in data set I<$nd> to I<$value>. Points
are numbered starting with 0, data sets are numbered starting with 1.
You probably will never need this. Returns undef on failure.

=cut

sub set_y
{
    my $self = shift;
    return $self->_set_error(ERR_ILL_DATASET)
        unless defined $_[0] && $_[0] >= 1;
    $self->_set_value(@_);
}

=head2 $data->get_y($nd, $np)

Get the Y value of point I<$np> in data set I<$nd>. See L<"set_y">. This
will return undef on an error, but the fact that it returns undef does
not mean there was an error (since undefined values can be stored, and
therefore returned).

=cut

sub get_y
{
    my $self = shift;
    my ($nd, $np) = @_;
    return $self->_set_error(ERR_ILL_DATASET)
        unless defined $nd && $nd >= 1 && $nd <= $self->num_sets;
    return $self->_set_error(ERR_ILL_POINT)
        unless defined $np && $np >= 0;

    $self->[$nd][$np];
}

=head2 $data->get_y_cumulative($nd, $np)

Get the cumulative value of point I<$np> in data set<$nd>. The
cumulative value is obtained by adding all the values of the points
I<$np> in the data sets 1 to I<$nd>.

=cut

sub get_y_cumulative
{
    my $self = shift;
    my ($nd, $np, $incl_vec) = @_;
    return $self->_set_error(ERR_ILL_DATASET)
        unless defined $nd && $nd >= 1 && $nd <= $self->num_sets;
    return $self->_set_error(ERR_ILL_POINT)
        unless defined $np && $np >= 0;
    
    my $value;
    my @indices = $incl_vec ? grep($_ <= $nd, @$incl_vec) : 1 .. $nd;
    for my $i ( @indices )
    {
        $value += $self->[$i][$np] || 0;
    }

    return $value;
}

sub _get_min_max
{
    my $self = shift;
    my $nd   = shift;
    my ($min, $max);

    for my $val (@{$self->[$nd]})
    {
        next unless defined $val;
        $min = $val if !defined $min || $val < $min;
        $max = $val if !defined $max || $val > $max;
    }

    return $self->_set_error("No (defined) values in " . 
        ($nd == 0 ? "X list" : "dataset $nd"))
            unless defined $min && defined $max;
    
    return ($min, $max);
}

=head2 $data->get_min_max_x

Returns a list of the minimum and maximum x value or the
empty list on failure.

=cut

sub get_min_max_x
{
    my $self = shift;
    $self->_get_min_max(0);
}

=head2 $data->get_min_max_y($nd)

Returns a list of the minimum and maximum y value in data set $nd or the
empty list on failure.

=cut

sub get_min_max_y
{
    my $self = shift;
    my $nd   = shift;

    return $self->_set_error(ERR_ILL_DATASET)
        unless defined $nd && $nd >= 1 && $nd <= $self->num_sets;
    
    $self->_get_min_max($nd);
}

=head2 $data->get_min_max_y_all()

Returns a list of the minimum and maximum y value in all data sets or the
empty list on failure.

=cut

sub get_min_max_y_all
{
    my $self = shift;
    my ($min, $max);

    for (my $ds = 1; $ds <= $self->num_sets; $ds++)
    {
        my ($ds_min, $ds_max) = $self->get_min_max_y($ds);
        next unless defined $ds_min;
        $min = $ds_min if !defined $min || $ds_min < $min;
        $max = $ds_max if !defined $max || $ds_max > $max;
    }

    return $self->_set_error('No (defined) values in any data set')
        unless defined $min && defined $max;
    
    return ($min, $max);
}

# Undocumented, not part of interface right now. Might expose at later
# point in time.

sub set_point
{
    my $self = shift;
    my $np = shift;
    return $self->_set_error(ERR_ILL_POINT)
        unless defined $np && $np >= 0;

    for (my $ds = 0; $ds < @_; $ds++)
    {
        $self->_set_value($ds, $np, $_[$ds]);
    }
    return $self;
}

=head2 $data->add_point($X, $Y1, $Y2 ...)

Adds a point to the data set. The base for the addition is the current
number of X values. This means that if you have a data set with the
contents

  (X1,  X2)
  (Y11, Y12)
  (Y21)
  (Y31, Y32, Y33, Y34)

a $data->add_point(Xx, Y1x, Y2x, Y3x, Y4x) will result in

  (X1,    X2,    Xx )
  (Y11,   Y12,   Y1x)
  (Y21,   undef, Y2x)
  (Y31,   Y32,   Y3x,  Y34)
  (undef, undef, Y4x)

In other words: beware how you use this. As long as you make sure that
all data sets are of equal length, this method is safe to use.

=cut

sub add_point
{
    my $self = shift;
    $self->set_point(scalar $self->num_points, @_);
}

=head2 $data->num_sets()

Returns the number of data sets.

=cut

sub num_sets
{
    my $self = shift;
    @{$self} - 1;
}

=head2 $data->num_points()

In list context, returns a list with its first element the number of X
values, and the subsequent elements the number of respective Y values
for each data set. In scalar context returns the number of points
that have an X value set, i.e. the number of data sets that would result
from a call to C<make_strict>.

=cut

sub num_points
{
    my $self = shift;
    return (0) unless @{$self};

    wantarray ?
        map { scalar @{$_} } @{$self} :
        scalar @{$self->[0]}
}

=head2 $data->x_values()

Return a list of all the X values.

=cut

sub x_values
{
    my $self = shift;
    return $self->_set_error(ERR_NO_DATASET)
        unless @{$self};
    @{$self->[0]};
}

=head2 $data->y_values($nd)

Return a list of the Y values for data set I<$nd>. Data sets are
numbered from 1. Returns the empty list if $nd is out of range, or if
the data set at $nd is empty.

=cut

sub y_values
{
    my $self = shift;
    my $nd   = shift;
    return $self->_set_error(ERR_ILL_DATASET)
        unless defined $nd && $nd >= 1 && $nd <= $self->num_sets;
    return $self->_set_error(ERR_NO_DATASET)
        unless @{$self};

    @{$self->[$nd]};
}

=head2 $data->reset() OR GD::Graph::Data->reset()

As an object method: Reset the data container, get rid of all data and
error messages. As a class method: get rid of accumulated error messages
and possible other crud.

=cut

sub reset
{
    my $self = shift;
    @{$self} = () if ref($self);
    $self->clear_errors();
    return $self;
}

=head2 $data->make_strict()

Make all data set lists the same length as the X list by truncating data
sets that are too long, and filling data sets that are too short with
undef values. always returns a true value.

=cut

sub make_strict
{
    my $self = shift;

    for my $ds (1 .. $self->num_sets)
    {
        my $data_set = $self->[$ds];

        my $short = $self->num_points - @{$data_set};
        next if $short == 0;

        if ($short > 0)
        {
            my @fill = (undef) x $short;
            push @{$data_set}, @fill;
        }
        else
        {
            splice @{$data_set}, $short;
        }
    }
    return $self;
}

=head2 $data->cumulate(preserve_undef => boolean)

The B<cumulate> parameter will summarise the Y value sets as follows:
the first Y value list will be unchanged, the second will contain a
sum of the first and second, the third will contain the sum of first,
second and third, and so on.  Returns undef on failure.

if the argument I<preserve_undef> is set to a true value, then the sum
of exclusively undefined values will be preserved as an undefined value.
If it is not present or a false value, undef will be treated as zero.
Note that this still will leave undefined values in the first data set
alone.

Note: Any non-numerical defined Y values will be treated as 0, but you
really shouldn't be using this to store that sort of Y data.

=cut

sub cumulate
{
    my $self = shift;

    return $self->_set_error(ERR_ARGS_NO_HASH) if (@_ && @_ % 2);
    my %args = @_;

    # For all the sets, starting at the last one, ending just 
    # before the first
    for (my $ds = $self->num_sets; $ds > 1; $ds--)
    {
        # For each point in the set
        for my $point (0 .. $#{$self->[$ds]})
        {
            # Add the value for each point in lower sets to this one
            for my $i (1 .. $ds - 1)
            {
                # If neither are defined, we want to preserve the
                # undefinedness of this point. If we don't do this, then
                # the mathematical operation will force undef to be a 0.
                next if 
                    $args{preserve_undef} &&
                    ! defined $self->[$ds][$point] &&
                    ! defined $self->[$i][$point];

                $self->[$ds][$point] += $self->[$i][$point] || 0;
            }
        }
    }
    return $self;
}

=head2 $data->wanted(indexes)

Removes all data sets except the ones in the argument list. It will also
reorder the data sets in the order given. Returns undef on failure.

To remove all data sets except the first, sixth and second, in that
order:

  $data->wanted(1, 6, 2) or die $data->error;

=cut

sub wanted
{
    my $self = shift;

    for my $wanted (@_)
    {
        return $self->_set_error("Wanted index $wanted out of range 1-"
                    . $self->num_sets)
            if $wanted < 1 || $wanted > $self->num_sets;
    }
    @{$self} = @{$self}[0, @_];
    return $self;
}

=head2 $data->reverse

Reverse the order of the data sets.

=cut

sub reverse
{
    my $self = shift;
    @{$self} = ($self->[0], reverse @{$self}[1..$#{$self}]);
    return $self;
}

=head2 $data->copy_from($data_ref)

Copy an 'old' style GD::Graph data structure or another GD::Graph::Data
object into this object. This will remove the current data. Returns undef
on failure.

=cut

sub copy_from
{
    my $self = shift;
    my $data = shift;
    return $self->_set_error('Not a valid source data structure')
        unless defined $data && (
                ref($data) eq 'ARRAY' || ref($data) eq __PACKAGE__);
    
    $self->reset;

    my $i = 0;
    for my $data_set (@{$data})
    {
        return $self->_set_error("Invalid data set: $i")
            unless ref($data_set) eq 'ARRAY';

        push @{$self}, [@{$data_set}];
        $i++;
    }

    return $self;
}

=head2 $data->copy()

Returns a copy of the object, or undef on failure.

=cut

sub copy
{
    my $self = shift;

    my $new = $self->new();
    $new->copy_from($self);
    return $new;
}

=head2 $data->read(I<arguments>)

Read a data set from a file. This will remove the current data. returns
undef on failure. This method uses the standard module 
Text::ParseWords to parse lines. If you don't have this for some odd
reason, don't use this method, or your program will die.

B<Data file format>: The default data file format is tab separated data
(which can be changed with the delimiter argument). Comment lines are
any lines that start with a #. In the following example I have replaced
literal tabs with <tab> for clarity

  # This is a comment, and will be ignored
  Jan<tab>12<tab>24
  Feb<tab>13<tab>37
  # March is missing
  Mar<tab><tab>
  Apr<tab>9<tab>18

Valid arguments are:

I<file>, mandatory. The file name of the file to read from, or a
reference to a file handle or glob.

  $data->read(file => '/data/foo.dat') or die $data->error;
  $data->read(file => \*DATA) or die $data->error;
  $data->read(file => $file_handle) or die $data->error;

I<no_comment>, optional. Give this a true value if you don't want lines
with an initial # to be skipped.

  $data->read(file => '/data/foo.dat', no_comment => 1);

I<delimiter>, optional. A regular expression that will become the
delimiter instead of a single tab.

  $data->read(file => '/data/foo.dat', delimiter => '\s+');
  $data->read(file => '/data/foo.dat', delimiter => qr/\s+/);

=cut

sub read
{
    my $self = shift;

    return $self->_set_error(ERR_ARGS_NO_HASH) if (@_ && @_ % 2);
    my %args = @_;

    return $self->_set_error('Missing required argument: file') 
        unless $args{file};

    my $delim = $args{delimiter} || "\t";

    $self->reset();

    # The following will die if these modules are not present, as
    # documented.
    require Text::ParseWords;

    my $fh;
    local *FH;

    if (UNIVERSAL::isa($args{file}, "GLOB"))
    {
        $fh = $args{file};
    }
    else
    {
        # $fh = \do{ local *FH }; # Odd... This dumps core, sometimes in 5.005
        $fh = \*FH; # XXX Need this for perl 5.005
        open($fh, $args{file}) or 
            return $self->_set_error("open ($args{file}): $!");
    }

    while (my $line = <$fh>)
    {
        chomp $line;
        next if $line =~ /^#/ && !$args{no_comment};
        my @fields = Text::ParseWords::parse_line($delim, 1, $line);
        next unless @fields;
        $self->add_point(@fields);
    }
    return $self;
}

=head2 $data->error() OR GD::Graph::Data->error()

Returns a list of all the errors that the current object has
accumulated. In scalar context, returns the last error. If called as a
class method it works at a class level.

This method is inherited, see L<GD::Graph::Error> for more information.

=cut

=head2 $data->has_error() OR GD::Graph::Data->has_error()

Returns true if the object (or class) has errors pending, false if not.
In some cases (see L<"copy">) this is the best way to check for errors.

This method is inherited, see L<GD::Graph::Error> for more information.

=cut

=head1 NOTES

As with all Modules for Perl: Please stick to using the interface. If
you try to fiddle too much with knowledge of the internals of this
module, you could get burned. I may change them at any time.
Specifically, I probably won't always keep this implemented as an array
reference.

=head1 AUTHOR

Martien Verbruggen E<lt>mgjv@tradingpost.com.auE<gt>

=head2 Copyright

(c) Martien Verbruggen.

All rights reserved. This package is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<GD::Graph>, L<GD::Graph::Error>

=cut

"Just another true value";

