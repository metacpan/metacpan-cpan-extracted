# $Id: Descriptor.pm,v 1.1 2007-01-26 12:33:15 mike Exp $

package Keystone::Resolver::Descriptor;

use strict;
use warnings;
use LWP;


=head1 NAME

Keystone::Resolver::Descriptor - a Descriptor in an OpenURL v1.0 ContextObject

=head1 SYNOPSIS

 $des = new Keystone::Resolver::Descriptor("rft");
 $des->superdata(ref => "http://some.host/path/entity.kev");
 $des->metadata(aulast => [ "Wedel" ]);
 $ids = $des->superdata("id");
 @authors = $des->metadata("aulast");

=head1 DESCRIPTION

A Descriptor is a small data structure containing information
describing one of the six OpenURL v1.0 entities (referent, referer,
etc.)  Each Descriptor has a name, and contains both metadata (author,
title, etc.)  and what we will call superdata (identifier, descriptor
format and suchlike), which are held in two different spaces.

Although this module neither knows nor cares what kind of information
is stored in the metadata and superdata hashes, it's worth knowing
that the way Keystone Resolver uses this is by storing references to
arrays of scalars.  In other words, instead of storing
C<author = "taylor">,
we store
C<author = [ "taylor", "wedel" ]>.

Three utility methods are provided for application such as Keystone
Resolver that use C<Descriptor> objects in this way:
C<metadata1()>,
C<superdata1()>
and
C<push_metadata()>

=head1 METHODS

=cut


=head2 new()

 $des = new Keystone::Resolver::Descriptor($name);

Constructs a new Descriptor with the specified name, and with
(initially) no metadata or superdata.

=cut

sub new {
    my $class = shift();
    my($name) = @_;

    return bless {
	name => $name,
	metadata => {},
	superdata => {},
    }, $class;
}


=head2 name()

Returns the name with which the descriptor was created.

=cut

sub name { my $this = shift(); return $this->{name} }


=head2 metadata(), superdata()

 $oldfoo = $des->metadata("foo");
 $des->metadata(foo => $newfoo);
 # ...
 $des->metadata(foo => $oldfoo);

These two methods behave the same way, but operate on different
data-spaces.  Each one returns the value associated with the key whose
name is specified in by the first parameter.  If a second parameter is
also specified, then it becomes the new value associated with that key
(although the old value is still returned).

=cut

sub metadata { my $this = shift(); return $this->_data("metadata", @_); }
sub superdata { my $this = shift(); return $this->_data("superdata", @_); }

sub _data {
    my $this = shift();
    my($table, $name, $value) = @_;

    my $old = $this->{$table}->{$name};
    $this->{$table}->{$name} = $value
	if defined $value;

    return $old;
}


=head2 metadata1(), superdata1()

 $des->metadata(foo => [ "bar" ]);
 $res = $des->metadata("foo");
 die if ref($ref) ne "ARRAY";
 $scalar = $des->metadata1("foo");
 die if ref($ref);

C<metadata1()> returns the first element of the array whose reference
is stored in a descriptor's metadata space under the specified key.
It is a fatal error if the array has zero elements, and a warning is
issued if it has more than one.

C<superdata1()> behaves the same but operates on the descriptor's
superdata space instead of its metadata space.

=cut

sub metadata1 { my $this = shift(); return $this->_data1("metadata", @_); }
sub superdata1 { my $this = shift(); return $this->_data1("superdata", @_); }

sub _data1 {
    my $this = shift();
    my($table, $name, $value) = @_;
    die "Oops!  value '$value' supplied to data1()" if defined $value;

    my $refs = $this->{$table}->{$name};
    return undef if !defined $refs;
    die "data1(): no $table values for " . $this->name()
	if @$refs == 0;
    if (@$refs > 1) {
	### Should use $openURL->warn(), but we don't have a $openURL
	warn("data1(): multiple $table values for " . $this->name() .
	     "($name): " . join(", ", @$refs));
    }

    return $refs->[0];
}


=head2 metadata_keys(), superdata_keys()

 foreach my $name ($des->metadata_keys()) {
     print $name, " -> ", $des->metadata($name), "\n";
 }

C<metadata_keys()> returns a list of all the keys for which the
descriptor has a metadata value.
C<superdata_keys()> returns a list of all the keys for which the
descriptor has a superdata value.

=cut

sub metadata_keys {
    my $this = shift();

    return sort keys %{ $this->{metadata} };
}

sub superdata_keys {
    my $this = shift();

    return sort keys %{ $this->{superdata} };
}


=head2 delete_superdata()

 $des->delete_superdata("ref");
 $oldval = $des->delete_superdata("ref_fmt");

Deletes the named superdata element from the descriptor, returning its
old value if any.

There is at present no corresponding C<delete_metadata()>.

=cut

sub delete_superdata {
    my $this = shift();
    my($name) = @_;

    return delete $this->{superdata}->{$name};
}


=head2 push_metadata()

 $des->push_metadata(foo => $extraFoo1, $extraFoo2, ...);

To be used only when the metadata keys are list-references.  Appends
the specified values to the list associated with the specified name.
The following two code-fragments are equivalent:

 $des->metadata(foo => []);
 $des->push_metadata(foo => 1);
 $des->push_metadata(foo => 2, 3);

and

 $des->metadata(foo => [ 1 2 ]);
 $des->push_metadata(foo => 3);

There is at present no corresponding C<push_superdata()>.

=cut

sub push_metadata {
    my $this = shift();
    my($name, @values) = @_;

    push @{ $this->{metadata}->{$name} }, @values;
}


1;
