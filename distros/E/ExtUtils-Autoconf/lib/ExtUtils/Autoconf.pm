package ExtUtils::Autoconf;

use strict;
use warnings;
use Cwd;
use Config;
use File::Spec;
use File::Path qw(rmtree);
use File::Which qw(which);

=head1 NAME

ExtUtils::Autoconf - Perl interface to GNU autoconf

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use ExtUtils::Autoconf;

    my $ac = ExtUtils::Autoconf->new;

    $ac->autogen;
    $ac->configure;

    $ac->clean;
    $ac->realclean;

=head1 DESCRIPTION

ExtUtils::Autoconf is a thin wrapper around GNU autoconf/autoheader which
allows to run those tools easily from perl. This allows using autoconf for
configuring perl modules and especially extensions in a portable way without
messing around with the compilation of C code from perl.

=head1 TYPICAL USAGE

Typically ExtUtils::Autoconf is being used from Makefile.PLs in Perl module
distributions.

=head2 AUTOCONF

To use it in your module you first need to create a directory called
C<autoconf> (or call it something else and set C<wd> accordingly. This is the
working directory for ExtUtils::Autoconf and the programs it invokes.

Create a C<configure.ac> or C<configure.in> file in this directory. This file
contains invocations of autoconf macros that test the system features
your package needs or can use.  Autoconf macros already exist to check for many
features; see L<Existing
Tests|http://www.gnu.org/software/autoconf/manual/html_node/Existing-Tests.html#Existing-Tests>,
for heir descriptions. For most other features, you can use Autoconf template
macros to produce custom checks; see L<Writing
Tests|http://www.gnu.org/software/autoconf/manual/html_node/Writing-Tests.html#Writing-Tests>,
for information about them.

A typical C<configure.ac> might look like this:

    AC_PREREQ(2.50)
    AC_INIT
    AC_CONFIG_HEADERS([config.h])

    AC_DEFINE_UNQUOTED(PERL_OSNAME, "$osname", [The operating system perl was ocnfigured for])

    AC_OUTPUT

In this script we first require autoconf version 2.50, then initialize the
system and tell it to create a config header file called C<config.h> with the
results it gathered while running the configure script.

In this script we only have one result called C<PERL_OSNAME>. This is simply
set to the value of the environment variable C<$osname>, which corresponds to
perls C<$Config{osname}>.

After our tests we do C<AC_OUTPUT> to write our results to C<config.h>.

That's it for the C<configure.ac> part. Now include the C<autoconf/config.h>
file in your C or C++ code of the module and use the defines in there.

=head2 Makefile.PL

Execute the configure script which will be generated from the above
C<configure.ac> when someone tries to build your module you'll need to modify
your C<Makefile.PL> script.

It's better to assume that the user of your module doesn't have autoconf and
autoheader installed so you need to generate C<configure> and C<config.h>
before rolling your distribution together.

=head3 ExtUtils::MakeMaker

This is easily done by using the C<dist> target of your generated Makefile:

    WriteMakefile(
        # usual arguments to WriteMakefile()..
        dist => {
            PREOP => q{$(PERLRUN) -MExtUtils::Autoconf -e'ExtUtils::Autoconf->run_autogen'},
        },
    );

B<autogen()> and B<configure()> automatically generate some files. To clean
those up automatically when doing C<make clean> or C<make realclean> you can
use MakeMakers postamble feature. We also add some additional Makefile targets
for the ease of use:

    sub postamble {
        return <<"EOM";
    autogen :
    \t\$(PERLRUN) -MExtUtils::Autoconf -e 'ExtUtils::Autoconf->run_autogen'

    configure :
    \t\$(PERLRUN) -MExtUtils::Autoconf -e'ExtUtils::Autoconf->run_configure'

    autoclean :
    \t\$(PERLRUN) -MExtUtils::Autoconf -e'ExtUtils::Autoconf->run_realclean'

    realclean purge ::
    \t\$(PERLRUN) -MExtUtils::Autoconf -e 'ExtUtils::Autoconf->run_realclean'

    clean ::
    \t\$(PERLRUN) -MExtUtils::Autoconf -e 'ExtUtils::Autoconf->run_clean'
    EOM
    }

Now everything will work, except for the actual execution of the configure
script during C<perl Makefile.PL>. To make it work do something like this in
C<Makefile.PL>:

    use strict;
    use warnings;
    use ExtUtils::MakeMaker;

    if (!eval 'use ExtUtils::Autoconf;') {
        print STDERR $@, "\n";

        WriteMakefile(
                PREREQ_FATAL => 1,
                PREREQ_PM    => {
                    'ExtUtils::Autoconf' => 0,
                },
        );

        exit 1; # not reached
    }

    my $ac = ExtUtils::Autoconf->new;
    $ac->configure;

    # rest of the usual Makefile.PL here..

The C<if> condition covers those cases where ExtUtils::Autoconf isn't installed
yet. I'll raise a fatal error which will hopefully tell CPAN to install it and
rerun C<Makefile.PL>.

=head3 Module::Install

If you're using L<Module::Install> for your Makefile.PL, you can simply install
L<Module::Install::Autoconf> and do B<configure()> in it.

=head1 SUBROUTINES/METHODS

=head2 new 

    my $ac = ExtUtils::Autoconf->new($arguments);

This is the constructor.. Takes an optional  hashref with additional
C<$arguments>. Returns a new ExtUtils::Autoconf instance.

The following arguments are supported:

=over

=item * C<wd>

The working directory for autoconf. All commands issued by ExtUtils::Autoconf
will be executed in this directory.

=item * C<autoconf>

The name of the autoconf executable.

=item * C<autoheader>

The name of the autoheader executable.

=item * C<env>

A hash reference with the environment variables which will be set for each
program execution issued by ExtUtils::Autoconf.

The default looks like this:

    {
        MAKE     => $Config{ make     },
        SHELL    => $Config{ sh       },
        CC       => $Config{ cc       },
        CPPFLAGS => $Config{ cppflags },
        CFLAGS   => $Config{ ccflags  },
        LDFLAGS  => $Config{ ldflags  },
        LINKER   => $Config{ ld       },
        LIBS     => '',
        %Config,
    }

Where C<%Config> is the local perl configuration from C<Config.pm>. To add
additional environment variables or to override existing ones do:

    my $ac = ExtUtils::Autoconf->new({
            env => {
                key1 => 'val1',
                key2 => 'val2',
            },
    });

=back

=cut

sub new {
    my ($class, $args) = @_;

    my $self = {
        wd           => 'autoconf',
        autoconf     => (which('autoconf'))[0] || 'autoconf',
        autoheader   => (which('autoheader'))[0] || 'autoheader',
        env          => {
                MAKE     => $Config{ make     },
                SHELL    => $Config{ sh       },
                CC       => $Config{ cc       },
                CPPFLAGS => $Config{ cppflags },
                CFLAGS   => $Config{ ccflags  },
                LDFLAGS  => $Config{ ldflags  },
                LINKER   => $Config{ ld       },
                LIBS     => q{},
                %Config,
        },
    };

    bless $self, $class;

    if (ref $args && ref $args eq 'HASH') {
        $self->_process_args($args);
    }

    return $self;
}

sub _process_args {
    my ($self, $args) = @_;

    while (my ($k, $v) = each %{ $args }) {
        next unless $self->can($k);

        if (!ref $v) { #plain scalar
            $self->$k($v);
        }

        elsif (ref $v eq 'HASH') { #hashref (env)
            while (my ($sk, $sv) = each %{ $v }) {
                $self->$k($sk => $sv);
            }
        }

    }
}

=head2 configure

    $ac->configure;

Runs the configure script. If the configure script doesn't exist yet it'll run
B<autogen()>.  Returns 1 on success or croaks on failure.

=cut

sub configure {
    my ($self) = @_;

    my $configure = 'configure';

    if (!-x File::Spec->catfile($self->wd, $configure)) {
        $self->autogen;
    }

    if (!$self->_run_cmd("./$configure", '--prefix='. "\Q$Config{prefix}\E")) {
        require Carp;
        Carp::croak(
                q{configure failed. Check }
                . File::Spec->catfile($self->wd, 'config.log')
                . q{.}
        );
    }

    return 1;
}

=head2 autogen

    $ac->autogen;

Runs autoheader and autoconf to generate config.h.in and configure from
configure.ac or configure.in. Returns 1 on success or croaks on failure.

=cut

sub autogen {
    my ($self) = @_;

    my $ret = $self->_run_cmd($self->autoheader) && $self->_run_cmd($self->autoconf);
    if (!$ret) {
        require Carp;
        Carp::croak('autogen failed. check the error messages above.');
    }

    return 1;
}

*reconf = \&autogen; #compat

=head2 clean

    $ac->clean;

Cleans up files which were generated during B<configure()>. Always returns
something true.

=cut

sub clean {
    my ($self) = @_;

    for my $file (qw( config.h config.log config.status )) {
        my $path = File::Spec->catfile($self->wd, $file);
        next unless -f $path;
        unlink $path;
    }

    return 1;
}

=head2 realclean

    my $success = $ac->realclean;

Cleans up files which were generated during B<autogen()> and B<configure()>.
Always returns something true.

=cut

sub realclean {
    my ($self) = @_;

    $self->clean;
    for my $file (qw( config.h.in configure )) {
        my $path = File::Spec->catfile($self->wd, $file);
        next unless -f $path;
        unlink $path;
    }

    rmtree( File::Spec->catfile($self->wd, 'autom4te.cache'), 0, 0 );

    return 1;
}

=head2 wd

    my $wd = $ac->wd;
    $ac->wd($new_wd);

Accessor for the wd (working directory) option. When called without any
argument it returns the current working directory. When called with one
argument the working directory is set to C<$new_wd> and the new working
directory is returned.

=cut

sub wd {
    my $self = shift;

    if (@_) {
        $self->{wd} = shift;
    }

    return $self->{wd};
}

=head2 autoconf

    my $autoconf = $ac->autoconf;
    $ac->autoconf($new_autoconf);

Accessor for the name of the autoconf executable.

=cut

sub autoconf {
    my $self = shift;

    if (@_) {
        $self->{autoconf} = shift;
    }

    return $self->{autoconf};
}

=head2 autoheader

    my $autoheader = $ac->autoheader;
    $ac->autoheader($new_autoheader);

Accessor for the name of the autoheader executable.

=cut

sub autoheader {
    my $self = shift;

    if (@_) {
        $self->{autoheader} = shift;
    }

    return $self->{autoheader};
}

=head2 env

    my $env = $ac->env;
    my $value = $ac->env($key);
    $ac->env($key => $value);

Accessor for the environment option. When called without any option it returns
a hash reference with all the environment variables that will be set when
running any command.

When called with one argument it'll return the value of the environment
variable corresponding to a given C<$key>.

When called with two arguments the environment variable C<$key> will be set to
C<$value>.

=cut

sub env {
    my $self = shift;

    if (scalar @_ == 1) {
        my ($key) = @_;
        return $self->{env}->{ $key };
    }
    elsif (scalar @_ == 2) {
        my ($key, $val) = @_;
        $self->{env}->{ $key } = $val;
        return $self->{env}->{ $key };
    }
    elsif (scalar @_ != 0) {
        require Carp;
        Carp::croak('ExtUtils::Config::env expects 0, 1 or 2 arguments');
    }

    return $self->{env};
}

sub _run_cmd {
    my ($self, $cmd, @args) = @_;

    my $cwd = cwd();
    if (!chdir $self->wd) {
        require Carp;
        Carp::croak("Could not chdir to `". $self->wd ."'. Did you set the working dir correctly?");
    }

    my $ret;
    {
        local %ENV = %ENV;
        while (my ($k, $v) = each %{ $self->{env} }) {
            next unless defined $v;
            $ENV{$k} = $v;
        }

        $ret = system $self->env('SHELL'), -c => "\Q$cmd\E ". join(q{ }, @args);
    }

    chdir $cwd;
    return ($ret == 0);
}

=head2 run_configure

    perl -MExtUtils::Autoconf -e'ExtUtils::Autoconf->run_configure' $wd

This class method is intended to be used from Makefiles and similar things and
reads its arguments from C<@ARGV>. It constructs a new ExtUtils::Autoconf
instance with the given C<$wd> and runs B<configure()>.

=cut

sub run_configure {
    my ($class) = @_;

    my $ac = $class->new;
    $ac->_process_argv;

    $ac->configure;
}

=head2 run_autogen

    perl -MExtUtils::Autoconf -e'ExtUtils::Autoconf->run_autogen' $wd, $autoconf, $autoheader

This class method is intended to be used from Makefiles and similar things and
reads its arguments from C<@ARGV>. It constructs a new ExtUtils::Autoconf
instance with the given C<$wd>, C<$autoconf>, C<$autoheader> and runs
B<autogen()>.

=cut

sub run_autogen {
    my ($class) = @_;

    my $ac = $class->new;
    $ac->_process_argv;

    $ac->autogen;
}

=head2 run_clean

    perl -MExtUtils::Autoconf -e'ExtUtils::Autoconf->run_clean' $wd

This class method is intended to be used from Makefiles and similar things and
reads its arguments from C<@ARGV>. It constructs a new ExtUtils::Autoconf
instance with the given C<$wd> and runs B<clean()>.

=cut

sub run_clean {
    my ($class) = @_;

    my $ac = $class->new;
    $ac->_process_argv;

    $ac->clean;
}

=head2 run_realclean

    perl -MExtUtils::Autoconf -e'ExtUtils::Autoconf->run_realclean' $wd

This class method is intended to be used from Makefiles and similar things and
reads its arguments from C<@ARGV>. It constructs a new ExtUtils::Autoconf
instance with the given C<$wd> and runs B<realclean()>.

=cut

sub run_realclean {
    my ($class) = @_;

    my $ac = $class->new;
    $ac->_process_argv;

    $ac->realclean;
}

sub _process_argv {
    my ($self) = @_;
    my ($wd, $autoconf, $autoheader) = @ARGV;

    $self->wd($wd) if defined $wd;
    $self->autoconf($autoconf) if defined $autoconf;
    $self->autoheader($autoheader) if defined $autoheader;
}

=head1 DIAGNOSTICS

=over

=item C<configure failed. Check %s/config.log>

Running ./configure failed. Diagnostic messages may be found in the according
config.log file.

=item C<autogen failed. check the error messages above.>

Running autoheader or autoconf failed. Probably your C<configure.ac> is
erroneous. Try running autoheader and autoconf manually.

=back

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to
E<lt>bug-extutils-autoconf@rt.cpan.orgE<gt>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ExtUtils-Autoconf>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ExtUtils::Autoconf

You can also look for information at:

=over 4

=item * GNU Autoconf documentation

L<http://www.gnu.org/software/autoconf/manual/>

=item * Felipe Bergo's autotools tutorial

L<http://www.seul.org/docs/autotut/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ExtUtils-Autoconf>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ExtUtils-Autoconf>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ExtUtils-Autoconf>

=item * Search CPAN

L<http://search.cpan.org/dist/ExtUtils-Autoconf>

=back

=head1 ACKNOWLEDGEMENTS

Marc Lehmann E<lt>schmorp@schmorp.deE<gt> for the idea and a prof-of-concept
implementation (autoconf.pm) in L<IO::AIO>.

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Florian Ragwitz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of ExtUtils::Autoconf
