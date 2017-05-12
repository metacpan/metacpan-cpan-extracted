use ExtUtils::MakeMaker;

print "\nWelcome to the installation of Device::Audiotron.\n\n";

WriteMakefile (
              NAME         => "Device::Audiotron",
              VERSION_FROM => "Audiotron.pm",
              dist         => {
                                   COMPRESS => 'gzip -9f', 
                                   SUFFIX => 'gz'
                              }
	      );

print <<End_of_Text;

Now do the following to install Device::Audiotron:

    % make 
    % make test
    % make install

End_of_Text
