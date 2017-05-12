package Enbld::Tutorial;

use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

Enbld::Tutorial - Tutorial for Enbld

=head1 GRAMMAR OF DSL

At Enbld, DSL for exclusive use defines the conditions of the software installation. Here, explain the grammar of the DSL.

=head2 THE EXAMPLE OF CONDITIONS SCRIPT

  #!/usr/bin/perl

  use strict;
  use warnings;

  use lib "$ENV{HOME}/.enbld/extlib/lib/perl5/";

  use Enbld;

  enbld 'mydevenv' => build {

      target 'git' => define {
          version 'latest';
      };

  };

=head2 FUNDAMENTAL ARCHITECTURE

=over

=item * Specify system perl to shebang

  #!/usr/bin/perl

Enbld must be ran from system perl. Therefore, please be sure to specify the path to system perl as shebang>.

=item * Must set 'use strict' and 'use warnings'

  use strict;
  use warnings;

For modern perl scirpt, that must use.

=item * Set path to Enbld's module by using lib pragma

  use lib "$ENV{HOME}/.enbld/extlib/lib/perl5/";

Since Enbld's modules (C<Enbld.pm> etc.) are installed to C<$HOME/.enbld/extlib/lib/perl5/>, specify a path by a 'lib' pragma so that the modules can be loaded.

=item * Load Enbld module

  use Enbld;

Enbld module exports DSL's methods.

=back

=head2 THE FUNCTIONS FOR THE INSTALLATION OF THE SOFTWARE

It explains the functions which can be used for below by DSL of Enbld. All of these functionses are exported at the time point of "use Enbld".

Since DSL of Enbld is a perl-based, all the things that are not written here follow the grammar of perl.

=head3 enbld

  enbld 'mydevenv' => build {
      ...
  }

'enbld' is a functions which performs an installing the software.

The first arguments specifies an environmental name. If it is a string, it will not matter anything.

The second arguments is the code references which the 'build' functions returns.enbld builds a Software by running the code reference to which conditions were written.

=head3 build

'build' is a functions of only the returning code reference.

It is a functions of a raise sake about the readability as a DSL.

=head3 target

  target 'git' => define {
      ....
  };

'target' is a functions which defines the conditions of the installation for every software.

The first arguments specifies the name of a software. It is necessary to coincide the name of a software with the name displayed by C<enblder available>.

The second Arguments is the code references which a 'define' functions returns. 'target' defines the conditions of installations by running the code reference to which written the conditions of the installation.

=head3 define

'define' is a functions of only the returning code reference.

It is a functions of a raise sake about the readability as a DSL.

=head3 version

  target 'perl' => define {
      version '5.18.1';
  };

'version' is a functions which specifies a version number to install. It specifies a version number as an arguments.

A list of the version which can install can check by C<enblder available [software name]>.

An error will occur the version number not existing is specified.

  target 'git' => define {
      version 'latest';
  };

Moreover, if it is specified as 'latest' at a version, Enbld will specify and install the latest version automatically. There is no required of looking for the latest version by yourself.

  target 'perl' => define {
      version 'development';
  };

In addition, by a part of softwares, you can specify the version under development.

For example, at perl, even version numbers show under a development, it can install the newest development version by specifying it as 'development'.

Refer to the document of each Definition modules for a more.

=head3 make_test

  target 'git' => define {
      version 'latest';
      make_test 1;
  };

'make_test' is a functions for running test code at building.

if the value which serves as a true by perl is specified as an arguments (except udnef, and zero and a null character string), it runs test code at building.

If a test goes wrong, a build will also go wrong.

Usually, this features is come by off.

=head3 module_file

  target 'perl' => define {
      version 'latest';
      module_file 'cpanfile';
  };

'module_file' is a functions which it uses to install a modules using the modules install features which a programming language prepares.

For example, in perl, call cpanm and install a modules specified by cpanfile.

The argument is path of the modules definition file for the languages (i.e. cpanfile at perl ).

Refer to the document of each Definition modules for a more.

=head3 arguments

  target 'perl' => define {
      version 'latest';
      arguments '-Dusethreads';
  };

'arguments' is a functions which adds the arguments to the 'configure' script of each software.

The string specified by the arguments is handed over as it is.

=head3 annotation

  target 'perl' => define {
      version 'latest';
      arguments '-Dusethreads';
      annotation 'with thread support';
  };

'annotation' is a functions which carries out an add annotation.

Unlike the comments of a mere script, C<enblder freeze> also reproduce annotation.

=head2 THE FUNCTIONS FOR THE CREATION OF THE CONFIGURATION FILE

  conf '.vimrc' => load {
      from 'https://raw.github.com/magnolia-k/vimrc/master/.vimrc';
  };

Enbld also has a features for it not only building each software, but creating the Configuration file (DOTFILES) of each software.

In the above-mentioned e.g., it download the configuration file for vim (.vimrc) from GitHub, and set to home directory.

Moreover, in Enbld, since correlation of an installable software and the filename of a configuration file does not check, you can arrange any configuration files.

=head3 conf

  conf '.vimrc' => load {
  ...
  };

'conf' is a functions for creating a configuration file.

The first arguments specifies the filename of a configuration file.

When a directory is attached and specified, it interpreted as follows.

=over

=item * Relative path

