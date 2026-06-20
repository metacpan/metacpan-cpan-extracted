
# public user level API: doc summary, help msg and arg cleaning

package Graphics::Toolkit::Color;
our $VERSION = '2.21';
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Error       qw/error/;
use Graphics::Toolkit::Color::Space::Util qw/is_nr/;
use Graphics::Toolkit::Color::SetCalculator;

## import export, error handling #######################################
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/color is_in_gamut/;

sub import {
    my ($class, @args) = @_;
    my @export_symbols;
    push @export_symbols, shift @args while @args and lc $args[0] ne 'error';
    Graphics::Toolkit::Color::Error::change_mode( $args[1] );
    $class->Exporter::export_to_level(1, $class, @export_symbols);
}

## constructor #########################################################
my $POD_link = ' Type "perldoc Graphics::Toolkit::Color" for more help.';
sub new {
    my ($pkg, @args) = @_;
    my $help = 'method "new" accepts the arguments: "color" (color definition), "raw", '.
               '"range" and "in" (space name). "color" is the required and default argument.'.$POD_link;
	my ($color_def, $space_name, $range_def, $is_raw);
    if (@args > 0 and not @args % 2){
		my %h = @args;
		return error('got an argument twice') if int(%h) * 2 < int(@args);
		($color_def, $space_name, $range_def, $is_raw) = ($h{'color'}, $h{'in'}, $h{'range'}, $h{'raw'} // 0);
	}
    $color_def = _color_def_into_scalar( @args ) unless defined $color_def;
    return error($help) unless defined $color_def;
    my $self = _new_from_scalar_def( $color_def, $space_name, $range_def, $is_raw );
	return (ref $self) ? $self : error($self);
}
sub color { 
	my $self = _new_from_scalar_def( _color_def_into_scalar( @_ ) );
	return (ref $self) ? $self : error($self);
}
sub _color_def_into_scalar {
    my (@args) = @_;
    return if @args < 1 or @args > 8 or @args == 7;
    return $args[0] if @args == 1; # pass names
    return [@args]  if @args <= 5; # lists and named lists --> array and named array
    return {@args};                # hashes without curly braces --> hash
}
sub _new_from_scalar_def {
    my ($color_def, $space_name, $range_def, $is_raw) = @_;
    return $color_def if ref $color_def eq __PACKAGE__;
    return _new_from_value_obj( Graphics::Toolkit::Color::Values->new_from_any_input( $color_def, $space_name, $range_def, $is_raw ) );
}
sub _new_from_value_obj {
    my ($value_obj) = @_;
    return $value_obj unless ref $value_obj eq 'Graphics::Toolkit::Color::Values';
    return bless {values => $value_obj};
}
sub values_object { $_[0]->{'values'} if ref $_[0] eq __PACKAGE__}

sub is_in_gamut {
    my ($self, $space_name, $named_arg) = @_;
    return is_in_gamut_sub (@_) if ref $self ne __PACKAGE__;
    my $help = 'The method "is_in_gamut" accepts one optional, positional argument, a color space name, '.
               'which defaults to the space the color was defined in'.$POD_link;
	$space_name = $named_arg if defined $space_name and $space_name eq 'in' and defined $named_arg;
    my $space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
	return error($help) if defined $space_name and not ref $space;
    $self->values_object->is_in_gamut( (ref $space) ? $space->name : undef );
}
sub is_in_gamut_sub {
    my (@color) = @_;
	my $values = Graphics::Toolkit::Color::Values->new_from_any_input( 
		_color_def_into_scalar( @_ ), undef, undef, 1 
	);
	return error($values.$POD_link) unless ref $values;
    $values->is_in_gamut( );
}

########################################################################
sub _split_named_args {
    my ($raw_args, $only_parameter, $required_parameter, $optional_parameter, $parameter_alias) = @_;
    @$raw_args = %{$raw_args->[0]} if @$raw_args == 1 and ref $raw_args->[0] eq 'HASH' and not
                  (defined $only_parameter and $only_parameter eq 'to' and ref _new_from_scalar_def( $raw_args ) );

    if (@$raw_args == 1 and defined $only_parameter and $only_parameter){
        return "The one default argument can not cover multiple, required parameter !" if @$required_parameter > 1;
        return "The default argument does not cover the required argument!"
            if @$required_parameter and $required_parameter->[0] ne $only_parameter;

        my %defaults = %$optional_parameter;
        delete $defaults{$only_parameter};
        return {$only_parameter => $raw_args->[0], %defaults};
    }
    my %clean_arg;
    if (@$raw_args % 2) {
        return (defined $only_parameter and $only_parameter)
             ? "Got odd number of arguments, please use key value pairs as arguments or one default argument !\n"
             : "Got odd number of values, please use key value pairs as arguments !\n"
    }
    my %arg_hash = @$raw_args;
    for my $parameter_name (@$required_parameter){
        if (ref $parameter_alias eq 'HASH' and exists $parameter_alias->{ $parameter_name }
            and exists $arg_hash{ $parameter_alias->{$parameter_name} }){
            $arg_hash{ $parameter_name } = delete $arg_hash{ $parameter_alias->{$parameter_name} };
        }
        return "Argument '$parameter_name' is missing!\n" unless exists $arg_hash{$parameter_name};
        $clean_arg{ $parameter_name } = delete $arg_hash{ $parameter_name };
    }
    for my $parameter_name (keys %$optional_parameter){
        if (ref $parameter_alias eq 'HASH' and exists $parameter_alias->{ $parameter_name }
            and exists $arg_hash{ $parameter_alias->{$parameter_name} }){
            $arg_hash{ $parameter_name } = delete $arg_hash{ $parameter_alias->{$parameter_name} };
        }
        $clean_arg{ $parameter_name } = exists $arg_hash{$parameter_name}
                                      ? delete $arg_hash{ $parameter_name }
                                      : $optional_parameter->{ $parameter_name };
    }
    return "Inserted unknown argument(s): ".(join ',', keys %arg_hash)."\n" if %arg_hash;
    return \%clean_arg;
}

### getter #############################################################
my $default_space_name = Graphics::Toolkit::Color::Space::Hub::default_space_name();
sub values       {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'in', [],
                               { in => $default_space_name, as => 'list', raw => 0,
                                 precision => undef, range => undef, suffix => undef } );
    my $help = 'The method "values" returns numeric color values and accepts six named, optional arguments: '.
               '"in" (color space name - default arg), "as" (color definition format), "raw", "range", "precision" and "suffix"!';
    return error($arg.$help.$POD_link) unless ref $arg;
    my @result = $self->values_object->formatted( @$arg{qw/in as suffix range precision raw/} );
    return error(${$result[0]}.$help.$POD_link) if ref $result[0] eq 'SCALAR';
    return wantarray ? @result : $result[0];
}

