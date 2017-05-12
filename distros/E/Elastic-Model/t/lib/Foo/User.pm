package Foo::User;

use Moose;
use Elastic::Doc;
use MooseX::Types::Moose qw(Str);
use namespace::autoclean;

#===================================
has 'name' => (
#===================================
    is  => 'rw',
    isa => Str,
);

#===================================
has 'email' => (
#===================================
    is  => 'ro',
    isa => Str,
);

#===================================
has 'lazy' => (
#===================================
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_lazy'
);

#===================================
sub _build_lazy {'lazy'}
#===================================

no Moose;

1;
