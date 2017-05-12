package builder::MyBuilder;
use strict;
use warnings;
use 5.008001;
use base 'Module::Build::XSUtil';

sub new {
    my ( $class, %args ) = @_;
    my $self = $class->SUPER::new(
        %args,
        c_source => 'xs-src',
        xs_files => {
            './xs-src/UtilsBy.xs' => './lib/List/UtilsBy/XS.xs',
        },
        generate_ppport_h  => 'lib/List/UtilsBy/ppport.h',
        extra_compiler_flags => ['-DPERL_EXT'],
        needs_compiler_c99 => 1,
    );
    return $self;
}

1;
