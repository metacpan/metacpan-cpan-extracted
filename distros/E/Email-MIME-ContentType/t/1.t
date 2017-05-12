# vim:ft=perl
use Test::More 'no_plan';
BEGIN { use_ok("Email::MIME::ContentType"); }

my %ct_tests = (
    '' => { type => "text", subtype => "plain",
            attributes => { charset => "us-ascii" } },

    "text/plain"   => { type => "text", subtype => "plain", attributes=>{} },
    "text/plain;"  => { type => "text", subtype => "plain", attributes=>{} },
    "text/plain; " => { type => "text", subtype => "plain", attributes=>{} },

    "application/foo" =>
        { type => "application", subtype => "foo", attributes=>{} },
    "multipart/mixed; boundary=unique-boundary-1" =>
        { type => "multipart", subtype => "mixed",
          attributes => { boundary => "unique-boundary-1" }
        },
    'message/external-body; access-type=local-file; name="/u/nsb/Me.jpeg"' =>
        { type => "message", subtype => "external-body",
          attributes => { "access-type" => "local-file",
                          "name"        => "/u/nsb/Me.jpeg" }
        },
    'multipart/mixed; boundary="----------=_1026452699-10321-0" ' => {
              'type' => 'multipart',
              'subtype' => 'mixed',
              'attributes' => {
                                'boundary' => '----------=_1026452699-10321-0'
                              }
           },
    'multipart/report; boundary= "=_0c5bb6a163fe08545fb49e4a=73e476c3-cd5a-5ba3-b910-2e1563f157b8_="' => {
            'type' => 'multipart',
            'subtype' => 'report',
            'attributes' => {
                'boundary' => '=_0c5bb6a163fe08545fb49e4a=73e476c3-cd5a-5ba3-b910-2e1563f157b8_='
            }
    },
    'multipart/report; boundary=' . " \t" . '"=_0c5bb6a163fe08545fb49e4a=73e476c3-cd5a-5ba3-b910-2e1563f157b8_="' => {
            'type' => 'multipart',
            'subtype' => 'report',
            'attributes' => {
                'boundary' => '=_0c5bb6a163fe08545fb49e4a=73e476c3-cd5a-5ba3-b910-2e1563f157b8_='
            }
    }
);

for (sort keys %ct_tests) {
    # So stupid. -- rjbs, 2013-08-10
    my $expect = $ct_tests{$_};
    $expect->{discrete}  = $expect->{type};
    $expect->{composite} = $expect->{subtype};

    is_deeply(parse_content_type($_), $ct_tests{$_}, "Can parse C-T <$_>");
}
