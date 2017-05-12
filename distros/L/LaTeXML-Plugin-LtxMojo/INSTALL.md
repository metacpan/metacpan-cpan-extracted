## Installing ltxMojo - the Web Service for LaTeXML

This manual assumes a Debian-based OS.

### Generics

1. Install a TeX distribution, e.g. TeXlive:

    ```
    $ sudo apt-get install texlive
    ```

2. Install Subversion
    
    ```
    $ sudo apt-get install subversion
    ```

3. Install LaTeXML dependencies
  
    ```
    $ sudo apt-get install libclone-perl \
    libdata-compare-perl perlmagick \
    libparse-recdescent-perl libxml-libxml-perl \
    libxml-libxslt-perl libarchive-zip-perl libio-string-perl libuuid-tiny-perl
    ```

4. Install LaTeXML from the arXMLiv branch:
    
    ```
    $ svn co https://svn.mathweb.org/repos/LaTeXML/branches/arXMLiv LaTeXML/
    $ cd LaTeXML/
    $ perl Makefile.PL
    $ make
    $ make test
    $ sudo make install
    ```

5. Install Mojolicious (bleeding edge)

    ```
    $ sudo apt-get install curl
    $ sudo sh -c "curl -L cpanmin.us | perl - Mojolicious"
    ```

### Deployment

There are two possible use cases currently supported - **standalone** deployment and **Apache+Mod_Perl** deployment.

0. Standard Perl build process

    ```
    $ perl Makefile.PL ; make ; make test
    $ sudo make install
    ```
    
1. Standalone

    You could deploy the application locally from the git checkout:

    ```
    $ morbo script/ltxmojo daemon
    ```
    
    or globally, after running ```sudo make install```:
    
    ```
    $ ltxmojo daemon
    ```

    Using the default "morbo" development server of the Mojolicious suite deploys a server at http://127.0.0.1:3000

    Another approach for standalone deployment is to reverse-proxy through Apache, which currently is the only way
    to deploy with good websocket support. Install additionally:
 
    ```
    $ sudo apt-get install libapache2-mod-proxy-html
    ```

    Then follow the instructions at: https://github.com/kraih/mojo/wiki/Apache-deployment#wiki-___top

2. Apache + Mod_Perl and Plack

  2.1. Install Apache as usual
    
    ```
    $ sudo apt-get install apache2
    ```

  2.2. Install Mod_perl 
  
    ```
    $ sudo apt-get install libapache2-mod-perl2
    ```

  2.3. Install Plack
  
    ```
    $ sudo apt-get install libplack-perl
    ```

  2.4. Grant permissiosn to www-data for the webapp folder:
  
    ```
    $ sudo chgrp -R www-data /path/to/LaTeXML-Plugin-ltxmojo/script
    $ sudo chmod -R g+w /path/to/LaTeXML-Plugin-ltxmojo/script
    ```

  2.5. Create a "latexml" file in /etc/apache2/sites-available and /etc/apache2/sites-enabled

    ```
    <VirtualHost *:80>
        ServerName latexml.example.com 
        DocumentRoot /path/to/LaTeXML-Plugin-ltxmojo/script
        Header set Access-Control-Allow-Origin *                                    

        PerlOptions +Parent
                                                                  
        <Perl>
          $ENV{PLACK_ENV} = 'production';
          $ENV{MOJO_HOME} = '/path/to/LaTeXML-Plugin-ltxmojo/script';
        </Perl>

        <Location />
          SetHandler perl-script
          PerlHandler Plack::Handler::Apache2
          PerlSetVar psgi_app /path/to/LaTeXML-Plugin-ltxmojo/script/ltxmojo
        </Location>

        ErrorLog /var/log/apache2/latexml.error.log
        LogLevel warn
        CustomLog /var/log/apache2/latexml.access.log combined
    </VirtualHost>
    ```
    
    For providing the requisite paths to profiles of bindings that do not come preinstalled with LaTeXML
    (namely for the sTeX, PlanetMath, arXMLiv and ZBL setups), set the respective environmental variable in
    the <Perl> block of the virtual host definition. All profiles add paths pointing to the $LATEXMLINPUTS environment,
    if defined. Note that all environment names ending in INPUTS may contain multiple directories,
    separated in the usual way via colons(:).

    Example setting all environments used in profiles thus far:

    ```
    <Perl>
      $ENV{PLACK_ENV} = 'production';
      $ENV{MOJO_HOME} = '/path/to/LaTeXML-Plugin-ltxmojo/script';
      $ENV{LATEXMLINPUTS} = '/first/path/to/custom/inputs:/second/path:/third/path:etc/etc/etc'
      $ENV{STEXSTYDIR} = '/path/to/stex/sty/directory'
      $ENV{ZBLINPUTS} = '/path/to/zbl/sty/'
      $ENV{PLANETMATHINPUTS} = '/path/to/planetmath/sty'
      $ENV{ARXMLIVINPUTS} = '/path/to/arxmliv/sty'
    </Perl>
    ```
   
    **Note:** Due to the current setup in Mojolicious, the server would work properly only if it is deployed as a
    top-level domain or subdomain. In other words, while "latexml.example.com" would work fine, "example.com/latexml"
    would run into quite some problems.
