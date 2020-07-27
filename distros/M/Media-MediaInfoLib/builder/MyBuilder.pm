package builder::MyBuilder;
use 5.008_001;
use strict;
use warnings;
use parent 'Module::Build';

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);

    my $cflags = `pkg-config libmediainfo --cflags`;
    $? and die '`pkg-config libmediainfo --cflags` returned an error';
    chomp $cflags;

    my $libs = `pkg-config libmediainfo --libs`;
    $? and die '`pkg-config libmediainfo --libs` returned an error';
    chomp $libs;

    $self->log_verbose("cflags: $cflags\n");
    $self->log_verbose("libs: $libs\n");
    my @compiler_flags = (qw/-I. -x c++/, split /\s+/, $cflags);
    $self->extra_compiler_flags(@compiler_flags);
    my @linker_flags = split /\s+/, $libs;
    $self->extra_linker_flags(@linker_flags);

    if ($self->is_debug) {
        $self->config(optimize => '-g -O0');
        $self->extra_compiler_flags(@compiler_flags, qw/
            -Wall -Wextra -Wno-parentheses
            -Wno-unused -Wno-unused-parameter
        /);
    }
    $self;
}

sub compile_xs {
    my ($self, $file, %args) = @_;
    require ExtUtils::ParseXS;
    $self->log_verbose("$file -> $args{outfile}\n");
    ExtUtils::ParseXS::process_file(
        filename   => $file,
        prototypes => 0,
        output     => $args{outfile},
        'C++'      => 1,
        hiertype   => 1,
    );
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
