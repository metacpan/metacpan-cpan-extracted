use ExtUtils::MakeMaker;

my $file = 'cpp2xs';

open RD, '<', 'cpp_script.in' or die "Can't open cpp_script.in for reading: $!";
open OUT, '>', $file or die "Can't open $file for writing: $!";

print OUT <<"!GROK!THIS!";
$Config::Config{'startperl'}
    eval 'exec perl -S \$0 "\$@"'
        if 0;
!GROK!THIS!

while(<RD>) { print OUT $_ }

close RD or die "Can't close cpp_script.in after reading: $!";
close OUT or die "Can't close $file after writing: $!";

chmod 0555, $file;

my $twv = $] > 5.013 ? 0.23 : 0.21;
$twv = 0.24 if $] > 5.015;

my %options =
  (
  NAME     => 'InlineX::CPP2XS',
  PREREQ_PM => {
                'Inline'       => 0.50,
                'Inline::CPP'  => 0.39,
                'Test::Warn'   => $twv,
               },
  VERSION_FROM => 'CPP2XS.pm',
  LICENSE  => 'perl',
  EXE_FILES => ['cpp2xs'],
  clean => { FILES => 'cpp2xs' },
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/inlinex-cpp2xs.git',
        web => 'https://github.com/sisyphus/inlinex-cpp2xs',
      },
    },
  },
  );

WriteMakefile(%options);




