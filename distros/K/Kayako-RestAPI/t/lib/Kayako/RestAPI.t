#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Slurp;

BEGIN { use_ok('Kayako::RestAPI'); }

my $api_params = {
    "api_url"    => 'http://kayako.example.com/api/index.php?',
    "api_key"    => '123',
    "secret_key" => '456'
};

my $module_params = {
    content_key      => 'text',
    pretty           => 1,
    attribute_prefix => 'attr_'
};

my $kayako_api = Kayako::RestAPI->new( $api_params, $module_params );

subtest "_prepare_request" => sub {

    my $r = $kayako_api->_prepare_request;

    is $r->{'apikey'}, $api_params->{'api_key'}, "Request has api key";
    ok $r->{'signature'}, "Request has signature";
    ok $r->{'salt'},      "Request has salt";
    is length $r->{'salt'}, 10, "Salt length is 10";

};

subtest "filter_fields" => sub {

    my $a = [
        {
            'title' => { text => 'In progress' },
            'id'  => =>     { text => 1 },
            'foo' => { text => 'bar' }
        },
        {
            'title' => { text => 'Closed' },
            'id'    => { text => 3 },
            'foo'   => { text => 'baz' }
        }
    ];

    my $b = [
        {
            'title' => 'In progress',
            'id'    => 1,
        },
        {
            'title' => 'Closed',
            'id'    => 3,
        }
    ];

    is_deeply $kayako_api->filter_fields($a), $b,
      'filter_fields is working as expected';

};

# http mock
local *Kayako::RestAPI::_query = sub {
    my ( $self, $method, $route, $params ) = @_;
    my $samples = Kayako::RestAPI::_samples();
    my $sample =
      ( grep { $_->{method} eq $method && $_->{route} =~ $route } @$samples )[0]
      ->{sample_file};
    warn "Sample: " . $sample;
    return read_file( 't/lib/Kayako/samples/' . $sample );
};

subtest "get_departements" => sub {

    my $res = $kayako_api->get_departements;
    is ref($res), 'HASH', 'return hash';
    is scalar keys %$res, 4, 'scalar ok';
    ok defined( ( values %$res )[0]->{title} ), 'element has title key';

    my $expected = {
        '14' => {
            'parentdepartmentid'   => '0',
            'uservisibilitycustom' => '0',
            'module'               => 'livechat',
            'displayorder'         => '11',
            'type'                 => 'public',
            'app'                  => 'livechat',
            'title'                => 'RAID',
            'usergroups'           => '
'
        },
        '13' => {
            'usergroups' => '
',
            'title'                => 'RAID',
            'type'                 => 'public',
            'app'                  => 'tickets',
            'module'               => 'tickets',
            'uservisibilitycustom' => '0',
            'parentdepartmentid'   => '0',
            'displayorder'         => '6'
        },
        '5' => {
            'app'                  => 'tickets',
            'type'                 => 'public',
            'displayorder'         => '3',
            'module'               => 'tickets',
            'uservisibilitycustom' => '0',
            'parentdepartmentid'   => '0',
            'title'                => 'Hard drives department',
            'usergroups'           => '
'
        },
        '6' => {
            'usergroups' => '
',
            'title'                => 'Flash drives department',
            'app'                  => 'tickets',
            'type'                 => 'public',
            'displayorder'         => '4',
            'uservisibilitycustom' => '0',
            'parentdepartmentid'   => '0',
            'module'               => 'tickets'
        }
    };

    is_deeply $res, $expected, 'data is same as expected'

};

subtest "get_departements_old" => sub {

    my $res = $kayako_api->get_departements_old;
    is ref($res), 'ARRAY', 'return array';
    is scalar @$res, 4, 'scalar ok';
    ok defined $res->[0]->{id},     'element has id key';
    ok defined $res->[0]->{title},  'element has title key';
    ok defined $res->[0]->{module}, 'element has module key';

    my $expected = [
        {
            'title'  => 'Hard drives department',
            'id'     => '5',
            'module' => 'tickets'
        },
        {
            'title'  => 'Flash drives department',
            'module' => 'tickets',
            'id'     => '6'
        },
        {
            'title'  => 'RAID',
            'id'     => '13',
            'module' => 'tickets'
        },
        {
            'title'  => 'RAID',
            'module' => 'livechat',
            'id'     => '14'
        }
    ];

    # is_deeply $res, $expected, 'data is same as expected'
};

