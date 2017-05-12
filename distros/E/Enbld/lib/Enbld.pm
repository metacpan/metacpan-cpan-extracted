package Enbld;

use strict;
use warnings;

use Carp;

use 5.010001;

our $VERSION = '0.7041';

use FindBin qw/$Script/;
use Getopt::Long;
use Try::Lite;

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw/
    enbld
    build
    target
    define
    version
    make_test
    module_file
    modules
    arguments
    annotation
    conf
    load
    copy
    set
    from
    to
    content
/;

require Enbld::App::Configuration;
require Enbld::Logger;
require Enbld::Target;
require Enbld::Condition;
require Enbld::Error;
require Enbld::Exception;
require Enbld::RcFile;
require Enbld::Deployed;

our $initialized;
our %target_result;
our %rcfile_result;

our %rcfile_collection;
our %target_collection;

sub enbld($$) {
    my ( $envname, $coderef ) = @_;

    if ( ref( $envname ) ) {
        _err(
                "Function 'enbld' first requires " .
                "string type parameter 'env name'."
                );
    }

    if ( $envname =~ /[^0-9a-zA-Z_]/ ) {
        _err(
                "Env name '$envname' contains invalid character.",
                $envname
                );
    }

    if ( ref( $coderef ) ne 'CODE' ) {
        _err( "Function 'enbld' second requires code reference parameter." );
    }

    require Enbld::Message;
    Enbld::Message->set_verbose;

    parse_option();

    require Enbld::Home;
    Enbld::Home->initialize;

    Enbld::App::Configuration->read_file;
    Enbld::App::Configuration->set_envname( $_[0] );

    $initialized++;

    $_[1]->();

    Enbld->_setup_directory;

    foreach my $name ( sort keys %target_collection ) {
        build_target( $name );
    }

    foreach my $filepath ( sort keys %rcfile_collection ) {
        do_rcfile( $rcfile_collection{$filepath} );
    }

    undef $initialized;

    show_result_message();

    check_targets_in_DSL();

    if ( ! Enbld::App::Configuration->is_dirty ) {
        Enbld::Message->notify(
                "INFO:No builded targets & loaded configuration file."
                );
    }

    return 1;
}

sub build_target {
    my $name = shift;

    my $config = Enbld::Feature->is_deploy_mode ? undef :
        Enbld::App::Configuration->search_config( $name );

    my $target = Enbld::Target->new( $name, $config );

    my $installed = try {
        return Enbld::Feature->is_deploy_mode ?
            $target->deploy_declared( \%target_collection ) :
            $target->install_declared( \%target_collection );
    } ( 'Enbld::Error' => sub {
        Enbld::Message->alert( $@ );

        if ( $^O ne 'darwin' ) {
            say "If you run Enbld at Linux or BSD, there is a possibility " .
            "that the Software which depends is not installed.";
        }

        say "\n" . "Please check build logile:" . Enbld::Logger->logfile;

        $target_result{$name} = $name . ' is failure to build.';

        return;
        }
      );

    # Target is installed.
    if ( $installed ) {
        $target_result{$name} = $name . ' ' . $installed->enabled .
            " is installed.";

        Enbld::App::Configuration->set_config( $installed );
        Enbld::App::Configuration->write_file;

        if ( Enbld::Feature->is_deploy_mode ) {
            Enbld::Deployed->add( $installed );
        }

        return $name;
    }

    # Target is up-to-date.
    $target_result{$name} = $name . ' is up-to-date.';

    return $name;
}

sub check_targets_in_DSL {

    return if Enbld::Feature->is_deploy_mode;

    my %not_in_dsl;
    foreach my $name ( keys %{ Enbld::App::Configuration->config } ) {
        my $config = Enbld::App::Configuration->search_config( $name );

        $not_in_dsl{$name}++ unless defined $target_result{$name};
    }

    if ( keys %not_in_dsl ) {
        Enbld::Message->notify(
                "WARN:The following targets are not defined in DSL $Script.\n" .
                "Please check $Script."
                );

        foreach my $target ( sort keys %not_in_dsl ) {
            Enbld::Message->notify( "    " . $target );
        }
    }
}

sub show_result_message {

    foreach my $target ( sort keys %target_result ) {
        Enbld::Message->notify( $target_result{$target} );
    }

    foreach my $file ( sort keys %rcfile_result ) {
        Enbld::Message->notify( $rcfile_result{$file} );
    }
}

sub build(&) {
    return $_[0];
}

our $condition_ref;

