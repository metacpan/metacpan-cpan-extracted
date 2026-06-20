
# store all color space objects, to convert check, convert and measure color values

package Graphics::Toolkit::Color::Space::Hub;
use v5.12;
use warnings;

#### internal space loading ############################################
our $default_space_name = 'RGB';
our @load_order = ($default_space_name,
                  qw/RGBLinear CMY CMYK HSL HSV HSB HWB NCol YIQ YPbPr/,
                  qw/CIEXYZ CIERGB CIELAB CIELUV CIELCHab CIELCHuv HunterLAB/,
                  qw/AppleRGB AdobeRGB ProPhotoRGB WideGamutRGB/,
                  qw/DisplayP3Linear DisplayP3 DCIP3Linear DCIP3 Rec709 Rec2020/,
                  qw/OKLAB OKLCH OKHSL OKHSV OKHWB/);
add_space( require "Graphics/Toolkit/Color/Space/Instance/$_.pm" ) for @load_order;
my ($default_space, @search_order, %space_obj, %next_conversion_node, %space_family);

#### space API #########################################################
sub is_space_name      { 
	(ref get_space( $default_space->normalize_name( $_[0] ))) ? 1 : 0 }
sub all_space_names    { sort keys %space_obj }
sub default_space_name { $default_space_name }
sub default_space      { $default_space }
sub get_space          { # takes only normal names or alias names
    my $name = shift;
    return unless defined $name;
    $name = default_space()->normalize_name( $name ) if ref $default_space;
	exists $space_obj{ $name }  ? $space_obj{ $name } : '';
}
sub try_get_space      { # takes any name variant and defaults to $default_space_name
    my $name = shift || $default_space_name;
    return $name if ref $name eq 'Graphics::Toolkit::Color::Space' and is_space_name( $name->name );
    $name = default_space()->normalize_name( $name );
    my $space = get_space( $name );
    return (ref $space) ? $space
                        : "$name is an unknown color space, try one of: ".(join ', ', all_space_names());
}

sub add_space {
    my $space = shift;
    return 'add_space got no Graphics::Toolkit::Color::Space object as argument' if ref $space ne 'Graphics::Toolkit::Color::Space';
    my $name = $space->name;
    my $alias = $space->name('alias');
    return "can not add color space object without a name" unless $name;
    return "color space name $name is already taken" if ref get_space( $name );
    if ($name eq $default_space_name) { # there is no parent
		$default_space = $space;
    } else {
		my $conversion_parent = $space->conversion_tree_parent;
		return "can not add color space $name, it has no converter" unless defined $conversion_parent and $conversion_parent;
		$conversion_parent = $space->normalize_name( $conversion_parent );
        my $parent_space = get_space( $conversion_parent );
        return "color space $name does only convert into '$conversion_parent', which is no known color space" unless ref $parent_space;
        my $parent_name = $parent_space->name;
        $next_conversion_node{ $parent_name }{ $name } = $name;
        unless ($parent_name eq $default_space_name){
			my $upper_space_name = $default_space_name;
			while ($upper_space_name ne $parent_name){
				$upper_space_name = $next_conversion_node{ $upper_space_name }{ $name } 
				                  = $next_conversion_node{ $upper_space_name }{ $parent_name };
			}
		}
    }
    push @search_order, $name;
    $space_obj{ $name } = $space;
    $space_obj{ $alias } = $space if $alias and not ref get_space( $alias );
    push @{$space_family{ $space->family }}, $space if $space->family;
    return 1;
}
sub remove_space {
    my $name = shift;
    return "need name of color space as argument in order to remove the space" unless defined $name and $name;
    my $space = try_get_space( $name );
    return "can not remove unknown color space: $name" if not ref $space;
    return "can not remove default color space: $name" if $space->name eq $default_space_name;

    $name = $space->name;
	my $upper_space_name = $default_space_name;
	while ($upper_space_name ne $name){
		$upper_space_name = delete $next_conversion_node{ $upper_space_name }{ $name };
	}
	delete $space_family{ $space->family } if $space->family;
    delete $space_obj{ $space->name('alias') } if $space->name('alias');
    delete $space_obj{ $name };
}

