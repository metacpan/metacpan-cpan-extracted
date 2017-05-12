# HTML-Element-Extended

$NAME = 'HTML-Element-Extended';

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => $NAME,
  VERSION_FROM => 'lib/HTML/ElementTable.pm',
  dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  PREREQ_PM    => {
    # Avoid older HTML::Element w/o new methods
    HTML::Element => 3.01,
    Data::Dumper  => 0,
  }
);
