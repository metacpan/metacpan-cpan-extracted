# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use ExtUtils::MakeMaker;

BEGIN { require 5.001 }


#--- Write the Makefile

my @ppd;

if ($] >= 5.00503) {
  @ppd = (
    AUTHOR    => 'Jonathan Kamens <jik@kamens.us>',
    ABSTRACT  => 'Module for manipulating E_Mail Alias files',
    META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
         homepage => 'https://github.com/jikamens/Mail-Alias',
         repository => {
           url => 'git://github.com/jikamens/Mail-Alias.git',
           web => 'https://github.com/jikamens/Mail-Alias',
           type => 'git',
         },
       },
    },
  );
}

WriteMakefile(
	VERSION_FROM   => "Alias.pm",
	NAME      => "Mail::Alias",
	@ppd
);

