#!/usr/bin/perl
#===============================================================================
#      PODNAME:  Logwatch::RecordTree
#     ABSTRACT:  an object to collect and print Logwatch events
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Thu Mar 12 18:41:04 PDT 2015
#===============================================================================

use 5.008;
use strict;
use warnings;

package Logwatch::RecordTree;
use Moo;
use Carp qw( croak );
use UNIVERSAL::require;
use List::Util qw ( max min sum );
use Sort::Key::Natural qw( natsort natkeysort );

our $VERSION = '2.056'; # VERSION

use overload '""' => \&sprint;

my $_defaults = {};   # class variable

sub defaults {
    my ($self) = @_;

    my $name = ref $self || $self;
    $_defaults->{$name} ||= {};  # a hash for each sub-class
    return $_defaults->{$name};
}

sub import {
    my ($class, %hash) = @_;

    my $defaults = $class->defaults();
    while (my ($key, $value) = each %hash) {
        $defaults->{$key} = $value;
    }
}

sub check_coderef { die 'Not a CODE ref' if (ref $_[0] ne 'CODE') };
sub check_hashref { die 'Not a HASH ref' if (ref $_[0] ne 'HASH') };
sub check_arryref { die 'Not an ARRAY ref' if (ref $_[0] ne 'ARRAY') };

has name => (           # name/title for this item
    is => 'ro',
);
has sprint_name => (    # callback to print the name
    is => 'rw',
    isa => \&check_coderef,
    default => sub {
        sub {
            return $_[0]->name;
        }
    },
);
has sort_key => (       # this overrides ->name in sort_children
    is => 'rw',
);
has case_sensitive => (
    is => 'rw',
);
has count => (          # count how many times we log this event
    is => 'rw',
    default => sub { 0 },
    trigger => sub {
        $_[0]->no_count;
    }
);
has count_fields => (       # fields to make the count
    is => 'rw',
    isa => \&check_arryref,
    default => sub { [] },
);
has count_formatted => ( # count and extended fields, after formatting
    is => 'rw',
);
has no_count => (       # suppress count field (probably because it's the same as the parent)
    is => 'rw',
);
has children => (   # a hash of child Logwtch::RecordTrees
    is => 'rw',
    isa => \&check_hashref,
    default => sub { {} },
);
has limit => (      # limit number of children printed
    is => 'rw',
    default => sub { 0 },   # default to no limit
);
has indent => (     # how much to indent this level of the tree
    is => 'rw',
);
has no_indent => (  # flag to suppress indentation of children
    is => 'rw',
);
has curr_indent => (    # total indentation of this level
    is => 'rw',
    default => sub { '' },
);
has post_callback => (  # when array is ready for printing, call this for final adjustments
    is => 'rw',
    isa => \&check_coderef,
    default => sub { sub {} },
);
has lines => (  # when array is ready for printing, store a ref to it here
    is => 'rw',
    isa => \&check_arryref,
);
has columnize => (  # flag to indicate we should columnize children
    is => 'rw',
);
has neat_names => ( # for the neat freaks
    is => 'rw',
);
has neat_format => ( # formatter for neatness, set by sprint
    is => 'rw',
    default => sub { "%s" },    # not neat
);
has extra => (      # a little something extra...
    is => 'rw',
);

sub BUILD {
    my ($self) = @_;

    while (my ($key, $value) = each %{$self->defaults}) {
        $self->$key($value);
    }
}

sub child_by_name { # find child by name(s), follow down the tree
    my ($self, @names) = @_;

    my $child = $self;
    for my $name (@names) {
        return if (not exists $child->children->{$name});
        $child = $child->children->{$name};
    }
    return $child;
}

sub create_child { # create child, add to children
    my ($self, $name, $type, $opts) = @_;

    $type ||= __PACKAGE__;  # default to this package
    $opts ||= {};
    $opts->{name} = $name;
    $type->require or croak($@);
    return $self->children->{$name} = $type->new( %{$opts} );
}

