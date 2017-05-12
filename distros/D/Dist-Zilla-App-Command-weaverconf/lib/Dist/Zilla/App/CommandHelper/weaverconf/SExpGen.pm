package # no indexing, please
    Dist::Zilla::App::CommandHelper::weaverconf::SExpGen;

use Moose;
use namespace::autoclean;

extends 'Data::Visitor';

sub visit_value {
    my ($self, $value) = @_;
    return qq{'$value};
}

override visit_normal_hash => sub {
    my ($self) = @_;
    my $ret = super;

    return sprintf q{(list %s)},
        join(q{ },
                map { sprintf "%s %s", $_, $ret->{$_} } keys %$ret
            );
};

override visit_normal_array => sub {
    my ($self) = @_;
    return sprintf q{(list %s)}, join(q{ }, super);
};

1;