subtest "get_ticket_statuses" => sub {

    my $res = $kayako_api->get_ticket_statuses;
    is ref($res), 'HASH', 'return hash';
    is scalar keys %$res, 6, 'scalar ok';
    ok defined( ( values %$res )[0]->{title} ), 'element has title key';

    my $expected = {
        '1' => {
            'resetduetime'          => '0',
            'displayorder'          => '2',
            'staffvisibilitycustom' => '0',
            'triggersurvey'         => '0',
            'type'                  => 'public',
            'title'                 => 'In progress',
            'markasresolved'        => '0',
            'displayinmainlist'     => '0',
            'statusbgcolor'         => '#00c41d',
            'displaycount'          => '0',
            'statuscolor'           => '#000000',
            'departmentid'          => '0',
            'displayicon'           => {}
        },
        '10' => {
            'type'                  => 'public',
            'statusbgcolor'         => '#5f5f5f',
            'title'                 => 'Candidate for close',
            'markasresolved'        => '0',
            'displayinmainlist'     => '0',
            'resetduetime'          => '0',
            'displayorder'          => '3',
            'staffvisibilitycustom' => '0',
            'triggersurvey'         => '0',
            'statuscolor'           => {},
            'departmentid'          => '0',
            'displayicon'           => {},
            'displaycount'          => '0'
        },
        '9' => {
            'displaycount' => '1',
            'statuscolor'  => {},
            'departmentid' => '0',
            'displayicon' =>
'http://ts.acelaboratory.com/__swift/files/file_uw8cs2d09hfwl2f.png',
            'resetduetime'          => '0',
            'displayorder'          => '2',
            'staffvisibilitycustom' => '0',
            'triggersurvey'         => '0',
            'type'                  => 'public',
            'title'                 => 'Awaiting reply from customer',
            'statusbgcolor'         => '#243eff',
            'displayinmainlist'     => '0',
            'markasresolved'        => '0'
        },
        '3' => {
            'displayicon' =>
'http://ts.acelaboratory.com/__swift/files/file_yo47r8tff1vwu8v.png',
            'departmentid'          => '0',
            'statuscolor'           => '#000000',
            'displaycount'          => '0',
            'markasresolved'        => '1',
            'title'                 => 'Closed',
            'displayinmainlist'     => '0',
            'statusbgcolor'         => '#16bd00',
            'type'                  => 'public',
            'triggersurvey'         => '1',
            'staffvisibilitycustom' => '0',
            'displayorder'          => '3',
            'resetduetime'          => '0'
        },
        '4' => {
            'displayorder'          => '1',
            'resetduetime'          => '0',
            'triggersurvey'         => '0',
            'staffvisibilitycustom' => '0',
            'type'                  => 'public',
            'markasresolved'        => '0',
            'displayinmainlist'     => '0',
            'title'                 => 'New',
            'statusbgcolor'         => '#ff0022',
            'displaycount'          => '0',
            'statuscolor'           => '#000000',
            'displayicon'           => {},
            'departmentid'          => '0'
        },
        '11' => {
            'resetduetime'          => '0',
            'displayorder'          => '4',
            'staffvisibilitycustom' => '0',
            'triggersurvey'         => '0',
            'type'                  => 'public',
            'displayinmainlist'     => '0',
            'title'                 => 'Awaiting new feature',
            'statusbgcolor'         => '#5f5f5f',
            'markasresolved'        => '0',
            'displaycount'          => '0',
            'statuscolor'           => {},
            'displayicon'           => {},
            'departmentid'          => '0'
        }
    };

    is_deeply $res, $expected, 'data is same as expected';
};

subtest "get_ticket_statuses_old" => sub {
    my $res = $kayako_api->get_ticket_statuses_old;

    # warn Dumper $res;
    is ref($res), 'ARRAY', 'return array';
    ok defined $res->[0]->{id},    'element has id key';
    ok defined $res->[0]->{title}, 'element has title key';
    my $expected = [
        {
            'id'    => '1',
            'title' => 'In progress'
        },
        {
            'title' => 'Closed',
            'id'    => '3'
        },
        {
            'title' => 'New',
            'id'    => '4'
        },
        {
            'title' => 'Awaiting reply from customer',
            'id'    => '9'
        },
        {
            'title' => 'Candidate for close',
            'id'    => '10'
        },
        {
            'id'    => '11',
            'title' => 'Awaiting new feature'
        }
    ];

# is_deeply $res, $expected, 'data is same as expected'        is_deeply $res, $expected, 'data is same as expected'
};

