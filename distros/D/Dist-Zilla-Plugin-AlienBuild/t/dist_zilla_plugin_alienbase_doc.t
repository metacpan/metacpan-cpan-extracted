use Test2::V0;
use Test::DZil;
use Dist::Zilla::Plugin::AlienBase::Doc;
use List::Util qw( first );

subtest 'render' => sub {

  my $tzil = Builder->from_config({ dist_root => 'corpus/Alien-Foo2' }, {
    add_files => {
      'source/dist.ini' => simple_ini(
        { name => 'Alien-Foo2' },
        [ 'GatherDir'  => {} ],
        [ 'AlienBase::Doc' => {
            name => 'libfoo',
        } ],
      ),
    },
  });

  my $plugin = first { $_->plugin_name eq 'AlienBase::Doc' } @{ $tzil->plugins };

  isa_ok $plugin, 'Dist::Zilla::Plugin::AlienBase::Doc';
    
  subtest 'synopsis library' => sub {
  
    my $synopsis = $plugin->render_synopsis;
    ok $synopsis;
    note $synopsis;
  
  };
  
  subtest 'synopsis tool' => sub {
  
    @{ $plugin->type } = ('tool');
  
    my $synopsis = $plugin->render_synopsis;
    ok $synopsis;
    note $synopsis;

  };

  subtest 'synopsis ffi' => sub {
  
    @{ $plugin->type } = ('ffi');
  
    my $synopsis = $plugin->render_synopsis;
    ok $synopsis;
    note $synopsis;

  };

  subtest 'description' => sub {
  
    my $d = $plugin->render_description;
    ok $d;
    note $d;
  
  };

  subtest 'see also' => sub {
  
    my @save = @{ $plugin->see_also };
    @{ $plugin->see_also } = ('Foo::Bar', 'Baz::Roger');
    
    my $see_also = $plugin->render_see_also;
    ok $see_also;
    note $see_also;
  
    @{ $plugin->see_also } = @save;
  };

  subtest 'do the build' => sub {
  
    @{ $plugin->type } = ('library', 'tool', 'ffi');
    
    $tzil->build;
    
    my $file = first { $_->name eq 'lib/Alien/Foo2.pm' } @{ $tzil->files };
    
    ok $file, "has file";
    note $file->content;
  
  };

};

done_testing;
