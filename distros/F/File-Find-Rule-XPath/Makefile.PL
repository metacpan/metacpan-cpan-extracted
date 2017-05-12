use ExtUtils::MakeMaker;

my @xpath_module;
if(eval { require XML::LibXML }) {
  @xpath_module = (XML::LibXML => undef);
}
else {
  @xpath_module = (XML::XPath => undef);
}

WriteMakefile(
    'NAME'		=> 'File::Find::Rule::XPath',
    'VERSION_FROM'	=> 'lib/File/Find/Rule/XPath.pm',
    'PREREQ_PM'		=> {
                             Test::Simple       => 0.41,
                             File::Find::Rule   => undef,
                             @xpath_module
                           },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/File/Find/Rule/XPath.pm',
       AUTHOR        => 'Grant McLean <grantm@cpan.org>') : ()),
);
