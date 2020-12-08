#!perl
#===============================================================================
#
# Makefile.PL
#
# DESCRIPTION
#   Top-level makefile creation script.
#
# COPYRIGHT
#   Copyright (C) 2004-2009, 2012, 2014, 2015, 2017, 2020 Steve Hay.  All rights
#   reserved.
#
# LICENCE
#   This script is free software; you can redistribute it and/or modify it under
#   the same terms as Perl itself, i.e. under the terms of either the GNU
#   General Public License or the Artistic License, as specified in the LICENCE
#   file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use ExtUtils::MakeMaker 6.66;
use ExtUtils::MakeMaker qw(WriteMakefile);

#===============================================================================
# INITIALIZATION
#===============================================================================

our($VERSION, $YEAR);

BEGIN {
    $VERSION = '2.10';
    $YEAR = '2004-2009, 2012, 2014, 2015, 2017, 2020';
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    my $cb = Filter::Crypto::_ConfigureBuild->new();

    my @opt_specs = (
        'prefix-dir|d=s',
        'cipher-config|c=s',
        'cipher-name|n=s',
        'cipher-mode|m=s',
        'pswd|p=s',
        'key|k=s',
        'rng|r=s',
        'key-len|l=i',
        'rc2-key-bits=i',
        'rc5-rounds=i',
        'install-script|i=s',
        'build|b=s',
        'unsafe-mode|u',
        'debug-mode'
    );

    $cb->process_opts(\@opt_specs);

    $cb->locate_openssl();
    $cb->configure_cipher();

    my $dir = $cb->query_build();

    if ("@$dir" =~ /Decrypt/o) {
        $cb->check_perl();
    }

    my $exe_files = $cb->query_script("@$dir" =~ /CryptFile/o ? 'y' : 'n');

    $cb->setup_env();

    my %configure_requires = ();
    $configure_requires{'VMS::DCLsym'} = '0' if $^O eq 'VMS';

    WriteMakefile(
        NAME          => 'Filter::Crypto',
        ABSTRACT_FROM => 'lib/Filter/Crypto.pm',
        AUTHOR        => 'Steve Hay <shay@cpan.org>',
        LICENSE       => 'perl_5',
        VERSION_FROM  => 'lib/Filter/Crypto.pm',

        META_MERGE => {
            'meta-spec' => {
                version => 2
            },

            no_index => {
                package => 'Filter::Crypto::_ConfigureBuild'
            },

            resources => {
                repository => {
                    type => 'git',
                    web  => 'https://github.com/steve-m-hay/Filter-Crypto'
                }
            },

            optional_features => {
                parfilter => {
                    description => 'PAR::Filter support',
                    prereqs => {
                        runtime => {
                            requires => {
                                'PAR::Filter' => '0'
                            }
                        },

                        test => {
                            requires => {
                                'Archive::Zip' => '0'
                            }
                        }
                    }
                },

                changestest => {
                    description => 'Changes testing',
                    prereqs => {
                        test => {
                            requires => {
                                'Test::CPAN::Changes' => '0'
                            }
                        }
                    }
                },

                critictest => {
                    description => 'Perl::Critic testing',
                    prereqs => {
                        test => {
                            requires => {
                                'Test::Perl::Critic' => '0'
                            }
                        }
                    }
                },

                podtest => {
                    description => 'POD testing',
                    prereqs => {
                        test => {
                            requires => {
                                'Test::Pod' => '1.00'
                            }
                        }
                    }
                },

                podcoveragetest => {
                    description => 'POD coverage testing',
                    prereqs => {
                        test => {
                            requires => {
                                'Test::Pod::Coverage' => '0.08'
                            }
                        }
                    }
                }
            }
        },

        MIN_PERL_VERSION => '5.008001',

        CONFIGURE_REQUIRES => {
            %configure_requires,
            'Carp'                  => '0',
            'Config'                => '0',
            'Cwd'                   => '0',
            'ExtUtils::MakeMaker'   => '6.66',
            'Fcntl'                 => '0',
            'File::Basename'        => '0',
            'File::Copy'            => '0',
            'File::Spec::Functions' => '0',
            'Getopt::Long'          => '0',
            'Pod::Usage'            => '1.15',
            'Text::Wrap'            => '0',
            'constant'              => '0',
            'perl'                  => '5.008001',
            'strict'                => '0',
            'warnings'              => '0'
        },

        TEST_REQUIRES => {
            'File::Path' => '0',
            'FindBin'    => '0',
            'Test::More' => '0',
            'blib'       => '0'
        },

        PREREQ_PM => {
            'Carp'                  => '0',
            'Config'                => '0',
            'Cwd'                   => '0',
            'Exporter'              => '0',
            'ExtUtils::MakeMaker'   => '6.66',
            'Fcntl'                 => '0',
            'File::Basename'        => '0',
            'File::Copy'            => '0',
            'File::Find'            => '0',
            'File::Spec::Functions' => '0',
            'File::Temp'            => '0',
            'Getopt::Long'          => '0',
            'Pod::Usage'            => '1.15',
            'Scalar::Util'          => '0',
            'Text::ParseWords'      => '0',
            'Text::Wrap'            => '0',
            'XSLoader'              => '0',
            'constant'              => '0',
            'strict'                => '0',
            'warnings'              => '0'
        },

        DIR => $dir,

        EXE_FILES => $exe_files,

        clean => {
            FILES => 'CipherConfig.h'
        },

        dist => {
            PREOP   => 'find $(DISTVNAME) -type d -print|xargs chmod 0755 && ' .
                       'find $(DISTVNAME) -type f -print|xargs chmod 0644 && ' .
                       'chmod 0755 $(DISTVNAME)/script/crypt_file',
            TO_UNIX => 'find $(DISTVNAME) -type f -print|xargs dos2unix'
        }
    );
}

#===============================================================================
# MAKEMAKER OVERRIDES
#===============================================================================

# Method to temporarily remove the list of sub-directories when creating the
# (top-level) "test" target since our sub-directories have no tests of their
# own.  This saves the bother of cd'ing into them and avoids the alarming "No
# tests defined..." message when running the top-level "test" target.  (The
# sub-directories' Makefiles still have their own "test" targets, though, so
# anyone manually cd'ing into them and running those "test" targets will get the
# message about there being no tests.)
#
# This method is based on code taken from the MY::test() method in the top-level
# Makefile.PL script in the Tk distribution (version 804.032).

sub MY::test {
    my($self, %args) = @_;
    my $dir = delete $self->{DIR};
    my $str = $self->MM::test(%args);
    $self->{DIR} = $dir;
    return $str;
}

#===============================================================================
# PRIVATE CLASS
#===============================================================================

{

package Filter::Crypto::_ConfigureBuild;

use Carp qw(croak);
use Config qw(%Config);
use Cwd qw(abs_path);
use ExtUtils::MakeMaker qw(prompt);
use Fcntl;
use File::Basename qw(basename dirname);
use File::Copy qw(copy);
use File::Spec::Functions qw(canonpath catdir catfile curdir
                             file_name_is_absolute path updir);
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);
use Text::Wrap qw(wrap);

use constant CIPHER_NAME_DES        => 'DES';
use constant CIPHER_NAME_DES_EDE    => 'DES_EDE';
use constant CIPHER_NAME_DES_EDE3   => 'DES_EDE3';
use constant CIPHER_NAME_RC4        => 'RC4';
use constant CIPHER_NAME_IDEA       => 'IDEA';
use constant CIPHER_NAME_RC2        => 'RC2';
use constant CIPHER_NAME_DESX       => 'DESX';
use constant CIPHER_NAME_BLOWFISH   => 'Blowfish';
use constant CIPHER_NAME_NULL       => 'Null';
use constant CIPHER_NAME_RC5        => 'RC5';
use constant CIPHER_NAME_CAST5      => 'CAST5';
use constant CIPHER_NAME_AES        => 'AES';

use constant CIPHER_MODE_ECB        => 'ECB';
use constant CIPHER_MODE_CBC        => 'CBC';
use constant CIPHER_MODE_CFB        => 'CFB';
use constant CIPHER_MODE_OFB        => 'OFB';

use constant CIPHER_KEY_GIVEN_PSWD  => 1;
use constant CIPHER_KEY_RANDOM_PSWD => 2;
use constant CIPHER_KEY_GIVEN       => 3;
use constant CIPHER_KEY_RANDOM      => 4;

use constant RAND_OPTION_STR        => 'rand';
use constant RAND_PSWD_LEN          => 32;

use constant RNG_PERL_RAND          => 'Perl';
use constant RNG_CRYPT_RANDOM       => 'Crypt::Random';
use constant RNG_MATH_RANDOM        => 'Math::Random';
use constant RNG_OPENSSL_RAND       => 'OpenSSL';

use constant CIPHER_CONFIG_FILENAME => 'CipherConfig.h';

use constant BUILD_OPTION_BOTH      => 'both';
use constant BUILD_OPTION_CRYPTFILE => 'CryptFile';
use constant BUILD_OPTION_DECRYPT   => 'Decrypt';

#-------------------------------------------------------------------------------
# CLASS INITIALIZATION
#-------------------------------------------------------------------------------

our($VERSION, $YEAR, $Show_Found_Var_Indent);

BEGIN {
    $VERSION = $main::VERSION;
    $YEAR = $main::YEAR;

    # Define indentation for show_found_var() method.
    $Show_Found_Var_Indent = 37;

    # Define protected accessor/mutator methods.
    foreach my $prop (qw(
        define inc libs opts
        prefix_dir inc_dir ver_num ver_str lib_dir lib_name bin_file
        cipher_name cipher_func cipher_needs_iv key_len rc2_key_bits rc5_rounds
        pswd key))
    {
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *$prop = sub {
            use strict 'refs';
            my $self = shift;
            $self->{$prop} = shift if @_;
            return $self->{$prop};
        };
    }
}

#-------------------------------------------------------------------------------
# PUBLIC API
#-------------------------------------------------------------------------------

sub new {
    return bless {}, shift;
}

sub process_opts {
    my($self, $opt_specs, $with_auto_install) = @_;

    # Allow options to be introduced with a "/" character on Windows, as is
    # common on those OSes, as well as the default set of characters.
    if ($self->is_win32()) {
        Getopt::Long::Configure('prefix_pattern=(--|-|\+|\/)');
    }

    # Deal with these common options immediately; have the rest stored in %opts.
    my $opt_def = 0;
    my %opts = (
        'defaults' => sub { $ENV{PERL_MM_USE_DEFAULT} = 1; $opt_def = 1 },
        'version'  => sub { $self->exit_with_version()   },
        'help'     => sub { $self->exit_with_help()      },
        'manpage'  => sub { $self->exit_with_manpage()   }
    );

    # Make sure that '-v' and '-h' unambiguously mean '--version' and '--help'
    # respectively, even if other option specs beginning with 'v' or 'h' are
    # given in @$opt_specs.
    my @opt_specs = (
        @$opt_specs,
        'defaults',
        'version|v',
        'help|h|?',
        'manpage|doc'
    );

    GetOptions(\%opts, @opt_specs) or
        $self->exit_with_usage();

    $self->opts(\%opts);
}

# This method is based on code taken from the can_run() method in the standard
# library module IPC::Cmd (version 0.92).

sub can_run {
    my($self, $cmd) = @_;

    if ($^O eq 'VMS') {
        require VMS::DCLsym;
        my $syms = VMS::DCLsym->new();
        return $cmd if scalar $syms->getsym(uc $cmd);
    }

    return MM->maybe_command($cmd) if file_name_is_absolute($cmd);

    foreach my $dir (path(), curdir()) {
        next if !$dir or !-d $dir;
        my $abs = catfile($dir, $cmd);
        return $abs if $abs = MM->maybe_command($abs);
    }

    return;
}

sub query_script {
    my($self, $default) = @_;

    my $script_name = 'crypt_file';

    my $install_script = $self->opts()->{'install-script'};
    if (defined $install_script) {
        if ($install_script =~ /^(?:y|n)$/io) {
            $self->show_found_var(
                'Using specified script option', $install_script
            );
        }
        else {
            $self->exit_with_error(3,
                "Invalid 'install_script' option value '%s'", $install_script
            );
        }
    }
    else {
        my $question = "Do you want to install '$script_name'?";
        $default = 'y' unless defined $default;
        $install_script = $self->prompt_yes_no($question, $default);
    }
    print "\n";

    if ($install_script) {
        return [ catfile('script', $script_name) ];
    }
    else {
        return [];
    }
}

