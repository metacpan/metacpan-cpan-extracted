use Test2::V0 -no_srand => 1;
use Config;

eval { require 'Test/More.pm' };

# This .t file is generated.
# make changes instead to dist.ini

my %modules;
my $post_diag;

$modules{$_} = $_ for qw(
  Data::Section
  Dist::Zilla
  Dist::Zilla::Plugin::AutoMetaResources
  Dist::Zilla::Plugin::CopyFilesFromBuild
  Dist::Zilla::Plugin::Git
  Dist::Zilla::Plugin::InsertExample
  Dist::Zilla::Plugin::InstallGuide
  Dist::Zilla::Plugin::MinimumPerl
  Dist::Zilla::Plugin::OurPkgVersion
  Dist::Zilla::Plugin::PkgVersion::Block
  Dist::Zilla::Plugin::PodWeaver
  Dist::Zilla::Plugin::ReadmeAnyFromPod
  Dist::Zilla::Plugin::Run::BeforeBuild
  Dist::Zilla::Role::PluginBundle::Easy
  Dist::Zilla::Role::TextTemplate
  Dist::Zilla::Util::CurrentCmd
  ExtUtils::MakeMaker
  File::ShareDir::Dist
  File::ShareDir::Install
  File::Which
  File::chdir
  IPC::System::Simple
  Moose
  Path::Tiny
  Perl::PrereqScanner
  Perl::Tidy
  PerlX::Maybe
  PerlX::Maybe::XS
  Pod::Markdown
  Sub::Exporter::ForMethods
  Term::Encoding
  Test2::V0
  Test::Fixme
  Test::More
  Test::Pod
  Test::Pod::Coverage
  Test::Script
  Test::Version
  URI::Escape
  YAML
  namespace::autoclean
);

$post_diag = sub {
  use Dist::Zilla::Plugin::Author::Plicease;
  diag 'share dir = ', Dist::Zilla::Plugin::Author::Plicease->dist_dir;
};

my @modules = sort keys %modules;

sub spacer ()
{
  diag '';
  diag '';
  diag '';
}

pass 'okay';

my $max = 1;
$max = $_ > $max ? $_ : $max for map { length $_ } @modules;
our $format = "%-${max}s %s";

spacer;

my @keys = sort grep /(MOJO|PERL|\A(LC|HARNESS)_|\A(SHELL|LANG)\Z)/i, keys %ENV;

if(@keys > 0)
{
  diag "$_=$ENV{$_}" for @keys;

  if($ENV{PERL5LIB})
  {
    spacer;
    diag "PERL5LIB path";
    diag $_ for split $Config{path_sep}, $ENV{PERL5LIB};

  }
  elsif($ENV{PERLLIB})
  {
    spacer;
    diag "PERLLIB path";
    diag $_ for split $Config{path_sep}, $ENV{PERLLIB};
  }

  spacer;
}

diag sprintf $format, 'perl', "$] $^O $Config{archname}";

foreach my $module (sort @modules)
{
  my $pm = "$module.pm";
  $pm =~ s{::}{/}g;
  if(eval { require $pm; 1 })
  {
    my $ver = eval { $module->VERSION };
    $ver = 'undef' unless defined $ver;
    diag sprintf $format, $module, $ver;
  }
  else
  {
    diag sprintf $format, $module, '-';
  }
}

if($post_diag)
{
  spacer;
  $post_diag->();
}

spacer;

done_testing;

