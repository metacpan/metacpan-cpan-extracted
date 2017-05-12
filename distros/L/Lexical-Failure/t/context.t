use Test::Effects;
use 5.014;
use Carp;

plan tests => 3;

use lib 'tlib';

use TestModule errors => sub {
    if (!defined wantarray) { croak "@_";    }
    elsif (!wantarray)      { return undef;  }
    else                    { return 'FAIL'; }
};

my $CROAK_LINE = __FILE__ . ' line ' . (__LINE__ + 1);
effects_ok { ; TestModule::dont_succeed() }
           { die => qr{\QDidn't succeed at $CROAK_LINE\E} }
           => 'void context should croak';

effects_ok { scalar TestModule::dont_succeed() }
           { scalar_return  => undef }
           => 'scalar context should return undef';

effects_ok { TestModule::dont_succeed() }
           { list_return  => ['FAIL'] }
           => 'list context should return one-element list';
