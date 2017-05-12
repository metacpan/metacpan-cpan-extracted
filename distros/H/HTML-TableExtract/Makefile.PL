use ExtUtils::MakeMaker;

my %prereq_pm = (
  'HTML::Parser' => 0,
);

# The idea is to skip tests and dependencies on H::ET if it is not
# installed at all. If it is presently installed, however, enforce the
# version dependency.
my $et_version = '1.16';
eval "use HTML::ElementTable";
unless ($@) {
  $prereq_pm{'HTML::ElementTable'} = $et_version;
}

WriteMakefile(
  NAME         => 'HTML-TableExtract',
  VERSION_FROM => 'lib/HTML/TableExtract.pm',
  PREREQ_PM    => \%prereq_pm,
);
