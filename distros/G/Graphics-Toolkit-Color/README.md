### NAME

    Graphics-Color-Toolkit - color palette creation tool 

### VERSION
 
    1.0

[on CPAN](https://metacpan.org/pod/Graphics-Color-Toolkit)

    This is the landing page for the user documentation.
    There is also a download link on the left side under "Tools".
   

### BUILDING

    The git repository contains much more than the software package itself.
    If you check out sources here, you have to build the package yourself.
    In order to do that you need perl and the module Dist::Zilla.
    
    cpan install Dist::Zilla   
        or 
    cpanm Dist::Zilla

    
    Then you have to check which further the Dist::Zilla plugins you miss:
    
    dzil authordeps
    
    and pipe them into your preferred installer:
    
    dzil authordeps | cpanm
    
  
    Than you can build a release yourself:

    dzil build
    
    Which gives you basically the same tgz file as under the download link
    from CPAN (as describes under HOME), just with more up to date 
    (and maybe buggy) sources. Don't forget to:
    
    dzil clean


### INSTALLING

    Once you downloaded or created a build, you unzip it and do the usual:
 
        perl Makefile.PL
        make
        make test
        make install

    This should install to your site_perl directory.


### PREREQUISITES

    Carp 1.35 or higher
    
    Optionally modules of the Graphics::ColorNames::* namespace are
    required if your color definitions calls for them.
    (see Chart::Color for details)
    
 
[CHANGES](https://github.com/lichtkind/Graphics-Color-Toolkit/blob/main/Changes) (with roadmap)

[CONTRIBUTING](https://github.com/lichtkind/Graphics-Color-Toolkit/blob/main/CONTRIBUTING)

[CONTRIBUTORS](https://metacpan.org/pod/Graphics-Color-Toolkit#CONTRIBUTORS)


### AUTHOR

    - Herbert Breunung (lichtkind@cpan.org)


### COPYRIGHT

    Copyright(c) 2022 by Herbert Breunung

    All rights reserved.  This program is free software; you can
    redistribute it and/or modify it under the same terms as Perl 
    itself.
