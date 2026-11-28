use strict;
use warnings;
use 5.016;

use ExtUtils::MakeMaker;

# smtpd(8) looks up relative proc-exec paths in /usr/local/libexec/smtpd,
# install the filter there.  With PREFIX (e.g. OpenBSD ports) use
# $(PREFIX)/libexec/smtpd instead; leave the defaults alone if the user chose
# an installation tree (INSTALL_BASE, e.g. via local::lib).
# INSTALL*SCRIPT given on the command line or in PERL_MM_OPT still win over
# these, and OpenBSD ports set INSTALLSCRIPT there for every perl port.
my $SMTPD_LIBEXEC = '/usr/local/libexec/smtpd';
my @user_opts = ( @ARGV, split ' ', $ENV{PERL_MM_OPT} // '' );
my %script_dir;
unless ( grep { /^INSTALL_BASE=/ } @user_opts ) {
    my $dir = ( grep { /^PREFIX=/ } @user_opts )
        ? '$(PREFIX)/libexec/smtpd'
        : $SMTPD_LIBEXEC;
    %script_dir = map { $_ => $dir }
        qw( INSTALLSCRIPT INSTALLSITESCRIPT INSTALLVENDORSCRIPT );
}

WriteMakefile(
    NAME             => 'Mail::MIMEDefang::OpenSMTPD',
    AUTHOR           => 'The McGrail Foundation',
    VERSION_FROM     => 'lib/Mail/MIMEDefang/OpenSMTPD.pm',
    ABSTRACT_FROM    => 'lib/Mail/MIMEDefang/OpenSMTPD.pm',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.016',
    EXE_FILES        => ['filter-mimedefang.pl'],
    %script_dir,
    MAN1PODS => {
        'filter-mimedefang.pl' => '$(INST_MAN1DIR)/filter-mimedefang.pl.$(MAN1EXT)',
    },
    # list the module explicitly, so nothing else at the top level is
    # picked up as a library file
    PM => {
        'lib/Mail/MIMEDefang/OpenSMTPD.pm' => '$(INST_LIB)/Mail/MIMEDefang/OpenSMTPD.pm',
    },
    MAN3PODS => {
        'lib/Mail/MIMEDefang/OpenSMTPD.pm' => '$(INST_MAN3DIR)/Mail::MIMEDefang::OpenSMTPD.$(MAN3EXT)',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    PREREQ_PM => {
        'Carp'              => 0,
        'Exporter'          => 0,
        'File::Path'        => 0,
        'Getopt::Std'       => 0,
        'IO::Select'        => 0,
        'IO::Socket::UNIX'  => 0,
        'Mail::MIMEDefang'  => 'v3.7.1',
        'Mail::MIMEDefang::Utils' => 0,
        'OpenSMTPd::Filter' => 0,
        'Socket'            => 0,
    },
    TEST_REQUIRES => {
        'File::Copy' => 0,
        'File::Temp' => 0,
        'IPC::Open3' => 0,
        'Symbol'     => 0,
        'Test::More' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/The-McGrail-Foundation/MIMEDefang-smtpd-filter.git',
                web  => 'https://github.com/The-McGrail-Foundation/MIMEDefang-smtpd-filter',
            },
            bugtracker => {
                web => 'https://github.com/The-McGrail-Foundation/MIMEDefang-smtpd-filter/issues',
            },
        },
    },
    test => { TESTS => 't/*.t' },
);
