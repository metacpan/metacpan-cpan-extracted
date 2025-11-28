#! perl
use strict;
use warnings;
use Config;
use File::Spec::Functions 0 qw/catdir catfile/;
use IPC::Open2;
use Test::More 0.88;
use lib 't/lib';
use DistGen qw/undent/;
use XSLoader;

local $ENV{PERL_INSTALL_QUIET};
local $ENV{PERL_MB_OPT};

#--------------------------------------------------------------------------#
# fixtures
#--------------------------------------------------------------------------#

my $dist = DistGen->new(name => 'Foo::Bar');
$dist->chdir_in;
$dist->add_file('planner/dynamic.pl', undent(<<'	---'));
	load_extension("Dist::Build::DynamicPrereqs");
	evaluate_dynamic_prereqs();
	---

$dist->regen;

my $interpreter = ($Config{startperl} eq $^X )
                ? qr/#!\Q$^X\E/
                : qr/(?:#!\Q$^X\E|\Q$Config{startperl}\E)/;
my ($guts, $ec);

sub _mod2pm   { (my $mod = shift) =~ s{::}{/}g; return "$mod.pm" }
sub _path2mod { (my $pm  = shift) =~ s{/}{::}g; return substr $pm, 5, -3 }
sub _mod2dist { (my $mod = shift) =~ s{::}{-}g; return $mod; }
sub _slurp { do { local (@ARGV,$/)=$_[0]; <> } }

#--------------------------------------------------------------------------#
# configure
#--------------------------------------------------------------------------#

{
  ok(my $pid = open2(my ($in, $out), $^X, 'Build.PL', '--install_base', 'install'), 'Running Build.PL') or BAIL_OUT("Couldn't run Build.PL");
  my $output = do { local $/;  <$in> };

  is(waitpid($pid, 0), $pid, 'Ran Build.PL successfully');
  is($?, 0, 'Build returned 0') or BAIL_OUT("");
  like($output, qr/Creating new 'Build' script for 'Foo-Bar' version '0.001'/, 'Output as expected');

  ok( -f 'Build', "Build created" );
  if ($^O eq 'MSWin32') {
    ok( -f 'Build.bat', 'Build is executable');
  }
  else {
    ok( -x 'Build', "Build is executable" );
  }

  open my $fh, "<", "Build";
  my $line = <$fh>;

  like( $line, qr{\A$interpreter}, "Build has shebang line with \$^X" );
  ok( -f '_build/params', "_build/params created" );
  ok( -f '_build/graph', "_build/graph created" );
}

#--------------------------------------------------------------------------#
# build
#--------------------------------------------------------------------------#

{
  ok( my $pid = open2(my($in, $out), $^X, 'Build'), 'Can run Build' );
  my $output = do { local $/; <$in> };
  is( waitpid($pid, 0), $pid, 'Could run Build');
  is($?, 0, 'Build returned 0');
  my $filename = catfile(qw/lib Foo Bar.pm/);
  like($output, qr{\Q$filename}, 'Build output looks correctly');
  ok( -d 'blib',        "created blib" );
  ok( -d 'blib/lib',    "created blib/lib" );
  ok( -d 'blib/script', "created blib/script" );

  # check pm
  my $pmfile = _mod2pm($dist->name);
  ok( -f 'blib/lib/' . $pmfile, "$dist->{name} copied to blib" );
  is( _slurp("lib/$pmfile"), _slurp("blib/lib/$pmfile"), "pm contents are correct" );
  is((stat "blib/lib/$pmfile")[2] & 0222, 0, "pm file in blib is readonly" );

  require CPAN::Meta;
  my $meta = CPAN::Meta->load_file("MYMETA.json");
  my $req = $meta->effective_prereqs->requirements_for('runtime', 'requires');
  my $dynamic_dependency = join ',', sort $req->required_modules;

  is($dynamic_dependency, 'Bar,perl', 'Dependency on Foo has been inserted');
}

done_testing;
