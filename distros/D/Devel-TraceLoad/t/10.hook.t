use strict;
use warnings;
use Test::More;
use Test::Deep;
use File::Spec;

use lib qw(t/lib);
use Test::SyntheticModule qw/make_module/;

use Devel::TraceLoad::Hook qw/register_require_hook/;

{
  my %fail  = ();
  my @calls = ();

  register_require_hook(
    sub {
      push @calls, [@_];
      if ( my $err = delete $fail{ $_[0] } ) {
        die $err;
      }
    }
  );

  sub poke_call { push @calls, @_ }
  sub get_calls { @calls }
  sub reset_calls { @calls = () }

  # Schedule a failure for the next call
  sub set_fail { $fail{ $_[0] } = $_[1] }
}

my @schedule;

BEGIN {
  my $is_absolute_name = code(
    sub {
      my $name = shift;
      return File::Spec->file_name_is_absolute( $name )
       ? 1
       : ( 0, "$name is not absolute" );
    }
  );

  my $is_relative_name = code(
    sub {
      my $name = shift;
      return ( defined $name
         && length( $name )
         && !File::Spec->file_name_is_absolute( $name ) )
       ? 1
       : ( 0, "$name is not relative" );
    }
  );

  my $is_version     = re( qr{ ^ \d+ (?: [.] \d+ )* $ }x );
  my $is_eval        = re( qr{ ^ \( eval \s+ \d+ \) }x );
  my $is_line_number = re( qr{ ^ \d+ $ }x );
  my $is_source_name = re( qr{ [.] (?: t | pl | pm ) $ }x );
  my $is_syn_package = re( qr{ ^ Synthetic::\w+ $}x );

  @schedule = (
    # require
    {
      name  => 'Simple require',
      setup => sub {
        my ( $name, $file ) = make_module( '' );
        require $file;
      },
      expect => [
        [
          'before',          1,
          $is_absolute_name, 'main',
          $is_source_name,   $is_line_number
        ],
        [
          'after', 1, $is_absolute_name, 'main', $is_source_name,
          $is_line_number, 1, ''
        ]
      ]
    },
    {
      name  => 'Bareword require',
      setup => sub {
        my $name = make_module( '' );
        eval "require $name";
        die $@ if $@;
      },
      expect => [
        [
          'before',          1,
          $is_relative_name, 'main',
          $is_eval,          $is_line_number
        ],
        [
          'after', 1, $is_relative_name, 'main', $is_eval,
          $is_line_number, 1, ''
        ]
      ]
    },
    {
      name  => 'Version require',
      setup => sub {
        require 5;
      },
      expect => [
        [
          'before',        1,
          $is_version,     'main',
          $is_source_name, $is_line_number
        ],
        [
          'after', 1, $is_version, 'main', $is_source_name,
          $is_line_number, 1, ''
        ]
      ]
    },
    {
      name  => 'Simple use',
      setup => sub {
        my $name = make_module( '' );
        eval "use $name";
        die $@ if $@;
      },
      expect => [
        [
          'before',          1,
          $is_relative_name, 'main',
          $is_eval,          $is_line_number
        ],
        [
          'after', 1, $is_relative_name, 'main', $is_eval,
          $is_line_number, 1, ''
        ]
      ]
    },
    {
      name  => 'Nested use',
      setup => sub {
        my $mod1 = make_module( '' );
        my $mod2 = make_module( '' );
        my $name = make_module( [ "use $mod1;", "use $mod2;" ] );
        eval "use $name";
        die $@ if $@;
      },
      expect => [
        [
          'before',          1,
          $is_relative_name, 'main',
          $is_eval,          $is_line_number
        ],
        [
          'before',          2,
          $is_relative_name, $is_syn_package,
          $is_absolute_name, $is_line_number
        ],
        [
          'after',           2,
          $is_relative_name, $is_syn_package,
          $is_absolute_name, $is_line_number,
          1,                 ''
        ],
        [
          'before',          2,
          $is_relative_name, $is_syn_package,
          $is_absolute_name, $is_line_number
        ],
        [
          'after',           2,
          $is_relative_name, $is_syn_package,
          $is_absolute_name, $is_line_number,
          1,                 ''
        ],
        [
          'after', 1, $is_relative_name, 'main', $is_eval,
          $is_line_number, 1, ''
        ]
      ]
    },
    {
      name  => 'Failure',
      setup => sub {
        my $name = 'Synthetic::Some::Module';
        eval "use $name";
        die $@ if $@;
      },
      expect => [
        [
          'before',          1,
          $is_relative_name, 'main',
          $is_eval,          $is_line_number
        ],
        [
          'after', 1, $is_relative_name, 'main', $is_eval,
          $is_line_number, undef, re( qr{^ Can't \s+ locate }x )
        ]
      ],
      error => qr{}x,
    },
    {
      name  => 'Fake failure before',
      setup => sub {
        my $name = make_module( '' );
        set_fail( 'before', 'No way dude' );
        eval "use $name";
        die $@ if $@;
      },
      expect => [
        [
          'before',          1,
          $is_relative_name, 'main',
          $is_eval,          $is_line_number
        ],
        [
          'after', 1, $is_relative_name, 'main', $is_eval,
          $is_line_number, undef, re( qr{^ No \s+ way }x )
        ]
      ],
      error => qr{}x,
    },
    {
      name  => 'Fake failure after',
      setup => sub {
        my $name = make_module( '' );
        set_fail( 'after', 'No way dude' );
        eval "use $name";
        die $@ if $@;
      },
      expect => [
        [
          'before',          1,
          $is_relative_name, 'main',
          $is_eval,          $is_line_number
        ],
        [
          'after', 1, $is_relative_name, 'main', $is_eval,
          $is_line_number, 1, ''
        ],
        re( qr{^ No \s+ way }x )
      ]
    },
    {
      name  => 'Fake failure before and after',
      setup => sub {
        my $name = make_module( '' );
        set_fail( 'before', 'No way dude' );
        set_fail( 'after',  'Huh' );
        eval "use $name";
        die $@ if $@;
      },
      expect => [
        [
          'before',          1,
          $is_relative_name, 'main',
          $is_eval,          $is_line_number
        ],
        [
          'after', 1, $is_relative_name, 'main', $is_eval,
          $is_line_number, undef, re( qr{^ No \s+ way }x )
        ],
        re( qr{^ Huh }x )
      ],
      error => qr{}x,
    },
  );

  plan tests => @schedule * 2;
}

for my $test ( @schedule ) {
  my $name = $test->{name};

  reset_calls();

  {
    # Any warnings get added to the list of results we
    # compare against.
    local $SIG{__WARN__} = sub { poke_call( $@ ) };
    eval { $test->{setup}->() };
  }

  if ( my $err = $test->{error} ) {
    like $@, $err, "$name: error OK";
  }
  else {
    ok !$@, "$name: no error OK";
  }

  my @calls = get_calls();

  unless (
    cmp_deeply( \@calls, $test->{expect}, "$name: capture matches" ) ) {
    use Data::Dumper;
    ( my $var = $name ) =~ s/\s+/_/g;
    diag( Data::Dumper->Dump( [ \@calls ], [$var] ) );
  }
}
