use ExtUtils::MakeMaker;

WriteMakefile
 ( NAME          => 'Mail::Box::Parser::C'
 , VERSION_FROM  => 'lib/Mail/Box/Parser/C.pm'
 , PREREQ_PM     =>
     { Test::More => 0.47
     }
 , ABSTRACT      => 'Parse mbox files with XS'
 , AUTHOR        => 'Mark Overmeer'
 , LICENSE       => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-Mail-Box-Parser-C.git'
              , web  => 'https://github.com/markov2/perl5-Mail-Box-Parser-C'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/mail-box-parser-c/raw
DISTDIR         = ../public_html/mail-box-parser-c/source

# for POD
FIRST_YEAR      = 2002
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/

__POSTAMBLE

