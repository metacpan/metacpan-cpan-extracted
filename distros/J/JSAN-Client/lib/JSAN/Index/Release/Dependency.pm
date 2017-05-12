package JSAN::Index::Release::Dependency;

use strict;
use Params::Util '_INSTANCE';
use Algorithm::Dependency::Ordered;

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.28';
	@ISA     = 'Algorithm::Dependency::Ordered';
}

sub new {
    my $class  = ref $_[0] ? ref shift : shift;
    my %params = @_;

    # Apply defaults
    $params{source} ||= JSAN::Index::Release::Source->new( %params );

    # Hand off to superclass constructor
    my $self = $class->SUPER::new( %params )
        or Carp::croak("Failed to create JSAN::Index::Release::Dependency object");

    # Save the type for later
    $self->{build} = !! $params{build};

    $self;
}

sub build { $_[0]->{build} }

sub schedule {
    my $self     = shift;
    my @schedule = @_;

    # Convert things in the schedule from index objects to
    # release source strings as needed
    my @cleaned = ();
    foreach my $item ( @schedule ) {
        if ( defined $item and ! ref $item and $item =~ /^(?:\w+)(?:\.\w+)*$/ ) {
            $item = JSAN::Index::Library->retrieve( name => $item );
        }
        if ( _INSTANCE($item, 'JSAN::Index::Library') ) {
            $item = $item->release;
        }
        if ( _INSTANCE($item, 'JSAN::Index::Release') ) {
            $item = $item->source;
        }
        push @cleaned, $item;
    }

    $self->SUPER::schedule(@cleaned);
}

1;