use strict;
use warnings;
use Dist::Zilla::PluginBundle::Author::Plicease;
use Config::INI::Reader;
use Path::Tiny qw( path );
use File::Temp qw( tempdir );

BEGIN {  @INC = map { ref($_) ? $_ : path($_)->absolute->stringify } @INC }

my $nl = 0;
my $in_config;

if($ARGV[0] eq '--default')
{
  $in_config = {};
  warn "using default";
  chdir(tempdir( CLEANUP => 1));
  mkdir 'My-Dist';
  chdir 'My-Dist';
}
else
{
  die "run from the directory with the dist.ini file" unless -r 'dist.ini';
  $in_config = Config::INI::Reader->read_file('dist.ini')->{'@Author::Plicease'};
}

die "unable to find [\@Author::Plicease] in your dist.ini" unless defined $in_config;

my $bundle = Bundle->new;

Dist::Zilla::PluginBundle::Author::Plicease::configure($bundle);

chdir(Path::Tiny->rootdir);

package
  Bundle;

sub new { bless {} }
sub payload { $in_config }
sub _my_add_plugin { shift->add_plugins(@_) }

sub add_plugins
{
  shift; # self
  foreach my $item (map { ref $_ ? [@$_] : [$_] } @_)
  {
    if(ref($item) eq 'ARRAY')
    {
      my %config = ref $item->[-1] eq 'HASH' ? %{ pop @$item } : ();
      my($moniker, $name) = @$item;
      
      print "\n" if $nl && %config;
      if(defined $name)
      {
        print "[$moniker / $name]\n";
      }
      else
      {
        print "[$moniker]\n";
      }

      foreach my $k (sort keys %config)
      {
        my $v = $config{$k};
        $v = [ $v ] unless ref $v;
        print "$k = $_\n" for @$v;
      }
      
      if(%config)
      {
        print "\n";
        $nl = 0;
      }
      else
      {
        $nl = 1;
      }

    }
    else
    {
      die "do not know how to handle " . ref $item;
    }
  }
}