# Method to store the build options in this process' environment so that they
# are available to the sub-directories' Makefile.PLs when they are run.  Note
# that ExtUtils::MakeMaker's PASTHRU macro is not good enough because that only
# passes things through when "make Makefile" is run, which is too late for the
# processing of the LIBS option that Makefile.PL itself handles.

sub setup_env {
    my $self = shift;

    $ENV{__SHAY_PRIVATE_DEFINE} = $self->define();
    $ENV{__SHAY_PRIVATE_INC}    = $self->inc();
    $ENV{__SHAY_PRIVATE_LIBS}   = $self->libs();
}

# Method to check the perl being used isn't a "debug" mode build, unless
# Makefile.PL was invoked with the "--debug-mode" command-line option, in which
# case it is okay.
# Only check whether the DEBUGGING symbol is defined in perl's C compiler flags
# here. This is sufficient to catch all normal cases. Fuller checks are
# performed in Decrypt.xs's "BOOT" code (the check is only relevant when the
# Decrypt component is built).

sub check_perl {
    my $self = shift;

    return if exists $self->opts()->{'debug-mode'};

    if ($Config{ccflags} =~ /(?:^|\s)-DDEBUGGING(?:\s|$)/o) {
        $self->exit_with_error(134,
            'OS unsupported: The "Decrypt" component requires a "release" ' .
            'mode build of perl (i.e. one built without DEBUGGING)'
        );
    }
}

sub locate_openssl {
    my $self = shift;

    print "\n";

    $self->query_prefix_dir();
    print "\n";

    $self->locate_inc_dir();
    $self->set_inc();

    $self->determine_ver_num();
    $self->set_define();

    $self->locate_lib_dir_and_file();
    $self->set_libs();

    $self->locate_bin_file();
    print "\n";
}

sub configure_cipher {
    my $self = shift;

    my $cipher_config = $self->opts()->{'cipher-config'};
    if (defined $cipher_config) {
        if (-f $cipher_config) {
            $self->show_found_var(
                'Using specified configuration file', $cipher_config
            );
            $self->copy_cipher_config($cipher_config);
        }
        else {
            $self->exit_with_error(100,
                "No such configuration file '%s'", $cipher_config
            );
        }
    }
    else {
        $self->query_cipher_name();

        my $lc_cipher_name = lc $self->cipher_name();
        my $cipher_config_method = "configure_${lc_cipher_name}_cipher";
        $self->$cipher_config_method();

        $self->query_pswd_or_key();

        $self->write_cipher_config();
    }
}

sub query_build {
    my $self = shift;

    my @build_options = (
        [ BUILD_OPTION_BOTH,      'Build both components'          ],
        [ BUILD_OPTION_CRYPTFILE, 'Build CryptFile component only' ],
        [ BUILD_OPTION_DECRYPT,   'Build Decrypt component only'   ]
    );

    my $build = $self->opts()->{'build'};
    if (defined $build) {
        my %build_options = map { $_->[0] => 1 } @build_options;
        if (exists $build_options{$build}) {
            $self->show_found_var('Using specified build option', $build);
        }
        else {
            $self->exit_with_error(101,
                "Invalid 'build' option value '%s'", $build
            );
        }
    }
    else {
        my $message  = 'Build options:';
        my $question = 'Which component(s) do you want to build?';
        my $default  = BUILD_OPTION_BOTH;

        $build = $self->prompt_list(
            $message, \@build_options, $question, $default
        );
    }
    print "\n";

    if ($build eq BUILD_OPTION_BOTH) {
        return [ BUILD_OPTION_CRYPTFILE, BUILD_OPTION_DECRYPT ];
    }
    else {
        return [ $build ];
    }
}

#-------------------------------------------------------------------------------
# PROTECTED API
#-------------------------------------------------------------------------------

sub is_win32 {
    return $^O =~ /^MSWin32$/io;
}

sub quote_str {
    my($self, $string) = @_;

    if ($string =~ / /o) {
        my $q = ($^O =~ /^(?:MSWin32|NetWare|VMS)$/io) ? '"' : "'";
        $string = $q . $string . $q;
    }

    return $string;
}

sub prompt_yes_no {
    my($self, $question, $default) = @_;

    my $answer = $self->prompt_validate(
        -question => $question,
        -default  => $default,
        -validate => sub { $_[0] =~ /^(?:y(?:es)?|no?)$/io }
    );

    return $answer =~ /^y/io ? 1 : 0;
}

sub prompt_dir {
    my($self, $question, $default) = @_;

    my $dir = $self->prompt_validate(
        -question => $question,
        -default  => $default,
        -validate => sub { -d $_[0] },
        -errmsg   => 'No such directory'
    );

    return canonpath(abs_path($dir));
}

sub prompt_list {
    my($self, $message, $options, $question, $default) = @_;

    my $num_options = scalar @$options;
    my $len = length $num_options;

    my %options = map { $_->[0] => 1 } @$options;
    my $num_unique_options = scalar keys %options;
    if ($num_unique_options != $num_options) {
        $self->exit_with_error(4, 'Options in list are not unique');
    }

    my $default_num = 0;
    for (my $i = 1; $i <= $num_options; $i++) {
        $message .= sprintf "\n  [%${len}d] %s", $i, $options->[$i - 1][1];
        $default_num = $i if $options->[$i - 1][0] eq $default;
    }

    if ($default_num == 0) {
        $self->exit_with_error(5, "Invalid default response '%s'", $default);
    }

    my $answer_num = $self->prompt_validate(
        -message  => $message,
        -question => $question,
        -default  => $default_num,
        -validate => sub {
            $_[0] =~ /^[1-9](?:\d+)?$/o and $_[0] <= $num_options
        }
    );

    return $options->[$answer_num - 1][0];
}

{
    my %defaults = (
        -question => '?',
        -default  => '',
        -validate => sub { 1 },
        -errmsg   => 'Invalid response'
    );
    
    sub prompt_validate {
        my $self = shift;
        my %args = (%defaults, @_);

        if (exists $args{-message}) {
            print wrap('', '', $args{-message}), "\n";
        }
    
        my $input;
        until (defined $input) {
            $input = prompt($args{-question}, $args{-default});
            unless ($args{-validate}->($input)) {
                if ($self->use_default_response()) {
                    $self->exit_with_error(7,
                        "Invalid default response '%s'", $args{-default}
                    );
                }
                else {
                    print wrap('', '', $args{-errmsg}), "\n";
                    $input = undef;
                }
            }
        }
    
        return $input;
    }
}

sub show_found_var {
    my($self, $msg, $var) = @_;
    local $Text::Wrap::break = qr{\s|(?<=[\\\\/]).{0}}o;
    print wrap('', ' ' x $Show_Found_Var_Indent,
        "$msg " . '.' x ($Show_Found_Var_Indent - length($msg) - 2) . " $var"
    ), "\n";
}

sub exit_with_version {
    my $self = shift;

    printf "This is %s %s.\n\n", basename($0), $main::VERSION;

    print "Copyright (C) $YEAR Steve Hay.  All rights reserved.\n\n";

    print wrap('', '',
        "This script is free software; you can redistribute it and/or modify " .
        "it under the same terms as Perl itself, i.e. under the terms of " .
        "either the GNU General Public License or the Artistic License, as " .
        "specified in the LICENCE file.\n\n"
    );

    exit 1;
}

sub exit_with_help {
    my $self = shift;
    pod2usage(
        -exitval => 1,
        -verbose => 1
    );
}

sub exit_with_manpage {
    my $self = shift;
    pod2usage(
        -exitval => 1,
        -verbose => 2
    );
}

sub exit_with_usage {
    my $self = shift;
    pod2usage(
        -exitval => 2,
        -verbose => 0
    );
}

sub exit_with_error {
    my($self, $num, $msg) = splice @_, 0, 3;
    $msg = sprintf $msg, @_ if @_;
    # Load Carp::Heavy now, otherwise (before Perl 5.8.7) croak() clobbers $!
    # when loading it.
    require Carp::Heavy;
    $! = $num;
    croak("Error ($num): $msg");
}

# This method is based on code taken from the prompt() function in the standard
# library module ExtUtils::MakeMaker (version 6.92).

sub use_default_response {
    my $self = shift;
    return($ENV{PERL_MM_USE_DEFAULT} or (not $self->isa_tty() and eof STDIN));
}

# This method is based on code taken from the prompt() function in the standard
# library module ExtUtils::MakeMaker (version 6.92).

sub isa_tty {
    my $self = shift;
    ## no critic (InputOutput::ProhibitInteractiveTest)
    return(-t STDIN and (-t STDOUT or not (-f STDOUT or -c STDOUT)));
}

sub query_prefix_dir {
    my $self = shift;

    my $prefix_dir = $self->opts()->{'prefix-dir'};
    if (defined $prefix_dir) {
        $prefix_dir = canonpath(abs_path($prefix_dir));
        if (-d $prefix_dir) {
            $self->show_found_var(
                'Using specified prefix directory', $prefix_dir
            );
        }
        else {
            $self->exit_with_error(102,
                "No such prefix directory '%s'", $prefix_dir
            );
        }
    }
    else {
        # Look for the main binary executable "openssl" and use the parent
        # directory of where that is located; otherwise use the default prefix
        # directory as specified in the latest OpenSSL's own INSTALL file if it
        # exists.
        my $bin_file;
        if ($bin_file = $self->can_run('openssl')) {
            if ($self->is_win32()) {
                # Find out (if we can) which platform this binary was built for.
                # This information is normally contained in the output of the
                # binary's "version -a" command, labelled "platform: ".
                my $quoted_bin_file = $self->quote_str($bin_file);
                my $bin_cmd = "$quoted_bin_file version -a 2>&1";

                my $bin_output = `$bin_cmd`;
                my $bin_rc = $? >> 8;

                if ($bin_rc) {
                    $self->exit_with_error(133,
                        "Could not get OpenSSL version information " .
                        "(%d):\n%s", $bin_rc, $bin_output
                    );
                }

                if ((my $platform) = $bin_output =~ /platform: ?(.*)$/imo) {
                    # If we have found a Cygwin binary then we had better not
                    # try to use it with our Win32 perl.
                    if ($platform =~ /^Cygwin/io) {
                        warn("Warning: Ignoring Cygwin OpenSSL binary " .
                             "'$bin_file' on Win32\n");
                        $bin_file = undef;
                    }
                }
            }
        }

        my $default;
        if (defined $bin_file) {
            # The binaries are normally located in a sub-directory (bin/,
            # out32/, out32dll/, out32.dbg/, out32dll.dbg or out/) of the prefix
            # directory.  See locate_bin_file().
            my $bin_dir = dirname($bin_file);
            $default = canonpath(abs_path(catdir($bin_dir, updir())));
        }
        else {
            $default = $self->is_win32() ? 'C:\\openssl' : '/usr/local/ssl';
            unless (-d $default) {
                if ($self->use_default_response()) {
                    $self->exit_with_error(132,
                        'OS unsupported: No OpenSSL/SSLeay directory found'
                    );
                }
                else {
                    $default = '';
                }
            }
        }

        my $question = 'Where is your OpenSSL?';

        $prefix_dir = $self->prompt_dir($question, $default);
    }

    $self->prefix_dir($prefix_dir)
}

sub locate_inc_dir {
    my $self = shift;

    # NOTE: We support finding the header files of older OpenSSLs and SSLeays
    # than we support so that we can report on the failed minimum requirement.

    # The headers are normally located in the include/ sub-directory of the
    # prefix directory.
    # However, we may be working with a build directory rather than an
    # installation directory, in which case the header files will be in a
    # different sub-directory on "native" Windows platforms, in this case inc32/
    # (0.9.0 onwards) or out/ (up to and including 0.8.1b), or even outinc/ for
    # MinGW builds.  Beware of version 0.6.0 build directories, which contain an
    # include/ sub-directory containing "Shortcuts" to the real header files in
    # the out/ sub-directory.  Check for the presence of the "cyrypto.h" header
    # file to be sure we find the correct sub-directory.  The header files are
    # now located in the openssl/ sub-directory of the include directory (0.9.3
    # onwards), but were located in the include directory itself (up to and
    # including 0.8.1b).
    my $prefix_dir = $self->prefix_dir();
    my($dir, $inc_dir);
    if (-d ($dir = catdir($prefix_dir, 'include')) and
        (-f catfile($dir, 'openssl', 'crypto.h') or
         -f catfile($dir, 'crypto.h')))
    {
        $inc_dir = $dir;
    }
    elsif ($self->is_win32()) {
        if (-d ($dir = catdir($prefix_dir, 'inc32')) and
            (-f catfile($dir, 'openssl', 'crypto.h') or
             -f catfile($dir, 'crypto.h')))
        {
            $inc_dir = $dir;
        }
        elsif (-d ($dir = catdir($prefix_dir, 'outinc')) and
               (-f catfile($dir, 'openssl', 'crypto.h') or
                -f catfile($dir, 'crypto.h')))
        {
            $inc_dir = $dir;
        }
        elsif (-d ($dir = catdir($prefix_dir, 'out')) and
               -f catfile($dir, 'crypto.h'))
        {
            $inc_dir = $dir;
        }
    }

    if (defined $inc_dir) {
        $self->show_found_var('Found include directory', $inc_dir);
        $self->inc_dir($inc_dir)
    }
    else {
        $self->exit_with_error(103,
            'No OpenSSL/SSLeay include directory found'
        );
    }
}

