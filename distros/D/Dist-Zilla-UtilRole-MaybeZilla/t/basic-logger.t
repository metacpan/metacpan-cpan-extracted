
use strict;
use warnings;

use Test::More;

# FILENAME: basic-logger.t
# CREATED: 12/14/13 17:07:05 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Basic logger functionality test

use Log::Contextual::LogDispatchouli qw( set_logger );
use Log::Dispatchouli;

my $logger = Log::Dispatchouli->new(
  {
    ident => 'test'
  }
);
set_logger $logger;

{

  package Dist::Zilla::Util::Example;
  use Moose;
  with 'Dist::Zilla::UtilRole::MaybeZilla';

  __PACKAGE__->meta->make_immutable;
  $INC{'Dist/Zilla/Util/Example.pm'} ||= 1;
}

use Test::Fatal qw( exception );
use Capture::Tiny qw( capture );
my ( $instance, $e, $stderr, $stdout );

subtest "instantiate no args" => sub {
  ( $stdout, $stderr, $e ) = capture {
    exception {
      $instance = Dist::Zilla::Util::Example->new();
    };
  };
  is( $e, undef, 'Instantiation ok' ) or diag explain $e;
  like( $stdout, qr/\A\s*\z/msx, 'Stdout empty' );
  like( $stderr, qr/\A\s*\z/msx, 'Stderr empty' );

  subtest '->has_zilla' => sub {
    ( $stdout, $stderr, $e ) = capture {
      exception {
        ok( !$instance->has_zilla, 'has_zilla is false' );
      };
    };
    is( $e, undef, '->zilla fails' ) and note $e;
    like( $stdout, qr/\A\s*\z/msx, 'Stdout empty' );
    like( $stderr, qr/\A\s*\z/msx, 'Stderr empty' );
  };

  subtest '->zilla' => sub {
    ( $stdout, $stderr, $e ) = capture {
      exception {
        $instance->zilla;
      };
    };
    isnt( $e, undef, '->zilla fails' ) and note $e;
    like( $stdout, qr/\A\s*\z/msx, 'Stdout empty' );
    like( $stderr, qr/\A\s*\z/msx, 'Stderr empty' );

  };
  subtest '->has_plugin' => sub {
    ( $stdout, $stderr, $e ) = capture {
      exception {
        ok( !$instance->has_plugin, 'has_plugin is false' );
      };
    };
    is( $e, undef, '->zilla fails' ) and note $e;
    like( $stdout, qr/\A\s*\z/msx, 'Stdout empty' );
    like( $stderr, qr/\A\s*\z/msx, 'Stderr empty' );
  };

  subtest '->plugin' => sub {
    ( $stdout, $stderr, $e ) = capture {
      exception {
        $instance->plugin;
      };
    };
    isnt( $e, undef, '->plugin fails' ) and note $e;
    like( $stdout, qr/\A\s*\z/msx, 'Stdout empty' );
    like( $stderr, qr/\A\s*\z/msx, 'Stderr empty' );

  };
};

subtest "instantiate w/zilla" => sub {
  ( $stdout, $stderr, $e ) = capture {
    exception {
      $instance = Dist::Zilla::Util::Example->new( zilla => bless {}, 'Example' );
    };
  };
  is( $e, undef, 'Instantiation ok' ) or diag explain $e;
  like( $stdout, qr/\A\s*\z/msx, 'Stdout empty' );
  like( $stderr, qr/\A\s*\z/msx, 'Stderr empty' );

  subtest '->has_zilla' => sub {
    ( $stdout, $stderr, $e ) = capture {
      exception {
        ok( $instance->has_zilla, 'has_zilla is true' );
      };
    };
    is( $e, undef, '->zilla fails' ) and note $e;
    like( $stdout, qr/\A\s*\z/msx, 'Stdout empty' );
    like( $stderr, qr/\A\s*\z/msx, 'Stderr empty' );
  };

  subtest '->zilla' => sub {
    ( $stdout, $stderr, $e ) = capture {
      exception {
        $instance->zilla;
      };
    };
    is( $e, undef, '->zilla fails' ) and note $e;
    like( $stdout, qr/\A\s*\z/msx, 'Stdout empty' );
    like( $stderr, qr/\A\s*\z/msx, 'Stderr empty' );

  };

  subtest '->has_plugin' => sub {
    ( $stdout, $stderr, $e ) = capture {
      exception {
        ok( !$instance->has_plugin, 'has_plugin is false' );
      };
    };
    is( $e, undef, '->zilla fails' ) and note $e;
    like( $stdout, qr/\A\s*\z/msx, 'Stdout empty' );
    like( $stderr, qr/\A\s*\z/msx, 'Stderr empty' );
  };

  subtest '->plugin' => sub {
    ( $stdout, $stderr, $e ) = capture {
      exception {
        $instance->plugin;
      };
    };
    isnt( $e, undef, '->plugin fails' ) and note $e;
    like( $stdout, qr/\A\s*\z/msx, 'Stdout empty' );
    like( $stderr, qr/\A\s*\z/msx, 'Stderr empty' );

  };
};

sub Example::zilla {
  return $_[0]->{zilla};
}

subtest "instantiate w/plugin" => sub {
  ( $stdout, $stderr, $e ) = capture {
    exception {
      $instance = Dist::Zilla::Util::Example->new( plugin => bless { zilla => bless {}, 'Example' }, 'Example' );
    };
  };
  is( $e, undef, 'Instantiation ok' ) or diag explain $e;
  like( $stdout, qr/\A\s*\z/msx, 'Stdout empty' );
  like( $stderr, qr/\A\s*\z/msx, 'Stderr empty' );

  subtest '->has_zilla' => sub {
    ( $stdout, $stderr, $e ) = capture {
      exception {
        ok( !$instance->has_zilla, 'has_zilla is false' );
      };
    };
    is( $e, undef, '->zilla fails' ) and note $e;
    like( $stdout, qr/\A\s*\z/msx, 'Stdout empty' );
    like( $stderr, qr/\A\s*\z/msx, 'Stderr empty' );
  };

  subtest '->zilla' => sub {
    ( $stdout, $stderr, $e ) = capture {
      exception {
        $instance->zilla;
      };
    };
    is( $e, undef, '->zilla ok' ) and note $e;
    like( $stdout, qr/\A\s*\z/msx, 'Stdout empty' );
    like( $stderr, qr/\A\s*\z/msx, 'Stderr empty' );

  };
  subtest '->has_plugin' => sub {
    ( $stdout, $stderr, $e ) = capture {
      exception {
        ok( $instance->has_plugin, 'has_plugin is true' );
      };
    };
    is( $e, undef, '->zilla fails' ) and note $e;
    like( $stdout, qr/\A\s*\z/msx, 'Stdout empty' );
    like( $stderr, qr/\A\s*\z/msx, 'Stderr empty' );
  };

  subtest '->plugin' => sub {
    ( $stdout, $stderr, $e ) = capture {
      exception {
        $instance->plugin;
      };
    };
    is( $e, undef, '->plugin ok' ) and note $e;
    like( $stdout, qr/\A\s*\z/msx, 'Stdout empty' );
    like( $stderr, qr/\A\s*\z/msx, 'Stderr empty' );

  };
};

done_testing;

