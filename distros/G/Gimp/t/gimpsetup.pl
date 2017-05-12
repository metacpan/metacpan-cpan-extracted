# only one "test" result - 'gimp set up' at bottom
# relies on caller having first done:
#    use Test::*; # to make available ok()
#    use Gimp;
#    our $dir;
#    our $blibplugins; # where plugins are built to - #! line correct
# if encounters problems, does a die()

use strict;
use Config;
use File::Temp;
use IO::All;
require Alien::Gimp;

our $DEBUG = 0 unless defined $DEBUG;

my $sysplugins = Alien::Gimp->gimpplugindir;
die "plugins dir: $!" unless -d $sysplugins;
die "script-fu not executable: $!" unless -x "$sysplugins/script-fu";

our $dir = File::Temp->newdir($DEBUG ? (CLEANUP => 0) : ());
my $myplugins = "$dir/plug-ins";
our $blibplugins = "blib/plugins";
die "mkdir $myplugins: $!\n" unless mkdir $myplugins;
my $s = io("$blibplugins/Perl-Server")->all or die "unable to read the Perl-Server: $!";
write_plugin($DEBUG, 'Perl-Server', $s);
map { symlink_sysplugin($_) } qw(script-fu sharpen);
map { die "mkdir $dir/$_: $!" unless mkdir "$dir/$_"; }
  qw(palettes gradients patterns brushes dynamics);
my %files = (
  'tags.xml' => "<?xml version='1.0' encoding='UTF-8'?><tags></tags>\n",
  'gimprc' => "(plug-in-path \"$myplugins\")\n",
);
map { die "write $dir/$_: $!" unless io("$dir/$_")->print($files{$_}); }
  keys %files;

$ENV{GIMP2_DIRECTORY} = $dir;

ok(1, 'gimp set up');

sub symlink_sysplugin {
  local $_ = shift;
  s#.*/##;
  die "symlink $_: $!" unless symlink "$sysplugins/$_", "$myplugins/$_";
}

sub make_executable {
  my $file = shift;
  my $newfile = "$file.pl";
  die "rename $file $newfile: $!\n" unless rename $file, $newfile;
  die "chmod $newfile: $!\n" unless chmod 0700, $newfile;
}

# prepends $myplugins to filename
sub write_plugin {
  my ($debug, $file, $text) = @_;
  $file =~ s#.*/##;
  $file = "$myplugins/$file";
  # trying to be windows- and unix-compat in how to make things executable
  # $file needs to have no extension on it
  my $wrapper = "$file-wrap";
  die "write $file: $!" unless io($file)->print($text);
  if ($DEBUG) {
    die "write $wrapper: $!" unless io($wrapper)->print(<<EOF);
$Config{startperl}
\$ENV{MALLOC_CHECK_} = '3';
\$ENV{G_SLICE} = 'always-malloc';
my \@args = (qw(valgrind --read-var-info=yes perl), '$file', \@ARGV);
open STDOUT, '>', "valgrind-out.\$\$";
open STDERR, '>&', \*STDOUT;
die "failed to exec \@args: \$!\\n" unless exec \@args;
EOF
    make_executable($wrapper);
  } else {
    make_executable($file);
  }
}

my $EPSILON = 1e-6;
# true if same within $EPSILON
sub cmp_colour {
  my ($c1, $c2) = @_;
  !grep { abs(($c1->[$_]//0) - ($c2->[$_]//0)) > $EPSILON } (0..3);
}

1;