sub target($$) {
    my ( $targetname, $coderef ) = @_;

    if ( ! $initialized ) {
        _err(
                "Environment is not initialized.".
                "Isn't the syntax of DSL possibly mistaken?"
                );
    }

    if ( ref( $targetname ) ) {
        _err(
                "Function 'target' first requsres " .
                "string type parameter 'target name'."
                );
    }

    if( $targetname =~ /[^0-9a-z]/ ) {
        _err( "Target name '$targetname' contains invalid character." );
    }

    if ( ref( $coderef ) ne 'CODE' ) {
        _err( "Function 'target' seconde requires code reference parameter." );
    }

    $condition_ref = {
        name        =>  $targetname,
    };

    $coderef->();

    my $condition = Enbld::Condition->new( %{ $condition_ref } );
    $target_collection{$targetname} = $condition;

    undef $condition_ref;
}

sub define(&) {
    my $coderef = shift;

    return $coderef;
}

sub version($) {
    my $version = shift;

    if ( ref( $version ) ) {
        _err( "Function 'version' requires string type parameter." );
    }

    $condition_ref->{version} = $version;
}

sub make_test(;$) {
    my $make_test = shift;

    if ( $make_test && ref( $make_test ) ) {
        _err( "Function 'make_test' requires string type parameter." );
    }

    $condition_ref->{make_test} = $make_test if $make_test;
}

sub arguments($) {
    my $arguments = shift;

    if ( ref( $arguments ) ) {
        _err( "Function 'arguments' requires string type parameter." );
    }

    $condition_ref->{arguments} = $arguments;
}

sub annotation($) {
    my $annotation = shift;

    if ( ref( $annotation ) ) {
        _err( "Function 'annotation' requires string type parameter." );
    }

    $condition_ref->{annotation} = $annotation;
}

sub module_file($) {
    my $module_file = shift;

    if ( ref( $module_file ) ) {
        _err( "Function 'module_file' requires string type parameter." );
    }

    $condition_ref->{module_file} = $module_file;
}

sub modules {
    croak "'modules' function is deparecated. Please use 'module_file'.";
}

our $rcfile_condition;
sub conf($$) {
    my ( $filepath, $coderef ) = @_;

    if ( ! $initialized ) {
        _err(
                "Environment is not initialized.".
                "Isn't the syntax of DSL possibly mistaken?"
                );
    }

    if ( ref( $filepath ) ) {
        _err( "Function 'conf' first requires string type parameter." );
    }

    if ( $filepath =~ /\s/ ) {
        _err(
                "Configuration file path parameter must " .
                "not contain space character."
                );
    }

    if ( ref( $coderef ) ne 'CODE' ) {
        _err( "Function 'conf' requires code reference type parameter." );
    }

    $coderef->();

    $rcfile_condition->{filepath} = $filepath;
    $rcfile_collection{$filepath} = Enbld::RcFile->new( %{ $rcfile_condition } );

    undef $rcfile_condition;
}

sub do_rcfile {
    my $rcfile = shift;

    my $result = try {
        return $rcfile->do;
    } ( 'Enbld::Error' => sub {
        Enbld::Message->alert( $@ );

        say "\n" . "Please check build logile:" . Enbld::Logger->logfile;

        $rcfile_result{$rcfile->filepath} =
            $rcfile->filepath . ' is failure to create.';

        return;
        }
      );

    # Configuration file is loaded or set.
    if ( $result ) {

        Enbld::App::Configuration->set_rcfile( $rcfile );
        Enbld::App::Configuration->write_file;

        $rcfile_result{$rcfile->filepath} =
            $rcfile->filepath . ' is created.';

        return $result;
    }

    # Configuration file is not loaded or set.
    $rcfile_result{$rcfile->filepath} =
        $rcfile->filepath . ' is not created.';

    return;
}

sub load(&) {
    $rcfile_condition->{command} = 'load';

    return $_[0];
}

sub set(&) {
    $rcfile_condition->{command} = 'set';

    return $_[0];
}

sub copy(&) {
    $rcfile_condition->{command} = 'copy';

    return $_[0];
}

sub from($) {
    my $from = shift;

    if ( ref( $from ) ) {
        _err( "Function 'from' requsres string type parameter." );
    }

    $rcfile_condition->{from} = $from;
}

sub to($) {
    my $to = shift;

    if ( ref( $to ) ) {
        _err( "Function 'to' requsres string type parameter." );
    }

    if ( $to =~ /\s/ ) {
        _err( "Function 'to' must not contain space character." );
    }

    $rcfile_condition->{directory} = $to;
}

sub content($) {
    my $content = shift;

    if ( ref( $content ) ) {
        _err( "Function 'content' reuqires string type parameter." );
    }

    chomp( $content );

    $rcfile_condition->{contents} .= $content . "\n";
}

our $setuped;
sub _setup_directory {

    unless ( $setuped ) {
        Enbld::Home->create_build_directory;
        Enbld::Logger->rotate( Enbld::Home->log );

        $setuped++;
    }
}

