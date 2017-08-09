# Copyright (c) 2006-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use ExtUtils::MakeMaker;

my $EMV = $ExtUtils::MakeMaker::VERSION;
my $STATUS = 'stable';          # unstable|testing|stable

WriteMakefile(
    NAME                 => 'Math::Logic::Ternary',
    VERSION_FROM         => 'lib/Math/Logic/Ternary.pm',
    PREREQ_PM            => {
        'Math::BigInt' => '1.78',
        'Role::Basic'  => 0,
    },
    ABSTRACT_FROM        => 'lib/Math/Logic/Ternary.pm',
    AUTHOR               => 'Martin Becker <becker-cpan-mp@cozap.com>',
    EXE_FILES            => [ qw(bin/tcalc) ],
    $EMV >= 6.18? (
        SIGN             => 1,
    ): (),
    $EMV >= 6.31? (
        LICENSE          => 'perl_5',
    ): (),
    $EMV >= 6.46? (
        META_MERGE       => {
            'meta-spec' => { version => 2 },
            prereqs => {
                runtime => {
                    recommends => {
                        'Math::ModInt' => 0,
                        'Term::ReadLine' => 0,
                    },
                },
            },
            provides => {
                'Math::Logic::Ternary' => {
                    file    => 'lib/Math/Logic/Ternary.pm',
                    version => '0.004',
                },
                'Math::Logic::Ternary::Calculator' => {
                    file    => 'lib/Math/Logic/Ternary/Calculator.pm',
                    version => '0.004',
                },
                'Math::Logic::Ternary::Calculator::Command' => {
                    file    => 'lib/Math/Logic/Ternary/Calculator/Command.pm',
                    version => '0.004',
                },
                'Math::Logic::Ternary::Calculator::Mode' => {
                    file    => 'lib/Math/Logic/Ternary/Calculator/Mode.pm',
                    version => '0.004',
                },
                'Math::Logic::Ternary::Calculator::Operator' => {
                    file    => 'lib/Math/Logic/Ternary/Calculator/Operator.pm',
                    version => '0.004',
                },
                'Math::Logic::Ternary::Calculator::Parser' => {
                    file    => 'lib/Math/Logic/Ternary/Calculator/Parser.pm',
                    version => '0.004',
                },
                'Math::Logic::Ternary::Calculator::Session' => {
                    file    => 'lib/Math/Logic/Ternary/Calculator/Session.pm',
                    version => '0.004',
                },
                'Math::Logic::Ternary::Calculator::State' => {
                    file    => 'lib/Math/Logic/Ternary/Calculator/State.pm',
                    version => '0.004',
                },
                'Math::Logic::Ternary::Calculator::Version' => {
                    file    => 'lib/Math/Logic/Ternary/Calculator/Version.pm',
                    version => '0.004',
                },
                'Math::Logic::Ternary::Expression' => {
                    file    => 'lib/Math/Logic/Ternary/Expression.pm',
                    version => '0.004',
                },
                'Math::Logic::Ternary::Object' => {
                    file    => 'lib/Math/Logic/Ternary/Object.pm',
                    version => '0.004',
                },
                'Math::Logic::Ternary::TAPI27' => {
                    file    => 'lib/Math/Logic/Ternary/TAPI27.pm',
                    version => '0.004',
                },
                'Math::Logic::Ternary::TAPI_9' => {
                    file    => 'lib/Math/Logic/Ternary/TAPI_9.pm',
                    version => '0.004',
                },
                'Math::Logic::Ternary::TFP_81' => {
                    file    => 'lib/Math/Logic/Ternary/TFP_81.pm',
                    version => '0.004',
                },
                'Math::Logic::Ternary::Trit' => {
                    file    => 'lib/Math/Logic/Ternary/Trit.pm',
                    version => '0.004',
                },
                'Math::Logic::Ternary::Word' => {
                    file    => 'lib/Math/Logic/Ternary/Word.pm',
                    version => '0.004',
                },
            },
            resources => {
                homepage    => q[https://vera.in-ulm.de/ternary-logic/],
                bugtracker  => {
                    web     => cpan_rt('Math-Logic-Ternary'),
                    mailto  => cpanbug('Math-Logic-Ternary'),
                },
            },
        },
        $STATUS eq 'stable'? (): (
            META_ADD         => {
                release_status => $STATUS,
            },
        ),
    ): (),
    $EMV >= 6.47? (
        MIN_PERL_VERSION => '5.008',
    ): (),
    $EMV >= 6.56? (
        BUILD_REQUIRES   => {
            'ExtUtils::MakeMaker' => 0,
            'File::Spec'          => 0,
            'Math::BigInt'        => '1.78',
            'Test::More'          => 0,
        },
    ): (),
);

patch_release_status('Makefile');
patch_release_status('MYMETA.json');

sub cpan_rt { qq{https://rt.cpan.org/Public/Bug/Report.html?Queue=$_[0]} }
sub cpanbug { qq{bug-$_[0]\@rt.cpan.org} }

sub patch_release_status {
    return if 'stable' eq $STATUS;
    my ($original) = @_;
    my $tmpfile = $original;
    $tmpfile =~ s/\.\w+\z//;
    $tmpfile =~ s/\z/.tmp/;
    if (-e $tmpfile) {
        warn "$tmpfile: temp file is in my way, please remove it\n";
        return;
    }
    open ORIG, '<', $original or return;
    my ($changes, $io_error, $do_unlink);
    open TMP, '>', $tmpfile and $do_unlink = 1 or $io_error = $!;
    while (!defined($io_error) && defined(my $line = <ORIG>)) {
        $changes += $line =~
            s/"release_status" : "stable",/"release_status" : "$STATUS",/;
        print TMP $line or $io_error = $!;
    }
    close TMP or $io_error = $! if $do_unlink;
    close ORIG;
    if ($io_error) {
        warn "$tmpfile: could not generate temp file: $io_error\n";
    }
    elsif ($changes) {
        warn "patching $original\n";
        if (rename $tmpfile, $original) {
            undef $do_unlink;
        }
        else {
            warn "$original: could not replace: %!\n";
        }
    }
    if ($do_unlink) {
        unlink $tmpfile or warn "$tmpfile: could not clean up temp file: $!\n";
    }
}

__END__
