package inc::bootstrap;
use Moose;
use File::Spec ();
use File::Basename ();

my $bs_file = "Dist/Zilla/Plugin/SimpleBootstrap.pm";

if (!$INC{$bs_file}) {
  my $real_lib = File::Spec->catdir(File::Basename::dirname(__FILE__), File::Spec->updir, 'lib');
  my $real_bs = "$real_lib/$bs_file";
  $INC{$bs_file} = $real_bs;
  require $real_bs;
  $INC{$bs_file} = $real_bs;
}

extends qw(Dist::Zilla::Plugin::SimpleBootstrap);
__PACKAGE__->meta->make_immutable;

1;
