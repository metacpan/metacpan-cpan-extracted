# vim:ft=perl
use strict;
use warnings;

use Test::More 'no_plan';

use Email::MIME::ContentType;

# The keys are...
#   input       - the arguments to pass to build_content_disposition
#   expect      - the C-D header built as usual
#   no_pre_2231 - the C-D header built without pre-2231 support
#
# If "no_pre_2231" is not specified, the output should be the same in both
# modes.
my @cd_tests = (
  {
    expect  => 'inline',
    input   => { type => 'inline', attributes => {} },
  },

  {
    expect  => 'attachment',
    input   => { type => 'attachment', attributes => {} },
  },

  {
    expect  => 'attachment; filename=genome.jpeg; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"',
    input   => {
      type => 'attachment',
      attributes => {
        filename => 'genome.jpeg',
        'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
      }
    },
  },

  {
    expect  => q(attachment; filename*=UTF-8''genom%C3%A9.jpeg; filename=genome.jpeg; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    no_pre_2231  => q(attachment; filename*=UTF-8''genom%C3%A9.jpeg; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    input   => {
      type => 'attachment',
      attributes => {
        filename => "genom\x{E9}.jpeg",
        'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
      }
    },
  },

  {
    expect => q(attachment; filename=loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    input => {
      type => 'attachment',
      attributes => {
          filename => 'loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong',
          'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
      }
    },
  },

  {
    expect  => q(attachment; filename*0=loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo; filename*1=ong; filename=looooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo...; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    no_pre_2231  => q(attachment; filename*0=loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo; filename*1=ong; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    input   => {
      type => 'attachment',
      attributes => {
        filename => 'looooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong',
        'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
      }
    },
  },

  {
    expect  => q(attachment; filename="l\\"oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong"; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    input   => {
      type => 'attachment',
      attributes => {
        filename => 'l"oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong',
        'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
      }
    },
  },

  {
    expect => q(attachment; filename*0="l\\"oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo"; filename*1="ong"; filename="l\"ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo..."; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    no_pre_2231 => q(attachment; filename*0="l\\"oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo"; filename*1="ong"; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    input => {
      type => 'attachment',
      attributes => {
        filename => 'l"ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong',
        'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
      }
    },
  },

  {
    expect  => q(attachment; filename*=UTF-8''%C3%A9loooooooooooooooooooooooooooooooooooooooooooooooooong; filename=eloooooooooooooooooooooooooooooooooooooooooooooooooong; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    no_pre_2231  => q(attachment; filename*=UTF-8''%C3%A9loooooooooooooooooooooooooooooooooooooooooooooooooong; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    input   => {
      type => 'attachment',
      attributes => {
        filename => "\x{E9}loooooooooooooooooooooooooooooooooooooooooooooooooong",
        'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
      }
    },
  },

  {
    expect  => q(attachment; filename*0*=UTF-8''%C3%A9loooooooooooooooooooooooooooooooooooooooooooooooooo; filename*1*=ong; filename=elooooooooooooooooooooooooooooooooooooooooooooooooooong; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    no_pre_2231  => q(attachment; filename*0*=UTF-8''%C3%A9loooooooooooooooooooooooooooooooooooooooooooooooooo; filename*1*=ong; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    input   => {
      type => 'attachment',
      attributes => {
        filename => "\x{E9}looooooooooooooooooooooooooooooooooooooooooooooooooong",
        'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
      }
    },
  },

  {
    expect  => q(attachment; filename*=UTF-8''%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9; filename=eeeeeeeee),
    no_pre_2231  => q(attachment; filename*=UTF-8''%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9),
    input   => {
      type => 'attachment',
      attributes => {
        filename => "\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}"
      }
    },
  },

  {
    expect  => q(attachment; filename*0*=UTF-8''%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9; filename*1*=%C3%A9; filename=eeeeeeeeee),
    no_pre_2231  => q(attachment; filename*0*=UTF-8''%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9; filename*1*=%C3%A9),
    input   => {
      type => 'attachment',
      attributes => {
        filename => "\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}"
      }
    },
  },

  {
    expect  => q(attachment; filename="UTF-8''name"),
    input   => {
      type => 'attachment',
      attributes => {
        filename => "UTF-8''name"
      }
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

      my $got = build_content_disposition($input);
      is($got, $expect, "build C-D ($type)");

      my $parsed = parse_content_disposition($got);
      is_deeply($parsed, $input, "parse C-D ($type)");
    }
  };
}

for my $test (@cd_tests) {
  test($test);
}
