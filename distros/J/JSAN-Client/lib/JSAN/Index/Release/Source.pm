package JSAN::Index::Release::Source;

use strict;
use Algorithm::Dependency::Item   ();
use Algorithm::Dependency::Source ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.28';
	@ISA     = 'Algorithm::Dependency::Source';
}

sub new {
    my $class  = ref $_[0] ? ref shift : shift;
    my %params = @_;

    # Create the basic object
    my $self = $class->SUPER::new();

    # Set the methods to use
    $self->{requires_releases} = 1;
    if ( $params{build} ) {
        $self->{build_requires_releases} = 1;
    }

    $self;
}

sub _load_item_list {
    my $self = shift;

    ### FIXME: This is crudely effective, but a little innefficient.
    ###        Later, we should be able to determine which subset of
    ###        these can never be called, and leave them out of the list.

    # Get every single release in the index
    my @releases = JSAN::Index::Release->retrieve_all;

    # Wrap the releases in the Adapter objects
    my @items  = ();
    foreach my $release ( @releases ) {
        my $id      = $release->source;

        # Get the list of dependencies
        my @depends = ();
        if ( $self->{requires_releases} ) {
            push @depends, $release->requires_releases;
        }
        if ( $self->{build_requires_releases} ) {
            push @depends, $release->build_requires_releases;
        }

        # Convert to a distinct source list
        my %seen = ();
        @depends = grep { ! $seen{$_} } map { $_->source } @depends;

        # Add the dependency
        my $item = Algorithm::Dependency::Item->new( $id => @depends )
            or die "Failed to create Algorithm::Dependency::Item";
        push @items, $item;
    }

    \@items;
}

1;