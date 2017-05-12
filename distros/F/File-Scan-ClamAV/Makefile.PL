use ExtUtils::MakeMaker;

$ENV{CLAMD_PATH} ||= -e "/usr/local/sbin/clamd" ? 
	"/usr/local/sbin" : -e "/usr/sbin/clamd" ?
	"/usr/sbin" : -e "/usr/local/bin/clamd" ?
	"/usr/local/bin" : -e "/usr/bin/clamd" ?
	"/usr/bin" : "$ENV{HOME}/bin";

my $help = `$ENV{CLAMD_PATH}/clamd --help 2>&1` || '';
if ($help !~ /clam/i) {
  die "Cannot find clamd in $ENV{CLAMD_PATH} (or a number of other places)\n - are you sure clamav in installed?\n";
}

WriteMakefile(
    'NAME' => 'File::Scan::ClamAV',
    'VERSION_FROM' => 'lib/File/Scan/ClamAV.pm',
    'PREREQ_PM' => {},
    'ABSTRACT' => 'A simple interface to the Clam Anti-Virus system',
    'AUTHOR' => 'Colin Faber <cfaber@fpsn.net>',
    'LICENSE' => 'perl_5',
    'MIN_PERL_VERSION' => 5.006,
    'META_MERGE' => {
        'resources' =>  {
            'repository' => 'https://github.com/smith153/File-Scan-ClamAV',
        },
    },
);

sub MY::test {
  package MY;
  my $self = shift;
  my $make = $self->SUPER::test();
  $make =~ s/PERL_DL_NONLAZY=1/PERL_DL_NONLAZY=1 CLAMD_PATH=$ENV{CLAMD_PATH}/g;
  return $make;
}