sub name         {
    my ($self, @args) = @_;
    return $self->values_object->name unless @args;
    my $arg = _split_named_args( \@args, 'from', [], {from => 'default', all => 0, full => 0, distance => 0}, {distance => 'd'});
    my $help = 'The method "name" returns one, several or no (empty) color name strings and accepts four named, optional arguments: '.
               '"from" (scheme name - default arg), "all" (color names), "full" (name) and "distance" (or "d")!';
    return error($arg.$help.$POD_link) unless ref $arg;
    Graphics::Toolkit::Color::Name::from_values( $self->values_object->shaped, @$arg{qw/from all full distance/});
}

sub closest_name {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'from', [], {from => 'default', all => 0, full => 0});
    my $help = 'The method "closest_name" returns one or several (in an ARRAY) color name strings and in list context also '.
			    'the numeric distance and accepts three named, optional arguments: '.
               '"from" (scheme name - default arg), "all" (color names) and "full" (name)!';
    return error($arg.$help.$POD_link) unless ref $arg;
    my ($name, $distance) = Graphics::Toolkit::Color::Name::closest_from_values(
                                $self->values_object->shaped, @$arg{qw/from all full/});
    return wantarray ? ($name, $distance) : $name;
}

sub distance {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'to', ['to'], {in => $default_space_name, only => undef, range => undef}, {only => 'select'});
    my $help = 'The method "distance" returns one numeric distance value and accepts four named arguments, the first being default '.
               'and required: "to" (definition of second color), "in" (color space name), "only" (axis selection) and "range"!';
    return error($arg.$help.$POD_link) unless ref $arg;
    my $target_color = _new_from_scalar_def( $arg->{'to'} );
    return error("target color definition: $arg->{to} is ill formed".$help.$POD_link) unless ref $target_color;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return error($color_space.$help.$POD_link) unless ref $color_space;
    if (defined $arg->{'only'}){
        if (not ref $arg->{'only'}){
			return error($arg->{'only'}." is not an axis name or role in color space: ".$color_space->name.$help.$POD_link)
                unless $color_space->is_axis_role( $arg->{'only'} );
        } elsif (ref $arg->{'only'} eq 'ARRAY'){
            for my $axis_name (@{$arg->{'only'}}) {
				return error( $axis_name." is not an axis name or role in color space: ".$color_space->name.$help.$POD_link)
					unless $color_space->is_axis_role( $axis_name );
            }
        } else { return error('The "only" argument needs one axis name or an ARRAY with several axis names from '.
			                  'the same color space!'.$help.$POD_link) }
    }
    my $range_def = $color_space->shape->try_check_range_definition( $arg->{'range'} );
    return error($range_def.$help.$POD_link) unless ref $range_def;
    Graphics::Toolkit::Color::Space::Hub::distance(
        $self->values_object->normalized, $target_color->values_object->normalized, $color_space->name, $arg->{'only'}, $range_def );
}

## single color creation methods #######################################
# lightweight designer API
my $design_default = 'OKHSL';
sub lighten {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'by', ['by'], {in => $design_default});
    return "The only argument or named argument 'by' has to be a number between 0 and 1!" unless ref $arg;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::lighten( $self->values_object, $arg->{'by'}, $arg->{'in'} ) );
}
sub darken {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'by', ['by'], {in => $design_default});
    return "The only argument or named argument 'by' has to be a number between 0 and 1!" unless ref $arg;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::darken( $self->values_object, $arg->{'by'}, $arg->{'in'} ) );
}
sub saturate {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'by', ['by'], {in => $design_default});
    return "The only argument or named argument 'by' has to be a number between 0 and 1!" unless ref $arg;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::saturate( $self->values_object, $arg->{'by'}, $arg->{'in'} ) );
}
sub desaturate {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'by', ['by'], {in => $design_default});
    return "The only argument or named argument 'by' has to be a number between 0 and 1!" unless ref $arg;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::desaturate( $self->values_object, $arg->{'by'}, $arg->{'in'} ) );
}
sub tint {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'by', ['by'], {in => $design_default});
    return "The only argument or named argument 'by' has to be a number between 0 and 1!" unless ref $arg;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::tint( $self->values_object, $arg->{'by'}, $arg->{'in'} ) );
}
sub tone {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'by', ['by'], {in => $design_default});
    return "The only argument or named argument 'by' has to be a number between 0 and 1!" unless ref $arg;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::tone( $self->values_object, $arg->{'by'}, $arg->{'in'} ) );
}
sub shade {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'by', ['by'], {in => $design_default});
    return "The only argument or named argument 'by' has to be a number between 0 and 1!" unless ref $arg;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::shade( $self->values_object, $arg->{'by'}, $arg->{'in'} ) );
}
sub tone_curve { 
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, undef, ['gamma'], {in => 'LinearRGB'} ); 
    my $help = 'The method "tone_curve" returns a GTC object with gamma corrected values and accepts two named arguments, '.
               'the first being required: "gamma", "in" (color space name - default LinearRGB)!';
    return error($arg.$help.$POD_link) unless ref $arg;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return error($color_space.$help.$POD_link) unless ref $color_space;
	my $result = Graphics::Toolkit::Color::Calculator::apply_gamma( $self->values_object, $arg->{'gamma'}, $color_space );
    return error($result.$help.$POD_link) unless ref $result;
    return _new_from_value_obj( $result );
}
sub apply { tone_curve(@_) }

