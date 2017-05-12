use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'MIME::DecodeText',
    'VERSION_FROM'	=> 'DecodeText.pm',
    'PREREQ_PM'		=> { MIME::Base64 => 0, MIME::QuotedPrint => 0 },
    ($] >= 5.005 ? (
       ABSTRACT_FROM	=> 'DecodeText.pm',
       AUTHOR		=> 'Vlad Danego <vlad@al.lg.ua>'
    ) : ())
);
