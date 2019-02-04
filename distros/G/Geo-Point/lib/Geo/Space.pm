# Copyrights 2005-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Geo-Point.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Geo::Space;
use vars '$VERSION';
$VERSION = '0.98';

use base 'Geo::Shape';

use strict;
use warnings;

use Math::Polygon::Calc    qw/polygon_bbox/;
use List::Util             qw/sum first/;


sub new(@)
{   my $thing = shift;
    my @components;
    push @components, shift while ref $_[0];
    my %args  = @_;

    if(ref $thing)    # instance method
    {   $args{proj} ||= $thing->proj;
    }

    my $proj = $args{proj};
    return () unless @components;

    $thing->SUPER::new(components => \@components);
}

sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    $self->{GS_comp} = $args->{components} || [];
    $self;
}


sub components() { @{shift->{GS_comp}} }


sub component(@)
{   my $self = shift;
    wantarray ? $self->{GS_comp}[shift] : @{$self->{GS_comp}}[@_];
}


sub nrComponents() { scalar @{shift->{GS_comp}} }


sub points()     { grep $_->isa('Geo::Points'), shift->components }


sub onlyPoints() { not first {! $_->isa('Geo::Points')} shift->components }


sub lines()      { grep $_->isa('Geo::Line'), shift->components }


sub onlyLines()  { not first {! $_->isa('Geo::Line')} shift->components }


sub onlyRings()  { not first {! $_->isa('Geo::Line') || ! $_->isRing}
                         shift->components }


sub in($)
{   my ($self, $projnew) = @_;
    return $self if ! defined $projnew || $projnew eq $self->proj;

    my @t;

    foreach my $component ($self->components)
    {   ($projnew, my $t) = $component->in($projnew);
        push @t, $t;
    }

    (ref $self)->new(@t, proj => $projnew);
}


sub bbox()
{   my $self = shift;
    my @bboxes = map [$_->bbox], $self->components;
    polygon_bbox(map +([$_->[0], $_->[1]], [$_->[2], $_->[3]]), @bboxes);
}


sub area() { sum map $_->area, shift->components }


sub perimeter() { sum map $_->perimeter, shift->components }


sub toString(;$)
{   my ($self, $proj) = @_;
    my $space;
    if(defined $proj)
    {   $space = $self->in($proj);
    }
    else
    {   $proj  = $self->proj;
        $space = $self;
    }

      "space[$proj]\n  ("
    . join(")\n  (", map {$_->string} $space->components)
    . ")\n";
}
*string = \&toString;

1;
