use strict;
use warnings;
use Carp;
use Test::More tests => 7;
require Filter::Cleanup;

{ # import
    my $filter = Filter::Cleanup->import;
    ok($filter->isa('Filter::Cleanup'), 'import');
    ok(!$filter->{dbg}, 'import');
    ok($filter->{pad} == 0, 'import');
}

{ # _transform
    my $code = q/
        sub test {
            my $data = [];
            cleanup { push @$data, 1 };
            cleanup { push @$data, 2 };
            cleanup { push @$data, 3 };
            return $data;
        }
    /;
    
    my $filtered = Filter::Cleanup::_transform($code);
    eval $filtered;
    
    ok(!$@, '_transform');
    
    my $result = test();
    ok(ref $result eq 'ARRAY', '_transform');
    ok(scalar(@$result) == 3, '_transform');
    ok(join('', @$result) eq '321', '_transform');
}

1;