# adopt items, handle name conflicts
sub adopt {
    my ($self, $item) = @_;

    my $item_name = $item->name;
    my $my_child = $self->child_by_name($item_name);
    if ($my_child) {
        # name conflict.  my_child must adopt $item's children
        my @item_children = values %{$item->children};
        if (@item_children) {
            for my $child (@item_children) {
                $my_child->adopt($child);
            }
        }
        else {
            # no children, so transfer count directly from item to my_child
            $my_child->count($my_child->count + $item->count);
        }
    }
    else {
        # no name conflict, just copy over
        $self->children->{$item_name} = $item;
    }
    $self->count($self->count + $item->count);
}

# log event, add new children if necessaary
sub _log_children {
    my ($self, $name, @children) = @_;

    my ($type, $opts);
    if (ref $name eq 'ARRAY') {
        ($name, $type, $opts) = @{$name};
    }

    $name = "<name not defined>" if (not defined $name);  # supposed to be a list of names or array-refs

    my $child = $self->child_by_name($name);
    if (not defined $child) {
        $child = $self->create_child($name, $type, $opts)
    }

    if (@children) {
        return $child->_log_children(@children);
    }

    return $child;
}

sub _count { # add 1 to count down the path
    my ($self, $name, @children) = @_;

    $self->count($self->count + 1);

    $name = $name->[0] if (ref $name);
    if (defined $name) {
        return $self->child_by_name($name)->_count(@children);
    }
    return $self;
}

sub log_no_count { # log new event without counting, add children if necessary
    my ($self, @args) = @_;

    return $self->_log_children(@args);
}

sub log { # log new event adding to count, add children if necessary
    my ($self, @args) = @_;

    $self->_log_children(@args);
    return $self->_count(@args);
}

# return sorted list of child names
sub sort_children { # sort children
    my ($self) = @_;

    # make hash, value is name, key is sort_key or name
    my %keys = map { (defined($_->sort_key) ? $_->sort_key : $_->name) => $_ }
                   values %{$self->children};

    # sort by hash keys, create array of values to get back to names
    my @children = $self->case_sensitive
      ? map { $keys{$_} } natsort  keys %keys
      : map { $keys{$_} } natkeysort { lc $_ } keys %keys;

    return wantarray
        ?  @children
        : \@children;
}

# make neat column of child names
sub _neaten_children {
    my ($self) = @_;

    my $max = max(1, map { length $_->sprint_name->($_) } values %{$self->children});
    my $format = $self->neat_names < 0
      ? "%-${max}s"
      : "%${max}s";
    map { $_->neat_format($format) } values %{$self->children};
}

# make neat columns of all the count fields
sub _format_child_counts {
    my ($self, $children, $depth) = @_;

    # measure each field, save max length for each column
    my @maxes;
    for my $child (values %{$children}) {
        unshift @{$child->count_fields}, $child->count;
        my $ii = 0;
        for my $field (@{$child->count_fields}) {
            $maxes[$ii] = max($maxes[$ii] || 0, length $field);
            $ii++;
        }
    }

    # string to indent children: total count field width or at least 3
    my $min = sum(1, @maxes);
    $min = 3 if ($min < 3);
    my $child_indent = " " x $min;

    # pad all fields to the max for the column
    for my $child (values %{$children}) {
        my $ccf = $child->count_fields;
        my @padded;
        for my $ii (0 .. $#maxes) {
            $padded[$ii] = sprintf "%*s", $maxes[$ii], $ccf->[$ii] || '';
        }
        $child->count_formatted(join '', @padded);
        $child->indent($child_indent) if (not defined $child->indent);
        shift @{$child->count_fields};  # remove the count field we inserted above
    }
}

