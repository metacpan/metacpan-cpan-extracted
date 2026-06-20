
# geometry of space: value range checks, normalisation and computing distance

package Graphics::Toolkit::Color::Space::Shape;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space::Basis;
use Graphics::Toolkit::Color::Space::Util qw/round_decimals is_nr/;

#### constructor #######################################################
sub new {
    my $pkg = shift;
    my ($basis, $type, $range, $precision, $constraint) = @_;
    return unless ref $basis eq 'Graphics::Toolkit::Color::Space::Basis';

    # expand axis type definition
    if (not defined $type){ $type = [ (1) x $basis->axis_count ] } # set all axis as linear per default
    elsif (ref $type eq 'ARRAY' and @$type == $basis->axis_count ) {
        for my $i ($basis->axis_iterator) {
            my $atype = $type->[$i];                              # type def of this axis
            return unless defined $atype;
            if    ($atype eq 'angular' or $atype eq 'circular' or $atype eq '0') { $type->[$i] = 0 }
            elsif ($atype eq 'linear'                          or $atype eq '1') { $type->[$i] = 1 }
            elsif ($atype eq 'no'                              or $atype eq '2') { $type->[$i] = 2 }
            else  { return 'invalid axis type at element '.$i.'. It has to be "angular", "linear" or "no".' }
        }
    } else        { return 'invalid axis type definition in color space '.$basis->space_name }

    $range = expand_range_definition(undef, $basis, $range );
    return $range unless ref $range;
    $precision = expand_precision_definition( $basis, $precision );
    return $precision unless ref $precision;

     # check constraint def
    if (defined $constraint){
        return 'color space constraint definition has to be a none empty HASH ref' if ref $constraint ne 'HASH' or not %$constraint;
        for my $constraint_name (keys %$constraint){
			my $properties = $constraint->{$constraint_name};
			return 'a color space constraint has to be a HASH ref with three keys' unless ref $properties eq 'HASH' and keys(%$properties) == 3;
            $properties = {%$properties};
            my $error_msg = 'constraint "$constraint_name" in '.$basis->space_name.' color space';
            for (qw/checker error remedy/){
				return $error_msg." needs the string-propertiy '$_'" 
					unless exists $properties->{$_} and $properties->{$_} and not ref $properties->{$_};
			}
 			$properties->{'checker_code'} = $properties->{'checker'};
			$properties->{'checker'} = eval 'sub {'.$properties->{'checker_code'}.'}';
			return 'checker code of '.$error_msg.":'$properties->{checker_code}' does not eval - $@" if $@;
			$properties->{'remedy_code'} = $properties->{'remedy'};
			$properties->{'remedy'} = eval 'sub {'.$properties->{'remedy_code'}.'}';
			return 'remedy code of '.$error_msg.":'$properties->{remedy_code}' does not eval - $@" if $@;
			$constraint->{ $constraint_name } = $properties;
       }
    } else { $constraint = '' }

    bless { basis => $basis, type => $type, range => $range, precision => $precision, constraint => $constraint }
}

#### object attribute checker ##########################################
sub expand_range_definition { # check if range def is valid and eval (expand) it
    my ($self, $basis, $range) = @_;
    $basis = $basis->{'basis'} if ref $basis eq __PACKAGE__;
    my $error_msg = 'Bad value range definition!';
    $range =   1 if not defined $range or $range eq 'normal';
    $range = 100 if                       $range eq 'percent';
    return $error_msg." It has to be 'normal', 'percent', a number or ARRAY of numbers (by axis position) or HASH (by axis name).'.
                      ' Instead of a number you can also insert ARRAY with two number!"
        unless (not ref $range and is_nr( $range )) or ref $range eq 'ARRAY' or ref $range eq 'HASH';
    if (ref $range eq 'HASH') {
		my $range_array = [];
		for my $axis_name (keys %$range){
			next unless $basis->is_axis_name( $axis_name );
			$range_array->[ $basis->pos_from_axis_name($axis_name) ] = $range->{$axis_name};
		}
		for my $axis_index ($basis->axis_iterator){
			next if exists $range_array->[$axis_index] and defined $range_array->[$axis_index];
			next unless ref $self and ref $self->{'range'};
			$range_array->[$axis_index] = $self->{'range'}[$axis_index];
		}		
		$range = $range_array;
	}
    $range = [$range] unless ref $range;
    $range = [(@$range) x $basis->axis_count] if @$range == 1;
    return "Range definition needs inside an ARRAY or HASH a number or pair of them in an ARRAY for each axis!"
		if @$range != $basis->axis_count;
    for my $axis_index ($basis->axis_iterator) {
        my $axis_range = $range->[$axis_index];
        if (not ref $axis_range){
            if    ($axis_range eq 'normal')  {$range->[$axis_index] = [0, 1]}
            elsif ($axis_range eq 'percent') {$range->[$axis_index] = [0, 100]}
            else                             {$range->[$axis_index] = [0, $axis_range+0]}
        } elsif (ref $axis_range eq 'ARRAY') {
            return $error_msg.' Array at axis number '.$axis_index.' has to have two elements' unless @$axis_range == 2;
            return $error_msg.' None numeric value at lower bound for axis number '.$axis_index unless is_nr( $axis_range->[0] );
            return $error_msg.' None numeric value at upper bound for axis number '.$axis_index unless is_nr( $axis_range->[1] );
            return $error_msg.' Lower bound (first value) is >= than upper bound at axis number '.$axis_index if $axis_range->[0] >= $axis_range->[1];
        } else { return "Range definitin for axis $axis_index was not an two element ARRAY!" }
    }
    return $range;
}
sub try_check_range_definition { # check if range def is valid and eval (expand) it
    my ($self, $range) = @_;
    return $self->{'range'} unless defined $range;
    return $self->expand_range_definition( $self->{'basis'}, $range );
}

