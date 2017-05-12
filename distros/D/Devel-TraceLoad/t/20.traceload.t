use strict;
use warnings;
use Test::More;
use Test::Deep;
use File::Temp qw/tempfile/;
use YAML qw/LoadFile/;

use lib qw(t/lib);
use Test::SyntheticModule qw/make_module/;

use constant HAS_F => $] >= 5.009002
 || ( $] >= 5.008007 && $] < 5.009000 );

my $PERL = $^X;
my @INCLUDE = map { "-I$_" } @INC[ 0 .. 3 ];    # Fragile

# Protect from modules loaded in PERL5OPT
local $ENV{PERL5OPT};

my @schedule;

{
  my $dump_file = undef;

  sub dump_file {
    unless ( defined $dump_file ) {
      ( undef, $dump_file ) = tempfile( UNLINK => 1 );
    }
    return $dump_file;
  }
}

BEGIN {
  my $is_syn_package = re( qr{ ^ Synthetic::\w+ $}x );
  @schedule = ( {
      name    => 'Summary',
      options => 'stdout,summary',
      setup   => sub {
        my $module = make_module( '' );
        return "use $module";
      },
      stdout => [
        '',
        'Loaded Modules Cross Reference',
        '==============================',
        '',
        $is_syn_package,
        '    -e (main), line 1',
        '',
        'Required versions',
        '=================',
        '',
        'No versions required'
      ]
    },
    {
      name    => 'YAML',
      options => 'yaml,dump',
      setup   => sub {
        my $dump   = dump_file();
        my $module = make_module(
          "Devel::TraceLoad::_option('dump_name', '$dump');" );
        return "use $module";
      },
      stdout => [],
      yaml   => [ {
          'rc'      => '1',
          'version' => undef,
          'pkg'     => 'main',
          'file'    => '-e',
          'nested'  => [],
          'module'  => $is_syn_package,
          'line'    => '1'
        }
      ],
    } );

  my @test_keys = qw/stdout stderr yaml/;
  my $tests     = 0;
  for my $test ( @schedule ) {
    $tests += grep { exists $test->{$_} } @test_keys;
  }

  plan tests => $tests;
}

for my $test ( @schedule ) {
  my $name = $test->{name};

  my $dtl = '-MDevel::TraceLoad';
  if ( my $opts = $test->{options} ) {
    $dtl .= "=$opts";
  }

  my $script = $test->{setup}->();

  my @cmd = ( $PERL, @INCLUDE, $dtl, ( HAS_F ? ( '-f' ) : () ), '-e',
    $script );

  my $cmd = join( ' ', @cmd );
  #diag "Running $cmd\n";

  if ( $^O =~ /Win32/ || $^O eq 'VMS' ) {
    @cmd = join ' ', map { qq{"$_"} } @cmd;
  }

  open( my $ch, '-|', @cmd ) or die "Can't run $cmd";
  chomp( my @stdout = <$ch> );
  close $ch or die "Can't run $cmd";

  if ( my $stdout = $test->{stdout} ) {
    unless ( cmp_deeply( \@stdout, $stdout, "$name: capture matches" ) )
    {
      use Data::Dumper;
      ( my $var = $name ) =~ s/\s+/_/g;
      diag( Data::Dumper->Dump( [ \@stdout ], [$var] ) );
    }
  }

  if ( my $yaml = $test->{yaml} ) {
    my $got = LoadFile( dump_file() );
    unless ( cmp_deeply( $got, $yaml, "$name: YAML matches" ) ) {
      use Data::Dumper;
      ( my $var = $name ) =~ s/\s+/_/g;
      diag( Data::Dumper->Dump( [$got], [$var] ) );
    }
  }
}

