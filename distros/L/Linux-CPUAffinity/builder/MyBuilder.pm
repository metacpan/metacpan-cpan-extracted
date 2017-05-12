package builder::MyBuilder;
use 5.008_001;
use strict;
use warnings;
use parent 'Module::Build';

use Config;

sub new {
    my ($class, %args) = @_;
    unless ($^O eq 'linux' && $Config{osvers} ge '2.5.8') {
        print "This module only support linux >= 2.5.8.\n";
        exit;
    }
    my $self = $class->SUPER::new(%args);
    my @extra_compiler_flags = qw(
        -I.
        -Wall -Wextra -Wno-duplicate-decl-specifier -Wno-parentheses
        -Wno-unused -Wno-unused-parameter
    );
    if ($self->is_debug) {
        $self->config(optimize => '-g -O0');
    }
    $self->extra_compiler_flags(@extra_compiler_flags);
    $self;
}

sub is_debug {
    -d '.git';
}

1;
__END__
