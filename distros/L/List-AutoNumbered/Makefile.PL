use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;
use Config;

my $VERSION_FROM = File::Spec->catfile(qw(lib List AutoNumbered.pm));
my $IS_TRIAL = check_trial();
my $secure_perl_path = get_perl_filename();
my @provides = ();

# Check if this is a TRIAL version {{{1
sub check_trial {
    TRIAL: {
        # Get the VERSION line
        open my $fd, '<', $VERSION_FROM or last TRIAL;
        my $linetext;
        while(<$fd>) {
            next unless /VERSION/;
            $linetext = $_;
            last;
        }
        close $fd;
        return !!($linetext =~ /\bTRIAL\b/);
    }
    return 0;
} #check_trial()

# }}}1
# Module metadata {{{1
eval {
    require Module::Metadata;
    @provides =
        (provides => Module::Metadata->provides(version => '2', dir => 'lib'));
        # Thanks to https://stackoverflow.com/a/28928985/2877364 by LEONT
        # for suggesting Module::Metadata.
};

# }}}1
# Get the filename of the Perl interpreter running this. {{{1
# Modified from perlvar.
# The -x test is for cygwin or other systems where $Config{perlpath} has no
# extension and $Config{_exe} is nonempty.  E.g., symlink perl->perl5.10.1.exe.
# There is no "perl.exe" on such a system.
sub get_perl_filename {
    my $secure_perl_path = $Config{perlpath};
    if ($^O ne 'VMS') {
        $secure_perl_path .= $Config{_exe}
            unless (-x $secure_perl_path) ||
                            ($secure_perl_path =~ m/$Config{_exe}$/i);
    }
    return $secure_perl_path;
} # get_perl_filename()

# }}}1
# Makefile customization (MY) {{{1
{   package MY;

    # dist_core: make `dist` a :: target rather than a : target,
    # and add distcheck before dist.  Also, add -TRIAL to the tgz if necessary.
    sub dist_core {
        my $self = shift;
        my $text = $self->SUPER::dist_core(@_);
        $text =~ s/^dist\s*:[^:]/dist:: distcheck /m;

        # Add -TRIAL if it's a trial release
        if($IS_TRIAL) {
            # Note: we don't have to worry about EOL; Appveyor uses gmake even
            # on Windows, and it only uses \n.
            print STDERR "TRIAL version\n";
            my $newtext .=  # Command to rename the tgz.  TODO see if this works on Windows.
                "\t\"$secure_perl_path\" -MExtUtils::Command -e mv -- " .
                '"$(DISTVNAME).tar$(SUFFIX)" ' .
                '"$(DISTVNAME)-TRIAL.tar$(SUFFIX)"' . "\n";

            # Insert $newtext at the end of the `dist` target
            $text =~ s{
                ^(dist\h*:.*\n      # dist header line
                    (?:\h+\S.*\n)+) # dist body lines.  `.` doesn't match `\n`.
                                    # NOTE: on Appveyor, the continuation line
                                    # begins with a space rather than a tab.
                                    # Therefore, look for \h after \n.
                                    # Not \s, because that matches a \n!
            }{$1$newtext}mx;
        } #endif $IS_TRIAL

        return $text;
    } # MY::dist_core

    # Generate README.md; add uninstall target and other test targets
    sub postamble {     # TODO also handle Windows nmake syntax (SET vs. export)

        # Note: pod2markdown is marked with a hyphen so that `make` can
        # succeed and generate META files even if Pod::Markdown is not yet
        # installed.

        my $make_readme_md = File::Spec->catfile(qw(support readme.pl));
        return <<EOT;
authortest:
\tRELEASE_TESTING=1 prove -lvj4 xt

testhere:   # Run the tests from lib rather than blib
\tprove -lj4

README.md: @{[$VERSION_FROM]} Makefile.PL $make_readme_md
\t-"$secure_perl_path" "$make_readme_md" -i "\$<" -o "\$@" -f md --appveyor cxw42/list-autonumbered

README: @{[$VERSION_FROM]} Makefile.PL $make_readme_md
\t-"$secure_perl_path" "$make_readme_md" -i "\$<" -o "\$@" -f text --appveyor cxw42/list-autonumbered

all :: README.md README
dist :: README.md README

# Uninstallation: mimic what the normal "uninstall" target does, but actually
# carry out the actions.
# Note: this may leave empty directories in place, since the packlist only
# includes files.

ACTUALLY_UNINSTALL = "$secure_perl_path" -MExtUtils::Install -e 'uninstall(shift,1)' --

actually_uninstall :: actually_uninstall_from_\$(INSTALLDIRS)dirs
\t\$(NOECHO) \$(NOOP)

actually_uninstall_from_perldirs ::
\t-\$(ACTUALLY_UNINSTALL) "\$(PERL_ARCHLIB)/auto/\$(FULLEXT)/.packlist"

actually_uninstall_from_sitedirs ::
\t-\$(ACTUALLY_UNINSTALL) "\$(SITEARCHEXP)/auto/\$(FULLEXT)/.packlist"

actually_uninstall_from_vendordirs ::
\t-\$(ACTUALLY_UNINSTALL) "\$(VENDORARCHEXP)/auto/\$(FULLEXT)/.packlist"

EOT

    } #postamble()
} #package MY

