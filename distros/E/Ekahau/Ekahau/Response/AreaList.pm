package Ekahau::Response::AreaList;
use base 'Ekahau::Response'; our $VERSION=Ekahau::Response::VERSION;

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

use Ekahau::Response::Area;
use constant AREA_CLASS => 'Ekahau::Response::Area';

use strict;
use warnings;

=head1 NAME

Ekahau::Response::AreaList - Represents a list of areas contained in an Ekahau response

=head1 SYNOPSIS

Contains information about a list of areas, possibly from an
L<Ekahau::Response::AreaEstimate|Ekahau::Response::AreaEstimate> object.

=head1 DESCRIPTION

=head2 Constructor

Generally you will not want to construct these objects yourself; they
are created by L<Ekahau::Response|Ekahau::Response>, and use its constructor.

=head2 Methods

=cut

# Internal method
sub init
{
    my $self = shift;

    warn "Created Ekahau::Response::AreaList object\n"
	if ($ENV{VERBOSE});
    $self->{_areas}=[ map { $self->create_area($_) } @{$self->{params}{AREA}} ];
    1;
}

# Internal method
sub create_area
{
    my $self = shift;
    my($area)=@_;
    
    if (!$area) { return undef; }
    
    my $new = { %$self };
    $new->{params} = { %$area };
    bless $new,AREA_CLASS;
    $new->init;
    $new;
}

=head3 get ( $which )

Return L<Ekahau::Response::Area|Ekahau::Response::Area> object number C<$which>.

=cut

sub get
{
    my $self = shift;
    
    my($which)=@_;
    return $self->{_areas}[$which];
}

=head3 get_all ( )

Return all L<Ekahau::Response::Area|Ekahau::Response::Area> objects in this list.

=cut

sub get_all
{
    my $self = shift;
    
    return @{$self->{_areas}};
}

=head3 num_areas

Returns the number of areas in this object

=cut

sub num_areas
{
    my $self = shift;
    
    return scalar(@{$self->{_areas}});
}

=head3 type ( )

Returns the string I<AreaList>, to identify the type of this object.
Note that subclasses of this class will override this method,
returning their own type string.

=cut

sub type
{
    'AreaList';
}

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2005 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.


=head1 SEE ALSO

L<Ekahau::Response|Ekahau::Response>, L<Ekahau::Response::Area|Ekahau::Response::Area>, L<Ekahau::Response::AreaEstimate|Ekahau::Response::AreaEstimate>.

=cut


1;
