
# methods to compute one related color

package Graphics::Toolkit::Color::Calculator;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space::Util qw/is_nr spow/;
use Graphics::Toolkit::Color::Values;

sub apply_gamma {
    my ($color_values, $gamma, $color_space) = @_;
    my $gamma_array = '';
    return "need a color space as third argument" if ref $color_space ne 'Graphics::Toolkit::Color::Space';
    if (ref $gamma eq 'HASH'){
        ($gamma_array, my $deduced_space_name) = 
			Graphics::Toolkit::Color::Space::Hub::deformat_search_partial_hash( $gamma, $color_space->name );
		return 'axis names: '.join(', ', keys %$gamma).' do not correlate to the selected color space: '.
			($color_space->name).'!' unless ref $gamma_array;
	}
	$gamma_array = [ ($gamma) x $color_space->axis_count] if is_nr( $gamma );
	$gamma_array = $gamma if not defined $gamma_array and ref $gamma eq 'ARRAY';
    return 'got badly formatted gamma value' if ref $gamma_array ne 'ARRAY';
	
	my $tuple = $color_values->normalized( $color_space->name );
    for my $axis_nr ($color_space->basis->axis_iterator){
	    $tuple->[$axis_nr] = spow($tuple->[$axis_nr], $gamma_array->[$axis_nr]) if exists $gamma_array->[$axis_nr];
    }
    return $color_values->new_from_tuple( $tuple, $color_space->name, 'normal' );
}

sub set_value { # .values, %newval -- ~space_name --> _
    my ($color_values, $partial_hash, $preselected_space_name) = @_;
    my ($new_values, $deduced_space_name) = 
		Graphics::Toolkit::Color::Space::Hub::deformat_search_partial_hash( $partial_hash, $preselected_space_name );
    unless (ref $new_values){
        my $help_start = 'axis names: '.join(', ', keys %$partial_hash).' do not correlate to ';
        return (defined $preselected_space_name) ? $help_start.'the selected color space: '.$preselected_space_name.'!'
                                                 : $help_start.'any supported color space!';
    }
    my $tuple = $color_values->shaped( $deduced_space_name );
    my $color_space = Graphics::Toolkit::Color::Space::Hub::get_space( $deduced_space_name );
    for my $pos ($color_space->basis->axis_iterator) {
        $tuple->[$pos] = $new_values->[$pos] if defined $new_values->[$pos];
    }
    return $color_values->new_from_tuple( $tuple, $color_space->name );
}

sub add_value { # .values, %newval -- ~space_name --> _
    my ($color_values, $partial_hash, $preselected_space_name) = @_;
    my ($new_values, $deduced_space_name) = 
		Graphics::Toolkit::Color::Space::Hub::deformat_search_partial_hash( $partial_hash, $preselected_space_name );
    unless (ref $new_values){
        my $help_start = 'axis names: '.join(', ', keys %$partial_hash).' do not correlate to ';
        return (defined $preselected_space_name) ? $help_start.'the selected color space: '.$preselected_space_name.'!'
                                                 : $help_start.'any supported color space!';
    }
    my $tuple = $color_values->shaped( $deduced_space_name );
    my $color_space = Graphics::Toolkit::Color::Space::Hub::get_space( $deduced_space_name );
    for my $pos ($color_space->basis->axis_iterator) {
        $tuple->[$pos] += $new_values->[$pos] if defined $new_values->[$pos];
    }
    return $color_values->new_from_tuple( $tuple, $color_space->name );
}


#### light designer API ################################################
sub _clear_values_amount_space_name {
    my ($color_values, $amount, $space_name, @more) = @_;
    return "need a G::T::Color::Values object as first argument" 
		unless ref $color_values eq 'Graphics::Toolkit::Color::Values';
    return "need a numeric amount between 0 and 1 as first argument" unless defined $amount;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return "$space_name is not a known color space" unless ref $color_space;
    return ($color_values, $amount, $color_space, @more);
}

sub lighten { add_axis_value( @_, 'lightness') }
sub darken  {
    my ($color_values, $amount, $color_space) = @_;
    add_axis_value($color_values, -$amount, $color_space, 'lightness');
}
sub saturate   { add_axis_value( @_, 'saturation') }
sub desaturate {
    my ($color_values, $amount, $color_space) = @_;
    add_axis_value($color_values, -$amount, $color_space, 'saturation');
}
sub add_axis_value {
    my ($color_values, $amount, $color_space, $axis_name) = _clear_values_amount_space_name(@_);
    return $color_values unless ref $color_values;
    my $axis_nr = $color_space->pos_from_axis_role( $axis_name );
    return "color space: '".$color_space->name."' has no $axis_name axis" unless defined $axis_nr;
    my $tuple = $color_values->normalized( $color_space->name );
	$tuple->[$axis_nr] += $amount;
    return $color_values->new_from_tuple( $tuple, $color_space->name, 'normal' );
}

