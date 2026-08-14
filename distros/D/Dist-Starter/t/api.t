use Test2::V1
  -target => { CLASS => 'Dist::Starter', CONTEXT => 'Dist::Starter::Context' },
  -pragmas, qw( diag dies is like mock note plan skip );
use Test::Output qw( stdout_from stderr_like stdout_like );
use Test::Script qw( program_runs );

use File::Basename        qw( dirname );
use File::Spec::Functions qw( catdir );
use File::Which           qw( which );

plan 21;

stdout_like { is CLASS->run( '-V' ), CLASS->EXIT_SUCCESS, 'Successful run' }
qr/\A api\.t \  v\d+.\d+.\d+ \n perl \  v\d+.\d+.\d+ \n \z/x, 'Show version';

my $distname = 'Foo-Bar-Baz';

# "mbt" means Module::Build::Tiny
stderr_like {
  is CLASS->run( '-T', catdir( qw( t data templates perl-dist-mbt ) ), $distname ), CLASS->EXIT_USAGE, 'Usage failure'
}
qr/^Template\ directory .* does\ not\ exist\n$/mx, 'Template directory missing';

# "mb" means Module::Build
stderr_like {
  is CLASS->run( '-T', catdir( qw( t data templates perl-dist-mb ) ), $distname ), CLASS->EXIT_USAGE, 'Usage failure'
}
qr/\A Template\ entry\ point\ directory .* does\ not\ exist/x, 'Template entry point directory missing';

# "eumm" means ExtUtils::MakeMaker
like dies { CLASS->run( '-T', catdir( qw( t data templates perl-dist-eumm ) ), $distname ) },
  qr/context\.yml.?\ does\ not\ exist/x, 'Context file missing';

stderr_like {
  is CLASS->run( '-o', 'TEMP_DIR' ), CLASS->EXIT_USAGE, 'Usage failure';
}
qr/required\ arguments\ .*\ but\ it\ is\ 0/x, 'Required distname argument missing';

stderr_like {
  is CLASS->run( '-o', 'TEMP_DIR', $distname, '-A', 'A meaningful abstract' ), CLASS->EXIT_USAGE, 'Usage failure';
}
qr/required\ arguments\ .*\ but\ it\ is\ 3/x, 'Options have to be specified first';

my $mock = mock CONTEXT, ( override => [ _gecos => sub { 'Fred Flintstone,,,,fred.flintstone@example.com' } ] );

stdout_like {
  is CLASS->run( '-n', '-G', 'https://github.com/sitcom', $distname ), CLASS->EXIT_SUCCESS, 'Successful run'
}
qr/\A ---/x, 'Dump context as YAML document';

#local  $ENV{ HARNESS_ACTIVE } = undef;
like my $got_project = stdout_from {
  is CLASS->run( '-o', 'TEMP_DIR', '-G', 'https://github.com/sitcom', 'Foo::Bar::Baz' ), CLASS->EXIT_SUCCESS,
    'Successful run (using module name instead of distname)'
}, qr/Foo-Bar-Baz\n\z/, 'Check project path';
chomp $got_project;
note $got_project;

SKIP: {
  skip "'diff' is not installed!", 1 unless defined which( 'diff' );

  my $stdout;
  program_runs [ 'diff', '-rq', $got_project, catdir( qw( t data expected basic Foo-Bar-Baz ) ) ], { stdout => \$stdout },
    'Deep comparison of expanded template'
    or diag $stdout
}

stderr_like { is CLASS->run( '-o', dirname( $got_project ), $distname ), CLASS->EXIT_USAGE, 'Usage failure' }
qr/already\ exists/x, 'Project directory already exists';

#local $ENV{ HARNESS_ACTIVE } = undef;
like $got_project = stdout_from {
  is CLASS->run(
    '-o', 'TEMP_DIR', '-G', 'https://github.com/jd', '-S', 'type=dist', '-S', 'dir=data', '-a',
    'John Doe <john.doe@example.com>',
    'Baz-Bar-Foo'
    ),
    CLASS->EXIT_SUCCESS,
    'Successful run (require dist share)'
}, qr/Baz-Bar-Foo\n\z/, 'Check project path';
chomp $got_project;
note $got_project;

SKIP: {
  skip "'diff' is not installed!", 1 unless defined which( 'diff' );

  my $stdout;
  program_runs [ 'diff', '-rq', $got_project, catdir( qw( t data expected share Baz-Bar-Foo ) ) ], { stdout => \$stdout },
    'Deep comparison of expanded template'
    or diag $stdout
}