A specified of a relative path will create a configuration file as a relative path from C<$HOME>.

For example, if it is specified as C<.module-starter/config>, the configuration file "config" will be created by C<$HOME/.module-starter/config>.

=item * Absolute Path

A specified of an absolute path will create a configuration file on the path.

For example, if it is specified as C</path/to/.module-starter/config>, the configuration file "config" will be created by C</path/to/.module-starter/config>.

However, be careful of an access permission.

=back

In addition, as long as a 'conf' functions is in the code reference specified as the arguments of the 'build' function, it may describe it anywhere.

  enbld 'mydevenv' => build {
      target 'vim' => define {
          version 'latest';

          conf '.vimrc' => load {
              from 'https://raw.github.com/magnolia-k/vimrc/master/.vimrc';
          }; # -> It's OK

      };

      conf '.bashrc' => set {
          content 'export PATH=$HOME/.enbld/bin:PATH';
      }; # -> It's also OK
  };

The second arguments is functionses which specify where Enbld acquire a configuration file from.

=head3 load

  conf '.vimrc' => load {
      from 'https://raw.github.com/magnolia-k/vimrc/master/.vimrc';
  };

Enbld download a configuration file from url specified by the arguments of the from functions.

An arguments is a code reference.

Enbld do nothing, when the files of the same content already exists. Even if a files exists, when the contents differ, Enbld change the filename of the existing files, and Enbld create a files as specified.

=head3 set

  conf '.bashrc' => set {
      content 'export PATH=$HOME/.enbld/bin:PATH';
  };

Enbld create a configuration file by the content specified by the arguments of the 'content' functions.

An arguments is a code reference.

Enbld do nothing, when the files of the same content already exists. Even if a files exists, when the contents differ, Enbld change the filename of the existing files, and Enbld create a files as specified.

=head3 copy

  conf '.vimrc' => copy {
      from '/path/to/.vimrc';
  };

Enbld copy and create a configuration file from the files specified by the arguments of the 'from' function.

An arguments is a code reference.

Enbld do nothing, when the files of the same content already exists. Even if a files exists, when the contents differ, Enbld change the filename of the existing files, and Enbld create a files as specified.

=head3 from

A 'from' functions is a functions which specifies the get origin of a configuration file.

Specify url or a full path as an arguments.

=head3 content

  conf '.vimrc' => set {
      content 'syntax on';
  };

A 'content' functions is a functions which specifies the content of a configuration file.

  conf '.wgetrc' => load {
      from 'http://xxx.xxx.xxx/.wgetrc';

      content 'proxy_user = user';
      content 'proxy_passwd = PassWord';
  }

Enbld can also add a postscript to the downloaded files using a 'content' Functions.

=head3 to

  conf 'filerc' => set {
    to "$ENV{HOME}/fileconfig";
    content 'setting string';
  };

'to' functions is a functions which specifies the deployment place of a configuration file.

Even when only a filename is specified as the arguments of a 'conf' functions, Enbld can control a deployment location by specifying a directory as to functions freely.

=head2 OPTIONS OF THE CONDITIONS SCIRPT

The conditions script can take some optionals. Here, explained the optional.

=head3 test

  $ ./conditions.pl --test

  $ ./conditions.pl -t

Option 'test' execute test at the installation.

=head3 force

  $ ./conditions.pl --force

  $ ./conditions.pl -f

Option 'force' installs all software also including an installed software by force.

=head3 deploy

  $ ./conditions.pl --deploy /path/to/install/

  $ ./conditions.pl -d /path/to/install/

Option 'deploy' specifies the installation location of the script which the condition script defined.

The deploy path can be specified by relative path or absolute path.

However, the release check of the new version of the software installed by 'deploy' is not made.

=head1 OTHER TOPICS

=head2 '.enbld' DIRECTORY COMPOSITION

'.enbld' directory has the following composition.

 $HOME/.enbld --+
                |
                +-- bin/         executable commands (symbolic links)
                |
                +-- lib/         library files       (symbolic links)
                |
                +-- include/     include files       (symbolic links)
                |
                +-- man/         man files           (symbolic links)
                |
                +-- share/       shared filed        (symbolic links)
                |
                +-- extlib/      Enbld's module files (e.g. lib/Enbld.pm)
                |
                +-- dists/       downloaded software' archivefiles
                |
                +-- etc/         other various files
                |
                +-- build/       software' build directory
                |
                +-- depository/  installed software' compornents files
                |   |
                |   +-- Software A
                |   |   |
                |   |   +-- version 1
                |   |   |
                |   |   +-- version 2
                |   |   |
                |   |
                |   +-- Software B
                |   |   |
                |   |   +-- version 1
                |   |   |
                |
                +--conf/         Enbld's configuration file
                |
                +--log/          Enbld's log files

Enbld installs software to C<$HOME/.enbld/depository/[Software Name]/[Version]/> and creates symbolic links to C<$HOME/.enbld/bin>, C<$HOME/.enbld/lib>, and so on. Therefore, it can change now easily a newer version.

=head1 SEE ALSO

L<Enbld>

L<enblder>

=head1 WEB SITE

L<https://github.com/magnolia-k/Enbld>

L<http://code-stylistics.net/enbld>

=head1 ISSUE REPORT

L<https://github.com/magnolia-k/Enbld/issues>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