sub set_value {
    my ($self, @args) = @_;
    @args = %{$args[0]} if @args == 1 and ref $args[0] eq 'HASH';
    my $help = 'The method "set_value" returns a GTC object with some values replaced. Arguments are selected axis '.
               'names of target space and optionally "in" for color space disambiguation!';
    return error($help.$POD_link) if @args % 2 or not @args or @args > 10;
    my $partial_color = { @args };
    my $space_name = delete $partial_color->{'in'};
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return error($color_space.$help.$POD_link) if defined $color_space and not ref $color_space;
    my $result = Graphics::Toolkit::Color::Calculator::set_value( $self->values_object, $partial_color, $space_name );
    return error($result.' '.$help.$POD_link) unless ref $result;
    return _new_from_value_obj( $result );
}
sub add_value {
    my ($self, @args) = @_;
    @args = %{$args[0]} if @args == 1 and ref $args[0] eq 'HASH';
    my $help = 'The method "add_value" returns a GTC object with some values different. Arguments are selected axis '.
               'names of target space and optionally "in" for color space disambiguation!';
    return error($help.$POD_link) if @args % 2 or not @args or @args > 10;
    my $partial_color = { @args };
    my $space_name = delete $partial_color->{'in'};
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return error($color_space.$help.$POD_link) if defined $color_space and not ref $color_space;
    my $result = Graphics::Toolkit::Color::Calculator::add_value( $self->values_object, $partial_color, $space_name );
    return error($result.' '.$help.$POD_link) unless ref $result;
    return _new_from_value_obj( $result );
}

sub mix {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'to', ['to'], {in => 'OKLAB', by => undef}, {by => 'amount'});
    my $help = 'The method "mix" returns a GTC object, which is a blend between given colors. Arguments are: '.
               '"to" (other color[s]-required and default), "by" (mix amounts) and "in"(color space name, default OKLAB)!';
    return error($arg.' '.$help.$POD_link) unless ref $arg;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( delete $arg->{'in'} );
    return error($color_space.' '.$help.$POD_link) unless ref $color_space;
    my $second_color = _new_from_scalar_def($arg->{'to'});
    if (ref $second_color){ $arg->{'to'} = [$second_color->values_object] } 
    else {
        if (ref $arg->{'to'} ne 'ARRAY'){
			return error("Target color definition (argument 'to'): '$arg->{to}' is ill formed. $second_color. ".$POD_link);
        } else {
			my @to = ();
			for my $color_def (@{$arg->{'to'}}){
				if (ref $color_def eq __PACKAGE__) { push @to, $color_def->values_object }
				else {
					$second_color = Graphics::Toolkit::Color::Values->new_from_any_input( $color_def );
					return error("target color definition (argument 'to'). '$color_def' is ill formed: $second_color. ".$POD_link)
						unless ref $second_color;
					push @to, $second_color;
				}
			}
			$arg->{'to'} = \@to;
		}
    }
    # backward compatibility: 'by' > 1 is read as percent (0 .. 100) and mapped to 0 .. 1
    if (defined $arg->{'by'}){
        if (ref $arg->{'by'} eq 'ARRAY') { 
			for (@{$arg->{'by'}}) { $_ /= 100 if is_nr($_) and $_ > 1 } 
		} elsif (is_nr($arg->{'by'}) and $arg->{'by'} > 1) { $arg->{'by'} /= 100 }
    }
    my $result = Graphics::Toolkit::Color::Calculator::mix( $self->values_object, $arg->{'to'}, $arg->{'by'}, $color_space );
    return error($result.' '.$help.$POD_link) unless ref $result;
    return _new_from_value_obj( $result );
}

sub invert {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'only', [], {in => undef, only => undef});
    my $help = 'The method "invert" returns a GTC object with inverted ($max - $_) values. Optional arguments are: '.
               '"only" (axis selection, default is all) and "in" (color space name)!';
    return error($arg.$help.$POD_link) unless ref $arg and (not ref $arg->{'only'} or ref $arg->{'only'} eq 'ARRAY');
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return error($color_space.$help.$POD_link) if defined $arg->{'in'} and not ref $color_space;
    $arg->{'in'} = $color_space if defined $arg->{'in'};
    my $default_space = Graphics::Toolkit::Color::Space::Hub::get_space( 'OKHSL' );
	my $result = Graphics::Toolkit::Color::Calculator::invert( $self->values_object, $arg->{'only'}, $arg->{'in'}, $default_space );
    return error($result.$help.$POD_link) unless ref $result;
    return _new_from_value_obj( $result );
}

