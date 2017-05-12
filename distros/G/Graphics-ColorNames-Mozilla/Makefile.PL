# Makefile.PL for Graphics-ColorNames-Mozilla package
# taken and edited from Graphics::ColorNames' package
# $Id: Makefile.PL,v 0.11 2002/05/24 16:00:20 steve Exp steve $

use ExtUtils::MakeMaker;

WriteMakefile(
    'PM' => {
       'Mozilla.pm'     => '$(INST_LIBDIR)/Mozilla.pm',
    },
    'NAME'		=> 'Graphics::ColorNames::Mozilla',
    'VERSION_FROM'	=> 'Mozilla.pm',
    'PREREQ_PM'		=> {
       'Graphics::ColorNames' => 0.30,
    },
  ($] ge '5.005') ? (
    'AUTHOR'   => 'Steve Pomeroy <xavier@cpan.org>',
    'ABSTRACT' => 'RGB values for Mozilla\'s color names',
  ) : (),
);
