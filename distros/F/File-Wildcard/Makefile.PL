use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

eval "require Params::Validate";

print <<END if $@;
I see you don't have Params::Validate installed.
No checking of incoming parameters will be done, and no sensible
diagnostics will be guaranteed. You can always install Params::Validate
afterwards.

END

WriteMakefile(
    NAME         => 'File::Wildcard',
    VERSION_FROM => 'lib/File/Wildcard.pm', # finds $VERSION
    AUTHOR       => 'I. Williams (ivorw-file-wildcard at xemaps.com)',
    ABSTRACT_FROM => 'lib/File/Wildcard.pm',
    PREREQ_PM    => {
                     'Module::Optional' => 0,
                    },
    LICENSE      => 'perl',
);
