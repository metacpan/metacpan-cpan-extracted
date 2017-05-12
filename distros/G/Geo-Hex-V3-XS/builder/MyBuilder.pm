package builder::MyBuilder;
use strict;
use warnings;
use parent qw/Module::Build::XSUtil/;

use Cwd::Guard ();
use File::Spec;
use File::Which;

sub new {
    my ($self, %args) = @_;

    if ( $^O =~ m!(?:MSWin32|cygwin)! ) {
        print "This module does not support Windows.\n";
        exit 0;
    }

    unless (which 'cmake') {
        print "This module require cmake.\n";
        exit 0;
    }

    $args{extra_compiler_flags} = ['-std=gnu99', '-fPIC', '-I' . File::Spec->rel2abs(File::Spec->catdir('deps', 'c-geohex3', 'local', 'include'))];
    $args{extra_linker_flags}   = [File::Spec->rel2abs(File::Spec->catdir('deps', 'c-geohex3', 'local', 'lib', 'libgeohex3.a'))];

    return $self->SUPER::new(%args);
}

sub ACTION_code {
    my $self = shift;

    {
        my $guard = Cwd::Guard::cwd_guard(File::Spec->catdir('deps', 'c-geohex3'));
        system('cmake', '-DCMAKE_INSTALL_PREFIX=local', '.') == 0 or die;
        system('make') == 0 or die;
        system('make', 'install') == 0 or die;
    }

    return $self->SUPER::ACTION_code(@_);
}

1;
