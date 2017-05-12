use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;
use JSON 2 qw/decode_json/;

subtest 'prep_param' => sub {
    my $fb = Facebook::OpenGraph->new;

    # https://developers.facebook.com/docs/opengraph/using-object-api/
    my $object = +{
        title       => "The Hunt for Red October",
        image       => "http://ecx.images-amazon.com/images/I/314leP6WviL._SL500_AA300_.jpg",
        url         => "https://link.you.want.displayed/example/hunt-for-red-october-link",
        description => "Classic cold war technothriller",
        data        =>  +{ isbn => 425240339 },
    };

    my $param_ref = $fb->prep_param(+{
        ids         => [qw|4 oklahomer.docs http://facebook-docs.oklahome.net/|],
        permissions => [qw|email publish_actions|],
        source      => '/path/to/pic.png',
        fields      => [qw/email albums/],
        object      => $object,
    });

    is $param_ref->{ids}, '4,oklahomer.docs,http://facebook-docs.oklahome.net/', 'ids';
    is $param_ref->{permissions}, 'email,publish_actions', 'permission';
    is_deeply $param_ref->{source}, [qw|/path/to/pic.png|], 'source';
    is $param_ref->{fields}, 'email,albums', 'fields';
    is_deeply decode_json($param_ref->{object}), $object, 'object';
};

done_testing;
