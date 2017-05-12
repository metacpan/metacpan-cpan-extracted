
use strict;
use warnings;

use Test::More;

require Dist::Zilla::Chrome::Test;
require Dist::Zilla::MVP::Section;
require Dist::Zilla::Dist::Builder;
require Dist::Zilla::MVP::Assembler::Zilla;

my $chrome  = Dist::Zilla::Chrome::Test->new();
my $section = Dist::Zilla::MVP::Assembler::Zilla->new(
  chrome        => $chrome,
  zilla_class   => 'Dist::Zilla::Dist::Builder',
  section_class => 'Dist::Zilla::MVP::Section',
);
use Path::Tiny qw( path );

my $cwd     = path('./')->absolute;
my $scratch = path('./')->child('corpus')->child('fake_dist_01');

chdir $scratch->stringify;

$section->current_section->payload->{chrome} = $chrome;
$section->current_section->payload->{root}   = $scratch->stringify;
$section->current_section->payload->{name}   = 'Example';
$section->finalize;

use Dist::Zilla::Plugin::LogContextual;
use Test::Fatal qw( exception );
use Capture::Tiny qw( capture );
use Log::Contextual::LogDispatchouli qw( log_info log_fatal );

my $instance;

my ($stdout, $stderr,$e);

subtest initialize => sub {
    ($stdout, $stderr,$e) = capture {
        exception {
            $instance = Dist::Zilla::Plugin::LogContextual->plugin_from_config( 'testing', {}, $section );
        };
    };
    is( $e, undef, 'bootstrapping didnt except' ) or diag explain $e;
    like( $stdout, qr/\A\s*\z/msx, 'Bootstrap did not print to stdout' );
    like( $stderr, qr/\A\s*\z/msx, 'Bootstrap did not print to stderr' );
    is ( scalar @{ $chrome->logger->events }, 0, 'No logger events seen' );
};
subtest log_info => sub {
    ($stdout, $stderr,$e) = capture {
        exception {
            log_info { 'test' }
        };
    };
    is( $e, undef, 'log_info did not except' ) or diag explain $e;
    like( $stdout, qr/\A\s*\z/msx, 'did not print to stdout' );
    like( $stderr, qr/\A\s*\z/msx, 'did not print to stderr' );
    is ( scalar @{ $chrome->logger->events }, 1, '1 logger event seen' );
};
subtest log_fatal => sub {
    ($stdout, $stderr,$e) = capture {
        exception {
            log_fatal { 'test' };
        };
    };
    isnt( $e, undef, 'log_fatal did except' );
    like( $e , qr/01-basic/msx, "log is from this test file") or diag explain $e;
    like( $stdout, qr/\A\s*\z/msx, 'did not print to stdout' );
    like( $stderr, qr/\A\s*\z/msx, 'did not print to stderr' );
    is ( scalar @{ $chrome->logger->events }, 2, '2 logger events seen' );
    my $last_event = $chrome->logger->events->[-1];
    is ( $last_event->{level} , 'error' , 'last event was an error' );
    is ( $last_event->{message} , 'test' , 'last message relayed ok' );
};


done_testing;