## color set creation methods ##########################################
sub complement {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'steps', [], {steps => 1, tilt => 0, skew => 0, target => {}, in => $design_default});
    my $help = 'The method "complement" returns a list of GTC objects with complementary colors. Optional arguments are: '.
               '"steps" (color count, default 1 - default argument), "in" (color space name, default "OKHSL", "tilt", "skew" and "target")!';
    return error($arg.$help.$POD_link) unless ref $arg;
    return error('Optional argument "steps" has to be a number ! '.$help.$POD_link) unless is_nr($arg->{'steps'});
    return error('Optional argument "steps" is zero or negative, no complement colors will be computed! '.$help.$POD_link) if $arg->{'steps'} < 1;
    return error('Optional argument "tilt" has to be a number! '.$help.$POD_link) unless is_nr($arg->{'tilt'});
    return error('Optional argument "skew" has to be a number! '.$help.$POD_link) unless is_nr($arg->{'skew'});
    return error('Optional argument "target" has to be a HASH ref! '.$help.$POD_link) if ref $arg->{'target'} ne 'HASH';
    my ($target_delta, $space_name);
    if (keys %{$arg->{'target'}}){
        ($target_delta, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat_search_partial_hash( $arg->{'target'}, 'HSL' );
        return error('Optional argument "target" got HASH keys that do not fit HSL roles ("h","s","l")! '.$help.$POD_link) unless ref $target_delta;
    } else { $target_delta = [] }
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return error($color_space.$help.$POD_link) unless ref $color_space;
    return error("Need a cylindrical space from the HSL family! ".$help.$POD_link) unless $color_space->family eq 'HSL';

    my @result = Graphics::Toolkit::Color::SetCalculator::complement( $self->values_object, $target_delta, @$arg{qw/steps tilt skew/}, $color_space );
	return error($result[0].$help.$POD_link) unless ref $result[0];
    map {_new_from_value_obj( $_ )} @result;
}

sub analogous {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'to', ['to'], {steps => 4, tilt => 0, in => $design_default});
    my $help = 'The method "analogous" returns a list of GTC objects with analogous colors. Arguments are: "to" (next color - default arg. and required), '.
               '"steps" (max. color count, default 4), "in" (color space name, default "OKHSL" and "tilt"!';
    return error($arg.$help.$POD_link) unless ref $arg;
    my $next_color = _new_from_scalar_def( $arg->{'to'} );
    if  (ref $next_color) { $arg->{'to'} = $next_color->values_object }
    else                  { return error('Argument "to" contains malformed color definition! '.$next_color.$POD_link) }
    return error('Optional argument "steps" has to be a number ! '.$help.$POD_link) unless is_nr($arg->{'steps'});
    return error('Optional argument "steps" has to be a number greater equal two! '.$help.$POD_link) unless is_nr($arg->{'steps'}) and $arg->{'steps'} >= 2;
    return error('Optional argument "tilt" has to be a number! '.$help.$POD_link) unless is_nr($arg->{'tilt'});
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return error($color_space.$help.$POD_link) unless ref $color_space;
    
    my @result = Graphics::Toolkit::Color::SetCalculator::analogous( $self->values_object, $arg->{'to'}, @$arg{qw/steps tilt/}, $color_space);
	return error($result[0].$help.$POD_link) unless ref $result[0];
    map {_new_from_value_obj( $_ )} @result;
}

sub gradient {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'to', ['to'], {steps => 10, tilt => 0, in => 'OKLAB'});
    my $help = 'The method "gradient" returns a list of GTC objects with a gradual transition between colors. Arguments are: '.
               '"to" (next color - default arg. and required), "steps" (color count, default 10), "in" (color space name, default "OKLAB" and "tilt")!';
    return error($arg.$help.$POD_link) unless ref $arg;
    my @colors = ($self->values_object);
    my $target_color = _new_from_scalar_def( $arg->{'to'} );
    if (ref $target_color) {
        push @colors, $target_color->values_object }
    else {
        return error('Argument "to" contains malformed color definition! '.$help.$POD_link) if ref $arg->{'to'} ne 'ARRAY' or not @{$arg->{'to'}};
        for my $color_def (@{$arg->{'to'}}){
            my $target_color = _new_from_scalar_def( $color_def );
            return error('Argument "to" contains malformed color definition: '.$color_def.'! '.$help.$POD_link) unless ref $target_color;
            push @colors, $target_color->values_object;
        }
    }
    return error('Argument "steps" has to be a number greater equel two! '.$help.$POD_link) unless is_nr($arg->{'steps'}) and $arg->{'steps'} >= 2;
    $arg->{'steps'} = int $arg->{'steps'};
    return error('Argument "tilt" has to be a number! '.$help.$POD_link) unless is_nr($arg->{'tilt'});
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return error($color_space.$help.$POD_link) unless ref $color_space;
    
    my @result = Graphics::Toolkit::Color::SetCalculator::gradient( \@colors, @$arg{qw/steps tilt/}, $color_space);
	return error($result[0].$help.$POD_link) unless ref $result[0];
    map {_new_from_value_obj( $_ )} @result;
}