# }}}1

# Main options for EUMM
my %opts = (
    NAME             => 'List::AutoNumbered',
    AUTHOR           => q{Christopher White <cxwembedded@gmail.com>},
    VERSION_FROM     => $VERSION_FROM,
    ABSTRACT_FROM    => $VERSION_FROM,
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'Config' => '0',
        'ExtUtils::MakeMaker' => '0',
        'File::Spec' => '0',
    },
    TEST_REQUIRES => {
        'Data::Dumper' => '0',  # to give us a random blessed reference
        'lib::relative' => '0.002',
        'Import::Into' => '0',
        'Test::Fatal' => '0',
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Getargs::Mixed' => '1.06', # Supports perl 5.6
        'Exporter' => '0',
        'parent' => '0',
        'Scalar::Util' => '1.50',
        'strict' => '0',
        'warnings' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'List-AutoNumbered-*' },

    META_MERGE => {
        'meta-spec' => { version => 2 },

        resources => {
            bugtracker => {
                web  => 'https://github.com/cxw42/List-AutoNumbered/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/cxw42/List-AutoNumbered.git',
                web  => 'https://github.com/cxw42/List-AutoNumbered',
            },
        },

        prereqs => {
            develop => {
                requires => {
                    'App::RewriteVersion' => '0',   # for perl-bump-version
                    'Module::Metadata' => '1.000016',
                    'Path::Class' => '0',           # for support/readme.pl
                },
            },
        },

        # The gymnastics in this file are primarily for developer
        # convenience.  The actual dist, if processed by an installer
        # new enough to support x_static_install, doesn't need any of
        # the above processing for a plain installation.  Therefore,
        # x_static_install is OK.  For more, see
        # http://blogs.perl.org/users/shoichi_kaji1/2017/03/make-your-cpan-module-static-installable.html
        "x_static_install" => "1",

        @provides,

    }, #META_MERGE
);

$opts{META_MERGE}->{release_status} = 'testing' if $IS_TRIAL;

# Some tests run on older versions of EUMM that do not support TEST_REQUIRES.
# http://www.cpantesters.org/cpan/report/f445404a-56b8-11e9-bab0-5e087347484a
# is one example.  This is a workaround, modified from
# https://metacpan.org/source/RJBS/JSON-Typist-0.005/Makefile.PL ,
# linked from http://blogs.perl.org/users/neilb/2017/05/specifying-dependencies-for-your-cpan-distribution.html .
# If we are on a version of EUMM that doesn't support TEST_REQUIRES,
# move those dependencies to PREREQ_PM.
unless( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
    $opts{PREREQ_PM}->{$_} = $opts{TEST_REQUIRES}->{$_}
        foreach keys %{$opts{TEST_REQUIRES}};
    delete $opts{TEST_REQUIRES};
}

WriteMakefile(%opts);
# vi: set fdm=marker: #
