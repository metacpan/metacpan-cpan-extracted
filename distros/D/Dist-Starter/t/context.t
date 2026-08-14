use Test2::V1 -pragmas, qw( dies is isa_ok like mock ok plan subtest );
use Test::Mock::Cmd ();
our $Current_qx; ## no critic ( ProhibitPackageVars )
BEGIN {
  $Current_qx = \&Test::Mock::Cmd::orig_qx;
  Test::Mock::Cmd->import( qx => sub { goto $Current_qx } );
}
use Test2::Tools::Target CLASS => 'Dist::Starter::Context';

use File::Spec::Functions qw( catfile );
use File::ShareDir::Tiny  qw( dist_dir );

plan 9;

my $context_file = catfile( dist_dir( 'Dist-Starter' ), qw( templates perl-dist-eummcpf context.yml ) );

like dies { CLASS->load_from_file( $context_file ) }->message, qr/\A'distname' parameter not specified/,
  'Missing distname';

subtest 'Invalid parameter values' => sub {
  plan 3;

  my $invalid_value = 'Sven Willenbuecher sven.willenbuecher@gmx.de>';
  like dies {
    CLASS->load_from_file(
      $context_file,
      distname    => 'Foo-Bar-Baz',
      author_from => $invalid_value
    )
  }
  ->message, qr/\ACannot parse author '$invalid_value'/, 'Invalid author';
  $invalid_value = '6.01000';
  like dies { CLASS->load_from_file( $context_file, distname => 'Foo-Bar-Baz', min_perl_version => $invalid_value ) }
  ->message, qr/\AInvalid minimum perl version '$invalid_value'/, 'Invalid minimum perl version';
  $invalid_value = 'package';
  like dies { CLASS->load_from_file( $context_file, distname => 'Foo-Bar-Baz', share => { type => $invalid_value } ) }
  ->message,
    qr/\AInvalid share type '$invalid_value'/, 'Invalid share type'
};

subtest 'Lookup default values (author full name from GECOS, author email from EMAIL)' => sub {
  plan 12;

  local $ENV{ EMAIL } = 'fred.flintstone@example.com';
  my $mock = mock CLASS, ( override => [ _gecos => sub { 'Fred Flintstone,,,,Some other information' } ] );

  isa_ok my $self = CLASS->load_from_file( $context_file, distname => 'Foo-Bar-Baz' ), [ CLASS ],
    'Load context file and create context object';

  is $self->lookup( 'distname' ),         'Foo-Bar-Baz',                 'Top-level lookup';
  is $self->lookup( 'abstract' ),         'The great new Foo::Bar::Baz', 'Lookup of derived abstract variable ok';
  is $self->lookup( 'author.full_name' ), 'Fred Flintstone',             'Deep lookup';
  is $self->lookup( 'author.email' ),     $ENV{ EMAIL },                 'Deep lookup';
  is $self->lookup( 'git_base_url' ),     '',                            'Top-level lookup';
  is $self->lookup( 'initial_version' ),  'v0.1.0',                      'Top-level lookup';
  is $self->lookup( 'license' ),          'perl_5',                      'Top-level lookup';
  is $self->lookup( 'main_module' ),      'Foo::Bar::Baz',               'Lookup of enriched variable ok';
  is $self->lookup( 'min_perl_version' ), '5.010000',                    'Top-level lookup';

  like dies { $self->lookup( 'author.street' ) }->message, qr/\AContext does not know the variable 'author.street'/,
    'Deep lookup fails';
  ok not( exists( $self->{ author }->{ street } ) ), 'Context not autovivified'
};

subtest 'Lookup default values (set author_from to FROM_GECOS explicitly)' => sub {
  plan 10;

  local $ENV{ EMAIL } = 'fred.flintstone@example.com';
  my $mock = mock CLASS, ( override => [ _gecos => sub { 'Fred Flintstone,,,,Some other information' } ] );

  isa_ok my $self = CLASS->load_from_file( $context_file, distname => 'Foo-Bar-Baz', author_from => 'FROM_GECOS' ),
    [ CLASS ],
    'Load context file and create context object';

  is $self->lookup( 'distname' ),         'Foo-Bar-Baz',                 'Top-level lookup';
  is $self->lookup( 'abstract' ),         'The great new Foo::Bar::Baz', 'Lookup of derived abstract variable ok';
  is $self->lookup( 'author.full_name' ), 'Fred Flintstone',             'Deep lookup';
  is $self->lookup( 'author.email' ),     $ENV{ EMAIL },                 'Deep lookup';
  is $self->lookup( 'git_base_url' ),     '',                            'Top-level lookup';
  is $self->lookup( 'initial_version' ),  'v0.1.0',                      'Top-level lookup';
  is $self->lookup( 'license' ),          'perl_5',                      'Top-level lookup';
  is $self->lookup( 'main_module' ),      'Foo::Bar::Baz',               'Lookup of enriched variable ok';
  is $self->lookup( 'min_perl_version' ), '5.010000',                    'Top-level lookup'
};

