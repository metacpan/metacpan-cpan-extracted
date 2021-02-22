use ExtUtils::MakeMaker;

my %prereq_pm = (
  'Date::Manip'        => 0,
  'LWP::UserAgent'     => 0,
  'HTTP::Request'      => 0,
  'HTML::TableExtract' => 2.07,
  'MIME::Base64'       => 0,
  'Text::CSV'          => 0,
  'JSON'               => 0,
);

eval "use Text::CSV_XS";
if ($@) {
  print STDERR <<__MSG;
Note: This is not required, but installing Text::CSV_XS on your system
      will speed up the parsing of quote data in CSV format. A C
      compiler is necessary, however. In the meantime we will use
      Text::CSV_PP.
__MSG
}
else {
  # why enforce the dependency if we already know it's present? Well, in
  # the future, we might want to enforce a version dependency here.
#  $prereq_pm{'Text::CSV_XS'} = 0;
}

WriteMakefile(
  NAME         => 'Finance-QuoteHist',
  VERSION_FROM => 'lib/Finance/QuoteHist.pm',
  PREREQ_PM    => \%prereq_pm,
);
