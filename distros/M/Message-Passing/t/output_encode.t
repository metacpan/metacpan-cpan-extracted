use strict;
use warnings;
use Test::More;
use Try::Tiny;

{
    package Message::MXS;
    use strict;
    use warnings;

    sub pack { { foo => "bar" } }
}

{
    package Message::LMS;
    use strict;
    use warnings;

    sub to_hash { { baz => "bar" } }
}

use Message::Passing::Output::Test;
use Message::Passing::Filter::Encoder::JSON;

my $packed;
my $test = Message::Passing::Output::Test->new(cb => sub { $packed = shift });
my $encoder = Message::Passing::Filter::Encoder::JSON->new(output_to => $test);

$encoder->consume(bless {}, 'Message::MXS');
is $packed, '{"foo":"bar"}';

$encoder->consume(bless {}, 'Message::LMS');
is $packed, '{"baz":"bar"}';

$encoder->consume('{}');
is $packed, '{}';

done_testing;