#### tuple API ##########################################################
sub convert { # normalized RGB tuple, ~space_name --> |normalized tuple in wanted space
    my ($tuple, $target_space_name, $want_result_normalized, $source_tuple, $source_space_name) = @_;
    return "need an ARRAY ref with 3 normalized RGB values as first argument in order to convert them" 
		unless $default_space->is_number_tuple( $tuple );
    my $target_space = try_get_space( $target_space_name );
    return "got unknown space name: '$target_space_name' as second argument, can not convert " unless ref $target_space;
    my $source_space = try_get_space( $source_space_name );
    return "did not found target color space !'$target_space_name'" unless ref $target_space;
    if ($source_space_name xor $source_tuple){
		return "arguments source_space_name and source_values (nr. 4 and 5) have to be provided both or none of them";
	} elsif ($source_space_name and $source_tuple) {
		return "got unknown source color space $source_space_name" if not ref $source_space;
		return "argument source_values has to be a tuple, if provided" unless $source_space->is_number_tuple( $source_tuple );
	}

    $tuple = [@$tuple];                       # unwrap ref to avoid spooky action
    my $current_space_name = $default_space_name; # we start in RGB
    $target_space_name = $target_space->name; # use only normalized name
    $want_result_normalized //= 0;            # normal flags to start state
    my $tuple_is_normal = 1;

    while ($current_space_name ne $target_space_name){
		my $next_space_name = $next_conversion_node{ $current_space_name }{ $target_space_name };
        my $next_space = get_space( $next_space_name );
		# replace tuple with values from constructor if possible
		if (defined $source_space_name and $next_space->is_name($source_space_name)){
            $tuple = [@$source_tuple];
            $tuple_is_normal = 1;
        } else {
            my @normal_in_out = $next_space->converter_normal_states( 'from', $current_space_name );
            $tuple = $next_space->normalize( $tuple ) if not $tuple_is_normal and $normal_in_out[0];
            $tuple = $next_space->denormalize( $tuple ) if $tuple_is_normal and not $normal_in_out[0];
            $tuple = $next_space->convert_from( $current_space_name, $tuple );
            $tuple_is_normal = $normal_in_out[1];
            if (not $tuple_is_normal and $next_space_name ne $target_space_name){
				$tuple_is_normal = 1;
				$tuple = $next_space->normalize( $tuple );
			}
        }
		$current_space_name = $next_space_name;		
	}
    $tuple = $target_space->normalize( $tuple )   if not $tuple_is_normal and $want_result_normalized;
    $tuple = $target_space->denormalize( $tuple ) if $tuple_is_normal and not $want_result_normalized;
    return $tuple;
}
sub deconvert { # normalized value tuple --> RGB tuple
    my ($tuple, $original_space_name, $want_result_normalized, $source_tuple, $source_space_name) = @_;
    my $original_space = try_get_space( $original_space_name );
    my $source_space = try_get_space( $source_space_name );
    $want_result_normalized //= 0;
    return "need a space name to convert from as second argument" unless defined $original_space_name;
    return "got unknown color space name as second argument" unless ref $original_space;
    return "need as first argument an ARRAY with valid number of normalized values from the color space ". $original_space->name
		unless $original_space->is_number_tuple( $tuple );
   
    if ($source_space_name xor $source_tuple){
		return "arguments source_space_name and source_values (nr. 4 and 5) have to be provided both or none of them";
	} elsif ($source_space_name and $source_tuple) {
		return "got unknown source color space $source_space_name" if not ref $source_space;
		return "argument source_values has to be a tuple, if provided" unless $source_space->is_number_tuple( $source_tuple );
	}
    
    # none conversion cases        
    if ($original_space->name eq $default_space_name) { # nothing to convert
        return ($want_result_normalized) ? $tuple : $original_space->denormalize( $tuple );
    }
    my $current_space = $original_space;
    my $tuple_is_normal = 1;
    # actual conversion
    while ($current_space->name ne $default_space_name){
        my ($next_space_name, @next_options) = $current_space->conversion_tree_parent;
        $next_space_name = shift @next_options while @next_options and $next_space_name ne $default_space_name;
        # replace tuple with values from constructor if possible
        if (defined $source_space_name and $current_space->is_name( $source_space_name )){
            $tuple = [@$source_tuple];
            $tuple_is_normal = 1;
        } else {
            my @normal_in_out = $current_space->converter_normal_states( 'to', $next_space_name );
            $tuple = $current_space->normalize( $tuple ) if not $tuple_is_normal and $normal_in_out[0];
            $tuple = $current_space->denormalize( $tuple ) if $tuple_is_normal and not $normal_in_out[0];
            $tuple = $current_space->convert_to( $next_space_name, $tuple);
            $tuple_is_normal = $normal_in_out[1];
            if (not $tuple_is_normal and $current_space->name ne $default_space_name){
				$tuple_is_normal = 1;
				$tuple = $current_space->normalize( $tuple );
			}
        }
        $current_space = get_space( $next_space_name );
    }
    $tuple = $current_space->normalize( $tuple )   if not $tuple_is_normal and $want_result_normalized;
    $tuple = $current_space->denormalize( $tuple ) if $tuple_is_normal and not $want_result_normalized;
    return $tuple;
}

