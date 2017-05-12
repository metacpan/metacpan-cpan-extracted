# vi:filetype=perl:

package Games::RolePlay::MapGen::MapQueue::Object;

use common::sense;
use overload fallback => 1, bool => sub{1}, '0+' => \&n, '""' => \&q, "-=" => \&me, "+=" => \&pe;

sub new { my $class = shift; my $val = shift; bless {q=>1, u=>1, v=>$val}, $class }

sub desc {
    my $this = shift;

    my $r = $this->{v};
       $r .= " ($this->{q})" if $this->{q} != 1;
       $r .= " #$this->{c}"  unless $this->{u};

    return $r;
}

sub attr {
    my $this = shift;
    my $name = shift;
    my $that = shift;

    return undef unless $name;

    $this->{a}{$name} = $that if defined $that;
    $this->{a}{$name};
}

sub q {
    my $this = shift;

    return lc("$this->{v} #$this->{c}") unless $this->{u};
    return lc($this->{v});
}

sub n {
    my $this = shift;

    return $this->{q};
}

sub pe {
    my $this = shift;
    my $that = shift;

    $this->{q} += $that;
    $this;
}

sub me {
    my $this = shift;
    my $that = shift;
    my $ordr = shift;

    return ($this->{q} = ($that - $this->{q})) if $ordr;
    $this->{q} -= $that;
    $this;
}

my %item_counts;
sub quantity  { my $this = shift; my $q = shift; $this->{q}=$q if defined $q; $this->{q} }
sub    unique { my $this = shift; $this->{u}=1; }
sub nonunique { my $this = shift; $this->{u}=0; my $num = shift;
    if( defined $num ) {
        $this->set_item_number($num);

    } else {
        unless( exists $this->{c} ) {
            $this->{c} = ++ $item_counts{$this->{v}};
        }
    }
}
sub set_item_number {
    my $this = shift;
    my $num  = 0+shift;

    $item_counts{$this->{v}} = $num if not exists $item_counts{$this->{v}} or $num > $item_counts{$this->{v}};
    $this->{c} = $num;
}

"I like GD::Graph.";


__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Games::RolePlay::MapGen::MapQueue::Object - adds special string interpolation support

=head1 SYNOPSIS

    my $ob = new Games::RolePlay::MapGen::MapQueue::Object("test");
       $ob->attr(var => 'var2');
       $ob->quantity(7);
       $ob->nonunique;

=head1 DESCRIPTION

This is a convenience object for programs where you wish to drop strings on a
map that seem to have various attributes and properties that they wouldn't
otherwise have.

The MapQueue can place blessed refs, strings, numbers or whatever; it uses
string interpolation to "tag" the things you drop on the map.  This module
produces tags that make sense for the mapqueue and text descriptions that make
sense to humans.

The tag is the key used in the mapqueue both to locate the object on the map and
to prevent having the same object on the map in more than one place.

It's intended to be used with strings; but will also work with any data type you
pass in to the C<new()> initializer.

=head2 DEFAULT

By default, you're making a unique object, quantity 1, with no attributes.

    my $ob = new Games::RolePlay::MapGen::MapQueue::Object("Test");

    print "yeah, undef\n" if not defined $ob->attr('var');
    print "quantity: ", $ob->quantity, "\n"; # 1
    print "tag: $ob\n";
    print "desc: ", $ob->desc, "\n";

The tag will be "test" and the description will be "Test".  In other words,
I<the MapQueue::Object creates case-insensitive tags> during string
interpolation.

=head2 UNIQUE/NONUNIQUE

The MapQueue will raise errors if you try to put two Joe the fighter objects on
the map.  That makes sense.  Joe is unique.  But for a pile of arrows, it makes
less sense.

    my $joe = new Games::RolePlay::MapGen::MapQueue::Object("Joe");
       # joe is unique, if we try to put him more than one place,
       # the mapqueue will raise errors

    my $arrow = new Games::RolePlay::MapGen::MapQueue::Object("arrow");
       $arrow->nonunique;

For nonunique items, the item id that trails the name in the tag (and
description) is a monotonically increasing integer.  You can set the id for an
object (which will increment the id counter if it's higher than the current
counter) by using this method:

    $arrow->set_item_number(30);

This arrow will now be "arrow #30" and the next non-unique object named "arrow"
will be #31.

Optionally, you can pass a number to C<nonunique()>.  This will call
C<set_item_number()> for you and it will do it before C<nonunique()> increments
the item id counter.

=head2 QUANTITY

Suppose you have a pile of 30 arrows.  It makes little sense to drop 30 arrow
objects on the tile.  This will affect the description of the object, but not
the tag.

    $arrow->quantity(30);

    print "$ob: ", $ob->desc, "\n";

Assuming this is the first pile of arrows, the tag will be "arrow #1" and the desc
will be "arrow (30) #1";

When the C<$arrow> is evaluated in numeric context, it will return the quantity.

    print "qty: ", $ob->quantity, " = ", ($arrow+0), "\n";

When the C<$arrow> is mutated with C<+=> or C<-=>, it will update the quantity.

    $arrow += 5; # works
    print "35: ", $arrow->quantity, "\n";

WARNING: ... other mutators will not work correctly.  They will flatten your
object reference to a number.

=head2 ATTR

Sometimes it's convenient to keep track of slots or field names in the object itself.
For example, suppose you have eight fields in a database, item1, item2, ...
You can use this to set the field name the item is currently slotted in.

    $ob->attr(field_name => "field1");
    $ob->attr(something  => "hrm, test");
    print "field_name: ", $ob->attr('field_name'), "\n";
    print "something:  ", $ob->attr('something'), "\n";

There are problem other uses for C<attr()>.  Then main thing to realize is that
it is otherwise unused metadata.

=head1 SEE ALSO

Games::RolePlay::MapGen::MapQueue

=cut