sub set_inc {
    my $self = shift;

    my $inc_dir = $self->quote_str($self->inc_dir());
    $self->inc("-I$inc_dir");
}

sub determine_ver_num {
    my $self = shift;

    # NOTE: We support finding the version number of older OpenSSLs and SSLeays
    # than we support so that we can report on the failed minimum requirement.

    # The header files are now located in the openssl/ sub-directory of the
    # include directory (0.9.3 onwards), but were located in the include
    # directory itself (up to and including 0.8.1b).
    my $inc_dir = $self->inc_dir();
    my($dir, $inc_files_dir);
    if (-d ($dir = catdir($inc_dir, 'openssl'))) {
        $inc_files_dir = $dir;
    }
    else {
        $inc_files_dir = $inc_dir;
    }

    # The version number is now specified by an OPENSSL_VERSION_NUMBER #define
    # in the opensslv.h header file (0.9.2 onwards).  That #define was in the
    # crypto.h header file (0.9.1s), and was called SSLEAY_VERSION_NUMBER (from
    # 0.6.0 to 0.9.0b inclusive).  Earlier versions do not seem to have a
    # version number defined in this way, but we do not support anything earlier
    # anyway.  The version number is specified as a hexadecimal integer of the
    # form MNNFFPPS (major, minor, fix, patch, status [0 for dev, 1 to 14 for
    # betas, and f for release) (0.9.5a onwards, but with the highest bit set in
    # the patch byte for the 0.9.5s), or of the form MNNFFRBB (major, minor,
    # fix, release, patch or beta) (0.9.3s, 0.9.4s and 0.9.5), or of the form
    # MNFP (major, minor, fix, patch) (up to and including 0.9.2b).
    my($file, $ver_file);
    if (-f ($file = catfile($inc_files_dir, 'opensslv.h'))) {
        $ver_file = $file;
    }
    elsif (-f ($file = catfile($inc_files_dir, 'crypto.h'))) {
        $ver_file = $file;
    }
    else {
        $self->exit_with_error(104,
            'No OpenSSL/SSLeay version number header file found'
        );
    }

    my $ver_define;
    if (open my $ver_fh, '<', $ver_file) {
        while (<$ver_fh>) {
            if (/^\#\s*define\s+(?:OPENSSL|SSLEAY)_VERSION_NUMBER\s+
                 0x([0-9a-f]+)/iox)
            {
                $ver_define = $1;
                last;
            }
        }
        close $ver_fh;
    }
    else {
        $self->exit_with_error(105,
            "Could not open version number header file '%s' for reading: %s",
            $ver_file, $!
        );
    }

    my($major, $minor, $fix, $patch, $status_str);
    if (defined $ver_define) {
        if (length $ver_define == 8 and
            $ver_define =~ /^([0-9a-f])([0-9a-f]{2})([0-9a-f]{2})/io)
        {
            ($major, $minor, $fix) = map { hex } ($1, $2, $3);

            my $mmf_ver_num = $major * 10000 + $minor * 100 + $fix;

            if ( $mmf_ver_num >  905 or
                ($mmf_ver_num == 905 and $ver_define !~ /100$/o))
            {
                my $status_num;
                ($patch, $status_num) = map { hex }
                    $ver_define =~ /([0-9a-f]{2})([0-9a-f])$/io;

                $patch = 0xff & ($patch & ~0x80) if $mmf_ver_num == 905;

                if ($status_num == 0) {
                    $status_str = '-dev';
                }
                elsif ($status_num < 0xf) {
                    $status_str = '-beta' . (1 .. 0xe)[$status_num - 1];
                }
                else {
                    $status_str = '';
                }
            }
            else {
                my($release, $patch_or_beta) = map { hex }
                    $ver_define =~ /([0-9a-f])([0-9a-f]{2})$/io;

                if ($release == 0) {
                    $patch = 0;
                    if ($patch_or_beta == 0) {
                        $status_str = '-dev';
                    }
                    else {
                        $status_str = '-beta' . (1 .. 0xff)[$patch_or_beta - 1];
                    }
                }
                else {
                    $patch = $patch_or_beta;
                    $status_str = '';
                }
            }
        }
        elsif (length $ver_define == 4 and
               $ver_define =~ /^([0-9a-f])([0-9a-f])([0-9a-f])([0-9a-f])$/io)
        {
            ($major, $minor, $fix, $patch) = map { hex } ($1, $2, $3, $4);
            $status_str = '';
        }
        else {
            $self->exit_with_error(106,
                'Unrecognized OpenSSL/SSLeay version number found (%s)',
                $ver_define
            );
        }
    }
    else {
        $self->exit_with_error(107, 'No OpenSSL/SSLeay version number found');
    }

    my $ver_num = $major * 1000000 + $minor * 10000 + $fix * 100 + $patch;
    my $ver_str = "$major.$minor.$fix";
    $ver_str .= ('', 'a' .. 'y', 'za' .. 'zz')[$patch];
    $ver_str .= $status_str;

    my $package = $ver_num >= 90100 ? 'OpenSSL' : 'SSLeay';

    if ($major == 0 and ($minor < 9 or ($minor == 9 and ($fix < 6 or
            ($fix == 6 and $patch < 11) or ($fix == 7 and $patch < 3)))))
    {
        $self->exit_with_error(135,
            'OS unsupported: OpenSSL version 0.9.6k or 0.9.7c or higher ' .
            'required. This is only %s version %s', $package, $ver_str
        );
    }

    $self->show_found_var('Found OpenSSL version', $ver_str);
    $self->ver_str($ver_str);
    $self->ver_num($ver_num);
}

sub set_define {
    my $self = shift;

    my $ver_num = $self->ver_num();
    my $unsafe_mode = exists $self->opts()->{'unsafe-mode'};
    my $debug_mode  = exists $self->opts()->{'debug-mode'};

    my $define =  "-DFILTER_CRYPTO_OPENSSL_VERSION=$ver_num";
    $define   .= ' -DFILTER_CRYPTO_UNSAFE_MODE' if $unsafe_mode;
    $define   .= ' -DFILTER_CRYPTO_DEBUG_MODE'  if $debug_mode;

    $self->define($define);
}

sub locate_lib_dir_and_file {
    my $self = shift;

    # The libraries are normally located in the lib/ sub-directory of the prefix
    # directory, but may be in the lib64/ sub-directory on some 64-bit systems,
    # or in the lib/amd64/ or lib/sparcv9/ sub-directory on 64-bit Solaris Intel
    # or 64-bit Solaris Sparc respectively.  Some 64-bit systems may have lib/
    # sub-directories as well, so check in lib64/ etc. first, but only check for
    # 64-bit libraries if we are using a 64-bit perl.  Under Debian Multiarch
    # (e.g. Ubuntu >= 11.04) the libraries are migrated to lib/i386-linux-gnu/
    # and lib/x86_64-linux-gnu/ sub-directories.  On an ARM-based Debian machine
    # the libraries may be found in /lib/arm-linux/gnueabihf/.
    # Again, build directories on "native" Windows platforms may have the files
    # in a different sub-directory, in this case out32/, out32dll/, out32.dbg/
    # or out32dll.dbg/ (depending on whether static or dynamic libraries were
    # built and whether they were built in release or debug mode).
    # The Win32 OpenSSL Installation produced by Shining Light Productions
    # installs its libraries into lib/VC (dynamic libraries), lib/VC/static
    # (static libraries) or lib/MinGW.
    my $prefix_dir = $self->prefix_dir();
    my($dir, $lib_dir, $lib_file, $lib_name);
    if ($self->is_win32()) {
        if (-d ($dir = catdir($prefix_dir, 'out32')) and
            ($lib_file, $lib_name) = $self->probe_for_lib_file($dir))
        {
            $lib_dir = $dir;
        }
        elsif (-d ($dir = catdir($prefix_dir, 'out32dll')) and
               ($lib_file, $lib_name) = $self->probe_for_lib_file($dir))
        {
            $lib_dir = $dir;
        }
        elsif (-d ($dir = catdir($prefix_dir, 'out32.dbg')) and
               ($lib_file, $lib_name) = $self->probe_for_lib_file($dir))
        {
            $lib_dir = $dir;
        }
        elsif (-d ($dir = catdir($prefix_dir, 'out32dll.dbg')) and
               ($lib_file, $lib_name) = $self->probe_for_lib_file($dir))
        {
            $lib_dir = $dir;
        }
        elsif ($Config{cc} =~ /cl/io and
               -d ($dir = catdir($prefix_dir, 'lib', 'VC', 'static')) and
               ($lib_file, $lib_name) = $self->probe_for_lib_file($dir))
        {
            $lib_dir = $dir;
        }
        elsif ($Config{cc} =~ /cl/io and
               -d ($dir = catdir($prefix_dir, 'lib', 'VC')) and
               ($lib_file, $lib_name) = $self->probe_for_lib_file($dir))
        {
            $lib_dir = $dir;
        }
        elsif ($Config{cc} =~ /gcc/io and
               -d ($dir = catdir($prefix_dir, 'lib', 'MinGW')) and
               ($lib_file, $lib_name) = $self->probe_for_lib_file($dir))
        {
            $lib_dir = $dir;
        }
    }
    if (not defined $lib_dir) {
        if (defined $Config{use64bitint} and
            $Config{use64bitint} eq 'define' and
            -d ($dir = catdir($prefix_dir, 'lib64')) and
            ($lib_file, $lib_name) = $self->probe_for_lib_file($dir))
        {
            $lib_dir = $dir;
        }
        elsif (defined $Config{use64bitint} and
               $Config{use64bitint} eq 'define' and
               -d ($dir = catdir($prefix_dir, 'lib', 'amd64')) and
               ($lib_file, $lib_name) = $self->probe_for_lib_file($dir))
        {
            $lib_dir = $dir;
        }
        elsif (defined $Config{use64bitint} and
               $Config{use64bitint} eq 'define' and
               -d ($dir = catdir($prefix_dir, 'lib', 'sparcv9')) and
               ($lib_file, $lib_name) = $self->probe_for_lib_file($dir))
        {
            $lib_dir = $dir;
        }
        elsif (defined $Config{use64bitint} and
               $Config{use64bitint} eq 'define' and
               -d ($dir = catdir($prefix_dir, 'lib', 'x86_64-linux-gnu')) and
               ($lib_file, $lib_name) = $self->probe_for_lib_file($dir))
        {
            $lib_dir = $dir;
        }
        elsif (-d ($dir = catdir($prefix_dir, 'lib', 'i386-linux-gnu')) and
               ($lib_file, $lib_name) = $self->probe_for_lib_file($dir))
        {
            $lib_dir = $dir;
        }
        elsif (-d ($dir = catdir($prefix_dir, 'lib', 'arm-linux-gnueabihf')) and
               ($lib_file, $lib_name) = $self->probe_for_lib_file($dir))
        {
            $lib_dir = $dir;
        }
        elsif (-d ($dir = catdir($prefix_dir, 'lib')) and
               ($lib_file, $lib_name) = $self->probe_for_lib_file($dir))
        {
            $lib_dir = $dir;
        }
    }

    if (defined $lib_dir) {
        $self->show_found_var('Found crypto library', $lib_file);
        $self->lib_dir($lib_dir);
        $self->lib_name($lib_name);
    }
    else {
        $self->exit_with_error(109, 'No OpenSSL crypto library found');
    }
}

