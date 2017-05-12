package builder::MyBuilder;
use strict;
use warnings;
use 5.008001;
use parent 'Module::Build::XSUtil';

sub new {
    my ($class, %args) = @_;
    return $class->SUPER::new(
        %args,
        c_source => ['src'],
        needs_compiler_c99 => 1,
        generate_xshelper_h => "src/xshelper.h",
        generate_ppport_h => "src/ppport.h",
        extra_compiler_flags => ['-DPERL_EXT'],
    );
}

1;
