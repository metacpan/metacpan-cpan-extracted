
# bridge to Graphics::ColorNames::* modules

package Graphics::Toolkit::Color::Name::Scheme;
use v5.12;
use warnings;

sub rgb_from_name { #
    my ( $scheme_name, $color_name ) = @_;
    return "need scheme name and color name as arguments" unless defined $scheme_name and defined $color_name;
    my $module_base = 'Graphics::ColorNames';
    eval "use $module_base";
    return "$module_base is not installed, but it's needed to load external colors" if $@;
    my $module = $module_base.'::'.$scheme_name;
    eval "use $module";
    return "$module is not installed, but needed to load color '$scheme_name:$color_name'" if $@;
    my $scheme = Graphics::ColorNames->new( $scheme_name );
    my @rgb = $scheme->rgb( $color_name );
    return "color '$color_name' was not found, propably not part of $module" unless @rgb == 3;
    return \@rgb;
}

1;