sub probe_for_lib_file {
    my $self = shift;
    my $candidate_lib_dir = shift;

    # The libraries on UNIX-type platforms (which includes Cygwin) are called
    # libssl.a (which contains the SSL and TLS implmentations) and libcrypto.a
    # (which contains the ciphers, digests, etc) and are specified as -lssl and
    # -lcrypto respectively.  Solaris 10 discourages static linking and Solaris
    # 11 doesn't even ship static libraries for OpenSSL, so libcrypto.so must be
    # used instead where that exists in place of libcrypto.a.
    # On "native" Windows platforms built with Visual C++ (cl) or Borland C++
    # (bcc32) they were called ssleay32.lib and libeay32.lib and were specified
    # as -lssleay32 and -llibeay32 but from 1.1.0 onwards are now called
    # libssl.lib and libcrypto.lib and are specified as -llibssl and
    # -llibcrypto.
    # It is also possible to produce "native" Windows builds (i.e. binaries and
    # libraries that are linked against the Microsoft C RTL msvcrt.dll rather
    # than Cygwin's POSIX C RTL cygwin1.dll) via MinGW/MinGW-w64 (gcc).  In that
    # case, the OpenSSL libraries are called either libssl.a and libcrypto.a
    # (for static builds) or libssl32.a and libeay32.a [sic] (for dynamic
    # builds).  They are specified as on UNIX-type platforms, as described in
    # the ExtUtils::Liblist manpage.
    # The Win32 OpenSSL Installation produced by Shining Light Productions names
    # its libraries differently. The Visual C++ libraries are named as normal
    # but with a MD, MDd, MT or MTd suffix just before the .lib extension (e.g.
    # libeay32MD.lib), depending on whether they were built with the -MD or -MT
    # compiler option (of which only the former is supported by Perl) and
    # whether they were built in release or debug mode. The MinGW libraries are
    # only provided as dynamic release build libraries, and are named similarly
    # to the default names of Visual C++ libraries, namely ssleay32.a and
    # libeay32.a.
    my($file, $lib_file, $lib_name);
    if ($self->is_win32()) {
        if ($Config{cc} =~ /gcc/io) {
            if (-f ($file = catfile($candidate_lib_dir, 'libcrypto.a'))) {
                $lib_file = $file;
                $lib_name = 'crypto';
            }
            elsif (-f ($file = catfile($candidate_lib_dir, 'libeay32.a'))) {
                $lib_file = $file;
                $lib_name = 'eay32';
            }
        }
        else {
            if (-f ($file = catfile($candidate_lib_dir, 'libeay32.lib'))) {
                $lib_file = $file;
                $lib_name = 'libeay32';
            }
            elsif ($Config{cc} =~ /cl/io and
                   -f ($file = catfile($candidate_lib_dir, 'libeay32MD.lib')))
            {
                $lib_file = $file;
                $lib_name = 'libeay32MD';
            }
            elsif ($Config{cc} =~ /cl/io and
                   -f ($file = catfile($candidate_lib_dir, 'libeay32MDd.lib')))
            {
                $lib_file = $file;
                $lib_name = 'libeay32MDd';
            }
            elsif (-f ($file = catfile($candidate_lib_dir, 'libcrypto.lib'))) {
                $lib_file = $file;
                $lib_name = 'libcrypto';
            }
        }
    }
    else {
        if (-f ($file = catfile($candidate_lib_dir, 'libcrypto.a'))) {
            $lib_file = $file;
            $lib_name = 'crypto';
        }
        elsif (-f ($file = catfile($candidate_lib_dir, 'libcrypto.so'))) {
            $lib_file = $file;
            $lib_name = 'crypto';
        }
        elsif (-f ($file = catfile($candidate_lib_dir, 'libcrypto.dylib'))) {
            $lib_file = $file;
            $lib_name = 'crypto';
        }
    }

    return $lib_file ? ($lib_file, $lib_name) : ();
}

sub set_libs {
    my $self = shift;

    my $lib_dir  = $self->quote_str($self->lib_dir());
    my $lib_name = $self->lib_name();
    my $libs = "-L$lib_dir -l$lib_name";

    # The CryptoAPI library is required for static builds of OpenSSL on Windows
    # from version 1.1.0 onwards (unless the no-capieng build option was used),
    # so include it in the list of libraries just in case it is required. See:
    # https://mta.openssl.org/pipermail/openssl-users/2016-May/003759.html
    # For Windows 7 onwards BCryptGenRandom is used instead of the legacy
    # CryptoAPI, although CryptoAPI is still used for Certificate functions too.
    # See: https://github.com/openssl/openssl/commit/fa64e63373
    if ($self->is_win32()) {
        $libs .= ' -lcrypt32.lib';
        my @osver = Win32::GetOSVersion();
        my $osver = 0 + "$osver[1].$osver[2]";
        $libs .= ' -lbcrypt.lib' if $osver >= 6.1;
    }

    $self->libs($libs);
}

sub locate_bin_file {
    my $self = shift;

    # The binaries are normally located in the bin/ sub-directory of the prefix
    # directory.
    # Again, build directories on "native" Windows platforms may have the files
    # in a different sub-directory, in this case out32/, out32dll/, out32.dbg/
    # or out32dll.dbg/ (depending on whether static or dynamic libraries were
    # built and whether they were built in release or debug mode).
    my $prefix_dir = $self->prefix_dir();
    my($dir, $bin_file);
    my $found = 0;
    if (-d ($dir = catdir($prefix_dir, 'bin')) and
        defined($bin_file = $self->probe_for_bin_file($dir)))
    {
        $found = 1;
    }
    elsif ($self->is_win32()) {
        if (-d ($dir = catdir($prefix_dir, 'out32')) and
            defined($bin_file = $self->probe_for_bin_file($dir)))
        {
            $found = 1;
        }
        elsif (-d ($dir = catdir($prefix_dir, 'out32dll')) and
               defined($bin_file = $self->probe_for_bin_file($dir)))
        {
            $found = 1;
        }
        elsif (-d ($dir = catdir($prefix_dir, 'out32.dbg')) and
               defined($bin_file = $self->probe_for_bin_file($dir)))
        {
            $found = 1;
        }
        elsif (-d ($dir = catdir($prefix_dir, 'out32dll.dbg')) and
               defined($bin_file = $self->probe_for_bin_file($dir)))
        {
            $found = 1;
        }
    }

    if ($found) {
        $self->show_found_var('Found binary executable', $bin_file);
        $self->bin_file($bin_file)
    }
    else {
        $self->exit_with_error(111, 'No OpenSSL binary executable found');
    }
}

sub probe_for_bin_file {
    my $self = shift;
    my $candidate_bin_dir = shift;

    # The main binary executable is called "openssl".
    my($file, $bin_file);
    if (-f ($file = catfile($candidate_bin_dir, "openssl$Config{_exe}"))) {
        $bin_file = $file;
    }

    return $bin_file;
}

