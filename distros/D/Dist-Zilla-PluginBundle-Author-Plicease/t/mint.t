use strict;
use warnings;
use 5.008001;
use Test::More;
use File::Temp qw( tempdir );
use File::chdir;
use Dist::Zilla::App;
use Capture::Tiny qw( capture_merged );
use Test::File;
use Test::Dir;
use YAML ();
use Path::Class qw( dir );
use Test::File::ShareDir
  -share => {
    -module => {
      'Dist::Zilla::MintingProfile::Author::Plicease' => dir->subdir('profiles')->stringify,
    },
  };

plan skip_all => 'for now';
plan skip_all => 'test requires Dist::Zilla::Plugin::Git' unless eval qq{ use Dist::Zilla::Plugin::Git; 1 };
plan skip_all => 'test requires Perl::PrereqScanner' unless eval qq{ use Perl::PrereqScanner; 1; };
plan skip_all => 'test requires Term::Encoding' unless eval qq{ use Term::Encoding; 1; };
plan tests => 1;

$Dist::Zilla::Plugin::Author::Plicease::Init2::chrome = 
$Dist::Zilla::Plugin::Author::Plicease::Init2::chrome = 'My::Chrome';

@INC = map { dir($_)->absolute->stringify } @INC;

subtest 'dzil' => sub {
  plan tests => 3;

  local $CWD = tempdir( CLEANUP => 1 );

  subtest 'new' => sub {
    plan tests => 3;

    my($out) = capture_merged {
      eval {
        local @ARGV = ('new', '-P', 'Author::Plicease', 'Foo::Bar');
        local $ENV{DIST_ZILLA_PLUGIN_AUTHOR_PLICEASE_INIT2_NO_GITHUB} = 1;
        #print "INC=$_\n" for @INC;    
        print "+ @ARGV\n";
        Dist::Zilla::App->run;    
      };
      if(my $error = $@)
      {
        print "EXCEPTION:$error\n";
      }
    };  

    if(-e 'Foo-Bar/lib/Foo/Bar.pm')
    {
      note $out;
    }
    else
    {
      diag $out;
    }
    dir_exists_ok 'Foo-Bar';
    file_exists_ok 'Foo-Bar/dist.ini';
    file_exists_ok 'Foo-Bar/lib/Foo/Bar.pm';
  };

  subtest 'build' => sub {
  
    plan skip_all => 'previous step failed' unless -d 'Foo-Bar';
    plan tests => 1;
  
    chdir 'Foo-Bar';

    my($out) = capture_merged {
      eval {
        local @ARGV = ('build');
        local $ENV{DIST_ZILLA_PLUGIN_AUTHOR_PLICEASE_INIT2_NO_GITHUB} = 1;
        #print "INC=$_\n" for @INC;    
        print "+ @ARGV\n";
        Dist::Zilla::App->run;    
      };
      if(my $error = $@)
      {
        print "EXCEPTION:$error\n";
      }
    };  

    note $out;
  
    file_exists_ok 'Foo-Bar-0.01';
    
    chdir '..';
  
  };
  
  subtest 'test' => sub {
  
    plan skip_all => 'previous step failed' unless -d 'Foo-Bar';
    plan tests => 2;
  
    chdir 'Foo-Bar';

    my($out) = capture_merged {
      eval {
        local @ARGV = ('test');
        local $ENV{DIST_ZILLA_PLUGIN_AUTHOR_PLICEASE_INIT2_NO_GITHUB} = 1;
        #print "INC=$_\n" for @INC;    
        print "+ @ARGV\n";
        Dist::Zilla::App->run;    
      };
      if(my $error = $@)
      {
        print "EXCEPTION:$error\n";
      }
    };  

    note $out;
    dir_exists_ok '.build';
    dir_empty_ok '.build';

    chdir '..';
  
  };
  
};

package
  My::Chrome;

sub prompt_str
{
  my($self, $prompt) = @_;
  
  return 'My abstract' if $prompt eq 'abstract';
  return 'plicease' if $prompt eq 'github user';
  
  die "something else:\n" . YAML::Dump(@_);
}

sub prompt_yn
{
  my($self, $prompt) = @_;

  return 1 if $prompt eq 'include release tests?';
  
  die "something else:\n" . YAML::Dump(@_);
}
