     _   _       _            _         
    | | | | __ _(_)_ __   ___| | _____  
    | |_| |/ _` | | '_ \ / _ \ |/ / _ \ 
    |  _  | (_| | | | | |  __/   < (_) |
    |_| |_|\__,_|_|_| |_|\___|_|\_\___/ 
    HTTP   API  into     ESMTP

Japanese version of README is [README-JA.md](https://github.com/azumakuniyuki/Haineko/blob/master/README-JA.md)

What is Haineko ?
=================

Haineko is an HTTP API server for sending email from a browser or any HTTP client.
It is implemented as a web server based on Plack and relays an email posted by 
HTTP client as JSON to other SMTP server or external email cloud service.

Haineko runs on the server like following systems which can execute Perl 5.10.1
or later and Plack.

* OpenBSD
* FreeBSD
* NetBSD
* Mac OS X
* Linux

Supported email clouds to relay using Web API
---------------------------------------------

* [SendGrid](http://sendgrid.com) - lib/Haineko/SMTPD/Relay/SendGrid.pm
* [Amazon SES](http://aws.amazon.com/ses/) - lib/Haineko/SMTPD/Relay/AmazonSES.pm
* [Mandrill](http://mandrill.com) - lib/Haineko/SMTPD/Relay/Mandrill.pm


How to build, configure and run
===============================

System requirements
-------------------

* Perl 5.10.1 or later

Dependencies
------------

Haineko relies on:

* Archive::Tar (core module from v5.9.3)
* __Authen::SASL__
* __Class::Accessor::Lite__
* __Email::MIME__
* Encode (core module from v5.7.3)
* File::Basename (core module from v5)
* File::Copy (core module from v5.2)
* File::Temp (core module from v5.6.1)
* __Furl__
* Getopt::Long (core module from v5)
* IO::File (core module from v5.3.7)
* IO::Pipe (core module from v5.3.7)
* __IO::Socket::SSL__
* IO::Zlib (core module from v5.9.3)
* __JSON::Syck__
* MIME::Base64 (core module from v5.7.3)
* Module::Load (core module from v5.9.4)
* __Net::DNS__
* Net::SMTP (core module from v5.7.3)
* __Net::SMTPS__
* __Net::CIDR::Lite__
* __Parallel::Prefork__
* __Path::Class__
* __Plack__
* __Router::Simple__
* Scalar::Util (core module from v5.7.3)
* __Server::Starter__
* Sys::Syslog (core module from v5)
* Time::Piece (core module from v5.9.5)
* __Try::Tiny__

Dependencies with Basic Authentication
--------------------------------------

Haineko with Basic Authentication at sending an email relies on the following modules:

* __Crypt::SaltedHash__
* __Plack::MiddleWare::Auth::Basic__

Dependencies with Haineko::SMTPD::Relay::AmazonSES
--------------------------------------------------

If you will use Haineko::SMTPD::Relay::AmazonSES, please install the following
modules.

* __XML::Simple__ 2.20 or later

Get the source
--------------

    $ cd /usr/local/src
    $ git clone https://github.com/azumakuniyuki/Haineko.git

A. Build and install from CPAN using cpanm
------------------------------------------

    $ sudo cpanm Haineko
    $ export HAINEKO_ROOT=/path/to/some/dir/for/haineko
    $ hainekoctl setup --dest $HAINEKO_ROOT
    $ cd $HAINEKO_ROOT
    $ vi ./etc/haineko.cf

    And edit other files in etc/ directory if you needed.

Run by the one of the followings:

    $ plackup -o '127.0.0.1' -p 2794 -a libexec/haineko.psgi
    $ hainekoctl start --devel

B. Run at the source directory
------------------------------

    $ cd ./Haineko
    $ sudo cpanm --installdeps .
    $ ./bin/hainekoctl setup --dest .
    $ vi ./etc/haineko.cf

    And edit other files in etc/ directory if you needed.

Run by the one of the followings:

    $ plackup -o '127.0.0.1' -p 2794 -a libexec/haineko.psgi
    $ ./bin/hainekoctl start --devel

C. Build and install into /usr/local/haineko
--------------------------------------------

### 1. Prepare ``configure'' script

    $ cd ./Haineko
    $ ./bootstrap
    $ sh configure --prefix=/path/to/dir (default=/usr/local/haineko)

### 2. Install required modules

    $ make depend

OR

    $ cpanm -L./dist --installdeps .

### 3. Build haineko

    $ make && make test && sudo make install

    $ /usr/local/haineko/bin/hainekoctl setup --dest /usr/local/haineko
    $ cd /usr/local/haineko
    $ vi ./etc/haineko.cf

    And edit other files in etc/ directory if you needed.

    $ export PERL5LIB=/usr/local/haineko/lib/perl5

Run by the one of the followings:

    $ plackup -o '127.0.0.1' -p 2794 -a libexec/haineko.psgi
    $ ./bin/hainekoctl start --devel

D. Build and install into /usr/local
------------------------------------

    $ cd ./Haineko
    $ sudo cpanm .
    $ sudo cpanm -L/usr/local --installdeps .

    $ /usr/local/bin/hainekoctl setup --dest /usr/local/etc
    $ cd /usr/local
    $ vi ./etc/haineko.cf

    And edit other files in etc/ directory if you needed.

Run by the one of the followings:

    $ plackup -o '127.0.0.1' -p 2794 -a libexec/haineko.psgi
    $ ./bin/hainekoctl start --devel

Starting Haineko server
-----------------------

### Use plackup command

    $ plackup -o 127.0.0.1 -p 2794 -a libexec/haineko.psgi

### Use wrapper script

    $ bin/hainekoctl start --devel -a libexec/haineko.psgi

The following command shows other options of bin/hainekoctl:

    $ bin/hainekoctl help

Configuration files in /usr/local/haineko/etc
---------------------------------------------
Please have a look at the complete format description in each file listed at the
followings. These files are read from Haineko as a YAML-formatted file.

### etc/haineko.cf
Main configuration file for Haineko. If you want to use other configuration file,
set $HAINEKO\_CONF environment variable like 'export HAINEKO\_CONF=/etc/neko.cf'.

### etc/mailertable
Defines "mailer table": Recipient's domain part based routing table like the 
same named file in Sendmail. This file is taken precedence over the routing 
table defined in etc/sendermt for deciding the mailer.

### etc/sendermt
Defines "mailer table" which decide the mailer by sender's domain part.

### etc/authinfo
Provide credentials for client side authentication information. 
Credentials defined in this file are used at relaying an email to external
SMTP server.

__This file should be set secure permission: The only user who runs haineko server
can read this file.__

### etc/relayhosts
Permitted hosts or network table for relaying via /submit.

### etc/recipients
Permitted envelope recipients and domains for relaying via /submit.

### etc/password
Username and password pairs for basic authentication. Haineko require an username
and a password at receiving an email if HAINEKO_AUTH environment variable was set.
The value of HAINEKO_AUTH environment variable is the path to password file.

__This file should be set secure permission: The only user who runs haineko server
can read this file.__

### Configuration data on the web

/conf display Haineko configuration data but it can be accessed from 127.0.0.1

Environment Variables
---------------------

### HAINEKO_ROOT

Haineko decides the root directory by HAINEKO_ROOT or the result of `pwd` command,
and read haineko.cf from HAINEKO_ROOT/etc/haineko.cf if HAINEKO_CONF environment
variable is not defined.

### HAINEKO_CONF

The value of HAINEKO_CONF is the path to __haineko.cf__ file. If this variable is
not defined, Haineko finds the file from HAINEKO_ROOT/etc directory. This variable
can be set with -C /path/to/haineko.cf at bin/hainekoctl script.

### HAINEKO_AUTH

Haineko requires Basic-Authentication at connecting Haineko server when HAINEK_AUTH
environment variable is set. The value of HAINEKO_AUTH should be the path to the
password file such as 'export HAINEKO_AUTH=/path/to/password'. This variable can be
set with -A option of bin/hainekoctl script.

### HAINEKO_DEBUG

Haineko runs on debug(development) mode when this variable is set. -d, --devel,and
--debug option of bin/hainekoctl turns on debug mode. When Haineko is running on
developement mode, you can send email data using GET method.

SAMPLE CODE IN EACH LANGUAGE
----------------------------

Sample codes in each language are available in eg/ directory: Perl, Python Ruby,
PHP, Java script(jQuery) and shell script.

SPECIAL NOTES FOR OpenBSD
-------------------------
If you look error messages like following at running configure,

    Provide an AUTOCONF_VERSION environment variable, please
    aclocal-1.10: autom4te failed with exit status: 127
    *** Error code 1

Set AUTOCONF_VERSION environment variable.

    $ export AUTOCONF_VERSION=2.60


REPOSITORY
----------
https://github.com/azumakuniyuki/Haineko

AUTHOR
------
azumakuniyuki

LICENSE
-------

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


