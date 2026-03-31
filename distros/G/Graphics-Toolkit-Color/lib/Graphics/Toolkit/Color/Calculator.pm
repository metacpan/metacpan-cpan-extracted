
# methods to compute one related color

package Graphics::Toolkit::Color::Calculator;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Values;


sub apply_gamma {
    my ($color_values, $gamma, $color_space) = @_;
    my $gamma_array;
    if (ref $gamma eq 'HASH'){
        ($gamma_array, my $deduced_space_name) = 
			Graphics::Toolkit::Color::Space::Hub::deformat_partial_hash( $gamma, $color_space->name );
		return 'axis names: '.join(', ', keys %$gamma).' do not correlate to the selected color space: '.
			($color_space->name).'!' unless ref $gamma_array;
	} else {
		$gamma_array = [ ($gamma) x $color_space->axis_count];
	}
	my $values = $color_values->normalized( $color_space->name );
    for my $axis_nr ($color_space->basis->axis_iterator){
	    $values->[$axis_nr] = $values->[$axis_nr] ** $gamma_array->[$axis_nr] if exists $gamma_array->[$axis_nr];
    }
    return $color_values->new_from_tuple( $values, $color_space->name, 'normal' );
}

sub set_value { # .values, %newval -- ~space_name --> _
    my ($color_values, $partial_hash, $preselected_space_name) = @_;
    my ($new_values, $deduced_space_name) = 
		Graphics::Toolkit::Color::Space::Hub::deformat_partial_hash( $partial_hash, $preselected_space_name );
    unless (ref $new_values){
        my $help_start = 'axis names: '.join(', ', keys %$partial_hash).' do not correlate to ';
        return (defined $preselected_space_name) ? $help_start.'the selected color space: '.$preselected_space_name.'!'
                                                 : 'any supported color space!';
    }
    my $values = $color_values->shaped( $deduced_space_name );
    my $color_space = Graphics::Toolkit::Color::Space::Hub::get_space( $deduced_space_name );
    for my $pos ($color_space->basis->axis_iterator) {
        $values->[$pos] = $new_values->[$pos] if defined $new_values->[$pos];
    }
    return $color_values->new_from_tuple( $values, $color_space->name );
}

sub add_value { # .values, %newval -- ~space_name --> _
    my ($color_values, $partial_hash, $preselected_space_name) = @_;
    my ($new_values, $deduced_space_name) = 
		Graphics::Toolkit::Color::Space::Hub::deformat_partial_hash( $partial_hash, $preselected_space_name );
    unless (ref $new_values){
        my $help_start = 'axis names: '.join(', ', keys %$partial_hash).' do not correlate to ';
        return (defined $preselected_space_name) ? $help_start.'the selected color space: '.$preselected_space_name.'!'
                                                 : 'any supported color space!';
    }
    my $values = $color_values->shaped( $deduced_space_name );
    my $color_space = Graphics::Toolkit::Color::Space::Hub::get_space( $deduced_space_name );
    for my $pos ($color_space->basis->axis_iterator) {
        $values->[$pos] += $new_values->[$pos] if defined $new_values->[$pos];
    }
    return $color_values->new_from_tuple( $values, $color_space->name );
}

sub mix { #  @%(+percent, _color)  -- ~space_name --> _
    my ($color_values, $recipe, $color_space ) = @_;
    return if ref $recipe ne 'ARRAY';
    my $result_values = [(0) x $color_space->axis_count];
    for my $ingredient (@$recipe){
        return if ref $ingredient ne 'HASH' or not exists $ingredient->{'percent'}
               or not exists $ingredient->{'color'} or ref $ingredient->{'color'} ne ref $color_values;
        my $values = $ingredient->{'color'}->shaped( $color_space->name );
        $result_values->[$_] +=  $values->[$_] * $ingredient->{'percent'} / 100 for 0 .. $#$values;
    }
    return $color_values->new_from_tuple( $result_values, $color_space->name );
}

sub invert {
    my ($color_values, $only, $color_space ) = @_;
    return unless ref $color_space;
    $only = [$only] if defined $only and not ref $only; # check which axis selected
    my $selected_axis = (defined $only) ? [ ] : [$color_space->basis->axis_iterator];
    if (defined $only) {
	    for my $axis_name (@$only){
		    my $pos = $color_space->pos_from_axis_name( $axis_name );
			return "axis name '$axis_name' is not part of clor space '".$color_space->name.
			       "', please try: ".(join(' ', $color_space->long_axis_names)).
			       ' or '.(join(' ', $color_space->short_axis_names)).' !' unless defined $pos;
			return "axis '$axis_name' is already selected for inversion" if exists $selected_axis->[$pos];
			$selected_axis->[$pos] = $pos;
		}
	} 
    my $values = $color_values->normalized( $color_space->name );
	for my $axis_nr ($color_space->basis->axis_iterator){
        next unless defined $selected_axis->[$axis_nr];
        if ($color_space->shape->is_axis_euclidean( $axis_nr )){
            $values->[$axis_nr] = 1 - $values->[$axis_nr];
        } else {
            $values->[$axis_nr] = ($values->[$axis_nr] < 0.5)
                                ? $values->[$axis_nr] + 0.5
                                : $values->[$axis_nr] - 0.5;
        }
	}
    return $color_values->new_from_tuple( $values, $color_space->name, 'normal' );
}

1;