sub cluster {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, undef, ['radius', 'minimal_distance'], {in => 'OKLAB'}, {radius => 'r', minimal_distance => 'min_d'});
    my $help = 'The method "cluster" returns a list of GTC objects with similar but distinct colors. The arguments are: '.
               '"radius" (max. distance from center, alias "r", required), "minimal_distance" (between colors, required) and "in" (color space name, default "OKLAB")!';
    return error($arg.$help.$POD_link) unless ref $arg;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return error($color_space.$help.$POD_link) unless ref $color_space;
    return error('Argument "radius" has to be a non-negative number or an ARRAY of numbers that holds for each space axis a radius value. '.$help.$POD_link)
        unless (is_nr($arg->{'radius'}) and $arg->{'radius'} >= 0) or $color_space->is_number_tuple( $arg->{'radius'} );
    return error('Argument "minimal_distance" (or "min_d") has to be a number greater zero! '.$help.$POD_link)
        unless is_nr($arg->{'minimal_distance'}) and $arg->{'minimal_distance'} > 0;
    return error('Ball shaped cluster works only in spaces with three dimensions! '.$help.$POD_link)
        if $color_space->axis_count > 3 and not ref $arg->{'radius'};

    my @result = Graphics::Toolkit::Color::SetCalculator::cluster( $self->values_object, @$arg{qw/radius minimal_distance/}, $color_space);
	return error($result[0].$help.$POD_link) unless ref $result[0];
    map {_new_from_value_obj( $_ )} @result;        
}

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color - calculate color (sets), IO many spaces and formats

