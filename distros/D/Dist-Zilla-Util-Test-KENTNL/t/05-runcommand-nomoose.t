use strict;
use warnings;

use Test::More;

my @paths;
my %inc_report;

BEGIN {
  unshift @INC, sub {
    my ( $self, $file ) = @_;
    return unless $file =~ /\AMoose.pm\z/;
    my @path;
    my $i = 0;
    my (@call) = caller($i);
    while ( $call[0] ) {

      #next if $call[0] =~ /\AMoose(\z|::)/;
      my $nick = $call[1];
      for my $dir_no ( 0 .. $#INC ) {
        next if ref $INC[$dir_no];
        my $dir = $INC[$dir_no];
        my $sub = sprintf '@INC[%d]', $dir_no;
        if ( $nick =~ s/\A\Q$dir\E/$sub/ ) {
          $inc_report{$dir_no} = $INC[$dir_no];
          last;
        }
      }
      push @path, sprintf "%-30s line %4s *( %s %s )", $nick, $call[2], $call[0], $call[3];
    }
    continue {
      $i++;
      (@call) = caller($i);
    }
    push @paths, join qq{\n\t}, @path;
    return;
  };
}
use Test::DZil qw( simple_ini );
use Dist::Zilla::Util::Test::KENTNL qw( dztest );
use Dist::Zilla::App::Command::authordeps;

# FILENAME: 02-basic-dztest.t
# ABSTRACT: Make sure dztest works

my $test     = dztest;
my $was_good = 0;
$test->add_file( 'dist.ini', simple_ini( ['GatherDir'] ) );
{
  local $TODO = "This wont always pass on systems because things :(";
  my $result = $test->run_command( ['version'] );
  ok( ref $result, 'version executed' );
  is( $result->error,     undef, 'no errors' );
  is( $result->exit_code, 0,     'exit = 0' );
  note( $result->stdout );
  $was_good = is( ( scalar @paths ), 0, "No Moose paths accidentally loaded" );
}
unless ($was_good) {
  diag "Moose is loaded by accident to simply to test `dzil version`. Causes:", join qq[\n], @paths;
  diag map { "INC[$_] => " . $inc_report{$_} } sort keys %inc_report;
}
done_testing;

