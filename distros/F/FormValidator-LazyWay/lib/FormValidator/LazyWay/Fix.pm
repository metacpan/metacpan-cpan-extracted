package FormValidator::LazyWay::Fix;

use strict;
use warnings;
use Carp;
use UNIVERSAL::require;
use base qw/FormValidator::LazyWay::Setting/;
__PACKAGE__->mk_accessors(qw/self name/);

sub init {
    my $self = shift;
    $self->self(__PACKAGE__);
    $self->name('fix');
}

1;