sub deformat { # formatted color def --> tuple
    my ($color_def, $space_name, $suffix) = @_;
    return 'Got no color definition!' unless defined $color_def;
    my ($tuple, $original_space, $format_name);
    my $color_space = get_space( $space_name );
    return "$color_space is an unknown space!" unless ref $color_space;
    ($tuple, $format_name) = $color_space->deformat( $color_def ); #, $suffix
    return "Could not deformat color definition: '$color_def' in space: ".$color_space->name unless defined $format_name;
    return $tuple, $color_space->name, $format_name;
}
sub deformat_search { # formatted color def --> tuple
    my ($color_def, $suffix) = @_;
    return 'got no color definition to deformat!' unless defined $color_def;
    for my $space_name (@search_order) {
        my @tuple_space_format = deformat( $color_def, $space_name, $suffix);
        return @tuple_space_format if @tuple_space_format > 1;
    }
    return "Could not deformat color definition in any space: '@$color_def'!" if ref $color_def eq 'ARRAY';
    return "Could not deformat color definition in any space: '%$color_def'!" if ref $color_def eq 'HASH';
    return "Could not deformat color definition in any space: '$color_def'!";
}
sub deformat_search_partial_hash { # convert partial hash into
    my ($value_hash, $space_name) = @_;
    return unless ref $value_hash eq 'HASH';
    my $space = try_get_space( $space_name );
    return $space unless ref $space;
    my @space_name_options = (defined $space_name and $space_name) ? ($space->name) : (@search_order);
    for my $space_name (@space_name_options) {
        my $color_space = try_get_space( $space_name );
        my $tuple = $color_space->tuple_from_partial_hash( $value_hash );
        next unless ref $tuple;
        return wantarray ? ($tuple, $color_space->name) : $tuple;
    }
    return undef;
}

sub distance { # @c1 @c2 -- ~space ~select @range --> +
    my ($tuple_a, $tuple_b, $space_name, $select_axis, $range) = @_;
    my $color_space = try_get_space( $space_name );
    return $color_space unless ref $color_space;
    $tuple_a = convert( $tuple_a, $space_name, 'normal' );
    $tuple_b = convert( $tuple_b, $space_name, 'normal' );
    my $delta = $color_space->delta( $tuple_a, $tuple_b );
    $delta = $color_space->denormalize_delta( $delta, $range );
    if (defined $select_axis){
        $select_axis = [$select_axis] unless ref $select_axis;
        my @selected_values = grep {defined $_} map {$delta->[$_]}
                              grep {defined $_} map {$color_space->pos_from_axis_name($_)} @$select_axis;
        $delta = \@selected_values;
    }
    my $d = 0;
    $d += $_ * $_ for @$delta;
    return sqrt $d;
}

1;
