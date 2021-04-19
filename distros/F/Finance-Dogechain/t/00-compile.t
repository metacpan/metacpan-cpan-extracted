use strict;
use warnings;

use Test::More;
use lib 'lib';

use File::Find;

sub main {
    for my $module ( get_modules() ) {
        use_ok( $module ) or BAIL_OUT("Could not load $module");
    }

    done_testing;
    return 0;
}

sub get_modules {
    my @modules;

    my $find_pm_files = sub {
        return unless /\.pm$/;
        return if /\.svn/;
        push @modules, path_to_pm_name( $File::Find::name );
    };

    find( $find_pm_files, 'lib' );

    return @modules;
}

sub path_to_pm_name {
    my $name = shift;

    $name    =~ s{lib/}{};
    $name    =~ s{.pm}{};
    $name    =~ s{/}{::}g;

    return $name;
}

# Do this in a BEGIN block to ensure that anything which might inadvertently
# use prototypes (directly or not) does so in the compile phase.
BEGIN { exit main( @ARGV ); }
