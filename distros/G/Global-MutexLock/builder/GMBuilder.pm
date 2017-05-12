package builder::GMBuilder;
use strict;
use warnings;
use parent qw(Module::Build);

sub new {
    my ($class, %args) = @_;
    $class->SUPER::new(%args,
        config => { cc => 'gcc -pthread' },
    );
}

1;
