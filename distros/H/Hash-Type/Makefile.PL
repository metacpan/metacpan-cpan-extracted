use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  NAME           => 'Hash::Type',
  VERSION_FROM   => 'lib/Hash/Type.pm',
  PREREQ_PM      => {},
  ABSTRACT_FROM  => 'lib/Hash/Type.pm',
  AUTHOR         => 'Laurent Dami <dami@cpan.org>',
  META_MERGE => {
   resources => {
     homepage   => 'https://metacpan.org/author/DAMI',
     license    => 'http://www.perlfoundation.org/artistic_license_2_0',
     repository => 'https://github.com/damil/Hash-Type.git',
     bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-Type',
   },
 },
 );
