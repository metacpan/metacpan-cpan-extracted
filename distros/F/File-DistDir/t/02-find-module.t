use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::DistDir;

my $root = tempdir( CLEANUP => 1 );
make_path( "$root/config", "$root/nested", "$root/Testing" );

foreach my $filename (qw(redis.xml nested/redis.xml config/example.xml nested/example.json)) {
  open my $fh, '>', "$root/$filename" or die $!;
  print {$fh} "test\n";
  close $fh;
}
symlink 'nested', "$root/alias" or die $!;

my $dist;
{
  no warnings 'redefine';

  local *File::DistDir::dist_dir = sub { return $root };
  $dist = File::DistDir->new( distribution => 'Example-Dist' );
}

is_deeply( [ $dist->find('*.xml') ],        [qw(config/example.xml nested/redis.xml redis.xml)], 'recursive glob search' );
is_deeply( [ $dist->find('redis.xml') ],    [qw(nested/redis.xml redis.xml)],                    'basename search' );
is_deeply( [ $dist->find('nested/*.xml') ], [qw(nested/redis.xml)],                              'relative-path search' );
is_deeply( [ $dist->find('*.json') ],       [qw(nested/example.json)],                           'other extensions' );
is_deeply( [ $dist->find('absent.xml') ],   [],                                                  'no matches' );

my $ok = eval { $dist->find(); 1 };
ok( !$ok && $@ =~ /requires a filename pattern/, 'pattern required' );

my $module_file = "$root/Testing/Example.pm";
open my $fh, '>', $module_file or die $!;
print {$fh} "package Testing::Example; 1;\n";
close $fh;

{
  no warnings 'redefine';

  local *File::DistDir::dist_dir = sub {
    my ($name) = @_;

    die "distribution not installed\n"
      if $name eq 'Testing-Example';

    return $root;
  };
  local *Module::Metadata::new_from_module = sub {
    return bless { filename => $module_file }, 'Test::ModuleMetadata';
  };
  local *ExtUtils::Installed::new = sub { return bless {}, 'Test::Installed'; };

  my $module_dist = File::DistDir->new( module => 'Testing::Example' );
  is( $module_dist->{distribution}, 'Another-Dist', 'module ownership comes from packlist, not module spelling' );
}

{

  package Test::ModuleMetadata;
  sub filename { return $_[0]->{filename}; }
}
{

  package Test::Installed;
  sub modules { return ('Another::Dist'); }

  sub packlist {
    return bless { $module_file => {} }, 'ExtUtils::Packlist';
  }
}

done_testing();
