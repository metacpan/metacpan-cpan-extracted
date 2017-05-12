use ExtUtils::MakeMaker;

my $file = 'c2xs';

open RD, '<', 'script.in' or die "Can't open script.in for reading: $!";
open OUT, '>', $file or die "Can't open $file for writing: $!";

print OUT <<"!GROK!THIS!";
$Config::Config{'startperl'}
    eval 'exec perl -S \$0 "\$@"'
        if 0;
!GROK!THIS!

while(<RD>) { print OUT $_ }

close RD or die "Can't close script.in after reading: $!";
close OUT or die "Can't close $file after writing: $!";

chmod 0555, $file;

my $twv = $] > 5.013 ? 0.23 : 0.21; # Test::Warn version
$twv = 0.24 if $] > 5.015;

my %options =
  (
  NAME     => 'InlineX::C2XS',
  PREREQ_PM => {
                'Inline::C'  => '0.54',
                'Test::Warn' => $twv,
                'File::Path'  => '2.08_01',
               },
  VERSION_FROM => 'C2XS.pm',
  LICENSE  => 'perl',

  EXE_FILES => [$file],
  clean => {FILES => '_Inline_test c2xs exports.pm exports.xs demos/context/FOO-0.01/*.*
                      demos/context/FOO-0.01/MANIFEST demos/context/FOO-0.01/t/00load.t'},
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/inlinex-c2xs.git',
        web => 'https://github.com/sisyphus/inlinex-c2xs',
      },
    },
  },
  );

WriteMakefile(%options);

