use v5.12;
use warnings;

# logic of value hash keys for all color spacs

package Graphics::Toolkit::Color::Space::Shape;
use Graphics::Toolkit::Color::Space::Basis;
use Graphics::Toolkit::Color::Space::Util ':all';
use Carp;

sub new {
    my $pkg = shift;
    my ($basis, $range, $type) = @_;
    return unless ref $basis eq 'Graphics::Toolkit::Color::Space::Basis';

    if    (not defined $range or $range eq 'normal'){       # check range settings
        $range = [([0,1]) x $basis->count];    # default range = normal range

    } elsif (not ref $range and $range > 0) {  # single int range def
        $range = int $range;
        $range = [([0, $range]) x $basis->count];

    } elsif (ref $range eq 'ARRAY' and @$range == $basis->count ) { # full range def
        for my $i ($basis->iterator) {
            my $drange = $range->[$i]; # range def of this dimension

            if (not ref $drange and $drange > 0){
                $drange = int $drange;
                $range->[$i] = [0, $drange];
            } elsif (ref $drange eq 'ARRAY' and @$drange == 2
                     and defined $drange->[0] and defined $drange->[1] and $drange->[0] < $drange->[1]) { # full valid def
            } else { return }
        }
    } else { return }


    if (not defined $type){ $type = [ (1) x $basis->count ] } # default is all linear space
    elsif (ref $type eq 'ARRAY' and @$type == $basis->count ) {
        for my $i ($basis->iterator) {
            my $dtype = $type->[$i]; # type def of this dimension
            return unless defined $dtype;
            if    ($dtype eq 'angle' or $dtype eq 'circular' or $dtype eq '0') { $type->[$i] = 0 }
            elsif ($dtype eq 'linear'                        or $dtype eq '1') { $type->[$i] = 1 }
            else { return }
        }
    } else { return }

    bless { basis => $basis, range => $range, type => $type }
}

sub basis            { $_[0]{'basis'}}
sub dimension_is_int {
    my ($self, $dnr, $range) = @_;
    $range //= $self->{'range'};
    return undef unless ref $range eq 'ARRAY' and exists $range->[$dnr];
    my $r = $range->[$dnr];
    return 0 if $r->[0] == 0 and $r->[1] == 1; #normal
    return 0 if int($r->[0]) != $r->[0];
    return 0 if int($r->[1]) != $r->[1];
    1;
}
sub _range {
    my ($self, $external_range) = @_;
    return $self->{'range'} unless defined $external_range;

    # check if range def is valid and eval (exapand) it
    $external_range = Graphics::Toolkit::Color::Space::Shape->new( $self->{'basis'}, $external_range, $self->{'type'});
    return (ref $external_range) ? $external_range->{'range'} : undef ;
}

########################################################################

sub delta { # values have to be normalized
    my ($self, $values1, $values2) = @_;
    return unless $self->basis->is_array( $values1 ) and $self->basis->is_array( $values2 );
    my @delta = map {$values2->[$_] - $values1->[$_] } $self->basis->iterator;
    map { $self->{'type'}[$_] ? $delta[$_]     :
            $delta[$_] < -0.5 ? ($delta[$_]+1) :
            $delta[$_] >  0.5 ? ($delta[$_]-1) : $delta[$_] } $self->basis->iterator;
}

sub check {
    my ($self, $values, $range) = @_;
    return carp 'color value vector in '.$self->basis->name.' needs '.$self->basis->count.' values'
        unless $self->basis->is_array( $values );
    $range = $self->_range( $range );
    return carp "bad range definition" unless ref $range;
    my @names = $self->basis->keys;
    for my $i ($self->basis->iterator){
        return carp $names[$i]." value is below minimum of ".$range->[$i][0] if $values->[$i] < $range->[$i][0];
        return carp $names[$i]." value is above maximum of ".$range->[$i][1] if $values->[$i] > $range->[$i][1];
        return carp $names[$i]." value has to be an integer" if $self->dimension_is_int($i, $range)
                                                            and int $values->[$i] != $values->[$i];
    }
    return;
}

sub clamp {
    my ($self, $values, $range) = @_;
    $range = $self->_range( $range );
    return undef, carp "bad range definition, need upper limit, 2 element ARRAY or ARRAY of 2 element ARRAYs" unless ref $range;
    $values = [] unless ref $values eq 'ARRAY';
    push @$values, 0 while @$values < $self->basis->count;
    pop  @$values    while @$values > $self->basis->count;
    for my $i ($self->basis->iterator){
        my $delta = $range->[$i][1] - $range->[$i][0];
        if ($self->{'type'}[$i]){
            $values->[$i] = $range->[$i][0] if $values->[$i] < $range->[$i][0];
            $values->[$i] = $range->[$i][1] if $values->[$i] > $range->[$i][1];
        } else {
            $values->[$i] += $delta while $values->[$i] < $range->[$i][0];
            $values->[$i] -= $delta while $values->[$i] > $range->[$i][1];
            $values->[$i] = $range->[$i][0] if $values->[$i] == $range->[$i][1];
        }
        $values->[$i] = round($values->[$i]) if $self->dimension_is_int($i, $range);
    }
    return @$values;
}

########################################################################

sub normalize {
    my ($self, $values, $range) = @_;
    return unless $self->basis->is_array( $values );
    $range = $self->_range( $range );
    return carp "bad range definition" unless ref $range;
    map { ($values->[$_] - $range->[$_][0]) / ($range->[$_][1]-$range->[$_][0]) } $self->basis->iterator;
}

sub denormalize {
    my ($self, $values, $range) = @_;
    return unless $self->basis->is_array( $values );
    $range = $self->_range( $range );
    return carp "bad range definition" unless ref $range;
    my @val = map { $values->[$_] * ($range->[$_][1]-$range->[$_][0]) + $range->[$_][0] } $self->basis->iterator;
    @val    = map { $self->dimension_is_int($_, $range) ? round ($val[$_]) : $val[$_] } $self->basis->iterator;
    return @val;
}

sub denormalize_range {
    my ($self, $values, $range) = @_;
    return unless $self->basis->is_array( $values );
    $range = $self->_range( $range );
    return carp "bad range definition" unless ref $range;
    map { $values->[$_] * ($range->[$_][1]-$range->[$_][0]) } $self->basis->iterator;
}

1;