# compare our count fields to $other's (for suppression when identical)
sub _count_fields_differ {
    my ($self, $other) = @_;

    return 1 if ($self->count != $other->count);
    for my $ii (0 .. max($#{$self->count_fields}, $#{$other->count_fields})) {
        return 1 if (
            not defined $self->count_fields->[$ii] or
            not defined $other->count_fields->[$ii] or
            $self->count_fields->[$ii] ne $other->count_fields->[$ii]);
    }
    return 0;   # match
}

sub sprint {
    my ($self, $callback, $path, $parent_indent, $depth) = @_;

    $path          ||= [];
    $parent_indent ||= '';
    $depth         ||= 1;

    if ($depth == 1) {
        # top level needs to format its own count field
        $self->_format_child_counts({ top => $self }, 0);
    }

    my $count = $self->no_count
      ? ''
      : $self->count_formatted . ' ';

    $self->lines(my $lines = []);

    if (length($self->name)) {
        push @{$lines}, join( '',
            $count,
            sprintf $self->neat_format, $self->sprint_name->($self),
        );
    }
    else {
        push @{$lines}, ''; # name is blank, so don't add anything here
    }

    # format count fields and calculate indent for all children,
    $self->_format_child_counts($self->children, $depth);

    my $children    = $self->sort_children;
    my $child_count = @{$children};

    if ($child_count == 1) {    # join single child to this line
        my $child = $children->[0];
        # save the child's flags we're going to alter
        my %flags = map { $_ => $child->$_ } qw( no_count no_indent );
        # suppress count field if child's is same as ours
        $child->no_count(1) if (not $self->_count_fields_differ($child));
        $child->no_indent(1);
        $child->curr_indent($parent_indent);    # no extra indent since we concat this line

        push @{$path}, $child->name;
        $child->sprint($callback, $path, $self->curr_indent, $depth + 1);
        if (length($lines->[0]) + length($child->lines->[0]) <= $self->width) {
            $lines->[0] .= ' ' . shift @{$child->lines};
        }
        push @{$lines}, @{$child->lines};
        pop @{$path};

        # restore child's flags
        map { $child->$_($flags{$_}) } keys %flags;
    }

    if ($child_count > 1) {
        my $last = $self->limit || $child_count; # if limit is zero, print all
        $last = $child_count if ($child_count - $last < 3); # if within 3, just print all
        $last = $child_count - $last;     # convert from limit to the last index

        # handle neat_children flag
        $self->_neaten_children if ($self->neat_names);

        for my $child (@{$children}) {
            $child->curr_indent($parent_indent . $self->indent);
            if ($child_count <= $last) {
                push @{$lines}, "... and $child_count more";
                last;
            }
            push @{$path}, $child->name;
            $child->sprint($callback, $path, $self->curr_indent, $depth + 1);
            push @{$lines}, @{$child->lines};
            pop  @{$path};
            $child_count--;
        }
    }

    $self->sprint_columns if ($self->columnize);

    # indent children
    if (not $self->no_indent) {
        for my $ii (1 .. $#{$lines}) {
            $lines->[$ii] = $self->indent . $lines->[$ii];
        }
    }

    $self->post_callback->($self, $path);

    $callback->($self, $path) if ($callback);

    return join "\n", @{$lines};
}

sub width {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{_width} = $new;
    }
    return $self->{_width} if (exists $self->{_width});
    return 80;  # default page width
}

sub col_width {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{_col_width} = $new;
    }

    if (not exists $self->{_col_width}) {
        # find longest line length, excluding the first line
        my $lines = $self->lines;
        $self->{_col_width} = max( 1, map { length $lines->[$_] } (1 .. $#{$lines}));
    }
    return $self->{_col_width};
}

sub col_count {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{_col_count} = $new;
    }

    if (not exists $self->{_col_count}) {
        # calculate from curr_indent, width, and col_width
        my $width = $self->width - length($self->curr_indent);
        $width = max(0, $width);    # at least 0
        $self->{_col_count} = int ($width / $self->col_width) || 1; # at least 1
    }
    return $self->{_col_count};
}