subtest "get_ticket_priorities" => sub {

    my $res = $kayako_api->get_ticket_priorities;
    is ref($res), 'HASH', 'return hash';
    is scalar keys %$res, 3, 'scalar ok';
    ok defined( ( values %$res )[0]->{title} ), 'element has title key';

    my $expected = {
        '1' => {
            'type'                 => 'public',
            'frcolorcode'          => '#45991c',
            'bgcolorcode'          => {},
            'uservisibilitycustom' => '0',
            'displayorder'         => '1',
            'title'                => 'Normal'
        },
        '3' => {
            'title'                => 'Urgent',
            'displayorder'         => '2',
            'frcolorcode'          => '#000000',
            'type'                 => 'public',
            'uservisibilitycustom' => '0',
            'bgcolorcode'          => '#ff9d00'
        },
        '6' => {
            'title'                => 'CRITICAL',
            'displayorder'         => '3',
            'type'                 => 'public',
            'frcolorcode'          => '#ffffff',
            'bgcolorcode'          => '#d6000e',
            'uservisibilitycustom' => '0'
        }
    };

    is_deeply $res, $expected, 'data is same as expected';
};

subtest "get_ticket_priorities_old" => sub {
    my $res = $kayako_api->get_ticket_priorities_old;
    is ref($res), 'ARRAY', 'return array';
    ok defined $res->[0]->{id},    'element has id key';
    ok defined $res->[0]->{title}, 'element has title key';
    my $expected = [
        {
            'id'    => '1',
            'title' => 'Normal'
        },
        {
            'title' => 'Urgent',
            'id'    => '3'
        },
        {
            'id'    => '6',
            'title' => 'CRITICAL'
        }
    ];

    # is_deeply $res, $expected, 'data is same as expected';
};

subtest "get_ticket_types" => sub {

    my $res = $kayako_api->get_ticket_types;
    is ref($res), 'HASH', 'return hash';
    is scalar keys %$res, 3, 'scalar ok';
    ok defined( ( values %$res )[0]->{title} ), 'element has title key';

    my $expected = {
        '3' => {
            'uservisibilitycustom' => '0',
            'title'                => 'Bug',
            'type'                 => 'public',
            'displayicon'          => '{$themepath}icon_typebug.gif',
            'departmentid'         => '0',
            'displayorder'         => '3'
        },
        '5' => {
            'uservisibilitycustom' => '0',
            'type'                 => 'public',
            'title'                => 'Feedback',
            'displayicon'          => '{$themepath}icon_lightbulb.png',
            'displayorder'         => '5',
            'departmentid'         => '0'
        },
        '1' => {
            'displayicon'          => '{$themepath}icon_typeissue.gif',
            'departmentid'         => '0',
            'displayorder'         => '1',
            'uservisibilitycustom' => '0',
            'title'                => 'Case',
            'type'                 => 'public'
        }
    };

    is_deeply $res, $expected, 'data is same as expected';

};

subtest "get_ticket_types_old" => sub {
    my $res = $kayako_api->get_ticket_types_old;
    is ref($res), 'ARRAY', 'return array';
    ok defined $res->[0]->{id},    'element has id key';
    ok defined $res->[0]->{title}, 'element has title key';
    my $expected = [
        {
            'id'    => '1',
            'title' => 'Case'
        },
        {
            'title' => 'Bug',
            'id'    => '3'
        },
        {
            'title' => 'Feedback',
            'id'    => '5'
        }
    ];

    # is_deeply $res, $expected, 'data is same as expected';
};

subtest "get_staff" => sub {

    my $res = $kayako_api->get_staff;
    is ref($res), 'HASH', 'return hash';
    is scalar keys %$res, 4, 'scalar ok';

    # ok defined ((values %$res)[0]->{{lastname}), 'element has lastname key';
    # ok defined ((values %$res)[0]->{{fullname}), 'element has fullname key';

    # is_deeply $res, $expected, 'data is same as expected';

};

