use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::FormHandlerX::Form::JQueryValidator',
    VERSION_FROM      => 'lib/HTML/FormHandlerX/Form/JQueryValidator.pm', # finds $VERSION
    PREREQ_PM         => {
			   HTML::FormHandler => 0,
			   JSON => 0,
			   URI => 0,
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
       ( AUTHOR         => 'Aaron Trevena <teejay@cpan.org>') : ()),
);
