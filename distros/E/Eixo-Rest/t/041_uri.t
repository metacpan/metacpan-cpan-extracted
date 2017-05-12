use strict;
use Eixo::Rest::Uri;

use Test::More;

my %args = (

    name=>"foo",
    organization=>"university"
);

my ($uri, @implicit_params) = Eixo::Rest::Uri->new(

    args=>\%args,

    uri_mask=>"/organizations/:organization/users/:name"

)->build;

is($uri, "/organizations/university/users/foo", "Uri correctly formed");

is(@implicit_params, 2, "Number of implicit params is correct");


done_testing();
