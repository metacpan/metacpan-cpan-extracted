package Diabetes::Glucose;
use Moose;
use DateTime;
use Data::Dumper;

our $VERSION = '0.01';

has 'stamp' => ( 
    is => 'rw',
    isa => 'DateTime',
    lazy_build => 1,
);

sub _build_stamp { DateTime->now }

has 'comment' => ( 
    is => 'rw',
    isa => 'Str',
);

has 'source' => ( 
    is => 'rw',
    isa => 'Str'
);

has ['mmol', 'mgdl'] => ( is => 'rw', isa => 'Num', required => 1 );

sub BUILDARGS {
    my( $self, %args ) = @_;

    if( exists $args{'mgdl'} ) { 
        $args{'mmol'} = $args{'mgdl'} / 18.5;
    } elsif( exists $args{'mmol'} ) { 
        $args{'mgdl'} = $args{'mmol'} * 18.5;
    }

   return \%args;
}


__PACKAGE__->meta->make_immutable;


=head1 NAME

Diabetes::Glucose - A simple utility package for storing and manipulating glucose values

=head1 VERSION

This document describes version 1.0

=head1 SYNOPSIS

    my $glucose = Diabetes::Glucose->new( 
        mgdl        => '103',                   # could also use mmol => 5.9
        stamp       => DateTime->now,
        comment     => 'Used a OneTouch meter',
        source      => 'Manual Entry'
    );

    say $glucose->mgdl;         # 103
    say $glucose->mmol;         # 5.674931129476585...

    say $glucose->source;       # Manual Entry

=head1 METHODS

=over 3

=item new

Creates a new object. Nothing much to see here.   

=item comment

A commment for this particular reading, if anything of note happened.  Some systems may make use of it, for whatever 
purposes they want.

=item source

The source of the reading.  This is ued by L<Parse::Dexcom::Tab> and L<Parse::Medtronic::Tab> to note the souce of the 
reading. L<Diabetes::Graph::Glucose> also makes use of this to note the source of data.

=item stamp

A timestamp.  Should be a DateTime object.  Will try hard to convert time-like strings into DateTime objects, but no
guarantees.  Give it what it wants and no one gets hurt.  Defaults to C<<DateTime->now>>.

=item mgdl, mmol

Display the currently-stored value in the unit system specified.  Using the same data from the L<SYNOPSIS>:

    say $glucose->mgdl          # 103
    say $glucose->mmol          # 5.67... etc, etc.

The conversion is done at object construction, don't try to change it later, it won't work like you think.

=back

=head1 BUGS

None known, so probably lots.  

=head1 AUTHOR

Dave Houston L<dhouston@cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2015 by Dave Houston.  This is free software; you can redistribute and/or
modify it under teh same terms as the Perl 5 programming language.

=cut