sub query_cipher_name {
    my $self = shift;

    my $ver_num = $self->ver_num();

    # Find out (as best as we can) which ciphers, if any, have been disabled in
    # the particular crypto library that we are using.  Ciphers can be disabled
    # at build time via "-DOPENSSL_NO_<cipher_name>" (or "-DNO_<cipher_name>"
    # before 0.9.7), where <cipher_name> can be one of: "DES", "RC4", "IDEA",
    # "RC2", "BF", "RC5", "CAST" or "AES".  This information is normally
    # contained in the output of the main binary executable's "version -a"
    # command, labelled "compiler: " and not always on a line of its own.
    my $bin_file = $self->quote_str($self->bin_file());
    my $bin_cmd = "$bin_file version -a 2>&1";

    my $bin_output = `$bin_cmd`;
    my $bin_rc = $? >> 8;

    if ($bin_rc) {
        $self->exit_with_error(112,
            "Could not get OpenSSL version information (%d):\n%s",
            $bin_rc, $bin_output
        );
    }

    my %disabled = ();
    if ((my $compiler) = $bin_output =~ /compiler: ?(.*)$/imo) {
        %disabled = map { $_ => 1 }
                    $compiler =~ m|[-/]D ?"?(?:OPENSSL_)?NO_(\w+)"?|go;
    }

    my @cipher_names = ();

    if (not exists $disabled{DES}) {
        push @cipher_names, (
            [ CIPHER_NAME_DES,      'DES block cipher'                  ],
            [ CIPHER_NAME_DES_EDE,  'Two key triple DES block cipher'   ],
            [ CIPHER_NAME_DES_EDE3, 'Three key triple DES block cipher' ],
            [ CIPHER_NAME_DESX,     'DESX block cipher'                 ]
        );
    }

    if (not exists $disabled{RC4}) {
        push @cipher_names, (
            [ CIPHER_NAME_RC4, 'RC4 stream cipher' ]
        );
    }

    if (not exists $disabled{IDEA}) {
        push @cipher_names, (
            [ CIPHER_NAME_IDEA, 'IDEA block cipher' ]
        );
    }

    if (not exists $disabled{RC2}) {
        push @cipher_names, (
            [ CIPHER_NAME_RC2, 'RC2 block cipher' ]
        );
    }

    if (not exists $disabled{BF}) {
        push @cipher_names, (
            [ CIPHER_NAME_BLOWFISH, 'Blowfish block cipher' ]
        );
    }

    push @cipher_names, (
        [ CIPHER_NAME_NULL, 'Null cipher' ]
    );

    if (not exists $disabled{RC5}) {
        push @cipher_names, (
            [ CIPHER_NAME_RC5, 'RC5 block cipher' ]
        );
    }

    if (not exists $disabled{CAST}) {
        push @cipher_names, (
            [ CIPHER_NAME_CAST5, 'CAST5 block cipher' ]
        );
    }

    # The AES cipher was added in OpenSSL 0.9.7.
    if (not exists $disabled{AES} and $ver_num >= 90700) {
        push @cipher_names, (
            [ CIPHER_NAME_AES, 'AES block cipher' ]
        );
    }

    my $cipher_name = $self->opts()->{'cipher-name'};
    if (defined $cipher_name) {
        my %lc_cipher_names = map { lc $_->[0] => 1 } @cipher_names;
        if (exists $lc_cipher_names{lc $cipher_name}) {
            $self->show_found_var('Using specified cipher name', $cipher_name);
        }
        else {
            $self->exit_with_error(113,
                "No such cipher name '%s'", $cipher_name
            );
        }
    }
    else {
        my $message  = 'Cipher algorithms available:';
        my $question = 'Which cipher algorithm do you want to use?';

        my $default;
        if (not exists $disabled{DES} and $ver_num < 90700) {
            $default = CIPHER_NAME_DES_EDE3;
        }
        elsif (not exists $disabled{AES} and $ver_num >= 90700) {
            $default = CIPHER_NAME_AES;
        }
        else {
            $default = $cipher_names[$#cipher_names][0];
        }

        $cipher_name = $self->prompt_list(
            $message, \@cipher_names, $question, $default
        );
    }
    print "\n";

    $self->cipher_name($cipher_name);
}

sub query_cipher_mode {
    my $self = shift;

    my @cipher_modes = (
        [ CIPHER_MODE_ECB, 'ECB (Electronic Codebook Mode)'    ],
        [ CIPHER_MODE_CBC, 'CBC (Cipher Block Chaining Mode)'  ],
        [ CIPHER_MODE_CFB, 'CFB (64-Bit Cipher Feedback Mode)' ],
        [ CIPHER_MODE_OFB, 'OFB (64-Bit Output Feedback Mode)' ]
    );

    my $cipher_mode = $self->opts()->{'cipher-mode'};
    if (defined $cipher_mode) {
        my %lc_cipher_modes = map { lc $_->[0] => $_->[0] } @cipher_modes;
        if (exists $lc_cipher_modes{lc $cipher_mode}) {
            $self->show_found_var('Using specified cipher mode', $cipher_mode);
            $cipher_mode = $lc_cipher_modes{lc $cipher_mode};
        }
        else {
            $self->exit_with_error(114,
                "No such cipher mode '%s'", $cipher_mode
            );
        }
    }
    else {
        my $message  = 'Modes of operation available:';
        my $question = 'Which mode of operation do you want to use?';
        my $default  = CIPHER_MODE_CBC;

        $cipher_mode = $self->prompt_list(
            $message, \@cipher_modes, $question, $default
        );
    }
    print "\n";

    return $cipher_mode;
}

sub query_key_len {
    my $self = shift;
    my %args = @_;

    my $validate;
    if (exists $args{-fixed}) {
        $validate = sub { $_[0] eq $args{-fixed} };
    }
    elsif (exists $args{-valid}) {
        my %valid = map { $_ => 1 } @{$args{-valid}};
        $validate = sub { exists $valid{$_[0]} };
    }
    else {
        my $int_pat = qr/^(?:0|[1-9](?:\d+)?)$/o;
        # Minimum key size is clearly 0 bytes if it is not otherwise set
        # already.  Restrict the maximum key size to some sensible value if it
        # is not set already: we do not want to allow the user to enter an
        # arbitrarily large integer.
        $args{-min} = 0    unless exists $args{-min};
        $args{-max} = 1024 unless exists $args{-max};
        $validate = sub {
            $_[0] =~ $int_pat and $_[0] >= $args{-min} and $_[0] <= $args{-max}
        };
    }

    my $key_len = $self->opts()->{'key-len'};
    my $key = $self->opts()->{key};
    if (defined $key_len) {
        if ($validate->($key_len)) {
            $self->show_found_var('Using specified key length', $key_len);
        }
        else {
            $self->exit_with_error(115, "Invalid key length '%d'", $key_len);
        }
    }
    elsif (defined $key and $key ne RAND_OPTION_STR) {
        $key_len = length($key) / 2;
        if ($validate->($key_len)) {
            $self->show_found_var('Using inferred key length', $key_len);
        }
        else {
            $self->exit_with_error(116, "Invalid length key (%d)", $key_len);
        }
    }
    elsif (exists $args{-fixed}) {
        $key_len = $args{-fixed};
        $self->show_found_var('Using fixed key length', $key_len);
    }
    else {
        my $message = "This is a variable key length algorithm.\n";

        if (exists $args{-valid}) {
            my @key_lens = @{$args{-valid}};
            my $max_key_len = pop @key_lens;
            $message .= sprintf 'Valid key lengths are: %s or %d bytes.',
                                join(', ', @key_lens), $max_key_len;
        }
        else {
            $message .= sprintf 'Valid key lengths are from %d byte%s up to ' .
                                '%d byte%s.',
                                $args{-min}, $args{-min} == 1 ? '' : 's',
                                $args{-max}, $args{-max} == 1 ? '' : 's';
        }

        my $question = 'What key length (in bytes) do you want to use?';

        $key_len = $self->prompt_validate(
            -message  => $message,
            -question => $question,
            -default  => $args{-default},
            -validate => $validate
        );
    }
    print "\n";

    $self->key_len($key_len);
}

sub query_rc2_key_bits {
    my $self = shift;

    # The "effective key bits" parameter can be from 1 to 1024 bits: see RFC
    # 2268.
    my %args = (-min => 1, -max => 1024, -default => 128);

    my $int_pat = qr/^(?:0|[1-9](?:\d+)?)$/o;
    my $validate = sub {
        $_[0] =~ $int_pat and $_[0] >= $args{-min} and $_[0] <= $args{-max}
    };

    my $rc2_key_bits = $self->opts()->{'rc2-key-bits'};
    if (defined $rc2_key_bits) {
        if ($validate->($rc2_key_bits)) {
            $self->show_found_var(
                'Using specified RC2 key bits', $rc2_key_bits
            );
        }
        else {
            $self->exit_with_error(117,
                "Invalid RC2 key bits '%d'", $rc2_key_bits
            );
        }
    }
    else {
        my $message = "This algorithm also has an 'effective key bits' (EKB) " .
                      "parameter.\n";

        $message .= sprintf 'Valid EKB values are from %d bit%s up to %d ' .
                            'bit%s.',
                            $args{-min}, $args{-min} == 1 ? '' : 's',
                            $args{-max}, $args{-max} == 1 ? '' : 's';

        my $question = 'What EKB value (in bits) do you want to use?';

        $rc2_key_bits = $self->prompt_validate(
            -message  => $message,
            -question => $question,
            -default  => $args{-default},
            -validate => $validate
        );
    }
    print "\n";

    $self->rc2_key_bits($rc2_key_bits);
}

sub query_rc5_rounds {
    my $self = shift;

    # The "number of rounds" parameter can be from 0 to 255: see RFC 2040.
    # However, it can currently only be set to 8, 12 or 16 by the RC5 code in
    # OpenSSL: see EVP_EncryptInit.pod in recent OpenSSL distributions.
    my %args = (-valid => [8, 12, 16], -default => 12);

    my %valid = map { $_ => 1 } @{$args{-valid}};
    my $validate = sub { exists $valid{$_[0]} };

    my $rc5_rounds = $self->opts()->{'rc5-rounds'};
    if (defined $rc5_rounds) {
        if ($validate->($rc5_rounds)) {
            $self->show_found_var('Using specified RC5 rounds', $rc5_rounds);
        }
        else {
            $self->exit_with_error(118,
                "Invalid RC5 rounds '%d'", $rc5_rounds
            );
        }
    }
    else {
        my $message = "This algorithm also has a 'number of rounds' " .
                      "parameter.\n";

        my @rc5_rounds = @{$args{-valid}};
        my $max_rc5_rounds = pop @rc5_rounds;
        $message .= sprintf 'Valid numbers of rounds are: %s or %d.',
                            join(', ', @rc5_rounds), $max_rc5_rounds;

        my $question = 'What number of rounds do you want to use?';

        $rc5_rounds = $self->prompt_validate(
            -message  => $message,
            -question => $question,
            -default  => $args{-default},
            -validate => $validate
        );
    }
    print "\n";

    $self->rc5_rounds($rc5_rounds);
}

sub query_pswd_or_key {
    my $self = shift;

    my $key_len = $self->key_len();

    if ($key_len == 0) {
        $self->key('');
        return;
    }

    my $validate_pswd = sub {
        $_[0] ne ''
    };

    my $validate_key = sub {
        $_[0] =~ /^[0-9a-f]*$/io and length $_[0] == 2 * $key_len
    };

    my $pswd = $self->opts()->{pswd};
    my $key  = $self->opts()->{key};
    if (defined $pswd) {
        if (lc $pswd eq lc RAND_OPTION_STR) {
            $pswd = $self->generate_rand_pswd();
            print "\n";

            $self->show_found_var('Using randomly generated password', $pswd);
            $self->pswd($pswd);
        }
        elsif ($validate_pswd->($pswd)) {
            $self->show_found_var('Using specified password', $pswd);
            $self->pswd(unpack 'H*', $pswd);
        }
        else {
            $self->exit_with_error(119, "Invalid password '%s'", $pswd);
        }
    }
    elsif (defined $key) {
        if (lc $key eq lc RAND_OPTION_STR) {
            $key = $self->generate_rand_key();
            print "\n";

            $self->show_found_var('Using randomly generated key', $key);
            $self->key($key);
        }
        elsif ($validate_key->($key)) {
            $self->show_found_var('Using specified key', $key);
            $self->key($key);
        }
        else {
            $self->exit_with_error(120, "Invalid key '%s'", $key);
        }
    }
    else {
        my @cipher_key_sources = (
            [ CIPHER_KEY_GIVEN_PSWD,  'Enter a password when prompted'     ],
            [ CIPHER_KEY_RANDOM_PSWD, 'Have a password randomly generated' ],
            [ CIPHER_KEY_GIVEN,       'Enter a key when prompted'          ],
            [ CIPHER_KEY_RANDOM,      'Have a key randomly generated'      ]
        );
    
        my $message  = 'You can either specify a password from which the ' .
                       'key to be used for encryption/decryption will be ' .
                       'derived using a PKCS#5 key derivation algorithm, or ' .
                       "you can directly specify the key to use.\n" .
                       'You can also have a password or key randomly ' .
                       "generated for you.\n\n" .
                       'Options for specifying or deriving the key:';
        my $question = 'How do you want to specify or derive the key?';
        my $default  = CIPHER_KEY_RANDOM_PSWD;

        my $cipher_key_source = $self->prompt_list(
            $message, \@cipher_key_sources, $question, $default
        );
    
        print "\n";
    
        if ($cipher_key_source == CIPHER_KEY_GIVEN_PSWD) {
            $message  = 'Enter your password:';
            $question = 'Password?';
            $default  = '';

            $pswd = $self->prompt_validate(
                -message  => $message,
                -question => $question,
                -default  => $default,
                -validate => $validate_pswd
            );

            $self->pswd(unpack 'H*', $pswd);
        }
        elsif ($cipher_key_source == CIPHER_KEY_RANDOM_PSWD) {
            $pswd = $self->generate_rand_pswd();
            $self->pswd($pswd);
        }
        elsif ($cipher_key_source == CIPHER_KEY_GIVEN) {
            $message  = "Enter your ${key_len}-byte key with each byte " .
                        "written as a pair of hexadecimal digits with the " .
                        "high nybble first:";
            $question = 'Key?';
            $default  = '';

            $key = $self->prompt_validate(
                -message  => $message,
                -question => $question,
                -default  => $default,
                -validate => $validate_key
            );

            $self->key($key);
        }
        elsif ($cipher_key_source == CIPHER_KEY_RANDOM) {
            $key = $self->generate_rand_key();
            $self->key($key);
        }
        else {
            $self->exit_with_error(121,
                "Unknown key source '%s'", $cipher_key_source
            );
        }
    }

    print "\n";
}

sub generate_rand_key {
    my $self = shift;
    return $self->generate_rand_octets_hex($self->key_len());
}

sub generate_rand_pswd {
    my $self = shift;
    return $self->generate_rand_octets_hex(RAND_PSWD_LEN);
}

sub generate_rand_octets_hex {
    my $self = shift;
    my $num_octets = shift;

    my $rng = $self->query_rng();

    my $octets;
    if (lc $rng eq lc RNG_PERL_RAND) {
        $octets = '';
        for (1 .. $num_octets) {
            $octets .= chr int rand 256;
        }
    }
    elsif (lc $rng eq lc RNG_CRYPT_RANDOM) {
        # Delay the loading of Crypt::Random until it is actually required since
        # it is not a standard module.
        my $ok = eval {
            require Crypt::Random;
            Crypt::Random->import(qw(makerandom_octet));
            1;
        };

        if (not $ok) {
            $self->exit_with_error(122,
                "Can't load Crypt::Random module for random number generation"
            );
        }

        # Specify "Strength => 0" to use /dev/urandom rather than /dev/random
        # to avoid potentially blocking for a long time.
        $octets = makerandom_octet(
            Length => $num_octets, Strength => 0
        );
    }
    elsif (lc $rng eq lc RNG_MATH_RANDOM) {
        # Delay the loading of Math::Random until it is actually required since
        # it is not a standard module.
        my $ok = eval {
            require Math::Random;
            Math::Random->import(qw(random_uniform_integer));
            1;
        };

        if (not $ok) {
            $self->exit_with_error(123,
                "Can't load Math::Random module for random number generation"
            );
        }

        $octets = join '',
                       map { chr } random_uniform_integer($num_octets, 0, 255);
    }
    elsif (lc $rng eq lc RNG_OPENSSL_RAND) {
        my $bin_file = $self->quote_str($self->bin_file());
        my $out_filename = 'rand.out';

        my $bin_cmd = "$bin_file rand -out $out_filename $num_octets 2>&1";

        my $bin_output = `$bin_cmd`;
        my $bin_rc = $? >> 8;

        if ($bin_rc) {
            $self->exit_with_error(124,
                "Could not generate %d random bytes (%d):\n%s",
                $num_octets, $bin_rc, $bin_output
            );
        }

        sysopen my $out_fh, $out_filename, O_RDONLY | O_BINARY or
            $self->exit_with_error(125,
                "Could not open random bytes output file '%s' for reading: %s",
                $out_filename, $!
            );

        my $num_octets_read = sysread $out_fh, $octets, $num_octets;
        if (not defined $num_octets_read) {
            $self->exit_with_error(126,
                "Could not read random bytes from output file '%s': %s",
                $out_filename, $!
            );
        }
        elsif ($num_octets_read != $num_octets) {
            $self->exit_with_error(127,
                "Could not read random bytes from output file '%s': %d bytes " .
                "read, %d bytes expected",
                $out_filename, $num_octets_read, $num_octets
            );
        }

        close $out_fh;
        unlink $out_filename;
    }
    else {
        $self->exit_with_error(128,
            "Unknown random number generator '%s'", $rng
        );
    }

    return unpack 'H*', $octets;
}

sub query_rng {
    my $self = shift;

    my @rngs = (
        [ RNG_PERL_RAND, "Perl's built-in rand() function" ]
    );

    if (eval { require Crypt::Random }) {
        push @rngs, (
            [ RNG_CRYPT_RANDOM, 'Crypt::Random' ]
        );
    }

    if (eval { require Math::Random }) {
        push @rngs, (
            [ RNG_MATH_RANDOM, 'Math::Random' ]
        );
    }

    push @rngs, (
        [ RNG_OPENSSL_RAND, "OpenSSL's rand command" ]
    );

    my $rng = $self->opts()->{rng};
    if (defined $rng) {
        my %lc_rngs = map { lc $_->[0] => $_->[0] } @rngs;
        if (exists $lc_rngs{lc $rng}) {
            $self->show_found_var('Using specified RNG', $rng);
            $rng = $lc_rngs{lc $rng};
        }
        else {
            $self->exit_with_error(129,
                "Invalid random number generator '%s'", $rng
            );
        }
    }
    else {
        my $message  = 'Random number generators:';
        my $question = 'Which RNG do you want to use?';
        my $default  = $rngs[$#rngs][0];

        $rng = $self->prompt_list(
            $message, \@rngs, $question, $default
        );
    }

    return $rng;
}

sub configure_des_cipher {
    my $self = shift;

    my %cipher_funcs = (
        CIPHER_MODE_ECB, 'EVP_des_ecb()',
        CIPHER_MODE_CBC, 'EVP_des_cbc()',
        CIPHER_MODE_CFB, 'EVP_des_cfb()',
        CIPHER_MODE_OFB, 'EVP_des_ofb()'
    );
    my $cipher_mode = $self->query_cipher_mode();
    $self->cipher_func($cipher_funcs{$cipher_mode});
    $self->cipher_needs_iv(1);

    # The DES cipher can only use an 8 byte key (of which only 7 bytes are
    # actually used by the algorithm): see FIPS PUB 46-3.
    $self->query_key_len(-fixed => 8);
}

sub configure_des_ede_cipher {
    my $self = shift;

    my $ver_num = $self->ver_num();
    my %cipher_funcs = (
        CIPHER_MODE_ECB, ($ver_num < 90700
                          ? 'EVP_des_ede()' : 'EVP_des_ede_ecb()'),
        CIPHER_MODE_CBC, 'EVP_des_ede_cbc()',
        CIPHER_MODE_CFB, 'EVP_des_ede_cfb()',
        CIPHER_MODE_OFB, 'EVP_des_ede_ofb()'
    );
    my $cipher_mode = $self->query_cipher_mode();
    $self->cipher_func($cipher_funcs{$cipher_mode});
    $self->cipher_needs_iv(1);

    # The DES-EDE cipher is two-key triple-DES (i.e. in which an encrypt
    # operation is encrypt with key 1, decrypt with key 2, encrypt with key 1),
    # and therefore requires a key length equivalent to two DES keys, i.e. 16
    # bytes (of which only 14 are used).
    $self->query_key_len(-fixed => 16);
}

sub configure_des_ede3_cipher {
    my $self = shift;

    my $ver_num = $self->ver_num();
    my %cipher_funcs = (
        CIPHER_MODE_ECB, ($ver_num < 90700
                          ? 'EVP_des_ede3()' : 'EVP_des_ede3_ecb()'),
        CIPHER_MODE_CBC, 'EVP_des_ede3_cbc()',
        CIPHER_MODE_CFB, 'EVP_des_ede3_cfb()',
        CIPHER_MODE_OFB, 'EVP_des_ede3_ofb()'
    );
    my $cipher_mode = $self->query_cipher_mode();
    $self->cipher_func($cipher_funcs{$cipher_mode});
    $self->cipher_needs_iv(1);

    # The DES-EDE3 cipher is three-key triple-DES (i.e. in which an encrypt
    # operation is encrypt with key 1, decrypt with key 2, encrypt with key 3),
    # and therefore requires a key length equivalent to two DES keys, i.e. 24
    # bytes (of which only 21 are used).
    $self->query_key_len(-fixed => 24);
}

sub configure_rc4_cipher {
    my $self = shift;

    $self->cipher_func('EVP_rc4()');
    $self->cipher_needs_iv(0);

    # The RC4 cipher can use any key length: see rc4.doc in old SSLeay
    # distributions.
    $self->query_key_len(-min => 1, -default => 16);
}

sub configure_idea_cipher {
    my $self = shift;

    my %cipher_funcs = (
        CIPHER_MODE_ECB, 'EVP_idea_ecb()',
        CIPHER_MODE_CBC, 'EVP_idea_cbc()',
        CIPHER_MODE_CFB, 'EVP_idea_cfb()',
        CIPHER_MODE_OFB, 'EVP_idea_ofb()'
    );
    my $cipher_mode = $self->query_cipher_mode();
    $self->cipher_func($cipher_funcs{$cipher_mode});
    $self->cipher_needs_iv(1);

    # The IDEA cipher can only use a 16 byte key: see idea.doc in old SSLeay
    # distributions.
    $self->query_key_len(-fixed => 16);
}

sub configure_rc2_cipher {
    my $self = shift;

    my %cipher_funcs = (
        CIPHER_MODE_ECB, 'EVP_rc2_ecb()',
        CIPHER_MODE_CBC, 'EVP_rc2_cbc()',
        CIPHER_MODE_CFB, 'EVP_rc2_cfb()',
        CIPHER_MODE_OFB, 'EVP_rc2_ofb()'
    );
    my $cipher_mode = $self->query_cipher_mode();
    $self->cipher_func($cipher_funcs{$cipher_mode});
    $self->cipher_needs_iv(1);

    # The RC2 cipher can use any key length from 1 to 128 bytes: see RFC 2268.
    $self->query_key_len(-min => 1, -max => 128, -default => 16);

    # The RC2 cipher also has a parameter called "effective key bits".
    $self->query_rc2_key_bits();
}

sub configure_desx_cipher {
    my $self = shift;

    $self->cipher_func('EVP_desx_cbc()');
    $self->cipher_needs_iv(1);

    # The DESX cipher can only use a 24 byte key: see des.pod in recent OpenSSL
    # distributions.
    $self->query_key_len(-fixed => 24);
}

sub configure_blowfish_cipher {
    my $self = shift;

    my %cipher_funcs = (
        CIPHER_MODE_ECB, 'EVP_bf_ecb()',
        CIPHER_MODE_CBC, 'EVP_bf_cbc()',
        CIPHER_MODE_CFB, 'EVP_bf_cfb()',
        CIPHER_MODE_OFB, 'EVP_bf_ofb()'
    );
    my $cipher_mode = $self->query_cipher_mode();
    $self->cipher_func($cipher_funcs{$cipher_mode});
    $self->cipher_needs_iv(1);

    # The Blowfish cipher can use any key length up to 72 bytes: see
    # blowfish.doc in old SSLeay distributions.
    $self->query_key_len(-min => 1, -max => 72, -default => 16);
}

sub configure_null_cipher {
    my $self = shift;

    $self->cipher_func('EVP_enc_null()');
    $self->cipher_needs_iv(0);

    # The null cipher does not require a key: it does nothing.
    $self->query_key_len(-fixed => 0);
}

sub configure_rc5_cipher {
    my $self = shift;

    my %cipher_funcs = (
        CIPHER_MODE_ECB, 'EVP_rc5_32_12_16_ecb()',
        CIPHER_MODE_CBC, 'EVP_rc5_32_12_16_cbc()',
        CIPHER_MODE_CFB, 'EVP_rc5_32_12_16_cfb()',
        CIPHER_MODE_OFB, 'EVP_rc5_32_12_16_ofb()'
    );
    my $cipher_mode = $self->query_cipher_mode();
    $self->cipher_func($cipher_funcs{$cipher_mode});
    $self->cipher_needs_iv(1);

    # The RC5 cipher can use any key length from 0 to 255 bytes: see RFC 2040.
    $self->query_key_len(-min => 0, -max => 255, -default => 16);

    # The RC5 cipher also has a parameter called "number of rounds".
    $self->query_rc5_rounds();
}

sub configure_cast5_cipher {
    my $self = shift;

    my %cipher_funcs = (
        CIPHER_MODE_ECB, 'EVP_cast5_ecb()',
        CIPHER_MODE_CBC, 'EVP_cast5_cbc()',
        CIPHER_MODE_CFB, 'EVP_cast5_cfb()',
        CIPHER_MODE_OFB, 'EVP_cast5_ofb()'
    );
    my $cipher_mode = $self->query_cipher_mode();
    $self->cipher_func($cipher_funcs{$cipher_mode});
    $self->cipher_needs_iv(1);

    # The CAST5 cipher can use any key length from 5 to 16 bytes: see RFC 2144.
    $self->query_key_len(-min => 5, -max => 16, -default => 16);
}

sub configure_aes_cipher {
    my $self = shift;

    my %cipher_funcs = (
        CIPHER_MODE_ECB, 'EVP_aes_ecb()',
        CIPHER_MODE_CBC, 'EVP_aes_cbc()',
        CIPHER_MODE_CFB, 'EVP_aes_cfb()',
        CIPHER_MODE_OFB, 'EVP_aes_ofb()'
    );
    my $cipher_mode = $self->query_cipher_mode();
    my $cipher_func = $cipher_funcs{$cipher_mode};

    # The AES cipher can only use a 16, 24 or 32 byte key: see FIPS PUB 197.  Do
    # not offer the choice of 24 or 32 byte keys for 0.9.7 because they do not
    # seem to work.  I do not know why, and the problem does not seem to occur
    # with debug OpenSSL builds, which does not make it very easy to find out
    # why.
    my $ver_num = $self->ver_num();
    if ($ver_num == 90700) {
        $self->query_key_len(-fixed => 16);
    }
    else {
        $self->query_key_len(-valid => [16, 24, 32], -default => 32);
    }

    my $key_len_bits = $self->key_len() * 8;
    $cipher_func =~ s/_aes_/_aes_${key_len_bits}_/;
    $self->cipher_func($cipher_func);
    $self->cipher_needs_iv(1);
}

sub write_cipher_config {
    my $self = shift;

    open my $cfg_fh, '>', CIPHER_CONFIG_FILENAME or
        $self->exit_with_error(130,
            "Could not open configuration file '%s' for writing: %s",
            CIPHER_CONFIG_FILENAME, $!
        );

    my $prefix_dir = $self->prefix_dir();
    my $ver_str    = $self->ver_str();

    print $cfg_fh <<"EOT";
/*============================================================================
 *
 * @{[CIPHER_CONFIG_FILENAME]}
 *
 * DESCRIPTION
 *   Cipher configuration file for Filter::Crypto modules.
 *
 *   DO NOT EDIT THIS FILE!
 *
 *   This file is written by Makefile.PL from its command-line option values
 *   and/or default values.  Any changes made here will be lost the next time
 *   Makefile.PL is run.
 *
 *   Created at @{[scalar localtime]} by Perl version $], installed as
 *   $^X
 *
 *   Configured against OpenSSL version $ver_str, installed under
 *   $prefix_dir
 *
 *============================================================================*/

EOT

    my $cipher_func = $self->cipher_func();
    print $cfg_fh "#define FILTER_CRYPTO_CIPHER_FUNC  $cipher_func\n";

    if ($self->cipher_needs_iv()) {
        print $cfg_fh "#define FILTER_CRYPTO_NEED_IV      1\n";
    }
    else {
        print $cfg_fh "#define FILTER_CRYPTO_NEED_IV      0\n";
    }

    my $key_len = $self->key_len();
    print $cfg_fh "#define FILTER_CRYPTO_KEY_LEN      $key_len\n";

    my $rc2_key_bits = $self->rc2_key_bits();
    my $rc5_rounds   = $self->rc5_rounds();
    if (defined $rc2_key_bits) {
        print $cfg_fh "#define FILTER_CRYPTO_RC2_KEY_BITS $rc2_key_bits\n";
    }
    elsif (defined $rc5_rounds) {
        print $cfg_fh "#define FILTER_CRYPTO_RC5_ROUNDS   $rc5_rounds\n";
    }

    my($def, $var);
    if ($key_len == 0) {
        $def = '#define FILTER_CRYPTO_USING_PBE    0';
        $var = 'static const unsigned char *filter_crypto_key = NULL;';
    }
    else {
        my $pswd = $self->pswd();
        if (defined $pswd) {
            $def = '#define FILTER_CRYPTO_USING_PBE    1';
            $pswd = $self->format_chars($pswd);
            $var = "static const unsigned char filter_crypto_pswd[] = {\n" .
                   "$pswd\n" .
                   "};";
        }
        else {
            $def = '#define FILTER_CRYPTO_USING_PBE    0';
            my $key = $self->key();
            $key = $self->format_chars($key);
            $var = "static const unsigned char filter_crypto_key[] = {\n" .
                   "$key\n" .
                   "};";
        }
    }
    print $cfg_fh "$def\n\n";
    print $cfg_fh "$var\n";

    print $cfg_fh <<'EOT';

/*============================================================================*/
EOT

    close $cfg_fh;

    print wrap('', '',
        "Your cipher configuration has been written to the file '" .
        CIPHER_CONFIG_FILENAME . "'.  You may want to keep this file in a " .
        "safe place if you ever need to rebuild these modules using the same " .
        "configuration, especially if your key was randomly generated."
    ), "\n\n";
}

sub format_chars {
    my $self = shift;
    my $chars = shift;

    $chars =~ s/(..)/0x$1, /g;
    $chars =~ s/^/    /o;
    $chars =~ s/, $//o;
    $chars =~ s/((?:0x.., ){8})/$1\n    /g;
    $chars =~ s/ \n/\n/go;
    $chars =~ s/\n    $//o;

    return $chars;
}

sub copy_cipher_config {
    my $self = shift;
    my $cipher_config_file = shift;

    if ($cipher_config_file ne CIPHER_CONFIG_FILENAME) {
        copy($cipher_config_file, CIPHER_CONFIG_FILENAME) or
            $self->exit_with_error(131,
                "Could not copy configuration file '%s' to '%s': %s",
                $cipher_config_file, CIPHER_CONFIG_FILENAME, $!
            );
    }

    print "\n";
}

}

__END__

#===============================================================================
# DOCUMENTATION
#===============================================================================

=head1 NAME

Makefile.PL - Generate makefiles for Filter-Crypto distribution

=head1 SYNOPSIS

    Makefile.PL [--defaults]
                [--prefix-dir=<dir>]
                [--cipher-config=<file>]
                [--cipher-name=<name>] [--cipher-mode=<mode>]
                [--pswd={<pswd>|rand} | --key={<key>|rand}] [--rng=<rng>]
                [--key-len=<len>]
                [--rc2-key-bits=<num>] [--rc5-rounds=<num>]
                [--install-script={y|n}>
                [--build=<component>] [--unsafe-mode] [--debug-mode]
                [--version] [--help] [--manpage]
                [<arg>...]

=head1 ARGUMENTS

Any standard ExtUtils::MakeMaker command-line arguments may be specified, but
note that the guts of this distribution is contained in two modules located in
their own sub-directories with their own B<Makefile.PL>s and not all
ExtUtils::MakeMaker arguments are necessarily passed through to such
sub-directory builds.

In particular, you should not rely on the INC and LIBS arguments for specifying
the location of the OpenSSL or SSLeay include and library directory paths.
Instead, use the B<--prefix-dir> option described below if the default value
does not match your system.

ExtUtils::MakeMaker arguments can also be given in the PERL_MM_OPTS environment
variable as usual.

=head1 OPTIONS

The build process for this distribution requires the answers to various
questions regarding (amongst other things) the location of OpenSSL or SSLeay,
which cipher algorithm to use, what password or key to use and whether to
install a script.

The command-line options detailed below can be used to provide the answers to
these questions.

If a particular question is not answered via the relevant command-line option
then B<Makefile.PL> will normally prompt the user for the answer.  However, if
it detects that it is not being run interactively and there is nothing on
C<STDIN>, or if either the PERL_MM_USE_DEFAULT environment variable is set to a
true value or the B<--defaults> option is specified, then the default value
indicated below in the description of the option concerned will be used instead
and no questions will be asked.

=over 4

=item B<--defaults>

Specify that the default value indicated below of each option that is not
specified by the relevant command-line option will be used instead of prompting
the user for a response.

=item B<-d E<lt>dirE<gt>>, B<--prefix-dir=E<lt>dirE<gt>>

Specify the OpenSSL or SSLeay prefix directory.  This is used to determine the
include and library directories.

By default, B<Makefile.PL> will look for an B<openssl> or B<ssleay> binary
executable and determine the prefix directory from that.  Failing that, the
default prefix directory as specified in the latest OpenSSL's own F<INSTALL>
file will be assumed, namely F</usr/local/ssl>, or F<C:\openssl> on "native"
(i.e. non-Cygwin) Windows platforms.

=item B<-c E<lt>fileE<gt>>, B<--cipher-config=E<lt>fileE<gt>>

Specify the cipher configuration file with which to build.  This should be a
file written by a previous run of B<Makefile.PL> containing the answers to all
the cipher configuration questions, which therefore will not be asked this time.
Any cipher configuration options specified along with this option will be
ignored.

This is useful if you ever need to rebuild this distribution using the same
configuration as was used on a previous occasion, for example, if you are
setting up two separate Perl installations, one containing the
Filter::Crypto::CryptFile module and another containing only the
Filter::Crypto::Decrypt module, as described under the B<--build> option above.

=item B<-n E<lt>nameE<gt>>, B<--cipher-name=E<lt>nameE<gt>>

Specify the name of the cipher algorithm to use.  The ciphers available will be
a subset of the following (depending on which version of OpenSSL or SSLeay you
are using and whether any of them were disabled when it was built):

    DES      (A block cipher with fixed key length)
    DES_EDE  (A block cipher with fixed key length)
    DES_EDE3 (A block cipher with fixed key length)
    RC4      (A stream cipher with variable key length)
    IDEA     (A block cipher with fixed key length)
    RC2      (A block cipher with variable key length)
    DESX     (A block cipher with fixed key length)
    Blowfish (A block cipher with variable key length)
    Null     (The null cipher with zero key length)
    RC5      (A block cipher with variable key length)
    CAST5    (A block cipher with variable key length)
    AES      (A block cipher with variable key length)

The default cipher is AES if it is available, or else DES_EDE3 if that is
available, or else whichever one nearest the end of the list above is available.

=item B<-m E<lt>modeE<gt>>, B<--cipher-mode=E<lt>modeE<gt>>

Specify the mode of operation if a block cipher was chosen above.  The following
modes are available:

    ECB (Electronic Codebook Mode)
    CBC (Cipher Block Chaining Mode)
    CFB (64-Bit Cipher Feedback Mode)
    OFB (64-Bit Output Feedback Mode)

The CBC mode is used by default.

This option is ignored for the DESX block cipher (which is only available in CBC
mode) and for the stream cipher(s) and the null cipher.

=item B<-p {E<lt>pswdE<gt>|rand}>, B<--pswd={E<lt>pswdE<gt>|rand}>

Specify the password from which to derive the key used for the encryption or
decryption.  (This is known as "password-based encryption" (PBE).)  The special
value "rand" means that a 32-byte password will be randomly generated using the
random number generator specified by the B<--rng> option.

The key will be derived using the PBKDF2 algorithm defined in PKCS#5 v2.0 (which
is also available as RFC2898).  An 8-byte random salt and 2048 iterations are
used.  A random initialization vector (IV) is also generated if required.  When
encrypting, both the salt and IV are prepended to the ciphertext so that they
may be recovered for use when decrypting.

Alternatively, the key may be specified directly (or randomly generated) using
the B<--key> option below.  If both options are given then B<--pswd> is used and
B<--key> is silently ignored.

Note that password-based encryption is preferable to using a fixed key if you
are going to be encrypting many files because the key used in the PBE scheme
will be different for each file that you encrypt because it is derived afresh
for each file using a new random salt.  (This, of course, is exactly the point
of the salt.)  Using the same key repeatedly is vulnerable to "dictionary
attacks", particularly if part of the files being encrypted is known or
predictable, for example, a header section like that used at the top of the
source files in this distribution.

A randomly generated password is used by default.

=item B<-k {E<lt>keyE<gt>|rand}>, B<--key={E<lt>keyE<gt>|rand}>

Specify the key if anything other than the null cipher was chosen above.  The
special value "rand" means that a key of the appropriate length will be randomly
generated using the random number generator specified by the B<--rng> option.

If a key length is also specified using the B<--key-len> option below, or if you
have chosen a fixed key length cipher, then the length of any key specified here
must match the relevant key length.

An N-byte key must be specified as a string of 2*N hexadecimal digits where each
pair of such digits represents one byte of the key (with the high nybble first).
This is the format produced by Perl's built-in C<unpack()> function with the 'H'
template character, i.e.

    $hexdigits = unpack 'H*', $bytes;

The key specified (or randomly generated) by this option is used directly
without being processed by any key derivation algorithm.  For password-based
encryption, use the B<--pswd> option above.  If both options are given then
B<--pswd> is used and B<--key> is silently ignored.

Note that password-based encryption is preferable to using a fixed key if you
are going to be encrypting many files.  See the description of the B<--pswd>
option above for an explanation.

A randomly generated password [sic] is used by default.

=item B<-r E<lt>rngE<gt>>, B<--rng=E<lt>rngE<gt>>

Specify the random number generator (RNG) with which to generate the password or
key if the option to have one of them randomly generated was chosen above.
Valid RNGs are:

    Perl          - Use Perl's built-in rand() function
    Crypt::Random - Use the Crypt::Random Perl module
    Math::Random  - Use the Math::Random Perl module
    OpenSSL       - Use OpenSSL's "rand" command

Note that not all of these options may be available:  Crypt::Random and
Math::Random are not standard Perl modules.

The default RNG is whichever one nearest the end of the list above is available.

This option is silently ignored if a randomly generated password or key was not
chosen.

=item B<-l E<lt>lenE<gt>>, B<--key-len=E<lt>lenE<gt>>

Specify the key length (in bytes) if a variable key length cipher was chosen
above.  Valid key lengths are as follows:

    RC4      - From 1 byte upwards
    RC2      - From 1 byte up to 128 bytes
    Blowfish - From 1 byte up to 72 bytes
    RC5      - From 0 bytes up to 255 bytes
    CAST5    - From 5 bytes up to 16 bytes
    AES      - Either 16, 24 or 32 bytes

The default key length is 16 bytes for each cipher except AES, which defaults to
32 bytes, unless a key is specified using the B<--key> option above in which
case the key length is inferred from that.

The key length of the fixed key length ciphers, of course, cannot be changed
using this or any other option, whatever version of OpenSSL or SSLeay you have,
but here are the key lengths used by those ciphers for reference purposes when
manually creating the key itself if you choose to do so:

    DES      - 8 bytes
    DES_EDE  - 16 bytes
    DES_EDE3 - 24 bytes
    IDEA     - 16 bytes
    DESX     - 24 bytes
    Null     - 0 bytes

=item B<--rc2-key-bits=E<lt>numE<gt>>

Specify the effective key bits value (in bits) if the RC2 cipher was chosen
above.  Valid values are from 1 bit up to 1024 bits.

The default value is 128 bits.

This option is silently ignored if the RC2 cipher was not chosen.

=item B<--rc5-rounds=E<lt>numE<gt>>

Specify the number of rounds if the RC5 cipher was chosen above.  Valid values
are 8, 12 and 16.

The default value is 12 rounds.

This option is silently ignored if the RC5 cipher was not chosen.

=item B<-i {y|n}>, B<--install-script={y|n}>

Specify whether or not to install the B<crypt_file> script.

The script is installed by default unless the B<--build> option is set to
"Decrypt" (in which case the Filter::Crypto::CryptFile module, which the
B<crypt_file> script uses, does not get built so there would be no point in
installing the script).

=item B<-b E<lt>componentE<gt>>, B<--build=E<lt>componentE<gt>>

Specify which component ("CryptFile", "Decrypt" or "both") to build.  This
determines which of the two C extension modules (Filter::Crypto::CryptFile,
Filter::Crypto::Decrypt or both) is built.

By default, both components are built.

However, building only one component may be useful if you want to maintain two
separate Perl installations: one containing the Filter::Crypto::CryptFile module
to be used for encrypting your Perl files, and another containing only the
Filter::Crypto::Decrypt module for distributing with your encrypted Perl files
so that they can be run but not easily decrypted.  (Well, not I<very> easily,
anyway.  Please see the L<Filter::Crypto/"WARNING"> regarding the level of
security provided for your source code by this software.)

If you are going to set-up two such Perl installations then clearly you will
need to ensure that the components of this distribution installed into each one
were built with the same cipher configuration options, otherwise the files
encrypted by one cannot be decrypted by the other.  The B<--cipher-config>
option below may assist in this.

=item B<-u>, B<--unsafe-mode>

Specify that the "Decrypt" component should be built in an "unsafe" mode in
which the Perl compiler backend modules are allowed to be loaded.

By default, the "Decrypt" component contains a check to try to disallow running
under the Perl compiler backend, which works by simply checking whether any of
the relevant modules have been loaded.

Unfortunately, that logic can be unhelpful in certain cases where those modules
are quite legitimately loaded.  One example is when code is running in a
mod_perl environment with the Apache::Status module loaded.  Another example is
when a script that uses an encrypted module is being packaged with PAR: the PAR
packager will not pick up any dependencies that the encrypted module has unless
it compiles or executes the module (via B<pp>'s B<-c> or B<-x> options), and the
Perl compiler backend modules are also loaded during that process.

Note that the existence of this B<--unsafe-mode> option should not be taken to
imply that omitting it produces a decryption environment that is entirely
"safe".  Even without the B<--unsafe-mode> option it will still be possible for
some hackers to make use of the Perl compiler backend modules, and there are
also other security issues anyway.  Please see the L<Filter::Crypto/"WARNING">
for more details.

=item B<--debug-mode>

Specify that the modules should be built in "debug" mode.  In this mode, all of
the checks described in the L<Filter::Crypto/"WARNING"> are disabled and lots of
output is written to C<STDERR> describing what is going on during the encryption
or decryption.

By default, the modules are not built in "debug" mode.

=item B<-v>, B<--version>

Display the script name and version, and then exit.

=item B<-h>, B<--help> | B<--?>

Display a help page listing the arguments and options, and then exit.

=item B<--manpage> | B<--doc>

Display the entire manual page, and then exit.

=back

Options may be introduced with a double dash, a single dash, a plus sign or
(on Win32) a forward slash; case does not matter; an equals sign may be used or
omitted between option names and values; long option names may be abbreviated to
uniqueness.

Options may also be placed between non-option arguments, and option processing
may be stopped at any point in the command-line by inserting a double dash.

=head1 EXIT STATUS

    0   The script exited normally.

    1   The script exited after printing the version, help or manpage.

    2   Invalid command-line arguments.

    >2  An error occurred.

=head1 DIAGNOSTICS

=head2 Warnings and Error Messages

This script may produce the following diagnostic messages.  They are classified
as follows (a la L<perldiag>):

    (W) A warning (optional).
    (F) A fatal error (trappable).
    (I) An internal error that you should never see (trappable).

=over 4

=item Can't load %s module for random number generation

(F) The specified module could not be loaded and therefore could not be used
as the random number generator (RNG).  Make sure that the module concerned is
properly installed or use one of the other RNGs instead.

=item Could not copy configuration file '%s' to '%s': %s

(F) The specified configuration file (i.e. the file given by the
B<--cipher-config> option) could not be copied to the specified location (from
which it is included in this distribution's build process).  The system error
message corresponding to the standard C library C<errno> variable is also given.

=item Could not generate %d random bytes (%d): %s

(F) The specified number of random bytes (to be used as the password or key)
could not be generated using the OpenSSL binary executable.  The exit code and
the output from the program are also given.

=item Could not get OpenSSL version information (%d): %s

(F) The OpenSSL version information could not be got from the binary executable.
The exit code and the output from the program are also given.

=item Could not open configuration file '%s' for writing: %s

(F) The specified configuration file could not be opened to write the chosen
cipher configuration options to.  The system error message corresponding to the
standard C library C<errno> variable is also given.

=item Could not open random bytes output file '%s' for reading: %s

(F) The specified file containing the random bytes generated by the OpenSSL
binary executable for use as the password or key could not be opened for
reading.  The system error message corresponding to the standard C library
C<errno> variable is also given.

=item Could not open version number header file '%s' for reading: %s

(F) The specified OpenSSL or SSLeay header file containing the package's version
number could not be opened for reading.  The system error message corresponding
to the standard C library C<errno> variable is also given.

=item Could not read random bytes from output file '%s': %s

(F) The random bytes generated by the OpenSSL binary executable for use as the
password or key could not be read from the specified file.  The system error
message corresponding to the standard C library C<errno> variable is also given.

=item Could not read random bytes from output file '%s': %d bytes read, %d bytes
expected

(F) The string of random bytes generated by the OpenSSL binary executable for
use as the password or key and read from the specified file was not of the
expected length.

=item Invalid 'build' option value '%s'

(F) The specified build option value (i.e. the value given by the B<--build>
option) is not valid.

=item Invalid default response '%s'

(I) The method called internally to prompt the user for some input was passed a
default response that was not valid itself.

=item Invalid 'install_script' option value '%s'

(I) The method called internally to determine whether to install the
B<crypt_file> script was passed an option value that it did not recognize.

=item Invalid key '%s'

(F) The specified key (i.e. the key given by the B<--key> option) is not valid.

=item Invalid key length '%d'

(F) The specified key length (i.e. the length given by the B<--key-length>
option) is not valid.

=item Invalid length key (%d)

(F) The inferred key length (i.e. the length inferred from the key given by the
B<--key> option) is not valid.

=item Invalid password '%s'

(F) The specified password (i.e. the password given by the B<--pswd> option) is
not valid.

=item Invalid random number generator '%s'

(F) The specified random number generator (i.e. the value given by the B<--rng>
option) is not valid.

=item Invalid RC2 key bits '%d'

(F) The specified RC2 key bits value (i.e. the value given by the
B<--rc2-key-bits> option) is not valid.

=item Invalid RC5 rounds '%d'

(F) The specified RC5 rounds value (i.e. the value given by the B<--rc5-rounds>
option) is not valid.

=item Invalid response

(W) The response supplied by the user to an interactive prompt was not valid.
The user will be prompted again until a valid response is supplied.

=item No OpenSSL binary executable found

(F) The main OpenSSL binary executable could not be located.  Ensure that there
is a full installation of OpenSSL in the location specified by the prefix
directory.

=item No OpenSSL crypto library found

(F) The OpenSSL "crypto" library could not be located.  Ensure that there is a
full installation of OpenSSL in the location specified by the prefix directory.

=item No OpenSSL/SSLeay include directory found

(F) The OpenSSL or SSLeay include directory could not be located.  Ensure that
there is a full installation of OpenSSL in the location specified by the prefix
directory.

=item No such cipher mode '%s'

(F) The specified cipher mode (i.e. the mode given by the B<--cipher-mode>
option) is not recognized.

=item No such cipher name '%s'

(F) The specified cipher name (i.e. the name given by the B<--cipher-name>
option) is not recognized.

=item No such configuration file '%s'

(F) The specified configuration file (i.e. the file given by the
B<--cipher-config> option) does not exist.

=item No such directory

(W) The response supplied by the user to an interactive prompt for a directory
was not a valid directory.  The user will be prompted again until a valid
directory is supplied.

=item No such prefix directory '%s'

(F) The specified prefix directory (i.e. the directory given by the
B<--prefix-dir> option) does not exist.

=item No OpenSSL/SSLeay version number found

(F) The OpenSSL or SSLeay package's version number could not be found in the
relevant header file.

=item No OpenSSL/SSLeay version number header file found

(F) The OpenSSL or SSLeay header file containing the package's version number
could not be located.  Ensure that there is a full installation of OpenSSL in
the location specified by the prefix directory.

=item Options in list are not unique

(I) The method called internally to prompt the user for a choice from a list of
supposedly unique options was passed a list of options that were not all unique.

=item OS unsupported: No OpenSSL/SSLeay directory found

(F) The OpenSSL or SSLeay prefix directory could not be located.  This error is
only produced when running non-interactively.  (In interactive mode the user
will be prompted for the prefix directory if it was not given by the
B<--prefix-dir> option.)

=item OS unsupported: OpenSSL version 0.9.6k or 0.9.7c or higher required. This is only %s version %s

(F) You do not have a sufficiently recent version of OpenSSL (namely, 0.9.6N
where N is k or higher, or 0.9.7N where N is c or higher, or 0.9.8 or higher).

=item OS unsupported: The "Decrypt" component requires a "release" mode build of
perl (i.e. one built without DEBUGGING)

(F) The perl being used was built in "debug" mode, which is not supported by the
"Decrypt" component unless specifically enabled with the B<--debug-mode>
command-line option.

=item Unknown key source '%s'

(I) The method called internally to prompt the user for a choice of how to
specify the cipher key returned an unknown value.

=item Unknown random number generator '%s'

(I) The method called internally to prompt the user for a choice random number
generator returned an unknown value.

=item Unrecognized OpenSSL/SSLeay version number found (%s)

(F) The OpenSSL or SSLeay package's version number, read from the relevant
header file, is not in a format that is recognized.

=item Warning: Ignoring Cygwin OpenSSL binary '%s' on Win32

(W) The main OpenSSL binary executable found in the PATH when trying to locate
the OpenSSL to use turned out to be a Cygwin binary, which is of no use with the
Win32 perl that is being used and will therefore be ignored.

=back

=head1 EXAMPLES

=over 4

=item [UNIX] You have installed OpenSSL in F</usr/local>

Type

    perl Makefile.PL -d /usr/local

The OpenSSL include and library directories F</usr/local/include> and
F</usr/local/lib> respectively will be used.  The user will be prompted for the
answers to other configuration questions.

=item [Win32] You have built OpenSSL in F<C:\Temp\openssl-0.9.7e>

Type

    perl Makefile.PL -d C:\Temp\openssl-0.9.7e

The OpenSSL include and library directories F<C:\Temp\openssl-0.9.7e\inc32> and
F<C:\Temp\openssl-0.9.7e\out32dll> respectively will be used: these are detected
automatically in the absence of F<include\> and F<lib\> sub-directories on
"native" Windows platforms.  The user will be prompted for the answers to other
configuration questions.

=item You want to run B<Makefile.PL> non-interactively

If you are happy with the default values of each option then just type

    perl Makefile.PL --defaults

If you want to override the default value of one or more options but accept the
default values for the rest then you can do so, e.g.

    perl Makefile.PL --defaults -n DES

This will use the DES cipher instead of the default AES (or DES_EDE3) cipher,
but is otherwise a default configuration with no questions asked.

Note that this style of accepting all default values except for specifically
overridden ones applies equally well to the prefix directory option, so creating
a default configuration with a non-standard OpenSSL installation location can be
easily handled, e.g.

    perl Makefile.PL --defaults -d /usr/local

Alternatively, you can explicitly provide values for every option that would
otherwise cause an interactive prompt to be given, e.g.

    perl Makefile.PL -b both -n AES -m CBC -l 32 -p rand -r openssl -i y

This will use the AES cipher in CBC mode with a 32-byte key derived from a
password randomly generated by B<openssl>; the B<crypt_file> script will be
installed.  If the OpenSSL or SSLeay prefix directory is not in one of the
locations in which it can be found automatically by B<Makefile.PL> then use the
B<-d> option as shown in the previous examples too.

=back

=head1 ENVIRONMENT

Any standard ExtUtils::MakeMaker environment variables may be used, namely:

=over 4

=item PERL_MM_OPT

Specify ExtUtils::MakeMaker command-line arguments to be prepended to the list
of command-line arguments before its argument processing takes place. 

Note that as far as quoting and escaping is concerned, the environment variable
value is not interpreted in the same way as the Bourne shell would interpret the
corresponding command-line.  Instead, it is simply split on whitespace before
being processed.

Also, bear in mind the caveat regarding the use of ExtUtils::MakeMaker command-
line arguments under L<"ARGUMENTS"> above.

=item PERL_MM_USE_DEFAULT

If set to a true value then the default value (indicated under L<"OPTIONS">
above) of each option that is not specified on the command-line will be used
instead of prompting the user for a response.

=back

=head1 SEE ALSO

The F<INSTALL> file;

L<ExtUtils::MakeMaker>.

=head1 ACKNOWLEDGEMENTS

The C<MY::test()> override method is based on code taken from that in the
top-level B<Makefile.PL> script in the Tk distribution (version 804.032),
written by Nick Ing-Simmons.

The C<can_run()> method in the Filter::Crypto::_ConfigureBuild class is based on
code taken from the C<can_run()> method in the standard library module IPC::Cmd
(version 0.92), written by Jos Boumans and currently maintained by Chris
Williams.

The C<use_default_response()> and C<isa_tty()> methods in the
Filter::Crypto::_ConfigureBuild class are based on code taken from the
C<prompt()> function in the standard library module ExtUtils::MakeMaker (version
6.92), written by Andy Dougherty, Andreas Koenig and Tim Bunce, and currently
maintained by Michael G Schwern.

=head1 AUTHOR

Steve Hay E<lt>L<shay@cpan.org|mailto:shay@cpan.org>E<gt>.

=head1 COPYRIGHT

Copyright (C) 2004-2009, 2012, 2014, 2015, 2017, 2020 Steve Hay.  All rights reserved.

=head1 LICENCE

This script is free software; you can redistribute it and/or modify it under the
same terms as Perl itself, i.e. under the terms of either the GNU General Public
License or the Artistic License, as specified in the F<LICENCE> file.

=head1 VERSION

Version 2.10

=head1 DATE

08 Dec 2020

=head1 HISTORY

See the F<Changes> file.

=cut

#===============================================================================
