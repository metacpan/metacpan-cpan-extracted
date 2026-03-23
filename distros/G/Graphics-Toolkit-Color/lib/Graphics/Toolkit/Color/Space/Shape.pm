
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

    $range = expand_range_definition( $basis, $range );
    return $range unless ref $range;
    $precision = expand_precision_definition( $basis, $precision );
    return $precision unless ref $precision;

     # check constraint def
    if (defined $constraint){
        return 'color space constraint definition has to be a none empty HASH ref' if ref $constraint ne 'HASH' or not %$constraint;
        for my $constraint_name (keys %$constraint){
			my $properties = $constraint->{$constraint_name};
			return 'a color space constraint has to be a HASH ref with three keys' unless ref $properties eq 'HASH' and %$properties == 3;
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
    my ($basis, $range) = @_;
    $basis = $basis->{'basis'} if ref $basis eq __PACKAGE__;
    my $error_msg = 'Bad value range definition!';
    $range =   1 if not defined $range or $range eq 'normal';
    $range = 100 if                       $range eq 'percent';
    return $error_msg." It has to be 'normal', 'percent', a number or ARRAY of numbers or ARRAY of ARRAY's with two number!"
        unless (not ref $range and is_nr( $range )) or (ref $range eq 'ARRAY') ;
    $range = [$range] unless ref $range;
    $range = [(@$range) x $basis->axis_count] if @$range == 1;
    return "Range definition needs inside an ARRAY either one definition for all axis or one definition".
           " for each axis!"                  if @$range != $basis->axis_count;
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
    return expand_range_definition( $self->{'basis'}, $range );
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
    $self->{'type'}[$axis_nr] == 2 ? 0 : 1;

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

#### value checker #####################################################
sub check_value_shape {  # $vals -- $range, $precision --> $@vals | ~!
    my ($self, $values, $range, $precision) = @_;
    return 'color value tuple in '.$self->basis->space_name.' space needs to be ARRAY ref with '.$self->basis->axis_count.' elements'
        unless $self->basis->is_value_tuple( $values );
    $range = $self->try_check_range_definition( $range );
    return $range unless ref $range;
    $precision = $self->try_check_precision_definition( $precision );
    return $precision unless ref $precision;
    my @names = $self->basis->long_axis_names;
    for my $axis_index ($self->basis->axis_iterator){
        next unless $self->is_axis_numeric( $axis_index );
        return $names[$axis_index]." value is below minimum of ".$range->[$axis_index][0]
            if $values->[$axis_index] < $range->[$axis_index][0];
        return $names[$axis_index]." value is above maximum of ".$range->[$axis_index][1]
            if $values->[$axis_index] > $range->[$axis_index][1];
        return $names[$axis_index]." value is not properly rounded "
            if $precision->[$axis_index] >= 0
           and round_decimals($values->[$axis_index], $precision->[$axis_index]) != $values->[$axis_index];
    }
    if ($self->has_constraints){
		my $values = $self->normalize($values, $range);
		for my $constraint (values %{$self->{'constraint'}}){
			return $constraint->{'error'} unless $constraint->{'checker'}->( $values );
		}
	}
    return $values;
}

sub is_equal {  # @values_a, @values_b -- $precision --> ? 
    my ($self, $values_a, $values_b, $precision) = @_;
    return 0 unless $self->basis->is_value_tuple( $values_a ) and $self->basis->is_value_tuple( $values_b );
    $precision = $self->try_check_precision_definition( $precision );
    for my $axis_nr ($self->basis->axis_iterator) {
        return 0 if round_decimals($values_a->[$axis_nr], $precision->[$axis_nr])
                 != round_decimals($values_b->[$axis_nr], $precision->[$axis_nr]);
    }
    return 1;
}

sub has_constraints {  my ($self) = @_;  return (ref $self->{'constraint'}) ? 1 : 0 } # --> ?

sub is_in_constraints {  # @values --> ?  # normalized values only, so it works on any ranges
    my ($self, $values) = @_;
    return 1 unless $self->has_constraints;
    for my $constraint (values %{$self->{'constraint'}}){
        return 0 unless $constraint->{'checker'}->( $values );
    }
    return 1;
}

sub is_in_bounds {  # :values --> ?
    my ($self, $values, $range) = @_;
    return 0 unless $self->basis->is_number_tuple( $values );
    $range = $self->try_check_range_definition( $range );
    for my $axis_nr ($self->basis->axis_iterator) {
		next if $self->{'type'}[$axis_nr] > 1; # skip none numeric axis
        return 0 if $values->[$axis_nr] < $range->[$axis_nr][0]
                 or $values->[$axis_nr] > $range->[$axis_nr][1];
    }
    if ($self->has_constraints){
		return $self->is_in_constraints( $self->normalize( $values, $range) );
	}
    return 1;
}

sub is_in_linear_bounds {  # :values --> ?
    my ($self, $values, $range) = @_;
    return 0 unless $self->basis->is_number_tuple( $values );
    $range = $self->try_check_range_definition( $range );
    for my $axis_nr ($self->basis->axis_iterator) {
		next if $self->{'type'}[$axis_nr] != 1; # skip none linear axis
        return 0 if $values->[$axis_nr] < $range->[$axis_nr][0]
                 or $values->[$axis_nr] > $range->[$axis_nr][1];
    }
    if ($self->has_constraints){
		return $self->is_in_constraints( $self->normalize( $values, $range) );
	}
    return 1;
}

#### value ops #########################################################
sub clamp { # change values if outside of range to nearest boundary, angles get rotated into range
    my ($self, $values, $range) = @_;
    $range = $self->try_check_range_definition( $range );
    return $range unless ref $range;
    $values = [] unless ref $values eq 'ARRAY';
    pop  @$values     while @$values > $self->basis->axis_count;
    for my $axis_nr ($self->basis->axis_iterator){
        next unless $self->is_axis_numeric( $axis_nr ); # touch only numeric values
        if (not defined $values->[$axis_nr]){
            my $default_value = 0;
            $default_value = $range->[$axis_nr][0] if $default_value < $range->[$axis_nr][0]
                                                   or $default_value > $range->[$axis_nr][1];
            $values->[$axis_nr] = $default_value;
            next;
        }
        if ($self->{'type'}[$axis_nr]){
            $values->[$axis_nr] = $range->[$axis_nr][0] if $values->[$axis_nr] < $range->[$axis_nr][0];
            $values->[$axis_nr] = $range->[$axis_nr][1] if $values->[$axis_nr] > $range->[$axis_nr][1];
        } else {
            my $delta = $range->[$axis_nr][1] - $range->[$axis_nr][0];
            $values->[$axis_nr] += $delta while $values->[$axis_nr] < $range->[$axis_nr][0];
            $values->[$axis_nr] -= $delta while $values->[$axis_nr] > $range->[$axis_nr][1];
            $values->[$axis_nr] = $range->[$axis_nr][0] if $values->[$axis_nr] == $range->[$axis_nr][1];
        }
    }
    if ($self->has_constraints){
		$values = $self->normalize( $values, $range);
		for my $constraint (values %{$self->{'constraint'}}){
			$values = $constraint->{'remedy'}->($values) unless $constraint->{'checker'}->( $values );
		}
		$values = $self->denormalize( $values, $range);
	}    
    return $values;
}

sub round {
    my ($self, $values, $precision) = @_;
    return unless $self->basis->is_value_tuple( $values );
    $precision = $self->try_check_precision_definition( $precision );
    return "round got bad precision definition" unless ref $precision;
    [ map { ($self->is_axis_numeric( $_ ) and $precision->[$_] >= 0) ? round_decimals ($values->[$_], $precision->[$_]) : $values->[$_] } $self->basis->axis_iterator ];
}

# normalisation
sub normalize {
    my ($self, $values, $range) = @_;
    return unless $self->basis->is_value_tuple( $values );
    $range = $self->try_check_range_definition( $range );
    return $range unless ref $range;
    [ map { ($self->is_axis_numeric( $_ )) ? (($values->[$_] - $range->[$_][0]) / ($range->[$_][1]-$range->[$_][0]))
                                           : $values->[$_]    } $self->basis->axis_iterator ];
}

sub denormalize {
    my ($self, $values, $range) = @_;
    return unless $self->basis->is_value_tuple( $values );
    $range = $self->try_check_range_definition( $range );
    return $range unless ref $range;
    return [ map { ($self->is_axis_numeric( $_ )) ? ($values->[$_] * ($range->[$_][1]-$range->[$_][0]) + $range->[$_][0])
                                                   : $values->[$_]   } $self->basis->axis_iterator ];
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

sub delta { # values have to be normalized
    my ($self, $values1, $values2) = @_;
    return unless $self->basis->is_value_tuple( $values1 ) and $self->basis->is_value_tuple( $values2 );
    # ignore none numeric dimensions
    my @delta = map { $self->is_axis_numeric($_) ? ($values2->[$_] - $values1->[$_]) : 0 } $self->basis->axis_iterator;
    [ map { $self->{'type'}[$_] ? $delta[$_]   :                                      # adapt to circular dimensions
            $delta[$_] < -0.5 ? ($delta[$_]+1) :
            $delta[$_] >  0.5 ? ($delta[$_]-1) : $delta[$_] } $self->basis->axis_iterator ];
}

1;