subtest "get_staff_old" => sub {
    my $res = $kayako_api->get_staff_old;
    is ref($res), 'ARRAY', 'return array';

    # ok defined $res->[0]->{id}, 'element has id key';
    # ok defined $res->[0]->{lastname}, 'element has lastname key';
    # ok defined $res->[0]->{fullname}, 'element has fullname key';
    # ok defined $res->[0]->{email}, 'element has email key';

    # ok defined $res->[0]->{id}{ $module_params->{content_key} };
    # ok defined $res->[0]->{lastname}{ $module_params->{content_key} };
    # ok defined $res->[0]->{fullname}{ $module_params->{content_key} };
    # ok defined $res->[0]->{email}{ $module_params->{content_key} };

};

subtest "get_ticket_hash" => sub {

    my $res = $kayako_api->get_ticket_hash(1000);
    use Data::Dumper;
    is ref($res), 'HASH', 'return hash';

    # attr_id and attr_flag type removed
    my @keys = qw/
      statusid
      lastactivity
      lastuserreply
      userorganization
      templategroupid
      templategroupname
      posts
      userid
      laststaffreply
      ownerstaffid
      creator
      nextreplydue
      creationmode
      departmentid
      fullname
      note
      ipaddress
      slaplanid
      replies
      priorityid
      tags
      typeid
      ownerstaffname
      escalationruleid
      creationtype
      email
      isescalated
      subject
      userorganizationid
      resolutiondue
      displayid
      creationtime
      lastreplier
      /;

    for my $k (@keys) {
        ok defined $res->{$k}, "element has $k key";
    }

    # is_deeply $res, $expected, 'data is same as expected';

};

subtest "xml2obj" => sub {
    my @good_files = map { $_->{sample_file} } @{ $kayako_api->_samples };

    for my $f (@good_files) {
        my $xml = read_file( 't/lib/Kayako/samples/' . $f );
        lives_ok { $kayako_api->xml2obj($xml) } "$f - live";
    }

    my @bad_files = (
        { file => 'empty.xml', error => "Document is empty\n" },
        { file => 'bad.xml',   error => "StartTag: invalid element name\n" },

  # { file => 'text.xml', error => "data source Hello world not found in .\n" },
  # { file => 'html.xml', error => "1" },
    );

    for my $i (@bad_files) {
        my $xml = read_file( 't/lib/Kayako/samples/' . $i->{file} );

        # # my $last_error_msg;
        # local $SIG{__DIE__} = sub {
        #     if (ref $_[0] eq 'XML::LibXML::Error') {
        #         $last_error_msg = $_[0]->message();
        #     }
        #     # else {
        #     #     warn "Message: ".$_[0];
        #     #     warn "Ref: ".ref $_[0];
        #     # }
        # };

        dies_ok { $kayako_api->xml2obj($xml) } $i->{file} . '- dies ok';

# throws_ok { $kayako_api->xml2obj($xml) } 'XML::LibXML::Error', $i->{file}.' XML::LibXML::Error thrown';
# warn $last_error_msg;
# is $last_error_msg, $i->{error}, $i->{file}." error msg ok";

        # warn Dumper $kayako_api->xml2obj($xml);
    }

# quick check
# warn Dumper $kayako_api->xml2obj( read_file( 't/lib/Kayako/samples/text.xml' ) );
};

# use Data::Dumper;
# subtest "get_ticket_hash_old" => sub {
#
# my @keys = qw/
#     statusid
#     lastactivity
#     lastuserreply
#     userorganization
#     templategroupid
#     templategroupname
#     posts
#     userid
#     laststaffreply
#     ownerstaffid
#     creator
#     nextreplydue
#     creationmode
#     departmentid
#     fullname
#     note
#     ipaddress
#     slaplanid
#     replies
#     priorityid
#     tags
#     attr_id
#     typeid
#     attr_flagtype
#     ownerstaffname
#     escalationruleid
#     creationtype
#     email
#     isescalated
#     subject
#     userorganizationid
#     resolutiondue
#     displayid
#     creationtime
#     lastreplier
# /;
#     my $res = $kayako_api->get_ticket_hash(1000);
#     for my $k (@keys) {
#         ok defined $res->{$k}, "element has $k key";
#     }
# };

done_testing;
