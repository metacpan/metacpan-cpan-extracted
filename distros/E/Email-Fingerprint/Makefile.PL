require 5.008002;

use strict;
use warnings;
use ExtUtils::MakeMaker;

# Automated tools don't handle this dependency automatically, because
# it's part of perl-core--yet some broken systems are actually missing
# them!
for my $module (qw/
    Carp
    Fcntl
    FileHandle
    AnyDBM_File
/) {
    eval "use $module";
    gripe($module) if $@;
}


# Make sure there's at least ONE backend for AnyDBM_File to invoke. This
# is a little paranoid, but distributions are ripping core modules out of
# Perl. We might as well make sure they didn't butcher it into uselessness.
my $found = 0;
for my $module (qw/ NDBM_File DB_File GDBM_File SDBM_File ODBM_File / )
{
    eval "use $module";
    $found++ unless $@;
}
gripe("SDBM_File") unless $found; # This is the likeliest not to be missing.


WriteMakefile(
    NAME                => 'Email::Fingerprint',
    AUTHOR              => 'Len Budney <lbudney@pobox.com>',
    VERSION_FROM        => 'lib/Email/Fingerprint.pm',
    ABSTRACT_FROM       => 'lib/Email/Fingerprint.pm',
    LICENSE             => 'perl',
    INST_SCRIPT         => 'blib/bin',
    EXE_FILES           => [ 'bin/eliminate-dups' ],
    NO_META             => 1,
    MIN_PERL_VERSION    => '5.008001',
    PREREQ_PM => {
        'Carp'              => 0,
        'Class::Std'        => 0,
        'Fcntl'             => 0,
        'File::Path'        => 2.08,
        'File::Slurp'       => 0.01,
        'File::Spec'        => 0.82,
        'FileHandle'        => 0,
        'FindBin'           => 0,
        'List::MoreUtils'   => 0.04,  # i.e., any version
        'LockFile::Simple'  => 0.2,   # 0.1@0 works but has bad version
        'Mail::Header'      => 1.40,
        'AnyDBM_File'       => 1.00,  # i.e., any version
        'Scalar::Util'      => 0,
        'Test::Exception'   => 0.07,
        'Test::More'        => 0,
        'Test::Warn'        => 0.09,
        'overload'          => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Email-Fingerprint-* Debian_CPANTS.txt' },
);

{
    package MY;
    sub postamble {
        return <<"EOF";
authortest: test
\t\$(MAKE) -e \$(TEST_TYPE) TEST_FILES="xt/*.t"

EOF
    }
    
    sub dist_test {
        my $self      = shift;
        my $inherited =  $self->SUPER::dist_test(@_);
        $inherited    =~ s/ test / authortest /;
        return $inherited;
    }
}

sub gripe
{
    my $module = shift;

    die <<"EOF";

    ****************************************************************
    I am unable to load the core module "$module". You must install
    $module and then try installing Email::Fingerprint again.  Your
    Perl installation should have included these modules, so if
    they're missing it suggests:

    1) Something might be very wrong, or
    2) You might be using too old a Perl version, or
    3) Your Perl package was intentionally crippled[*]

    [*] RedHat and derivatives, I'm talking about YOU.

    Sorry for any inconvenience!
    ****************************************************************

EOF
}

1;
