# vim:ft=perl
use strict;
use warnings;

use Test::More 'no_plan';
use Email::MIME::ContentType;

my @ct_tests = (
  {
    expect  => 'text/plain',
    input   => { type => 'text', subtype => 'plain', attributes => {} },
  },

  {
    expect  => 'text/plain; charset=us-ascii',
    input   => { type => 'text', subtype => 'plain', attributes => { charset => 'us-ascii' } },
  },

  {
    expect  => 'text/plain; charset=ISO-8859-1',
    input   => { type => 'text', subtype => 'plain', attributes => { charset => 'ISO-8859-1' } },
  },

  {
    expect  => 'text/plain; charset=us-ascii; format=flowed',
    input   => {
      type    => 'text',
      subtype => 'plain',
      attributes => { charset => 'us-ascii', format => 'flowed' }
    },
  },

  {
    expect  => 'application/foo',
    input   => { type => 'application', subtype => 'foo', attributes => {} },
  },

  {
    expect  => 'multipart/mixed; boundary=unique-boundary-1',
    input   => {
      type    => 'multipart',
      subtype => 'mixed',
      attributes => { boundary => 'unique-boundary-1' },
    },
  },

  {
    expect  => 'message/external-body; access-type=local-file; name="/u/nsb/Me.jpeg"',
    input   => {
      type    => 'message',
      subtype => 'external-body',
      attributes => {
        'access-type' => 'local-file',
        'name'        => '/u/nsb/Me.jpeg'
      },
    },
  },

  {
    expect  => 'multipart/mixed; boundary="----------=_1026452699-10321-0"',
    input   => {
      'type' => 'multipart',
      'subtype' => 'mixed',
      'attributes' => {
        'boundary' => '----------=_1026452699-10321-0'
      }
    },
  },

  {
    expect  => 'multipart/report; boundary="=_0c5bb6a163fe08545fb49e4a=73e476c3-cd5a-5ba3-b910-2e1563f157b8_="',
    input   => {
      'type' => 'multipart',
      'subtype' => 'report',
      'attributes' => {
        'boundary' => '=_0c5bb6a163fe08545fb49e4a=73e476c3-cd5a-5ba3-b910-2e1563f157b8_='
      }
    },
  },

  {
    expect  => 'message/external-body; access-type=URL; url="ftp://cs.utk.edu/pub/moore/bulk-mailer/looooooooooong/bulk-mailer.tar"',
    input   => {
      'type' => 'message',
      'subtype' => 'external-body',
      'attributes' => {
        'access-type' => 'URL',
        'url' => 'ftp://cs.utk.edu/pub/moore/bulk-mailer/looooooooooong/bulk-mailer.tar',
      }
    }
  },

  {
    expect  => q(message/external-body; access-type=URL; url*0="ftp://cs.utk.edu/pub/moore/bulk-mailer/looooooooooooong/bulk-mailer."; url*1="tar"; url="ftp://cs.utk.edu/pub/moore/bulk-mailer/looooooooooooong/bulk-mailer..."),
    no_pre_2231  => q(message/external-body; access-type=URL; url*0="ftp://cs.utk.edu/pub/moore/bulk-mailer/looooooooooooong/bulk-mailer."; url*1="tar"),
    input   => {
      'type' => 'message',
      'subtype' => 'external-body',
      'attributes' => {
        'access-type' => 'URL',
        'url' => 'ftp://cs.utk.edu/pub/moore/bulk-mailer/looooooooooooong/bulk-mailer.tar',
      }
    },
  },

  {
    expect  => 'message/external-body; access-type=URL; url="ftp://cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar"',
    input   => {
      'type' => 'message',
      'subtype' => 'external-body',
      'attributes' => {
        'access-type' => 'URL',
        'url' => 'ftp://cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar',
      }
    },
  },

  {
    expect  => q(application/x-stuff; title*=UTF-8''This%20is%20%2A%2A%2Afun%2A%2A%2A%20%C2%A9; title="This is ***fun*** (c)"),
    no_pre_2231  => q(application/x-stuff; title*=UTF-8''This%20is%20%2A%2A%2Afun%2A%2A%2A%20%C2%A9),
    input   => {
      'type' => 'application',
      'subtype' => 'x-stuff',
      'attributes' => {
        'title' => "This is ***fun*** \N{U+A9}"
      }
    },
  },

  {
    expect  => q(application/x-stuff; title*0*=UTF-8''This%20is%20even%20more%20%2A%2A%2Afun%2A%2A%2A%20%C2%A9%20i; title*1*=sn%27t%20it!; title="This is even more ***fun*** (c) isn't it!"),
    no_pre_2231  => q(application/x-stuff; title*0*=UTF-8''This%20is%20even%20more%20%2A%2A%2Afun%2A%2A%2A%20%C2%A9%20i; title*1*=sn%27t%20it!),
    input   => {
      'type' => 'application',
      'subtype' => 'x-stuff',
      'attributes' => {
        'title' => "This is even more ***fun*** \N{U+A9} isn't it!"
      }
    },
  },

  {
    expect  => 'text/plain; attribute="value\"value\\\\value(value><)@,;:/][?=value value"; charset=us-ascii',
    input   => {
      'type' => 'text',
      'subtype' => 'plain',
      'attributes' => {
        'attribute' => 'value"value\\value(value><)@,;:/][?=value value',
        'charset' => 'us-ascii',
      },
    },
  },
);

sub test {
  my ($test) = @_;

  local $_;

  my $input = $test->{input};

  my $label = $test->{expect};
  $label =~ s/\r/\\r/g;
  $label =~ s/\n/\\n/g;

  subtest "$test->{expect}" => sub {
    for my $pre_2231 (0, 1) {
      local $Email::MIME::ContentType::PRE_2231_FORM = $pre_2231;

      my $type   = $pre_2231  ? 'default' : 'no_pre_2231';
      my $expect = $pre_2231  ? $test->{expect}
                              : $test->{no_pre_2231} // $test->{expect};

      my $got = build_content_type($input);
      is($got, $expect, "build C-T ($type)");

      my $parsed = parse_content_type($got);

      delete $parsed->{discrete};
      delete $parsed->{composite};

      is_deeply($parsed, $input, "parse C-T ($type)");
    }
  };
}

for my $test (@ct_tests) {
  test($test);
}