sub parse_option {

    my $make_test;
    my $force;
    my $deploy_path;

    Getopt::Long::Configure( "bundling" );
    Getopt::Long::GetOptions(
            't|test'        => sub { $make_test++ },
            'f|force'       => sub { $force++ },
            'd|deploy=s'    => \$deploy_path,
            );

    ### to absolute path
    if ( $deploy_path ) {
        unless ( File::Spec->file_name_is_absolute( $deploy_path ) ) {
            $deploy_path = File::Spec->rel2abs( $deploy_path );
        }
    }

    require Enbld::Feature;
    Enbld::Feature->initialize(
            make_test   =>  $make_test,
            force       =>  $force,
            deploy      =>  $deploy_path,
            );

    if ( Enbld::Feature->is_deploy_mode ) {
        Enbld::Message->notify(
                "INFO:Enbld is set 'deploy mode'.\n" .
                "All targets will be deployed in $deploy_path."
                );
    }

    if ( Enbld::Feature->is_make_test_all ) {
        Enbld::Message->notify(
                "INFO:Enbld is set 'make test mode'.\n" .
                "All targets will be tested."
                );
    }

    if ( Enbld::Feature->is_force_install ) {
        Enbld::Message->notify(
                "INFO:Enbld is set 'force install mode'.\n" .
                "All targets will be builded by force."
                );
    }

}

sub _err {
    my ( $msg, $param ) = @_;

    Enbld::Error->throw( $msg, $param );
}

1;

__END__

=pod

=head1 NAME

Enbld - Yet another package manager for building development environment

=head1 SYNOPSIS

=head2 Installation

  $ curl -L http://goo.gl/MrbDDB | perl

=head2 Prepare a conditions script

  $ cat conditions_for_build.pl
  #!/usr/bin/perl

  use strict;
  use warnings;

  use lib "$ENV{HOME}/.enbld/extlib/lib/perl5/";

  use Enbld;

  enbld 'mydevenv' => build {

      # install latest version
      target 'git' => define {
          version 'latest';
      };

      # install specific version
      target 'perl' => define {
          version '5.18.1';
      };

  };

=head2 Run as perl script

  $ chmod +x conditions_for_build.pl
  $ ./conf_for_build.pl

  -> Installs software according to the conditions which are defined at script.

=head1 DESCRIPTION

B<Enbld is yet another package manager for building development environment.>

Write conditions of software installation (a version - latest or specific version , the execution of a test code etc.) to a conditions script, and run as perl script.

Then Enbld installs software according to the conditions which is defined in script.

=head2 FEATURES

=over

=item 1. The conditions of installation are defined by perl-based DSL

Once it writes a conditions script, the same environment will become reproducible easily.

=item 2. The specified versions can install

Unlike other package management systems, Enbld does not fix a version.

The version to install can be specified freely.

And version 'latest' also can be specified. In this case the latest version is decided automatically, and it be installed.

=item 3. The release of the newer version can check

The software specified version 'latest' can check release of the newer version.

So the software upgraded frequently (vim, git, etc.) can always use the latest version.

=item 4. The all software are installed in a home directory.

There is not require sudo for installation.

Backup and remove is easy.

=item 5. The same interface of installation is offered for all programing languages

Unlike other programing language version manager, the same interface of installatin is offered for all programing languages.

You do not need to learn a different way for every programming language.

=back

=head2 ANTI FEATURES

=over

=item 1. Enbld does NOT aim at perfect package manager

The selection plan of the software to support by Enbld is as follows.

=over

=item * The software for development updated frequently

e.g. vim, git

=item * The Software which has a specific version specified by the projects.

e.g.

programming language (perl, ruby, nodejs, scala etc.)

Web Server (apache, nginx etc.)

Database (MySQL etc.)

=item * The software required for a developer although not installed in OS X

e.g. tmux

=back

The software which does not correspond to the above-mentioned base does not support.

=item 2. Enbld does not offer the features which overlaps with the module install features in which a programming language offers.

CPAN, Rubygem, etc. should use for a module install features which a programming language offers.

=back

=head2 CAUTION

B<Enbld does not gurantee success of building of all the versions.>

Since log file is displayed when building goes wrong, please analyze and send report:)

=head1 INSTALLATION

=head2 SUPPORTED PLATFORMS

B<Enbld is performing verification of running on OS X Mavericks.>

Probably, it may operate also on Linux (Debian, Ubuntu etc.). When not running, it is waiting for the report :)

=head2 REQUIREMENTS

=over

=item * perl 5.10.1 or above

Enbld certainly use the system perl (`/usr/bin/perl`).

=item * GNU Make

=item * compiler (gcc or clang)

=item * other stuff required for individual target software (e.g. JRE for scala)

=back

=head2 INSTALL

 $ curl -L http://goo.gl/MrbDDB | perl

Enbld installs all the components in a C<$HOME/.enbld> directory. Therefore, it is necessary to set the PATH of the software which Enbld installed. 

