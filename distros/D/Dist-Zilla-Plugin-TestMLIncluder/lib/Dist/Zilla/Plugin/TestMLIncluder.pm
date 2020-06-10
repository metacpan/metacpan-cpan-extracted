package Dist::Zilla::Plugin::TestMLIncluder;
our $VERSION = '0.19';

use Moose;
with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::FileMunger';
with 'Dist::Zilla::Role::PrereqSource';

use Dist::Zilla::File::InMemory;
use IO::All;

# Check that author has TestML enabled:
my $testml_root;
BEGIN {
  $testml_root = $ENV{TESTML_ROOT};

  if (not $ENV{PERL_ZILD_TEST_000_COMPILE_MODULES}) {
    die <<'...' if not defined $testml_root;
--------------------------------------------------------------------------------
TESTML_ROOT is not set in your environment.
This means TestML is not set up properly.

For more information, see:
https://github.com/testml-lang/testml/wiki/publishing-cpan-modules-with-testml-tests
--------------------------------------------------------------------------------
...

    -d $testml_root and -f "$testml_root/bin/testml"
      or die "Invalid TESTML_ROOT '$testml_root'";

    # Load the local TestML::Compiler:
    unshift @INC, "$testml_root/src/testml-compiler-perl/lib";
    require TestML::Compiler;
  }
}

# Pull the local Perl TestML modules into inc/lib/:
sub gather_files {
  my ($self) = @_;

  for my $file (io("$testml_root/src/perl/lib")->All_Files) {
    my $path = $file->pathname;
    $path =~ s{\Q$testml_root\E/src/perl/}{};
    $self->add("inc/$path", $file->all);
  }

  # Also add the user-side-only TestML runner bin: 'testml-cpan':
  my $testml_cpan = <<'...';
#!/usr/bin/perl

use lib 't', 'inc/lib';

use TestML::Run::TAP;

my $testml_file = $ARGV[-1];
my $test_file = $testml_file;

$test_file =~ s/(.*)\.t$/inc\/$1.tml.lingy/
  or die "Error with '$testml_file'. testml-cpan only works with *.t files.";
-e $test_file
  or die "TestML file '$testml_file' not compiled as '$test_file'";

TestML::Run::TAP->run($test_file);
...

  $self->add(
    "inc/bin/testml-cpan",
    $testml_cpan,
  );
}

# Modify TestML .t files and the Makefile.PL (on the user side):
sub munge_file {
  my ($self, $file) = @_;

  # Change shebang lines for TestML .t files:
  if ($file->name =~ m{^t/.*\.t$}) {
    my $content = $file->content;
    return unless $content =~ /\A#!.*testml.*/;
    $content =~ s{\A#!.*testml.*}{#!inc/bin/testml-cpan};
    $file->content($content);

    # Then precompile the TestML .t files to Lingy/JSON:
    my $compiler = TestML::Compiler->new;
    my $lingy = $compiler->compile($content, $file->name);
    my $name = $file->name;
    $name =~ s/\.t$// or die;
    $name = "inc/$name.tml.lingy";

    $self->add($name => $lingy);
  }
  # Add a footer to Makefile.PL to use the user's perl in testml-cpan:
  elsif ($file->name eq 'Makefile.PL') {
    my $content = $file->content;
    $content .= <<'...';

use Config;
use File::Find;

my $file = 'inc/bin/testml-cpan';
open IN, '<', $file or die "Can't open '$file' for input";
my @bin = <IN>;
close IN;

shift @bin;
unshift @bin, "#!$Config{perlpath}\n";
open OUT, '>', $file or die "Can't open '$file' for output";
print OUT @bin;
close OUT;

chmod 0755, 'inc/bin/testml-cpan';

if ($^O eq 'MSWin32') {
  my $file = 'inc/bin/testml-cpan.cmd';
  open OUT, '>', $file or die "Can't open '$file' for output";
  print OUT 'if exist "%~dpn0" perl %0 %*', "\r\n";
  close OUT;

  find sub {
    return unless -f && /\.t$/;
    my $file = $_;
    open IN, '<', $file or die "Can't open '$file' for input";
    return unless <IN> =~ /testml-cpan/;
    my $text = do {local $/; <IN>};
    close IN;
    open OUT, '>', $file or die "Can't open '$file' for output";
    print OUT '#!inc\\bin\\testml-cpan', "\r\n";
    print OUT $text;
    close OUT;
  }, 't';
}
...
    $file->content($content);
  }
}

sub add {
  my ($self, $name, $content) = @_;

  $self->add_file(
    Dist::Zilla::File::InMemory->new(
      name => $name,
      content => $content,
    )
  );
}

sub register_prereqs {
  my $self = shift;
  $self->zilla->register_prereqs(
    {
      type  => 'requires',
      phase => 'test',
    },
    'JSON::PP' => 0,
  );
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;