subtest 'Lookup adjusted values' => sub {
  plan 8;

  isa_ok my $self = CLASS->load_from_file(
    $context_file,
    distname         => 'Foo-Baz',
    abstract         => 'Look up Canadian Federal Sales Tax rates',
    author_from      => 'Sven Willenbuecher <sven.willenbuecher@gmx.de>',
    initial_version  => 'v1.0.0',
    license          => 'restricted',
    min_perl_version => '5.016003'
    ),
    [ CLASS ], 'Load context file and create context object';

  is $self->lookup( 'abstract' ),         'Look up Canadian Federal Sales Tax rates', 'Lookup abstract';
  is $self->lookup( 'author.full_name' ), 'Sven Willenbuecher',                       'Lookup author full name';
  is $self->lookup( 'author.email' ),     'sven.willenbuecher@gmx.de',                'Lookup author email';
  is $self->lookup( 'initial_version' ),  'v1.0.0',                                   'Lookup initial version';
  is $self->lookup( 'license' ),          'restricted',                               'Lookup license string';
  is $self->lookup( 'main_module' ),      'Foo::Baz',                                 'Lookup main module';
  is $self->lookup( 'min_perl_version' ), '5.016003',                                 'Lookup minimum perl version'
};

subtest 'Lookup adjusted values; ask git for author information; FROM_GIT set in context file' => sub {
  plan 5;

  local $Current_qx = sub {
    my ( $cmd, @args ) = split / +/, $_[ 0 ];
    die "'$cmd' is not a git command (only git command calls should be mocked)" ## no critic ( RequireCarping )
      unless $cmd eq 'git';
    ( grep { $_ eq 'user.name' } @args ) ? 'Scott Chacon' : 'schacon@gmail.com'
  };
  isa_ok my $self = CLASS->load_from_file( catfile( qw( t data context.yml ) ), distname => 'Baz' ),
    [ CLASS ], 'Load context file and create context object';

  is $self->lookup( 'abstract' ),         'The great new Baz', 'Lookup abstract';
  is $self->lookup( 'author.full_name' ), 'Scott Chacon',      'Lookup author full name';
  is $self->lookup( 'author.email' ),     'schacon@gmail.com', 'Lookup author email';
  is $self->lookup( 'main_module' ),      'Baz',               'Lookup main module'
};

subtest 'Lookup adjusted values; ask git for author information' => sub {
  plan 5;

  local $Current_qx = sub {
    my ( $cmd, @args ) = split / +/, $_[ 0 ];
    die "'$cmd' is not a git command (only git command calls should be mocked)" ## no critic ( RequireCarping )
      unless $cmd eq 'git';
    ( grep { $_ eq 'user.name' } @args ) ? 'Scott Chacon' : 'schacon@gmail.com'
  };
  isa_ok my $self = CLASS->load_from_file(
    $context_file,
    distname    => 'Baz',
    author_from => 'FROM_GIT'
    ),
    [ CLASS ], 'Load context file and create context object';

  is $self->lookup( 'abstract' ),         'The great new Baz', 'Lookup abstract';
  is $self->lookup( 'author.full_name' ), 'Scott Chacon',      'Lookup author full name';
  is $self->lookup( 'author.email' ),     'schacon@gmail.com', 'Lookup author email';
  is $self->lookup( 'main_module' ),      'Baz',               'Lookup main module'
};

subtest 'Lookup adjusted values; ask environment for author information' => sub {
  plan 5;

  local @ENV{ qw( FULL_NAME EMAIL ) } = ( 'John Doe', 'john.doe@example.com' );
  isa_ok my $self = CLASS->load_from_file(
    $context_file,
    distname    => 'Baz',
    author_from => 'FROM_ENV'
    ),
    [ CLASS ], 'Load context file and create context object';

  is $self->lookup( 'abstract' ),         'The great new Baz', 'Lookup abstract';
  is $self->lookup( 'author.full_name' ), $ENV{ FULL_NAME },   'Lookup author full name';
  is $self->lookup( 'author.email' ),     $ENV{ EMAIL },       'Lookup author email';
  is $self->lookup( 'main_module' ),      'Baz',               'Lookup main module'
};

subtest 'Lookup adjusted values; author information without email' => sub {
  plan 5;

  isa_ok my $self = CLASS->load_from_file(
    $context_file,
    distname    => 'Foo',
    author_from => 'John Doe'
    ),
    [ CLASS ], 'Load context file and create context object';

  is $self->lookup( 'abstract' ),         'The great new Foo', 'Lookup abstract';
  is $self->lookup( 'author.full_name' ), 'John Doe',          'Lookup author full name';
  is $self->lookup( 'author.email' ),     '',                  'Lookup author email';
  is $self->lookup( 'main_module' ),      'Foo',               'Lookup main module'
}