sub expand_precision_definition { # check if precision def is valid and eval (exapand) it
    my ($basis, $precision) = @_;
    $basis = $basis->{'basis'} if ref $basis eq __PACKAGE__;
    $precision = -1 unless defined $precision;
    $precision = [($precision) x $basis->axis_count] unless ref $precision;
    return 'need an ARRAY as definition of axis value precision' unless ref $precision eq 'ARRAY';
    return 'definition of axis value precision has to have same lengths as basis' unless @$precision == $basis->axis_count;
    return $precision;
}
sub try_check_precision_definition { # check if range def is valid and eval (expand) it
    my ($self, $precision) = @_;
    return $self->{'precision'} unless defined $precision;
    return expand_precision_definition( $self->{'basis'}, $precision );
}

#### getter of space object ############################################
sub basis           { $_[0]{'basis'}}
# per axis
sub is_axis_numeric {
    my ($self, $axis_nr) = @_;
    return 0 if not defined $axis_nr or not exists $self->{'type'}[$axis_nr];
    $self->{'type'}[$axis_nr] < 2 ? 1 : 0;

}
sub is_axis_euclidean {
    my ($self, $axis_nr) = @_;
    return 0 if not defined $axis_nr or not exists $self->{'type'}[$axis_nr];
    $self->{'type'}[$axis_nr] == 1 ? 1 : 0;

}
sub is_axis_angular {
    my ($self, $axis_nr) = @_;
    return 0 if not defined $axis_nr or not exists $self->{'type'}[$axis_nr];
    $self->{'type'}[$axis_nr] == 0 ? 1 : 0;
}
sub axis_value_max { # --> +value
    my ($self, $axis_nr, $range) = @_;
    $range = $self->try_check_range_definition( $range );
    return undef unless ref $range;
    return undef unless $self->is_axis_numeric($axis_nr);
    return $range->[$axis_nr][1];
}
sub axis_value_min { # --> +value
    my ($self, $axis_nr, $range) = @_;
    $range = $self->try_check_range_definition( $range );
    return undef unless ref $range;
    return undef unless $self->is_axis_numeric($axis_nr);
    return $range->[$axis_nr][0];
}
sub axis_value_precision { # --> +precision?
    my ($self, $axis_nr, $precision) = @_;
    return undef if not defined $axis_nr or not exists $self->{'type'}[$axis_nr];
    return undef unless $self->is_axis_numeric($axis_nr);
    $precision //= $self->{'precision'};
    return undef unless ref $precision eq 'ARRAY' and exists $precision->[$axis_nr];
    $precision->[$axis_nr];
}

# all axis
sub is_euclidean {     # all axis linear ?
    my ($self) = @_;
    map { return 0 if $self->{'type'}[$_] != 1 } $self->basis->axis_iterator;
    return 1;
}
sub is_cylindrical {  # one axis angular, rest linear ?
    my ($self) = @_;
    my $angular_axis = 0;
    map { $angular_axis++ if $self->{'type'}[$_] == 0;
          return 0 if $self->{'type'}[$_] > 1;        } $self->basis->axis_iterator;
    return ($angular_axis == 1) ? 1 : 0;
}
sub is_int_valued { # all ranges int valued ?
    my ($self) = @_;
    map { return 0 if $self->{'precision'}[$_] != 0 } $self->basis->axis_iterator;
    return 1;
}
sub has_constraints {  my ($self) = @_;  return (ref $self->{'constraint'}) ? 1 : 0 } # --> ?


