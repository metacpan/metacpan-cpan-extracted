package Linux::Perl::X::Call;

use strict;
use warnings;

use parent 'Linux::Perl::X::Base';

sub _new {
    my ($class, $num, $error) = @_;

    return $class->SUPER::_new("System call $num failed: $error");
}

1;
