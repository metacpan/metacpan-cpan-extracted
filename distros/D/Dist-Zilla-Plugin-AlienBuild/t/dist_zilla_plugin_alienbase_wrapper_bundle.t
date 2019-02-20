use Test2::V0 -no_srand => 1;
use Dist::Zilla::Plugin::AlienBase::Wrapper::Bundle;
use Test::DZil;
use List::Util qw( first );
use JSON::MaybeXS qw( decode_json );
use Alien::Base::Wrapper 1.28;
use YAML ();

subtest 'defaults' => sub {

  my $tzil = Builder->from_config({ dist_root => 'corpus/Foo-XS' }, {
    add_files => {
      'source/dist.ini' => simple_ini(
        { name => 'Foo-XS' },
        [ 'GatherDir'  => {} ],
        [ 'MakeMaker' => {} ],
        [ 'MetaJSON'   => {} ],
        [ 'AlienBase::Wrapper::Bundle' => {} ],
      ),
    },
  });

  $tzil->build;

  my $file = first { $_->name eq 'inc/Alien/Base/Wrapper.pm' } @{ $tzil->files };

  ok defined $file, 'has inc/Alien/Base/Wrapper.pm';
  if(defined $file)
  {
    note " ### inc/Alien/Base/Wrapper.pm ###";
    note join "\n", splice(@{[split /\n/, $file->content]}, 0, 20), "...";
    
  }

  $file = first { $_->name eq 'Makefile.PL' } @{ $tzil->files };
  note " ### Makefile.PL ###";
  note $file->content;

};

subtest 'alt location' => sub {

  my $tzil = Builder->from_config({ dist_root => 'corpus/Foo-XS' }, {
    add_files => {
      'source/dist.ini' => simple_ini(
        { name => 'Foo-XS' },
        [ 'GatherDir'  => {} ],
        [ 'MakeMaker' => {} ],
        [ 'MetaJSON'   => {} ],
        [ 'AlienBase::Wrapper::Bundle' => { filename => "alt/Alien/Base/Wrapper.pm" } ],
      ),
    },
  });

  $tzil->build;

  my $file = first { $_->name eq 'alt/Alien/Base/Wrapper.pm' } @{ $tzil->files };

  ok defined $file, 'has alt/Alien/Base/Wrapper.pm';
  if(defined $file)
  {
    note join "\n", splice(@{[split /\n/, $file->content]}, 0, 20), "...";
    
  }

};

subtest 'removes prereq' => sub {

  my $tzil = Builder->from_config({ dist_root => 'corpus/Foo-XS' }, {
    add_files => {
      'source/dist.ini' => simple_ini(
        { name => 'Foo-XS' },
        [ 'GatherDir'  => {} ],
        [ 'MakeMaker' => {} ],
        [ 'MetaJSON'   => {} ],
        [ 'Prereqs/ConfigureRequires'  => { '-phase' => 'configure', 'Alien::Base::Wrapper' => "0", } ],
        [ 'Prereqs/BuildRequires'      => { '-phase' => 'build',     'Alien::Base::Wrapper' => "0", } ],
        [ 'AlienBase::Wrapper::Bundle' => { filename => "alt/Alien/Base/Wrapper.pm" } ],
      ),
    },
  });

  $tzil->build;

  my $meta = decode_json((first { $_->name eq 'META.json' } @{ $tzil->files })->content);
  note YAML::Dump($meta->{prereqs});

  is($meta->{prereqs}->{configure}->{requires}->{'ExtUtils::MakeMaker'}, '0');
  is($meta->{prereqs}->{configure}->{requires}->{'Alien::Base::Wrapper'}, U());
  is($meta->{prereqs}->{build}    ->{requires}->{'Alien::Base::Wrapper'}, U());

};

subtest 'munger!' => sub {

  my $tzil = Builder->from_config({ dist_root => 'corpus/Foo-XS' }, {
    add_files => {
      'source/dist.ini' => simple_ini(
        { name => 'Foo-XS' },
        [ 'GatherDir'  => {} ],
        [ 'MakeMaker' => {} ],
        [ 'MetaJSON'   => {} ],
        [ 'AlienBase::Wrapper::Bundle' => {
          system_check => [ 
                            '| do {', 
                            '|   # STUFF', 
                            '| }'
                          ],
          system       => [ 
                            '| # use libfoo!', 
                            '| $WriteMakefileArgs{LIBS} = [ "-lfoo" ]',
                          ],
          alien        => [ qw( Alien::libfoo Alien::libbar@2.02 ) ],
        } ],
      ),
    },
  });

  $tzil->build;

  ok 1;

  my $file = first { $_->name eq 'Makefile.PL' } @{ $tzil->files };
  note " ### Makefile.PL ###";
  note $file->content;

  my $meta = decode_json((first { $_->name eq 'META.json' } @{ $tzil->files })->content);
  note YAML::Dump($meta->{prereqs});

  is($meta->{prereqs}->{configure}->{requires}->{'ExtUtils::MakeMaker'}, '6.52');
};

done_testing;
