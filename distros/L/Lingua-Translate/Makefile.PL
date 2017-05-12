use ExtUtils::MakeMaker;

WriteMakefile
    (
ABSTRACT => 'Lingua::Translate - Translate text from one language to another',
AUTHOR => 'Sam Vilain, <samv@cpan.org>',
NAME => "Lingua::Translate",
PREREQ_PM =>
  { HTML::TokeParser => 2.19,
    I18N::LangTags   => 0.27,
    LWP::UserAgent   => 1.73,
    Pod::Constants   => 0.15,
    Unicode::MapUTF8 => 1.09, },
VERSION_FROM => "lib/Lingua/Translate.pm",
    )

