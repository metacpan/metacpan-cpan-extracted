package builder::MyBuilder;
use 5.008_001;
use strict;
use warnings;
use parent 'Module::Build';

use Config;
use Devel::CheckLib;

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);

    check_lib(
        lib    => 'mp4v2',
        header => 'mp4v2/mp4v2.h',
    ) or die $@;
    $self->extra_linker_flags('-lmp4v2');
    $self->extra_compiler_flags('-I.');

    if ($self->is_debug) {
        $self->config(optimize => '-g -O0');
        $self->extra_compiler_flags(qw/
            -I. -Wall -Wextra -Wno-parentheses
            -Wno-unused -Wno-unused-parameter
        /);
    }
    $self;
}

sub is_debug {
    -d '.git';
}

sub ACTION_build {
    my $self = shift;
    $self->ACTION_ppport_h() unless -e 'ppport.h';
    $self->SUPER::ACTION_build();
}

sub ACTION_ppport_h {
    require Devel::PPPort;
    Devel::PPPort::WriteFile('ppport.h');
}

1;
__END__
