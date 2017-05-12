use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME' => 'Lingua::EN::Summarize',
    'VERSION_FROM' => 'Summarize.pm', # finds $VERSION
    'PM' =>  {
        'Summarize.pm' => '$(INST_LIBDIR)/Summarize.pm',
        'Filters.pm'   => '$(INST_LIBDIR)/Summarize/Filters.pm',
    },
    'PREREQ_PM' => {
        'Text::Sentence' => 0,
        'Text::Wrap' => 0,
        'Carp' => 0,
    },
);