=head1 SYNOPSIS

    use Graphics::Toolkit::Color qw/color is_in_gamut/;

    my $red = Graphics::Toolkit::Color->new('red');  # create color object
    say $red->add_value( 'blue' => 255 )->name;      # red + blue = 'magenta'
    my @blue = color( 0, 0, 255)->values('HSL');     # 240, 100, 50 = blue
    if (is_in_gamut('oklab(14, -106, 3)')) { ..      # check if valid
    $red->mix( to => [HSL => 0,0,80], by => 0.1);     # mix red with a little grey
    $red->gradient( to => '#0000FF', steps => 10);   # 10 colors from red to blue
    my @base_triadic = $red->complement( 3 );        # get fitting red green and blue
    my @reds = $red->cluster( r => 1.1, min_d => 1 );# 13 shades of red

=head1 DESCRIPTION

Graphics::Toolkit::Color, for short B<GTC>, is the top level API of this
library and the only package a regular user should be concerned with.
Its main purpose is the creation of related colors or sets of them,
such as gradients, complements and more. But if you want to convert, 
quantize, round or reformat color definitions or translate from and to 
color names, it can be helpful too.

This page will give you a quick overview of all GTC methods. 
The L<Manual|Graphics::Toolkit::Color::Manual> contains deeper explanations
and describes every argument and topic of interest in detail. Therefore each
chapter here starts with a link to the appropriate paragraph of a manual page.

While this module can understand and output color values of many (33)
L<color spaces|Graphics::Toolkit::Color::Manual::Space>,
L<RGB|Graphics::Toolkit::Color::Manual::Space/RGB> is the internal and
primary one for input and output, because GTC is about colors that can be 
shown on the screen, and these are usually encoded in I<RGB> (nonlinear standard RGB). 
However, many color calculations are operating by default in 
I<OKLAB> or I<OKHSL> to give perceptually uniform results. 

Each GTC object represents one color and is read-only. It has no runtime 
dependencies. Only L<Test::Simple> and L<Test::Warn> are needed for testing. 
The behavior of L<error messages|Graphics::Toolkit::Color::Manual::Error>
can be chosen, but defaults to using L<Carp>.

=head1 DEPRECATION

The next API cleanup will come with version 3.0. Please see which 
syntax is L<on the way out|Graphics::Toolkit::Color::Manual::Deprecation>.

=head1 CONSTRUCTOR

L<new|Graphics::Toolkit::Color::Manual::Constructor/new> is the universal
constructor to create a GTC object that takes the arguments: 
L<color|Graphics::Toolkit::Color::Manual::Argument/color> (color definition), 
L<raw|Graphics::Toolkit::Color::Manual::Argument/raw> (defaults to false, which clamps values into range), 
L<range|Graphics::Toolkit::Color::Manual::Argument/range> (min. and max. values) and 
L<in|Graphics::Toolkit::Color::Manual::Argument/in> (color space name).
C<color> is the only required argument and the default argument 
(can be provided as the only positional argument).

The importable method L<color|Graphics::Toolkit::Color::Manual::Constructor/color>
is a short alias for calling C<new> just with the argument C<color>.

    use Graphics::Toolkit::Color qw/color/;

    my $color = Graphics::Toolkit::Color->new( 'Emerald' ); # X11 constant
    my $green = Graphics::Toolkit::Color->new( 'SVG:green');# SVG constant (explicit with full name)
    my $navy  = color( 'navy' );                            # just a shortcut, X11 constant
    
    color(  r => 255, g => 0, b => 0 );                     # red (RGB)
    color( {r => 255, g => 0, b => 0});                     # red in char_hash format (RGB)
    color( Red => 255, Green => 0, Blue => 0);              # red in hash format (RGB)
    color( Hue => 0, Saturation => 1, Lightness => .5 );    # red in OKHSL
    color( hue => 0, whiteness => 0, blackness => 0 );      # red in OKHWB

    color(  255, 0, 0 );                # list format, no space name -> RGB
    color( [255, 0, 0] );               # array format, RGB only (as input)
    color( 'RGB',   255, 0, 0  );       # named list format
    color(  RGB =>  255, 0, 0  );       # with fat comma
    color( [RGB =>  255, 0, 0] );       # named_array
    color(  RGB => [255, 0, 0] );       # tuple under named key
    color( [RGB => [255, 0, 0]]);       # nested_array

    color( 'rgb: 255, 0, 0' );          # named string format, commas are not optional
    color( 'HSV: 240, 100, 100' );      # space name is case insensitive
    color( 'hsv(240, 100, 100)' );      # css_string format
    color( 'hsv(240, 100%, 100%)' );    # value suffix is optional
    color( 'rgb(255 0 0)' );            # commas are optional
									    
    color( '#FF0000' );                 # hex_string format, RGB only
    color( '#f00' );                    # hex_string format, short form

    # color is far outside the RGB16 range, but will be read as is, unclamped
    Graphics::Toolkit::Color->new( color => [100_000,0,0], range => 2**16-1, raw => 1 );

=head1 GETTER

These methods provide information about color(s), but not a GTC object.

=head2 is_in_gamut

L<is_in_gamut|Graphics::Toolkit::Color::Manual::Getter/is_in_gamut> returns 
a perlish pseudo boolean that answers the question: is this color inside
the value L<range|Graphics::Toolkit::Color::Manual::Argument/range>
of a L<color space|Graphics::Toolkit::Color::Manual::Space> (gamut). 
It can be used as a method or an importable subroutine. In method mode
it takes one optional positional argument, which is a color space name 
(like L<in|Graphics::Toolkit::Color::Manual::Argument/in>).
The color will be converted into that space, before a check is performed.
If no space name is provided, the check happens in the color space the
original values (when the object was created) were defined in.

When used as a subroutine, it requires only one positional argument,
that has to be a color definition (like with the C<color> routine).
This check will be performed in the color space the color is defined in.
For color names this would be L<RGB|Graphics::Toolkit::Color::Manual::Space/RGB>, 
which makes the result always true (1).

    $color->is_in_gamut( 'okLab');               # is current color inside OKLAB?

    use Graphics::Toolkit::Color qw/is_in_gamut/;
    is_in_gamut('rgb: 0, 0, 300');               # false, SRGB ranges span up to 255
    is_in_gamut('#000000');                      # true, black is always included


=head2 values

L<values|Graphics::Toolkit::Color::Manual::Getter/values> returns the 
numeric values of the color, held by the object and accepts six optional, 
named arguments: 
L<in|Graphics::Toolkit::Color::Manual::Argument/in> (color space),
C<as> ( L<format|Graphics::Toolkit::Color::Manual::Format>), 
L<range|Graphics::Toolkit::Color::Manual::Argument/range> (min. and max. values),
C<precision>, C<suffix> and 
L<raw|Graphics::Toolkit::Color::Manual::Argument/raw> (defaults to false, which clamps values into range).
C<in> is the default argument (used as only positional) and if no arguments
are provided, the method will return a list with 
L<RGB|Graphics::Toolkit::Color::Manual::Space/RGB> values.

    $blue->values();                                        #  0, 0, 255
    $blue->values( in => 'RGB', as => 'list');              #  0, 0, 255  # explicit arguments
    $blue->values(              as => 'array');             # [0, 0, 255] - RGB only
    $blue->values( in => 'RGB', as => 'named_array');       # ['RGB', 0, 0, 255]
    $blue->values( in => 'RGB', as => 'hash');              # { red => 0, green => 0, blue => 255}
    $blue->values( in => 'RGB', as => 'char_hash');         # { r => 0, g => 0, b => 255}
    $blue->values( in => 'RGB', as => 'named_string');      # 'rgb: 0, 0, 255'
    $blue->values( in => 'RGB', as => 'css_string');        # 'rgb( 0, 0, 255)'
    $blue->values(              as => 'hex_string');        # '#0000ff' - RGB only
    $blue->values(           range => 2**16-1 );            # 0, 0, 65535
    $blue->values('HSL');                                   # 240, 100, 50 # HSL is only argument
    $blue->values( in => 'HSL',suffix => ['', '%','%']);    # 240, '100%', '50%'
    $blue->values( in => 'HSB',  as => 'hash')->{'hue'};    # 240
   ($blue->values( 'HSB'))[0];                              # 240
    $blue->values( in => 'XYZ', range => 1, precision => 2);# normalized, 2 decimals max.

=head2 name

L<name|Graphics::Toolkit::Color::Manual::Getter/name> returns the
normalized name of the current color, if it (converted to RGB) is
part of a L<color scheme|Graphics::Toolkit::Color::Manual::Name/SCHEME>.
It has four optional named arguments: 
L<from|Graphics::Toolkit::Color::Manual::Argument/from> (scheme name),
C<all> (allows to return more names), 
C<full> (include scheme name in color name) and 
C<distance> (all colors within distance). 
The default argument is C<from> which defaults to the 
L<default scheme|Graphics::Toolkit::Color::Manual::Name/DEFAULT>.
All other arguments default to zero.

    $blue->name();                                   # 'blue'
    $blue->name('SVG');                              # 'blue'
    $blue->name( from => [qw/CSS X/], all => 1);     # 'blue', 'blue1'
    $blue->name( from => 'CSS', full => 1);          # 'CSS:blue'
    $blue->name( distance => 3, all => 1);           # all names within the distance

=head2 closest_name

L<closest_name|Graphics::Toolkit::Color::Manual::Getter/closest_name>
(almost) always returns a normalized color name (unlike L<name>). 
In list context it also returns the L</distance> between the current color 
and the color belonging to the returned name. It has three optional,
named arguments: C<from>, C<all>, C<full> which work the same way as in L</name>.

    my $name = $red_like->closest_name;              # closest name in default scheme
    my $name = $red_like->closest_name('HTML');      # closest HTML constant
    ($name, $distance) = $color->closest_name( from => 'Pantone', all => 1 );

=head2 distance

L<distance|Graphics::Toolkit::Color::Manual::Getter/distance> returns  
a numeric value, the Euclidean distance between two colors in some color
space, which works even in cylindrical spaces. 
It accepts four named arguments: L<to|Graphics::Toolkit::Color::Manual::Argument/to>, 
L<range|Graphics::Toolkit::Color::Manual::Argument/range>, 
L<only|Graphics::Toolkit::Color::Manual::Argument/only> and
L<in|Graphics::Toolkit::Color::Manual::Argument/in>. 
Only the C<to> is required and can be provided as the only positional argument.

    my $d = $blue->distance( 'lapisblue' );                        # how close is blue to lapisblue?
    $d = $blue->distance( to => 'airyblue', only => 'b');          # do they have the same amount of blue?
    $d = $color->distance( to => $c2, only => 'hue', in => 'HSL' );# same hue?
    $d = $color->distance( to => $c2, range => 'normal' );         # distance with values in 0 .. 1 range
    $d = $color->distance( to => $c2, only => [qw/r g b b/]);      # double the weight of blue value differences


=head1 SINGLE COLOR

These methods create one GTC object with a color that is related to the
current one. They can be divided into the simpler, high level convenience
methods on the one side 
(I<lighten>, I<darken>, I<saturate>, I<desaturate>, I<tint>, I<shade>, I<tone>)
and the more powerful low level operations on the other 
(I<apply>, I<set_value>, I<add_value>, I<mix>, I<invert>).

The signature of the high level methods is always the same. 
It understands 2 named arguments: C<by> and C<in>. The first is the 
required one, which can be provided as a positional argument, if it is 
the only one. C<by> needs a floating point number between 0 and 1.
Usually the method produces the same color again when 0 is provided and
a fixed predictable outcome when the argument is 1. 
The attribute L<in|Graphics::Toolkit::Color::Manual::Argument/in> is as 
always the L<color space|Graphics::Toolkit::Color::Manual::Space> the
method is computed in, which defaults here to I<OKHSL>. The first 4 methods
can only operate in a space of the I<HSL> family.

=head2 lighten

L<lighten|Graphics::Toolkit::Color::Manual::Calculation/lighten> 
increases the lightness by an absolute amount, but does not touch saturation.
The result will be clamped, so lighten(1) will always return I<white>.

    my $c = $mint->lighten( 0.1 );                      # is the same as :
    my $c = $mint->lighten( by => 0.1, in => 'OKHSL' );  

=head2 darken

L<darken|Graphics::Toolkit::Color::Manual::Calculation/darken> 
decreases the lightness by an absolute amount, but does not touch saturation.
The result will be clamped, so darken(1) will always return I<black>.

=head2 saturate

L<saturate|Graphics::Toolkit::Color::Manual::Calculation/saturate> 
increases the saturation by an absolute amount, but does not touch lightness.
The result will be clamped, so saturate(1) will always return 
the purest possible color.

=head2 desaturate

L<desaturate|Graphics::Toolkit::Color::Manual::Calculation/desaturate> 
decreases the saturation by an absolute amount, but does not touch lightness.
The result will be clamped, so desaturate(1) will always return a shade
of grey with the same lightness as the given color.

=head2 tint

L<tint|Graphics::Toolkit::Color::Manual::Calculation/tint> mixes (L</mix>)
a color with I<white> by the given percentage (0.2 = 20% white, 80% given color).
That lightens and desaturates at once. The result of tint(1) will always be I<white>.

=head2 tone

L<tone|Graphics::Toolkit::Color::Manual::Calculation/tone> mixes (L</mix>)
a color with mid gray (I<gray50>) by the given percentage 
(0.2 = 20% gray50, 80% given color).
That darkens or lightens and desaturates at once. 
The result of tone(1) will always be I<gray50>.

=head2 shade

L<shade|Graphics::Toolkit::Color::Manual::Calculation/shade> mixes (L</mix>)
a color with I<black> by the given percentage (0.2 = 20% black, 80% given color).
That darkens and desaturates at once. The result of shade(1) will always be I<black>.

=head2 tone_curve

L<tone_curve|Graphics::Toolkit::Color::Manual::Calculation/apply> computes a 
gamma correction. It has two named arguments: C<gamma> and 
L<in|Graphics::Toolkit::Color::Manual::Argument/in>, the first one 
being required and the default argument. C<in> defaults here to I<LinearRGB>.

    my $c = $blue->tone_curve( gamma => 2.2 );                          # is the same as :
    my $c = $blue->tone_curve( gamma => {r => 2.2, g =>2.2, b => 2.2}, in => 'LinearRGB' );


=head2 set_value

L<set_value|Graphics::Toolkit::Color::Manual::Calculation/set_value> 
returns a color that differs in some chosen values from the current one.
Its arguments have to be short or long axis names from one selected 
L<color space|Graphics::Toolkit::Color::Manual::Space>.
You may additionally provide the color space in mind with the argument 
L<in|Graphics::Toolkit::Color::Manual::Argument/in> if the axis names 
alone are too ambiguous.

    my $blue = $black->set_value( blue => 255 );                    # same as #0000ff
    my $color = $blue->set_value( saturation => 50, in => 'HSV' );  # would otherwise use OKHSL

=head2 add_value

Works exactly as L</set_value> with only one difference: the provided
axis values will be added to the current ones and not exchanged.

    my $darkblue = $blue->add_value( Lightness => -25 );    # get a darker tone
    my $blue3 = $blue->add_value( l => 10, in => 'LAB' );   # lighter color according to CIELAB

=head2 mix

L<mix|Graphics::Toolkit::Color::Manual::Calculation/mix> computes a color
that is a blend between two or more other colors. 
It has three named arguments: 
L<to|Graphics::Toolkit::Color::Manual::Argument/to>,
L<by|Graphics::Toolkit::Color::Manual::Argument/by> and
L<in|Graphics::Toolkit::Color::Manual::Argument/in>.
The first one is the only required and also the default argument.
C<by> defaults to a 50:50 blend and C<in> to I<OKLAB>.

    $blue->mix( $silver );                                     # 50% silver, 50% blue
    $blue->mix( to => 'silver', by => .6 );                    # 60% silver, 40% blue
    $blue->mix( to => [qw/silver green/], by => [.1, .2]);     # 10% silver, 20% green, 70% blue

=head2 invert

L<invert|Graphics::Toolkit::Color::Manual::Calculation/invert> computes 
a color with opposite properties (values). 
It has two named, optional arguments: 
L<only|Graphics::Toolkit::Color::Manual::Argument/only> (select axes) and
L<in|Graphics::Toolkit::Color::Manual::Argument/in> (color space name, defaults to I<OKHSL>).

    my $still_gray = $gray->invert();                 # got same color back
    my $blue = $yellow->invert('hue');                # invert hue in 'OKHSL'
    $yellow->invert( in => 'OKHSL', only => 'hue' );  # same in long form, same result as $yellow->complement();


=head1 COLOR SETS

These methods create sets of colors which are currently just a list of
GTC objects.

=head2 complement 

L<complement|Graphics::Toolkit::Color::Manual::Set/complement> computes 
colors that form a circle of complementary colors. This can only work in 
cylindrical spaces of the I<HSL> family. It understands five named arguments: 
L<steps|Graphics::Toolkit::Color::Manual::Argument/steps> (color count),
L<tilt|Graphics::Toolkit::Color::Manual::Argument/tilt>, C<target>, C<skew> and
L<in|Graphics::Toolkit::Color::Manual::Argument/in> (color space name, defaults to I<OKHSL>).
With no argument given it computes THE complementary color.

    my @colors = $c->complement( 4 );                       # 'quadratic' colors
    my @colors = $c->complement( steps => 4, tilt => 1.5 ); # split-complementary colors
    my @colors = $c->complement( steps => 3, tilt => 2, target => { l => -10 } );
    my @colors = $c->complement( steps => 3, tilt => 2, target => { h => 20, s=> -5, l => -10 });

=head2 analogous

L<analogous|Graphics::Toolkit::Color::Manual::Set/analogous> creates a list 
of colors where values of neighbours differ from each other the same way
as the two given colors. It accepts four named arguments: 
L<to|Graphics::Toolkit::Color::Manual::Argument/to> (next color), 
L<steps|Graphics::Toolkit::Color::Manual::Argument/steps> (max. color count, default 4),
L<tilt|Graphics::Toolkit::Color::Manual::Argument/tilt> and 
L<in|Graphics::Toolkit::Color::Manual::Argument/in> 
(color space name, defaults to I<OKHSL>). Only C<to> is required and also
the default argument.

    my @colors = $darkblue->analogous( to => $midblue, steps => 5);     # 5 shades of blue
    @colors = $c->analogous( to => [14,10,222], steps => 3, tilt => 0.2, in => 'RGB' );

=head2 gradient

L<gradient|Graphics::Toolkit::Color::Manual::Set/gradient> creates a list 
of colors that are a gradual blend between two or more given colors.
It accepts four named arguments: L<to|Graphics::Toolkit::Color::Manual::Argument/to>, 
L<steps|Graphics::Toolkit::Color::Manual::Argument/steps> (color count), 
C<tilt> and L<in|Graphics::Toolkit::Color::Manual::Argument/in> 
(color space name, defaults to I<OKLAB>). Only C<to> is required and also
the default argument.

    my @colors = $c->gradient( to => $grey, steps => 5);       # we turn to grey
    @colors = $c1->gradient( to => [14,10,222], steps => 10, tilt => 1, in => 'HSL' );

=head2 cluster

L<cluster|Graphics::Toolkit::Color::Manual::Set/cluster> creates a list of GTC 
color objects that look similar to the calling color but distinctly different.
It accepts three named arguments: C<radius>, C<minimal_distance> and 
L<in|Graphics::Toolkit::Color::Manual::Argument/in> (color space name, defaults to I<OKLAB>).
C<radius>, C<minimal_distance> are required and can be written C<r> and C<min_d>.

    my @blues = $blue->cluster( radius => 4, minimal_distance => 0.3 ); # ball shapes cluster
    my @c = $color->cluster( r => [2,2,3], min_d => 0.4, in => 'YUV' ); # box shaped cluster


=head1 SEE ALSO

=over 4

=item *

L<PDL::Transform::Color>

=item *

L<PDL::Graphics::ColorSpace>

=item *

L<Color::Scheme>

=item *

L<Graphics::ColorUtils>

=item *

L<Color::Fade>

=item *

L<Graphics::Color>

=item *

L<Graphics::ColorObject>

=item *

L<Color::Calc>

=item *

L<Convert::Color>

=item *

L<Color::Similarity>

=back

=head1 ACKNOWLEDGEMENT

These people contributed by providing patches, bug reports and useful
comments:

=over 4

=item *

Petr Pisar  (ppisar)

=item *

Slaven Rezic (srezic)

=item *

Gabor Szabo (szabgab)

=item *

Gene Boggs (GENE)

=item *

Stefan Reddig (sreagle)

=back

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=head1 COPYRIGHT

Copyright 2022-2026 Herbert Breunung.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
