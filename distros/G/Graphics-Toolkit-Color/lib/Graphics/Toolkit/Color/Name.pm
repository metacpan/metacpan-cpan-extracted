
# translate color names to values and vice versa

package Graphics::Toolkit::Color::Name;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Name::Scheme;
use Graphics::Toolkit::Color::Space::Util qw/uniq round_decimals/;

#### public API ########################################################
sub all {
    my (@scheme_names) = @_;
    push @scheme_names, 'default' unless @scheme_names;
    my @names = ();
    for my $scheme_name (@scheme_names) {
        my $scheme = try_get_scheme( $scheme_name );
        next unless ref $scheme;
        push @names, $scheme->all_names;
    }
    return uniq( @names );
}

sub get_values {
    my ($color_name, $scheme_name) = @_;
    ($scheme_name, $color_name) = split(':', $color_name, 2) if index($color_name, ':') > -1;
    my $scheme = try_get_scheme( $scheme_name );
    return $scheme unless ref $scheme;
    return $scheme->values_from_name( $color_name );
}

sub from_values {
    my ($values, $scheme_name, $all_names, $full_name, $distance) = @_;
    my @return_names = ();
    my @scheme_names = (ref $scheme_name eq 'ARRAY') ? (@$scheme_name)
                     : (defined $scheme_name)        ? $scheme_name : 'DEFAULT';
    for my $scheme_name (@scheme_names) {
        my $scheme = try_get_scheme( $scheme_name );
        next unless ref $scheme;
        my $names = $distance ? $scheme->names_in_range( $values, $distance )
                              : $scheme->names_from_values( $values );
        next unless ref $names;
        $names = [ map { uc($scheme_name).':'.$_} @$names] if $full_name and uc($scheme_name) ne 'DEFAULT';
        push @return_names, @$names;
    }
    push @return_names, '' unless @return_names;
    @return_names = uniq( @return_names );
    return (defined $all_names and $all_names) ? @return_names : $return_names[0];
}

sub closest_from_values {
    my ($values, $scheme_name, $all_names, $full_name) = @_;
    # exact search first
    my @return_names = from_values( $values, $scheme_name, $all_names, $full_name );
    return ((@return_names == 1) ? $return_names[0] : \@return_names, 0)
        unless @return_names == 1 and $return_names[0] eq '';

    my @scheme_names = (ref $scheme_name eq 'ARRAY') ? (@$scheme_name)
                     : (defined $scheme_name)        ? $scheme_name : 'DEFAULT';
    @return_names = ();
    my $distance = 'Inf';
    for my $scheme_name (@scheme_names) {
        my $scheme = try_get_scheme( $scheme_name );
        next unless ref $scheme;
        my ($names, $d) = $scheme->closest_names_from_values( $values );
        $d = round_decimals($d, 5);
        next unless ref $names;
        next unless $d <= $distance;
        $distance = $d;
        $names = [ map { uc($scheme_name).':'.$_} @$names] if $full_name and uc($scheme_name) ne 'DEFAULT';
        @return_names = ($distance == $d) ? (@return_names, @$names) : (@$names);
    }
    @return_names = uniq( @return_names );
    my $name = (defined $all_names and $all_names) ? \@return_names : $return_names[0];
    return ($name, $distance);
}

#### color scheme API ##################################################
# load default scheme on RUNTIME
my %color_scheme = (DEFAULT => Graphics::Toolkit::Color::Name::Scheme->new());
my $default_names = require Graphics::Toolkit::Color::Name::Constant;
for my $color_block (@$default_names){
    $color_scheme{'DEFAULT'}->add_color( $_, [ @{$color_block->{$_}}[0,1,2] ] ) for keys %$color_block;
}

sub try_get_scheme { # auto loader
    my $scheme_name = shift // 'DEFAULT';
    $scheme_name = uc $scheme_name;
    unless (exists $color_scheme{ $scheme_name }){
        my $module_base = 'Graphics::ColorNames';
        # eval "use $module_base";
        # return "$module_base is not installed, but it's needed to load external color schemes!" if $@;
        my $module = $module_base.'::'.$scheme_name;
        eval "use $module";
        return "Perl module $module is not installed, but needed to load color scheme '$scheme_name'" if $@;
        my $palette = eval $module.'::NamesRgbTable();';
        return "Could not use Perl module $module , it seems to be damaged!" if $@ or ref $palette ne 'HASH';
        my $scheme = Graphics::Toolkit::Color::Name::Scheme->new();
        $scheme->add_color( $_, from_hex_to_rgb_tuple( $palette->{$_} ) ) for keys %$palette;
        add_scheme( $scheme, $scheme_name );
    }
    return $color_scheme{ $scheme_name };
}
sub add_scheme {
    my ($scheme, $scheme_name) = @_;
    return if ref $scheme ne 'Graphics::Toolkit::Color::Name::Scheme'
        or not defined $scheme_name or exists $color_scheme{ $scheme_name };
    $color_scheme{ uc $scheme_name } = $scheme;
}
my $rgb_max = 256;
sub from_hex_to_rgb_tuple {
    my $hex = shift;
    my $rg = int $hex / $rgb_max;
    return [ int $rg / $rgb_max, $rg % $rgb_max, $hex % $rgb_max];
}


1;