# re-arrange children into columns
sub sprint_columns {
    my ($self, $width, $col_count, $col_width) = @_;

    # allow caller to override width, col_count, and col_width
    $self->width($width)         if (defined $width);
    $self->col_count($col_count) if (defined $col_count);
    $self->col_width($col_width) if (defined $col_width);

    $col_count = $self->col_count;
    $col_width = $self->col_width;

    my $lines = $self->lines;
    my @new_lines = shift @{$lines};    # first line is unchanged

    my $lines_per_col = int ((@{$lines} + $col_count - 1) / $col_count);

    for my $ii (0 .. $lines_per_col - 1) {
        my @line;
        if ($col_count <= 1) {
            # single column, just prepend indent
            push @new_lines, join '',
                $self->indent,
                $lines->[$ii];
        }
        else {
            # join segments into a line of columns
            for my $jj (0 .. $col_count - 1) {
                my $l = $lines->[$ii + $jj * $lines_per_col];
                push @line, sprintf "%-*s", $col_width, $l if (defined $l);
            }
            push @new_lines, join '',
                $self->indent,
                join(' ', @line);
        }
    }
    $self->lines(\@new_lines);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Logwatch::RecordTree - an object to collect and print Logwatch events

=head1 VERSION

version 2.056

=head1 SYNOPSIS

 use Logwatch::RecordTree ( %options );

 my $tree = Logwatch::RecordTree->new( name => 'Service', ... );

 while ($ThisLine = <>) {
   ...
   # typical Logwatch event parsing from log files:
   elsif (my ($event, $from, $to) = $ThisLine =~ m/.../) {
     $tree->log($event, $from, $to);
   }
   elsif (my ($rx_or_tx, $subject, $ip) = $ThisLine =~ m/.../) {
     $tree->log('Event', [$rx_or_tx, 'Logwatch::RecordTree::IPv4', {limit => 5}], $ip, $subject);
   }
   ...
 }
 ...
 print $tree;    # print the accumulated logs

=head1 DESCRIPTION

B<Logwatch::RecordTree> collects events noticed by logwatch service scripts.
When the script is finished, it produces a formatted summary ready to print.
The tree structure can be extended indefinitely.  There are options and hooks
for adjusting the format of the summary.

B<Logwatch::RecordTree> can be used as-is, or it can be sub-classed to add
specialized formatting.  For example, see B<Logwatch::RecordTree::IPv4>
which can be used when events should be keyed and sorted by IP number.

B<Logwatch::RecordTree> overloads the stringification operator via the
B<sprint> method.

B<%options> specified at 'use' time are added to the B<defaults> option
hash (see B<defaults> method below).

Example service scripts for dovecot, exim, and http-error (Apache's
error_log) are provided in the extra/ subdirectory.  These scripts would be
placed in the /etc/logwatch/services/scripts directory according to the
normal Logwatch configuration instructions.

=head2 Methods

=over

=item Logwatch::RecordTree->new( [ options ] );

Creates a new B<Logwatch::RecordTree> object.  The following options are available,
and are also available as accessors:

=back

=head3 Options

=over 8

=item name => 'event/group name'

Set or get the name/title of this event or group.  Required at B<new> time and
cannot be changed after.

This is the label that will appear in the logwatch listing.  For example, the
top level B<name> might be 'Sendmail:' and the second level B<name>s could be
'Sent:', 'Received:', etc.

=item sprint_name => sub {my $self = shift; ... }

Callback to format the B<name> field.  The default simply returns B<name>.

=item sort_key => 'string'

Get or set a key to use when the parent B<sort_children> method is called.
If B<sort_key> is defined for a child, its value is used instead of the
child's B<name>

Be careful that 'string' doesn't collide with any B<name>s or other
B<sort_keys> within this child.  Duplications can cause unpredictable
sorting problems, including possible loss of output lines.

=item case_sensitive => true or false

Set or get case sensitivity for B<sort_children>.  Default is insensitive
(false).

=item count => integer

Count how many times this event has been logged.  Incremented by each call to B<log>.

=item count_fields => [ array of fields to make up the count ]

Set or get the extended fields to be added to the B<count>.  For example,
you can make the B<count> field look like "8/14" to indicate that this
particular item represents 8 events out of a total of 14.

During sprint, each child's B<count> is unshifted into the first position
of the array.  Next, all the columns of the B<children>'s B<count_fields>
are measured, then padded (on the left) to the same length.  The padded
fields are concatenated to make the 'count' field of each child's line.

=item no_indent => true or false

Suppress the indentation.  This flag is set for a child if it is an only
child (in B<sprint>).

=item no_count => true or false

Suppress the B<count> field.  This flag is set for a child if it is an only
child and its B<count> is the same as the parent's B<count>.

=item children

A hash of child B<Logwtch::RecordTree> items keyed by their B<name>s.

=item limit => integer

Limit the number of children printed.  When the limit is reached,
the list is truncated with a report of how many more are left.

This is a 'soft' limit: if the count is over the limit by three or less, the
list is not truncated.  This prevents the rather ridiculous 'and 1 more'
message.

=item indent => '  '

The string used to indent the children of this level of the tree.  During
<Bsprint> for an item, this string is calculated based on the length of the
longest B<count> field (or at least 3), then set for each child.

=item post_callback =>  sub {my ($self, $path_ref) = @_; ... }

The B<sprint> method prepares an array of lines to print.  When the array
is fully constructed, this callback is called thusly:

    $self->post_callback->($self, \@path);

where B<path> is the array of B<names> leading to this item.  The callback
may adjust @{B<$self-E<gt>lines>}.

=item columnize => true or false

If this flag is set, B<Logwatch::RecordTree> will convert the child
B<lines> into multi-column output.  See the B<sprint_columns> method below.

=item neat_names => true or false

If true, B<children>'s B<names> will be printed with padding so that they
make a neat column.  If this value is negative, the padding will be on the
right (B<name>s are left-justified).

=item neat_format => format string

When B<neat_names> is set, B<sprint> calculates the format string and stores
it here in each of the B<children>.  The default is:

    "%s"

which means no special formatting.

=item extra => whatever...

Set or get a user defined data field for this item.  The value can be
any scalar or object.

=back

In the following methods, either B<$tree> or B<$item> is used as the
object reference.  B<$item> indicates that the particular item at that
point of the RecordTree is affected.  B<$tree> indicates that the method
affects the entire tree, either through class variables or because the
method is inherently recursive and may descend down through the RecordTree.

=over

=item $tree->defaults

Returns a reference to a hash of default options.  This hash is a class
variable, used for all instances, but each sub-class gets its own
independant hash.

The keys of the hash are the option/method names and the values are the
default values to be used when a B<new> instance is created.  Any options
specified in the 'use' directive are added to the hash.

=item $tree->child_by_name (@path)

Find and return the child by following the B<name>s in B<path>.  Returns undef
if no item exists for the given B<path>.

=item $item->create_child ($name, [ $type, [ $opts ] ] )

Create (and return) a child B<Logwatch::RecordTree> (or a subclass) and add
it to B<children> of B<$item>.

If B<type> is not defined (or is any false value), it is set to this
package ('Logwatch::RecordTree').  B<opts>, if set, is a reference to a
hash of options.  The child is then constructed with:

    $opts->{name} = $name;  # add name to %opts
    $child = $type->new( %{$opts} );

The new child is added to the B<children> hash and returned to the caller.

=item $item->adopt($child)

Copy B<$child> (a B<Logwatch::RecordTree> object) into B<$item>'s
B<children>.  B<$item>'s B<count> is updated (by adding the B<$child>'s
B<count>.

If B<$child>'s B<name> is already in B<$item>'s B<children>, then instead
of simply adding B<$child>, B<$item>'s child B<adopt>s (recursively)
B<$child>s B<children>.

=item $tree->log (@path);

=item $tree->log_no_count (@path);

Log new event or group, adding children as necessary.  This method is the primary
reason for this module.  It is called to create and log events as they are parsed
from log file lines.  B<log_no_count> is the same except that B<count>s are not
incremented.

B<path> is an array representing the event.  The elements of B<path> may be the
B<name>s leading to the event, or they may be a reference to an array.  The
array consists of:

    name, type, [ \%options ]

where type is the module name to be created (i.e: 'Logwatch::RecordTree::IPv4'),
and B<%options> are options to be passed when creating the item.  These are all
passed directly to B<create_child> (above) when B<@path> doesn't yet exist.

See 'USAGE' below to see how this works in practice.

=item $item->sort_children

Returns an array of the b<name>s of the B<children> sorted by
Sort::Key::Natural's natsort.  B<children>s' B<name>s are used as the sort
key unless the child has a B<sort_key> assigned, in which case, that is
used.

Subclassing and overriding this method can be useful (for example, see
B<Logwatch::RecordTree::IPv4>).

=item $item->curr_indent( [ 'indent string' ] )

B<Logwatch::RecordTree> stores a copy of the current indentation string
here when B<sprint> is called.

=item $tree->sprint( [ $callback ] )

Returns the B<Logwatch::RecordTree> as a formatted string ready for printing.

If B<callback> is set, it is called just before the B<sprint> returns (after
B<post_callback>):

    $callback->($self, $path)

where B<self> is the current B<Logwatch::RecordTree> item, and B<path> is a
reference to the array of B<name>s that lead to this item.
B<callback> may make adjustments to B<$self-E<gt>lines>.

This method is used to overload the stringification operator, so:

    print $tree

is the same as:

    print $tree->sprint;

=item $item->width( [ integer ] )

Set or get the page or display width.  Used for calculating column formatting
in the B<sprint_columns> method.  Default is 80.

=item $item->col_width ( [ integer ] )

Set or get the columns width for B<sprint_columns>.  If not explicitly set,
B<Logwatch::RecordTree> uses the length of the longest child line in
B<lines>.

=item $item->col_count {

Set or get the number of columns for B<sprint_columns>.  If not explicitly set,
B<Logwatch::RecordTree> calculates it from B<width> (minus indentation) and
B<col_width>.

=item $tree->sprint_columns ([ $width, [ $col_count, [ $col_width ] ] ])

Convert B<lines> into a multi-column display if it fits.  B<width>, B<col_count>,
and B<col_width>, all of which are optional, control the formatting.

=back

=head1 USAGE

Create a B<$tree> with:

    my $tree = Logwatch::RecordTree->new(name => 'Tree');

Calling this:

    $tree->log('One', 'AAA');

creates a new child in B<$tree> named 'One', and a new child in 'One' named
'AAA'.  Each child (and B<$tree> itself) have their counts incremented to
one.

Subsequently calling:

    $tree->log('One', 'BBB');

increments the counts for B<$tree> and 'One'.  Since 'BBB' doesn't exist yet,
it is created and added to the B<children> of 'One', and its count is set to one.

If we now call:

    $tree->log('One', 'AAA');

again, this path exists all the way down to 'AAA', so the only effect is to increment
the counts along that path.

If we were to print $tree now, we would see:

    3 Tree One
      2 AAA
      1 BBB

B<$tree> has only one child ('One') and its B<count> is 3, the same as
B<$tree>'s B<count>, so the child is concatenated to the parent and its
B<count> is suppressed (making for a cleaner, more readable report).

If we now call:

    $tree->log('Two', 'BBB');
    $tree->log('Two', 'CCC');
    $tree->log(['Three', undef, {sort_key => 'Z'}], 'xxx');
    $tree->log('Two', 'AAA');
    $tree->log('Two', 'BBB');

printing would show:

    8 Tree
      3 One
        2 AAA
        1 BBB
      4 Two
        1 AAA
        2 BBB
        1 CCC
      1 Three xxx

Note that 'Three' sorts alphabetically before 'Two', so we override
with "sort_key => 'Z'".

The B<callback> argument to B<sprint> can add last-minute formatting:

 print $tree->sprint(
     sub {
         my ($self, $path) = @_;

         if (@{$path} == 1) {           # entries with exactly one name in the path
             push @{$self->lines}, '';  # add blank line after each top-level entry
         }
     }
 );

gives:

    8 Tree
      3 One
        2 AAA
        1 BBB

      4 Two
        1 AAA
        2 BBB
        1 CCC

      1 Three xxx

=head1 SEE ALSO

=over

=item Logwatch

=item Logwatch::RecordTree::IPv4

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
