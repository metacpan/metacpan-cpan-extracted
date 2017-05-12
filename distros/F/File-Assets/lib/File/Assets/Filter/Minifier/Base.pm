package File::Assets::Filter::Minifier::Base;

use strict;
use warnings;

use base qw/File::Assets::Filter::Minifier/;
use File::Assets::Carp;

my %minifier_package;
sub _minifier_package {
    my $class = shift;
    return $minifier_package{$class} ||= do {
        my $package = substr $class, length qq/File::Assets::Filter::Minifier::/;
        # JavaScript
        # JavaScript::XS
        # CSS
        # CSS::XS
        my @package = split m/::/, $package;
        join qw/::/, (shift @package), qw/Minifier/, @package;
    };
}

my %minifier_package_is_available;
sub _minifier_package_is_available {
    my $class = shift;
    return $minifier_package_is_available{$class} if exists $minifier_package_is_available{$class};
    my $package = $class->_minifier_package;
    return $minifier_package_is_available{$class} = eval "require $package;";
}

sub new {
    my $class = shift;
    croak "You need to install ", $class->_minifier_package, " to use this filter: $class" unless $class->_minifier_package_is_available;
    return $class->SUPER::new(@_);
}

1;
