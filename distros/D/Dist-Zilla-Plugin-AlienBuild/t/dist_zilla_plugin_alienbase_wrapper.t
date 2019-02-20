use Test2::V0 -no_srand => 1;
use Test2::Mock;
use Test::DZil;
use Dist::Zilla::Plugin::AlienBase::Wrapper;
use List::Util qw( first );
use JSON::MaybeXS qw( decode_json );
use Alien::Base::Wrapper 1.02;
use YAML ();

subtest 'eumm' => sub {

  my $tzil = Builder->from_config({ dist_root => 'corpus/Foo-XS' }, {
    add_files => {
      'source/dist.ini' => simple_ini(
        { name => 'Foo-XS' },
        [ 'GatherDir'  => {} ],
        [ 'MakeMaker' => {} ],
        [ 'MetaJSON'   => {} ],
        [ 'AlienBase::Wrapper' => {
            alien => [ 'Alien::libfoo1@1.23', 'Alien::libfoo2' ],
        } ],
      ),
    },
  });

  $tzil->build;

  subtest 'meta' => sub {

    my $meta = decode_json((first { $_->name eq 'META.json' } @{ $tzil->files })->content);
    note YAML::Dump($meta);

    is(
      $meta->{prereqs}->{configure}->{requires},
      hash {
        field 'Alien::Base::Wrapper' => '1.02';
        field 'Alien::libfoo1'       => '1.23';
        field 'Alien::libfoo2'       => '0';
        etc;
      },
      'configure prereqs',
    );

  };
  
  subtest 'installer' => sub {
  
    my $file = first { $_->name eq 'Makefile.PL' } @{ $tzil->files };
    
    ok $file, 'has a Makefile.PL';

    note $file->content;

    my($code) = $file->content =~ /(# BEGIN.*# END code inserted by Dist::Zilla::Plugin::AlienBase::Wrapper)/s;
    
    my @args_import;
    my @args_mm_args;
    
    my $mock = Test2::Mock->new(
      class => 'Alien::Base::Wrapper',
      override => [
        import => sub {
          @args_import = @_;
        },
        mm_args => sub {
          @args_mm_args = @_;
          ( foo => 'bar' );
        },
      ],
    );

    my %WriteMakefileArgs;    
    eval $code;
    
    is $@, '', 'code does not die';
    diag "error = $@" if $@;
    
    is( \@args_import,       [ qw( Alien::Base::Wrapper Alien::libfoo1 Alien::libfoo2 !export ) ], 'import arguments'     );
    is( \@args_mm_args,      [ qw( Alien::Base::Wrapper ) ],                                       'mm_args arguments'    );
    is( \%WriteMakefileArgs, { foo => 'bar' },                                                     'mm_args return value' );
    
  };

};

subtest 'mb' => sub {

  my $tzil = Builder->from_config({ dist_root => 'corpus/Foo-XS' }, {
    add_files => {
      'source/dist.ini' => simple_ini(
        { name => 'Foo-XS' },
        [ 'GatherDir'  => {} ],
        [ 'ModuleBuild' => {} ],
        [ 'MetaJSON'   => {} ],
        [ 'AlienBase::Wrapper' => {
            alien => [ 'Alien::libfoo1@1.23', 'Alien::libfoo2' ],
        } ],
      ),
    },
  });

  $tzil->build;

  subtest 'installer' => sub {

    my $file = first { $_->name eq 'Build.PL' } @{ $tzil->files };
    
    ok $file, 'has a Build.PL';

    note $file->content;
    
    my($code) = $file->content =~ /(# BEGIN.*# END code inserted by Dist::Zilla::Plugin::AlienBase::Wrapper)/s;
    
    my @args_import;
    my @args_mb_args;
    
    my $mock = Test2::Mock->new(
      class => 'Alien::Base::Wrapper',
      override => [
        import => sub {
          @args_import = @_;
        },
        mb_args => sub {
          @args_mb_args = @_;
          ( foo => 'bar' );
        },
      ],
    );

    my %module_build_args;
    eval $code;
    
    is $@, '', 'code does not die';
    diag "error = $@" if $@;
    
    is( \@args_import,       [ qw( Alien::Base::Wrapper Alien::libfoo1 Alien::libfoo2 !export ) ], 'import arguments'     );
    is( \@args_mb_args,      [ qw( Alien::Base::Wrapper ) ],                                       'mb_args arguments'    );
    is( \%module_build_args, { foo => 'bar' },                                                     'mb_args return value' );
  
  };

};

done_testing;
