# vim:ft=perl
use Test::More 'no_plan';
BEGIN { use_ok("Email::MIME::ContentType"); }

my %ct_tests = (
    '' => { type => "text", subtype => "plain",
            attributes => { charset => "us-ascii" } },

    "text/plain"   => { type => "text", subtype => "plain", attributes=>{} },

    'text/plain; charset=us-ascii'               => { type => "text", subtype => "plain", attributes => { charset => "us-ascii" } },
    'text/plain; charset="us-ascii"'             => { type => "text", subtype => "plain", attributes => { charset => "us-ascii" } },
    "text/plain; charset=us-ascii (Plain text)"  => { type => "text", subtype => "plain", attributes => { charset => "us-ascii" } },

    'text/plain; charset=ISO-8859-1'             => { type => "text", subtype => "plain", attributes => { charset => "ISO-8859-1" } },
    'text/plain; charset="ISO-8859-1"'           => { type => "text", subtype => "plain", attributes => { charset => "ISO-8859-1" } },
    'text/plain; charset="ISO-8859-1" (comment)' => { type => "text", subtype => "plain", attributes => { charset => "ISO-8859-1" } },

    '(comment) text/plain (comment); (comment) charset=ISO-8859-1 (comment)' => { type => "text", subtype => "plain", attributes => { charset => "ISO-8859-1" } },
    '(comment \( \\\\) (comment) text/plain (comment) (comment) ; (comment) (comment) charset=ISO-8859-1 (comment)' => { type => "text", subtype => "plain", attributes => { charset => "ISO-8859-1" } },
    'text/plain; (comment (nested ()comment)another comment)() charset=ISO-8859-1' => { type => "text", subtype => "plain", attributes => { charset => "ISO-8859-1" } },
    'text/plain (comment \(not nested ()comment\)\)(nested\(comment())); charset=ISO-8859-1' => { type => "text", subtype => "plain", attributes => { charset => "ISO-8859-1" } },

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
    },

    'message/external-body; access-type=URL; URL*0="ftp://"; URL*1="cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar"' => {
            'type' => 'message',
            'subtype' => 'external-body',
            'attributes' => {
                'access-type' => 'URL',
                'url' => 'ftp://cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar',
            }
    },
    'message/external-body; access-type=URL; URL="ftp://cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar"' => {
            'type' => 'message',
            'subtype' => 'external-body',
            'attributes' => {
                'access-type' => 'URL',
                'url' => 'ftp://cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar',
            }
    },

    "application/x-stuff; title*=us-ascii'en-us'This%20is%20%2A%2A%2Afun%2A%2A%2A" => {
            'type' => 'application',
            'subtype' => 'x-stuff',
            'attributes' => {
                'title' => 'This is ***fun***'
            }
    },
    "application/x-stuff; title*=us-ascii''This%20is%20%2A%2A%2Afun%2A%2A%2A" => {
            'type' => 'application',
            'subtype' => 'x-stuff',
            'attributes' => {
                'title' => 'This is ***fun***'
            }
    },
    "application/x-stuff; title*=''This%20is%20%2A%2A%2Afun%2A%2A%2A" => {
            'type' => 'application',
            'subtype' => 'x-stuff',
            'attributes' => {
                'title' => 'This is ***fun***'
            }
    },
    "application/x-stuff; title*='en-us'This%20is%20%2A%2A%2Afun%2A%2A%2A" => {
            'type' => 'application',
            'subtype' => 'x-stuff',
            'attributes' => {
                'title' => 'This is ***fun***'
            }
    },

    q(application/x-stuff; title*0*=us-ascii'en'This%20is%20even%20more%20; title*1*=%2A%2A%2Afun%2A%2A%2A%20; title*2="isn't it!") => {
            'type' => 'application',
            'subtype' => 'x-stuff',
            'attributes' => {
                'title' => "This is even more ***fun*** isn't it!"
            }
    },
    q(application/x-stuff; title*0*='en'This%20is%20even%20more%20; title*1*=%2A%2A%2Afun%2A%2A%2A%20; title*2="isn't it!") => {
            'type' => 'application',
            'subtype' => 'x-stuff',
            'attributes' => {
                'title' => "This is even more ***fun*** isn't it!"
            }
    },
    q(application/x-stuff; title*0*=''This%20is%20even%20more%20; title*1*=%2A%2A%2Afun%2A%2A%2A%20; title*2="isn't it!") => {
            'type' => 'application',
            'subtype' => 'x-stuff',
            'attributes' => {
                'title' => "This is even more ***fun*** isn't it!"
            }
    },
    q(application/x-stuff; title*0*=us-ascii''This%20is%20even%20more%20; title*1*=%2A%2A%2Afun%2A%2A%2A%20; title*2="isn't it!") => {
            'type' => 'application',
            'subtype' => 'x-stuff',
            'attributes' => {
                'title' => "This is even more ***fun*** isn't it!"
            }
    },

    'text/plain; attribute="value\"value\\\\value\(value\>\<\)\@\,\;\:\/\]\[\?\=value value"; charset=us-ascii' => {
            'type' => 'text',
            'subtype' => 'plain',
            'attributes' => {
                'attribute' => 'value"value\\value(value><)@,;:/][?=value value',
                'charset' => 'us-ascii',
            },
    },
);

my %non_strict_ct_tests = (
    "text/plain;"  => { type => "text", subtype => "plain", attributes=>{} },
    "text/plain; " => { type => "text", subtype => "plain", attributes=>{} },
    'image/jpeg; x-mac-type="3F3F3F3F"; x-mac-creator="3F3F3F3F" name="file name.jpg";' => { type => "image", subtype => "jpeg", attributes => { 'x-mac-type' => "3F3F3F3F", 'x-mac-creator' => "3F3F3F3F", 'name' => "file name.jpg" } },
    "text/plain; key=very long value" => { type => "text", subtype => "plain", attributes => { key => "very long value" } },
    "text/plain; key=very long value key2=value2" => { type => "text", subtype => "plain", attributes => { key => "very long value", key2 => "value2" } },
    'multipart/mixed; boundary = "--=_Next_Part_24_Nov_2016_08.09.21"' => { type => "multipart", subtype => "mixed", attributes => { boundary => "--=_Next_Part_24_Nov_2016_08.09.21" } },
);

sub test {
    my ($string, $expect, $info) = @_;
    # So stupid. -- rjbs, 2013-08-10
    $expect->{discrete}  = $expect->{type};
    $expect->{composite} = $expect->{subtype};

    local $_;
    is_deeply(parse_content_type($string), $expect, $info);
}

for (sort keys %ct_tests) {
    test($_, $ct_tests{$_}, "Can parse C-T <$_>");
}

local $Email::MIME::ContentType::STRICT_PARAMS = 0;
for (sort keys %ct_tests) {
    test($_, $ct_tests{$_}, "Can parse non-strict C-T <$_>");
}
for (sort keys %non_strict_ct_tests) {
    test($_, $non_strict_ct_tests{$_}, "Can parse non-strict C-T <$_>");
}
