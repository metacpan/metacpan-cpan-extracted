use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::FormHandlerX::Form::Login',
    AUTHOR              => q{Rob Brown <rob@intelcompute.com>},
    VERSION_FROM        => 'lib/HTML/FormHandlerX/Form/Login.pm',
    ABSTRACT_FROM       => 'lib/HTML/FormHandlerX/Form/Login.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Exception' => 0,
        'Digest::SHA' => 0,
        'Email::Valid' => 0,
        'HTML::FormHandler::Moose' => 0,
        'HTML::FormHandler' => 0,
        
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-FormHandlerX-Form-Login-*' },
);
