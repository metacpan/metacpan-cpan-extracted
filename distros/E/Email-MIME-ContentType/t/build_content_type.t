# vim:ft=perl
use strict;
use warnings;

use Test::More 'no_plan';
BEGIN { use_ok('Email::MIME::ContentType'); }

my %ct_tests = (
    'text/plain' => { type => 'text', subtype => 'plain', attributes => {} },
    'text/plain; charset=us-ascii' => { type => 'text', subtype => 'plain', attributes => { charset => 'us-ascii' } },
    'text/plain; charset=ISO-8859-1' => { type => 'text', subtype => 'plain', attributes => { charset => 'ISO-8859-1' } },
    'text/plain; charset=us-ascii; format=flowed' => { type => 'text', subtype => 'plain', attributes => { charset => 'us-ascii', format => 'flowed' } },
    'application/foo' => { type => 'application', subtype => 'foo', attributes => {} },
    'multipart/mixed; boundary=unique-boundary-1' => { type => 'multipart', subtype => 'mixed', attributes => { boundary => 'unique-boundary-1' } },

    'message/external-body; access-type=local-file; name="/u/nsb/Me.jpeg"' => {
            type => 'message',
            subtype => 'external-body',
            attributes => {
                'access-type' => 'local-file',
                'name'        => '/u/nsb/Me.jpeg'
            }
    },
    'multipart/mixed; boundary="----------=_1026452699-10321-0"' => {
            'type' => 'multipart',
            'subtype' => 'mixed',
            'attributes' => {
                'boundary' => '----------=_1026452699-10321-0'
            }
    },
    'multipart/report; boundary="=_0c5bb6a163fe08545fb49e4a=73e476c3-cd5a-5ba3-b910-2e1563f157b8_="' => {
            'type' => 'multipart',
            'subtype' => 'report',
            'attributes' => {
                'boundary' => '=_0c5bb6a163fe08545fb49e4a=73e476c3-cd5a-5ba3-b910-2e1563f157b8_='
            }
    },

    'message/external-body; access-type=URL; url="ftp://cs.utk.edu/pub/moore/bulk-mailer/looooooooooong/bulk-mailer.tar"' => {
            'type' => 'message',
            'subtype' => 'external-body',
            'attributes' => {
                'access-type' => 'URL',
                'url' => 'ftp://cs.utk.edu/pub/moore/bulk-mailer/looooooooooong/bulk-mailer.tar',
            }
    },
    q(message/external-body; access-type=URL; url*0="ftp://cs.utk.edu/pub/moore/bulk-mailer/looooooooooooong/bulk-mailer."; url*1="tar"; url="ftp://cs.utk.edu/pub/moore/bulk-mailer/looooooooooooong/bulk-mailer...") => {
            'type' => 'message',
            'subtype' => 'external-body',
            'attributes' => {
                'access-type' => 'URL',
                'url' => 'ftp://cs.utk.edu/pub/moore/bulk-mailer/looooooooooooong/bulk-mailer.tar',
            }
    },
    'message/external-body; access-type=URL; url="ftp://cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar"' => {
            'type' => 'message',
            'subtype' => 'external-body',
            'attributes' => {
                'access-type' => 'URL',
                'url' => 'ftp://cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar',
            }
    },

    q(application/x-stuff; title*=UTF-8''This%20is%20%2A%2A%2Afun%2A%2A%2A%20%C2%A9; title="This is ***fun*** (c)") => {
            'type' => 'application',
            'subtype' => 'x-stuff',
            'attributes' => {
                'title' => "This is ***fun*** \N{U+A9}"
            }
    },

    q(application/x-stuff; title*0*=UTF-8''This%20is%20even%20more%20%2A%2A%2Afun%2A%2A%2A%20%C2%A9%20i; title*1*=sn%27t%20it!; title="This is even more ***fun*** (c) isn't it!") => {
            'type' => 'application',
            'subtype' => 'x-stuff',
            'attributes' => {
                'title' => "This is even more ***fun*** \N{U+A9} isn't it!"
            }
    },

    'text/plain; attribute="value\"value\\\\value(value><)@,;:/][?=value value"; charset=us-ascii' => {
            'type' => 'text',
            'subtype' => 'plain',
            'attributes' => {
                'attribute' => 'value"value\\value(value><)@,;:/][?=value value',
                'charset' => 'us-ascii',
            },
    },

);

sub test {
    my ($expect, $struct) = @_;
    local $_;
    my $info = $expect;
    $info =~ s/\r/\\r/g;
    $info =~ s/\n/\\n/g;
    my $got = build_content_type($struct);
    is($got, $expect, "Can build C-T <$info>");
    my $parsed = parse_content_type($got);
    delete $parsed->{discrete};
    delete $parsed->{composite};
    is_deeply($parsed, $struct, "Can parse C-T <$info>");
}

for (sort keys %ct_tests) {
    test($_, $ct_tests{$_});
}