=head2 SET PATH

In C<.bashrc> or C<.bash_profile>, add below setting.

 export PATH=$HOME/.enbld/bin:$HOME/.enbld/extlib/bin:$PATH
 export MANPATH=$HOME/.enbld/share/man:$HOME/.enbld/man:$MANPATH

=head1 GETTING STARTED Enbld

=head2 INSTALL LATEST VERSION

=head3 Ready conditions script

 $ cat samples/git_install.pl
 #!/usr/bin/perl

 use strict;
 use warnings;

 use lib "$ENV{HOME}/.enbld/extlib/lib/perl5/";

 use Enbld;

 enbld 'mydevenv' => build {

     target 'git' => define {
         version 'latest';
     };
 }

=head3 Run as perl script

 $ ./samples/git_install.pl

=head3 Finish installation

 $ git --version
 git version [latest version]

=head3 Upgrade

Then, if the newer version is released, please run script again.

 $ ./samples/git_install.pl

The latest version will be installed.

=head2 INSTALL SPECIFIC VERSION

A specific version is specified in a conditions script. -> version '5.18.1';

 $ cat samples/specific_version_install.pl
 #!/usr/bin/perl
    
 use strict;
 use warnings;
    
 use lib "$ENV{HOME}/.enbld/extlib/lib/perl5/";
    
 use Enbld;
    
 enbld 'mydevenv' => build {
    
     target 'perl' => define {
         version '5.18.1';
     };
    
 };

'perl 5.18.1' is installed.

 $ perl -v

 This is perl 5, version 18, subversion 1 (v5.18.1) built for ...

=head2 ADD ARGUMENTS

'arguments' method adds an additional arguments to 'configure' script.

 target 'perl' => define {
     version '5.18.1';
     arguments '-Dusethreads';
 };

perl 5.18.1 with thread is builded.

 $ perl -v
    
 This is perl 5, version 18, subversion 1 (v5.18.1) built for darwin-thread-multi-2level

=head2 INSTALL SOFTWARE WHICH DEPENDS 

When using Enbld at OS X, Enbld also solve the dependencies between softwares automatically.

For example, when the is equal to which needs a libidn library for wget, and Enbld install wget, they also install libidn automatically.

  $ enblder install wget
  =====> Start building target 'wget'.
  =====> Found dependencies.
  --> Dependency 'libidn'.
  --> libidn is not installed yet.
  =====> Start building target 'libidn'.

Please solve the software which needs the fix patterns of a dependencies at that of a many using the package Management manager of operating system in operating system of Linux and BSD(s) other than OS X.

=head2 UTILITY COMMAND 'enblder'

Enbld installs utility command 'enblder'.

The main commands are shown below. 

The description of all commands are shown by C<perldoc enblder>.

=head3 Displays available software

Subcommand 'available' displays software list that can install by Enbld.

 $ enblder available

The name displayed on this list is used for the name of the Software which I specify as a condition script. 

=head3 Install the software

subcommand 'install' installs the latest version of the software.

Use to install Software, without writing a condition script.

Then the 'freeze' subcommand is used, displays the conditions script reflecting the installation.

=head3 Displays installed software

Subcommand 'list' displays software list that is installed.

 $ enblder list

=head3 Displays conditions script

Subcommand 'freeze' displays the condition script reproducing the software of an installed. 

 $ enblder freeze

If the displayed content is redirected to a text file, it will become a script of perl which can be performed as it is. 

 $ enblder freeze > conditions.pl
 $ chmod +x conditions.pl
 $ ./conditions.pl

=head3 Displays outdated software

Subcommand 'outdated' displays outdated software list.

 $ enblder outdated

=head3 Upgrade outdated software

Subcommand 'upgrade' upgrade outdated software.

 $ enblder upgrade git

=head1 HOW TO USE RECOMMENDATION OF Enbld

I introduce how to use recommendation of Enbld for the the last. 

=over

=item 1 Install Enbld

  $ curl -L http://goo.gl/MrbDDB | perl

=item 2 Display available software list

  $ enblder available

=item 3 Install software to always use the latest version.

  $ enblder install git

=item 4 Make conditions script

  $ enblder freeze > my_conditions.pl
  $ chmod +x my_conditions.pl

=item 5 Add a software to use a specific version

  target 'perl' => define {
      version '5.18.1';
  }

=item 6 Run a conditions script

  $ ./conditions.pl

=item 7 Sometimes check the release of the newer version

  $ enblder outdated

=item 8 Upgrade outdated software  
 
  $ enblder upgrade git

=item 9 Since a trouble is surely encountered by somewhere, please send me a report or a Patch :)

L<https://github.com/magnolia-k/Enbld/issues>

=item 10 Repeat 7 -> 10

=back

=head1 SEE ALSO

L<Enbld::Tutorial>

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

