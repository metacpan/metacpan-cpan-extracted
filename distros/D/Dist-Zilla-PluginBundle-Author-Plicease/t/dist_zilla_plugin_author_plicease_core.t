use 5.022;
use Test2::V0 -no_srand => 1;
use Test::DZil;
use List::Util qw( first );

sub tzil
{
  my(%core) = @_;

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          # [GatherDir]
          'GatherDir',
          [ 'Prereqs' => {
            'perl'                => '5.010',
            'File::Spec'          => 0,   # core since 5.00405
            'Scalar::Util'        => '1.5', # core, but versioned
            'IO::Socket::IP'      => 0,   # core since 5.019008
            'Foo::Bar::NotCore'   => 0,   # not core
            'ExtUtils::MakeMaker' => 0,   # always kept
          } ],
          [ 'Prereqs' => 'TestRequires' => {
            'Test::More'          => 0,   # core since 5.006002
          } ],
          [ 'Prereqs' => 'DevelopRequires' => {
            'JSON::PP'            => 0,   # develop phase is skipped
          } ],
          'MakeMaker',
          [ 'Author::Plicease::Core' => \%core ],
        )
      }
    }
  );

  $tzil->build;

  return $tzil;
}

subtest 'guessed starting version' => sub {

  my $tzil = tzil();
  my $plugin = $tzil->plugin_named('Author::Plicease::Core');

  is $plugin->starting_version, '5.010', 'starting version from runtime perl prereq';

  is
    $tzil->prereqs->as_string_hash,
    hash {
      field runtime => hash {
        field requires => {
          'perl'                => '5.010',
          'Scalar::Util'        => '1.5',
          'IO::Socket::IP'      => 0,
          'Foo::Bar::NotCore'   => 0,
          'ExtUtils::MakeMaker' => 0,
        };
        end;
      };
      # emptied, so the test phase goes away entirely
      field test => DNE;
      field develop => hash {
        field requires => {
          'JSON::PP' => 0,
        };
        end;
      };
      etc;
    },
    'core prereqs removed',
  ;

  is $plugin->check_at_configure, { 'File::Spec' => 1, 'Test::More' => 1 }, 'check_at_configure';

  my $log = [ map { $_->{message} } $tzil->chrome->logger->events->@* ];
  note $_ for @$log;
  ok( (grep /guessing perl version 5\.010/, @$log), 'logged guess' );
  ok( (grep /removing prereq: File::Spec/,  @$log), 'logged removing File::Spec' );
  ok( (grep /removing prereq: Test::More/,  @$log), 'logged removing Test::More' );

  my $file = first { $_->name eq 'Makefile.PL' } $tzil->files->@*;
  ok $file, 'has Makefile.PL';

  my $content = $file->content;
  note $content;

  like $content, qr/\A\QBEGIN {\E\n/, 'starts with BEGIN block';
  like $content, qr/\Q} qw( File::Spec Test::More );\E/, 'checks the removed modules';
  like $content, qr/Your Perl is missing core modules/, 'has diagnostic';
  like $content, qr/dnf install perl-core/, 'has install hint';

  my $code = $content =~ s/\n}\n.*\z/\n}\n/sr;
  ok eval "sub { $code }", 'BEGIN block compiles' or diag $@; ## no critic (BuiltinFunctions::ProhibitStringyEval)

};

subtest 'explicit starting version' => sub {

  my $tzil = tzil( starting_version => '5.020' );
  my $plugin = $tzil->plugin_named('Author::Plicease::Core');

  is
    $tzil->prereqs->as_string_hash->{runtime}->{requires},
    {
      'perl'                => '5.010',
      'Scalar::Util'        => '1.5',
      'Foo::Bar::NotCore'   => 0,
      'ExtUtils::MakeMaker' => 0,
    },
    'IO::Socket::IP is also removed',
  ;

  is $plugin->check_at_configure, { 'File::Spec' => 1, 'Test::More' => 1, 'IO::Socket::IP' => 1 }, 'check_at_configure';

  my $file = first { $_->name eq 'Makefile.PL' } $tzil->files->@*;
  like $file->content, qr/\Q} qw( File::Spec IO::Socket::IP Test::More );\E/, 'checks the removed modules';

};

done_testing;