#### value checker #####################################################
sub check_value_shape {  # @tuple -- $range, $precision --> $@vals | ~!
    my ($self, $tuple, $range, $precision) = @_;
    return 'color value tuple in '.$self->basis->space_name.' space needs to be ARRAY ref with '.$self->basis->axis_count.' elements'
        unless $self->basis->is_value_tuple( $tuple );
    $range = $self->try_check_range_definition( $range );
    return $range unless ref $range;
    $precision = $self->try_check_precision_definition( $precision );
    return $precision unless ref $precision;
    my @names = $self->basis->long_axis_names;
    for my $axis_index ($self->basis->axis_iterator){
        next unless $self->is_axis_numeric( $axis_index );
        return $names[$axis_index]." value is below minimum of ".$range->[$axis_index][0]
            if $tuple->[$axis_index] < $range->[$axis_index][0];
        return $names[$axis_index]." value is above maximum of ".$range->[$axis_index][1]
            if $tuple->[$axis_index] > $range->[$axis_index][1];
        return $names[$axis_index]." value is not properly rounded "
            if $precision->[$axis_index] >= 0
           and round_decimals($tuple->[$axis_index], $precision->[$axis_index]) != $tuple->[$axis_index];
    }
    if ($self->has_constraints){
		my $tuple = $self->normalize($tuple, $range);
		for my $constraint (values %{$self->{'constraint'}}){
			return $constraint->{'error'} unless $constraint->{'checker'}->( $tuple );
		}
	}
    return $tuple;
}

sub is_equal {  # @tuple_a, @tuple_b -- $precision --> ? 
    my ($self, $tuple_a, $tuple_b, $precision) = @_;
    return 0 unless $self->basis->is_value_tuple( $tuple_a ) and $self->basis->is_value_tuple( $tuple_b );
    $precision = $self->try_check_precision_definition( $precision );
    for my $axis_nr ($self->basis->axis_iterator) {
        return 0 if round_decimals($tuple_a->[$axis_nr], $precision->[$axis_nr])
                 != round_decimals($tuple_b->[$axis_nr], $precision->[$axis_nr]);
    }
    return 1;
}

sub is_in_constraints {  # @tuple --> ?  # normalized values only, so it works on any ranges
    my ($self, $tuple) = @_;
    return 0 unless $self->basis->is_number_tuple( $tuple );
    return 1 unless $self->has_constraints;
    for my $constraint (values %{$self->{'constraint'}}){
        return 0 unless $constraint->{'checker'}->( $tuple );
    }
    return 1;
}

sub is_in_bounds {  # @tuple --> ?
    my ($self, $tuple, $range) = @_;
    return 0 unless $self->is_in_linear_bounds( $tuple, $range );
    $range = $self->try_check_range_definition( $range );
    for my $axis_nr ($self->basis->axis_iterator) {
		next if $self->{'type'}[$axis_nr]; # skip none linear axis
        return 0 if $tuple->[$axis_nr] < $range->[$axis_nr][0]
                 or $tuple->[$axis_nr] > $range->[$axis_nr][1];
    }
    return 1;
}

sub is_in_linear_bounds {  # @tuple --> ?
    my ($self, $tuple, $range) = @_;
    return 0 unless $self->basis->is_number_tuple( $tuple );
    $range = $self->try_check_range_definition( $range );
    for my $axis_nr ($self->basis->axis_iterator) {
		next if $self->{'type'}[$axis_nr] != 1; # skip none linear axis
        return 0 if $tuple->[$axis_nr] < $range->[$axis_nr][0]
                 or $tuple->[$axis_nr] > $range->[$axis_nr][1];
    }
    if ($self->has_constraints){
		return $self->is_in_constraints( $self->normalize( $tuple, $range) );
	}
    return 1;
}

