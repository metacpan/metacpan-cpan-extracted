package # hidden from search.cpan.org
    MyTestBase;

use strict;
use warnings;
use Test::Base -Base;

package MyTestBase::Filter;

use strict;
use warnings;

use Test::Base::Filter -base;

sub yaml {
    $self->assert_scalar(@_);
    require YAML::Syck;

    local $YAML::Syck::ImplicitUnicode = 1;
    return YAML::Syck::Load(shift);
}

sub yaml_bytes {
    $self->assert_scalar(@_);
    require YAML::Syck;

    return YAML::Syck::Load(shift);
}

1;