sub tint     { mix_with(@_, [255  ,255  ,255  ]) } # white
sub tone     { mix_with(@_, [127.5,127.5,127.5]) } # grey50
sub shade    { mix_with(@_, [  0,    0,    0  ]) } # black
sub mix_with {
    my ($color_values, $amount, $color_space, $tuple) = _clear_values_amount_space_name(@_);
    return $color_values unless ref $color_values;
    return mix( $color_values, [Graphics::Toolkit::Color::Values->new_from_tuple( $tuple )], $amount, $color_space);
}

#### deep designer methods #############################################
sub mix { #  .base_color_vals, @.added_volor_vals, @+|+add_amount, .space --> .color_values
    my ($base_color, $added_color, $add_amount, $color_space ) = @_;
    return "need color value object as first argument !\n" unless ref $base_color eq 'Graphics::Toolkit::Color::Values';
    return "second argument has to be an ARRAY !\n" unless ref $added_color eq 'ARRAY';
    return "need a color space object !\n" unless ref $color_space eq 'Graphics::Toolkit::Color::Space';

    my $color_count = @$added_color + 1;
    $add_amount = 1 / $color_count unless defined $add_amount;
    $add_amount = [($add_amount) x ($color_count - 1)] unless ref $add_amount eq 'ARRAY';
	return "ARRAY of mix amounts needs a value for every color !\n" unless @$add_amount == $color_count - 1;
    my $mix_sum = 0;
    $mix_sum += $_ for @$add_amount;
    if ($mix_sum > 1){
		for my $reciepe_index (0 .. $#$add_amount){
			$add_amount->[$reciepe_index] = $add_amount->[$reciepe_index] / $mix_sum;
		}
	} else {
         push @$add_amount, 1 - $mix_sum;
         push @$added_color, $base_color;
	}
   
    my $result_values = [(0) x $color_space->axis_count];
    for my $color_nr (0 .. $#$added_color){
        my $tuple = $added_color->[$color_nr]->shaped( $color_space->name );
        $result_values->[$_] +=  $tuple->[$_] * $add_amount->[$color_nr] for 0 .. $#$tuple;
    }
    return $base_color->new_from_tuple( $result_values, $color_space->name );
}

sub invert {
    my ($color_values, $only, $color_space, $default_color_space ) = @_;
    $only = [$only] if defined $only and not ref $only; # selected axes
    return "need argument only as axis name (short or long) or as ARRAY of names!"
		if defined $only and ref $only ne 'ARRAY';
    if (defined $only){
		my %partial_hash = map { $_ => 1 } @$only;
		my $preselected_space_name = defined($color_space) ? $color_space->name : undef;
		my ($new_values, $deduced_space_name) =
			Graphics::Toolkit::Color::Space::Hub::deformat_search_partial_hash( \%partial_hash, $preselected_space_name );
		return "could not find any color space that contains the axes: ". join(', ', @$only).' !' 
			if not defined $deduced_space_name and not defined $color_space;
		return "axes ". join(', ', @$only) . 'do not match color space '.$color_space->name.' !'
			if not defined $deduced_space_name and ref $color_space;
		$color_space = Graphics::Toolkit::Color::Space::Hub::get_space( $deduced_space_name );
	}
	$color_space //= $default_color_space;
    
    my $selected_axis = (defined $only) ? [ ] : [$color_space->basis->axis_iterator];
    if (defined $only) {
	    for my $axis_name (@$only){
		    my $pos = $color_space->pos_from_axis_role( $axis_name );
			$selected_axis->[$pos] = $pos;
		}
	} 
    my $tuple = $color_values->normalized( $color_space->name );
	for my $axis_nr ($color_space->basis->axis_iterator){
        next unless defined $selected_axis->[$axis_nr];
        if ($color_space->shape->is_axis_euclidean( $axis_nr )){
            $tuple->[$axis_nr] = 0.5 - ($tuple->[$axis_nr] - 0.5);
        } else {
			$tuple->[$axis_nr]++ while $tuple->[$axis_nr] < 0;
			$tuple->[$axis_nr]-- while $tuple->[$axis_nr] > 1;
            $tuple->[$axis_nr] = ($tuple->[$axis_nr] < 0.5)
                                ? $tuple->[$axis_nr] + 0.5
                                : $tuple->[$axis_nr] - 0.5;
        }
	}
    return $color_values->new_from_tuple( $tuple, $color_space->name, 'normal' );
}
 
1;