#### value ops #########################################################
sub clamp { # change values if outside of range to nearest boundary, angles get rotated into range
    my ($self, $tuple, $range) = @_;
    $range = $self->try_check_range_definition( $range );
    return $range unless ref $range;
    $tuple = [] unless ref $tuple eq 'ARRAY';
    pop  @$tuple     while @$tuple > $self->basis->axis_count;
    $tuple = [@$tuple];

    for my $axis_nr ($self->basis->axis_iterator){
        next unless $self->is_axis_numeric( $axis_nr );
        if (not defined $tuple->[$axis_nr]){
            my $default_value = 0;
            $default_value = $range->[$axis_nr][0] if $default_value < $range->[$axis_nr][0]
                                                   or $default_value > $range->[$axis_nr][1];
            $tuple->[$axis_nr] = $default_value;
        } else {
            next unless $self->is_axis_euclidean( $axis_nr );
			$tuple->[$axis_nr] = $range->[$axis_nr][0] if $tuple->[$axis_nr] < $range->[$axis_nr][0];
			$tuple->[$axis_nr] = $range->[$axis_nr][1] if $tuple->[$axis_nr] > $range->[$axis_nr][1];
		}
    }
    $tuple = $self->rotate($tuple, $range);
    if ($self->has_constraints){
		$tuple = $self->normalize( $tuple, $range);
		for my $constraint (values %{$self->{'constraint'}}){
			$tuple = $constraint->{'remedy'}->($tuple) unless $constraint->{'checker'}->( $tuple );
		}
		$tuple = $self->denormalize( $tuple, $range);
	}    
    return $tuple;
}
sub rotate { # rotate values of circular dimensions into range
    my ($self, $tuple, $range) = @_;
    return unless $self->basis->is_number_tuple( $tuple );
    $range = $self->try_check_range_definition( $range );
    return $range unless ref $range;
    $tuple = [@$tuple];
    for my $axis_nr ($self->basis->axis_iterator){
        next unless $self->is_axis_angular( $axis_nr );
        if (not defined $tuple->[$axis_nr]){
            my $default_value = 0;
            $default_value = $range->[$axis_nr][0] if $default_value < $range->[$axis_nr][0]
                                                   or $default_value > $range->[$axis_nr][1];
            $tuple->[$axis_nr] = $default_value;
        } else {
			my $delta = $range->[$axis_nr][1] - $range->[$axis_nr][0];
			$tuple->[$axis_nr] += $delta while $tuple->[$axis_nr] < $range->[$axis_nr][0];
			$tuple->[$axis_nr] -= $delta while $tuple->[$axis_nr] > $range->[$axis_nr][1];
			$tuple->[$axis_nr] = $range->[$axis_nr][0] if $tuple->[$axis_nr] == $range->[$axis_nr][1];
		}
    }
    return $tuple;
}

sub round { # $tuple -- $precision --> $tuple
    my ($self, $tuple, $precision) = @_;
    return unless $self->basis->is_value_tuple( $tuple );
    $precision = $self->try_check_precision_definition( $precision );
    return "round got bad precision definition" unless ref $precision;
    [ map { ($self->is_axis_numeric( $_ ) and $precision->[$_] >= 0) ? round_decimals ($tuple->[$_], $precision->[$_]) : $tuple->[$_] } $self->basis->axis_iterator ];
}

# normalisation
sub normalize {
    my ($self, $tuple, $range) = @_;
    return unless $self->basis->is_value_tuple( $tuple );
    $range = $self->try_check_range_definition( $range );
    return $range unless ref $range;
    [ map { ($self->is_axis_numeric( $_ )) ? (($tuple->[$_] - $range->[$_][0]) / ($range->[$_][1]-$range->[$_][0]))
                                           : $tuple->[$_]    } $self->basis->axis_iterator ];
}

sub denormalize {
    my ($self, $tuple, $range) = @_;
    return unless $self->basis->is_value_tuple( $tuple );
    $range = $self->try_check_range_definition( $range );
    return $range unless ref $range;
    return [ map { ($self->is_axis_numeric( $_ )) ? ($tuple->[$_] * ($range->[$_][1]-$range->[$_][0]) + $range->[$_][0])
                                                   : $tuple->[$_]   } $self->basis->axis_iterator ];
}

sub denormalize_delta {
    my ($self, $delta_values, $range) = @_;
    return unless $self->basis->is_value_tuple( $delta_values );
    $range = $self->try_check_range_definition( $range );
    return $range unless ref $range;
    [ map { ($self->is_axis_numeric( $_ ))
             ? ($delta_values->[$_] * ($range->[$_][1]-$range->[$_][0]))
             :  $delta_values->[$_]                                       } $self->basis->axis_iterator ];
}

sub delta { # @normal_tuple_a, @normal_tuple_b   --> @delta_tuple
    my ($self, $tuple1, $tuple2) = @_;
    return unless $self->basis->is_value_tuple( $tuple1 ) and $self->basis->is_value_tuple( $tuple2 );
    # ignore none numeric dimensions
    my @delta = map { $self->is_axis_numeric($_) ? ($tuple2->[$_] - $tuple1->[$_]) : 0 } $self->basis->axis_iterator;
    [ map { $self->{'type'}[$_] ? $delta[$_]   :                                      # adapt to circular dimensions
            $delta[$_] < -0.5 ? ($delta[$_]+1) :
            $delta[$_] >  0.5 ? ($delta[$_]-1) : $delta[$_] } $self->basis->axis_iterator ];
}

1;
