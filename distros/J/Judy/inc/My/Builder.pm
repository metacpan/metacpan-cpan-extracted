package My::Builder;

use strict;
use warnings;
use vars qw( @ISA );
use Config ();
use File::Spec;

use Module::Build;
@ISA = 'Module::Build';

my @actions =
    grep { /^ACTION_\w+\z/ && $_ ne 'ACTION_config_data' }
    keys %Module::Build::Base::;

my $new_actions_src = '';
for my $action ( @actions ) {
    my $src = qq{
        sub $action {
            my \$self = shift \@_;

            \$self->update_inc_lib_dirs();

            return \$self->SUPER::$action( \@_ );
        }
    };
    $new_actions_src .= $src;
}
$new_actions_src .= "1;\n";
eval $new_actions_src
    or do {
        print STDERR $new_actions_src;
        die $@;
    };

sub update_inc_lib_dirs {
    my ( $self ) = @_;

    my $action = $self->current_action();

    # Update include_dirs and extra_linker_flags to find the Judy.h
    # that's come while provided by installing Alien::Judy. 
    my @all_dirs = unique(
        '.',
        (
            map {
                my $judy_dir = File::Spec->catdir( $_, 'Alien', 'Judy' );
                ( $_, $judy_dir );
            }
            @Config::Config{qw( sitearchexp sitearch )},
            @INC
        )
    );

    my @old_include_dirs = @{ $self->include_dirs() || [] };
    my @new_include_dirs = unique(
        @old_include_dirs,
        grep {
               -e File::Spec->catfile( $_, 'Judy.h' )
            || -e File::Spec->catfile( $_, 'pjudy.h' )
            || -e File::Spec->catfile( $_, 'ppport.h' )
        }
        @all_dirs
    );
    if ( "@old_include_dirs" ne "@new_include_dirs" ) {
        local $" = q{', '};
        print "$action: include_dirs='@{new_include_dirs}'\n";
    }
    if ( ! @new_include_dirs ) {
        @new_include_dirs = ( @old_include_dirs, @all_dirs );
        local $" = q{', '};
        print "$action: I couldn't find Judy.h in any of the below listed places.\n";
        print "$action: include_dirs='@{new_include_dirs}'\n";
    }
    $self->{properties}{include_dirs} = \ @new_include_dirs;


    my @old_extra_linker_flags = @{ $self->extra_linker_flags() || [] };
    my @new_extra_linker_flags = unique(
        (
            map { "-L$_" }
            @all_dirs
        ),
        '-lJudy',
    );
    if ( "@old_extra_linker_flags" ne "@new_extra_linker_flags" ) {
        local $" = q{', '};
        print "$action: extra_linker_flags='@{new_extra_linker_flags}'\n";
    }
    if ( ! grep { /^-L/ } @new_extra_linker_flags ) {
        @new_extra_linker_flags = unique(
            (
                map { "-L$_" }
                @all_dirs
            ),
            '-lJudy'
        );
        local $" = q{', '};
        print "$action: I couldn't resolve -lJudy in any of the below listed places.\n";
        print "$action: extra_linker_flags='@{new_extra_linker_flags}'\n";
    }
    $self->{properties}{extra_linker_flags} = \ @new_extra_linker_flags;


    $self->dispatch( 'config_data' );
}

sub unique {
    my %seen;
    return
        grep { ! $seen{$_}++ }
        @_;
}

1;
