:<<BATCHFILE
@echo off
if "%OS%" == "Windows_NT" goto WinNT
set PERL5LIB=lib
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
set PERL5LIB=lib
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
BATCHFILE
PERL5LIB=lib
perl -x -S $0 ${1+"$@"}
exit
#!perl
#line 19
package pmake;
######################################################################
#
# pmake - make of Perl Poor Tools
#
# Copyright (c) 2008, 2009, 2010, 2018, 2019, 2020, 2021, 2026 INABA Hitoshi <ina.cpan@gmail.com> in a CPAN
######################################################################

$PMAKE_BAT_VERSION = '0.33';
$PMAKE_BAT_VERSION = $PMAKE_BAT_VERSION;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;
use FindBin;
use File::Path;
use File::Copy;
use File::Basename;

unless (@ARGV) {
    if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
        die <<'END';

usage:

C:\> pmake
C:\> pmake test
C:\> pmake xtest
C:\> pmake install
C:\> pmake dist
C:\> pmake ptar
C:\> pmake xzvf
C:\> pmake pwget
C:\> pmake selfcheck
C:\> pmake selfcheck --check1
C:\> pmake selfcheck --check2
END
    }
    elsif (1 or ($^O =~ /(?:solaris|linux)/i)) {
        die <<'END';

usage:

$ ./pmake.bat
$ ./pmake.bat test
$ ./pmake.bat xtest
$ ./pmake.bat install
$ ./pmake.bat dist
$ ./pmake.bat ptar
$ ./pmake.bat xzvf
$ ./pmake.bat pwget
$ ./pmake.bat selfcheck
$ ./pmake.bat selfcheck --check1
$ ./pmake.bat selfcheck --check2

END
    }
}

# get file list
my @file = ();
if (open(FH_MANIFEST, 'MANIFEST')) {
    chomp(@file = <FH_MANIFEST>);
    close FH_MANIFEST;
}

for my $target (@ARGV) {

    # make test
    if ($target eq 'test') {
        my @test = grep m{ \A (?: test\.pl | t/.+\.t ) \z }xmsi, @file;
        _runtests(@test);
        print STDERR "\a";
    }

    # make xtest
    elsif ($target eq 'xtest') {
        my @test = grep m{ \A (?: test\.pl | t/.+\.t | xt/.+\.t ) \z }xmsi, @file;
        _runtests(@test);
        print STDERR "\a";
    }

    # make install
    elsif ($target eq 'install') {

        # install *.pm files to /Perl/site/lib
        my $perl_site_lib = '';
        if (($perl_site_lib) = grep(m{site_perl}xms, reverse @INC)) {
        }
        elsif (($perl_site_lib) = grep(m{site}xms, reverse @INC)) {
        }
        if ($perl_site_lib ne '') {
            for (grep m/ \. pm \z /xmsi, @file) {
                if (m#^lib/(.+)/([^/]+)$#) {
                    print STDERR "copy $_ $perl_site_lib/$1/$2\n";
                    mkpath("$perl_site_lib/$1", 0, 0777) unless -d "$perl_site_lib/$1";
                    copy($_, "$perl_site_lib/$1/$2");
                }
                elsif (m#^(.+)/([^/]+)$#) {
                    print STDERR "copy $_ $perl_site_lib/$1/$2\n";
                    mkpath("$perl_site_lib/$1", 0, 0777) unless -d "$perl_site_lib/$1";
                    copy($_, "$perl_site_lib/$1/$2");
                }
                else {
                    print STDERR "copy $_ $perl_site_lib/$_\n";
                    copy($_, "$perl_site_lib/$_");
                }
            }
        }

        # install *.pl, *.bat, *.exe, and *.com files to /Perl/bin
        my($perl_bin) = $^X =~ /^(.*)\\[^\\]*$/;
        for (grep m/ \. (?: pl | bat | exe | com ) \z /xmsi, @file) {
            next if m/(?: Makefile | test ) \.pl  $/xmsi;
            next if m/(?: pmake | ptar )    \.bat $/xmsi;
            if (m#^bin/(.+)/([^/]+)$#) {
                print STDERR "copy $_ $perl_bin/$1/$2\n";
                mkpath("$perl_bin/$1", 0, 0777) unless -d "$perl_bin/$1";
                copy($_, "$perl_bin/$1/$2");
            }
            elsif (m#^(.+)/([^/]+)$#) {
                print STDERR "copy $_ $perl_bin/$1/$2\n";
                mkpath("$perl_bin/$1", 0, 0777) unless -d "$perl_bin/$1";
                copy($_, "$perl_bin/$1/$2");
            }
            else {
                print STDERR "copy $_ $perl_bin/$_\n";
                copy($_, "$perl_site_lib/$_");
            }
        }
    }

    # make dist
    elsif ($target eq 'dist') {

        # dist-time check flags (both ON by default)
        my $dist_check1 = 1;
        my $dist_check2 = 1;
        for my $arg (@ARGV) {
            $dist_check1 = 0 if $arg eq '--no-check1';
            $dist_check2 = 0 if $arg eq '--no-check2';
        }

        # your PAUSE ID here
        my $author = q{ina <ina.cpan@gmail.com>};

        # get $name_as_filesystem
        open(FH_MANIFEST,'MANIFEST') || die "Can't open file: MANIFEST.\n";
        chomp(my $name_as_filesystem = <FH_MANIFEST>);
        close(FH_MANIFEST);
        die "'NAME_AS_FILESYSTEM' not found.\n" unless $name_as_filesystem;
        check_usascii('MANIFEST');

        # get $name_as_dist_on_url
        my $name_as_dist_on_url = $name_as_filesystem;
        $name_as_dist_on_url =~ s#^lib/##;
        $name_as_dist_on_url =~ s#\.(pl|pm)$##i;
        $name_as_dist_on_url =~ s#/#-#g;
        die "'NAME_AS_DIST_ON_URL' not found.\n" unless $name_as_dist_on_url;

        # get $name_as_perlsyntax
        my $name_as_perlsyntax = $name_as_filesystem;
        $name_as_perlsyntax =~ s#^lib/(Char/)?##;
        $name_as_perlsyntax =~ s#\.(pl|pm|bat)$##i;
        $name_as_perlsyntax =~ s#/#::#g;
        die "'NAME_AS_PERLSYNTAX' not found.\n" unless $name_as_perlsyntax;

        # get $package, $version, and $abstract
        my $package  = '';
        my $version  = '';
        my $abstract = '';
        open(FH_NAME,$name_as_filesystem) || die "Can't open file: $name_as_filesystem.\n";
        while (<FH_NAME>) {
            if ($package eq '') {
                if (/^#/) {
                }
                elsif (/^package\s+([^;]+);/) {
                    $package = $1;
                }
            }
            if ($version eq '') {
                if (/^#/) {
                }
                elsif (/\$VERSION\s*=\s*([^;]+);/) {
                    $version = eval "$1";
                }
            }
            if ($abstract eq '') {
                if (/\b$name_as_perlsyntax\s+-\s+(.+)/) {
                    $abstract = $1;
                }
            }
        }
        close(FH_NAME);
        die "'PACKAGE' not found.\n"  unless $package;
        die "'VERSION' not found.\n"  unless $version;
        die "'ABSTRACT' not found.\n" unless $abstract;

        my %requires_version = (qw(
            Archive::Tar         0.072
            Compress::Zlib       1.03
            Config               0
            ExtUtils::MakeMaker  5.4302
            Fcntl                1.03
            File::Basename       2.6
            File::Copy           2.02
            File::Path           1.0401
            FindBin              1.42
            IOas::CP932          0.06
            IOas::CP932IBM       0.06
            IOas::CP932NEC       0.06
            IOas::CP932X         0.06
            IOas::SJIS2004       0.06
            Jacode4e::RoundTrip  2.13.81.8
            UTF8::R2             0.05
        ));
        my %requires = (qw(
            perl                 5.005_03
        ));
        my %provides = ();
        for my $file (grep m{\Alib/.*\.pm\z}i, @file) {
            if (open FILE, $file) {
                while (<FILE>) {
                    chomp;
                    if (/^use\s+([0-9]+(\.[0-9]*)?)/) {
                        $requires{'perl'} = $1;
                    }
                    elsif (/^use\s+([A-Za-z][^;\s]*).*;/) {
                        $requires{$1} = ($requires_version{$1} || '0');
                    }
                    elsif (/^package\s+([A-Za-z][^;\s]*).*;/) {
                        $provides{$1} = $file;
                    }
                }
                close(FILE);
            }
        }
        delete @requires{keys %provides};
        if ($package eq 'Char') {
            delete @requires{qw(
                Ebig5hkscs
                Ebig5plus
                Egb18030
                Egbk
                Ehp15
                Einformixv6als
                Ekps9566
                Euhc
            )};
            delete @provides{qw(
                Esjis
                Sjis
            )};
        }
        delete $requires{'strict'};
        delete $requires{'warnings'};
        delete $requires{'vars'};
        $requires{'ExtUtils::MakeMaker'} = '5.4302';

        #                                                12345678
        my $requires_as_makefile_pl = join "\n", map {qq{        '$_' => '$requires{$_}',}} sort keys %requires;

        #                                                12345678901234567890
        my $provides_as_makefile_pl = join ",\n", map {
            my $f = $provides{$_};
            qq{            '$_' => {\n                'file'    => '$f',\n                'version' => '$version',\n            }}
        } sort keys %provides;

        # write Makefile.PL
        open(FH_MAKEFILEPL,'>Makefile.PL') || die "Can't open file: Makefile.PL.\n";
        binmode FH_MAKEFILEPL;
        printf FH_MAKEFILEPL (<<'END', $package, $version, $abstract, $requires_as_makefile_pl, $author, $name_as_dist_on_url, $name_as_dist_on_url, $name_as_dist_on_url, $provides_as_makefile_pl);
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use ExtUtils::MakeMaker;

my %%args = (
    'NAME'      => q{%s},
    'VERSION'   => q{%s},
    'ABSTRACT'  => q{%s},
    'PREREQ_PM' => {
%s
    },
    'AUTHOR'    => q{%s},
);

# LICENSE was introduced in ExtUtils::MakeMaker 6.31 (2006).
# Passing it to older versions produces an "is not a known parameter" warning
# without failing, but we suppress the noise by checking the version.
if ($ExtUtils::MakeMaker::VERSION >= 6.31) {
    $args{LICENSE} = q{perl};
}

# MIN_PERL_VERSION (6.48) and META_MERGE (6.46) arrived together in the
# same EUMM release cycle; guard them under the higher threshold (6.48)
# so both are always either present or absent.
if ($ExtUtils::MakeMaker::VERSION >= 6.48) {
    $args{MIN_PERL_VERSION} = q{5.00503};
    $args{META_MERGE} = {
        'meta-spec' => { version => 2 },
        'resources' => {
            'license'    => [ 'http://dev.perl.org/licenses/' ],
            'bugtracker' => {
                'web' => 'https://github.com/ina-cpan/%s/issues',
            },
            'repository' => {
                'url'  => 'https://github.com/ina-cpan/%s',
                'web'  => 'https://github.com/ina-cpan/%s',
                'type' => 'git',
            },
        },
        'provides' => {
%s
        },
    };
}

WriteMakefile(%%args);

__END__
END
        close(FH_MAKEFILEPL);
        check_usascii('Makefile.PL');

        # write META.yml
        #
        # CPANTS Kwalitee shows us following message, but never believe it.
        # It's a trap. #'
        #
        # Kwalitee Indicator: meta_yml_conforms_to_known_spec core
        # META.yml does not conform to any recognised META.yml Spec.
        # How to fix
        # Take a look at the META.yml Spec at https://metacpan.org/pod/CPAN::Meta::History::Meta_1_4
        # (for version 1.4) or https://metacpan.org/pod/CPAN::Meta::Spec (for version 2),
        # and change your META.yml accordingly.
        #
        # How to escape from trap
        #
        #   meta-spec:
        #     version: 1.4
        #     url: http://module-build.sourceforge.net/META-spec-v1.4.html

        #                                      12     1234
        my $provides_as_yml = join "\n", map {"  $_:\n    file: $provides{$_}\n    version: $version"} sort keys %provides;
        my $requires_as_yml = join "\n", map {"  $_: $requires{$_}"}                                   sort keys %requires;
        #                                      12

        open(FH_METAYML,'>META.yml') || die "Can't open file: META.yml.\n";
        binmode FH_METAYML;
        printf FH_METAYML (<<'END', $name_as_dist_on_url, $version, $abstract, $author, $pmake::PMAKE_BAT_VERSION, $requires_as_yml, $provides_as_yml, $name_as_dist_on_url, $name_as_dist_on_url);
--- #YAML:1.0
meta-spec:
  version: 1.4
  url: http://module-build.sourceforge.net/META-spec-v1.4.html
name: %s
version: %s
abstract: %s
author:
  - %s
license: perl
generated_by: pmake.bat version %s
requires:
%s
minimum_perl_version: 5.00503
provides:
%s
resources:
  license: http://dev.perl.org/licenses/
  bugtracker: https://github.com/ina-cpan/%s/issues
  repository: https://github.com/ina-cpan/%s
END
        close(FH_METAYML);
        check_usascii('META.yml');

        # write META.json
        #
        # CPANTS Kwalitee shows us following message, but never believe it.
        # It's a trap. #'
        #
        # Kwalitee Indicator: meta_json_conforms_to_known_spec
        # META.json does not conform to any recognised META Spec.
        # How to fix
        # Take a look at the META.json Spec at https://metacpan.org/pod/CPAN::Meta::History::Meta_1_4
        # (for version 1.4) or https://metacpan.org/pod/CPAN::Meta::Spec (for version 2),
        # and change your META.json accordingly.
        #
        # How to escape from trap
        #
        #   "meta-spec" : {
        #       "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
        #       "version" : 2
        #   },

        #                                          1234567890123456
        my $requires_as_json = join ",\n", map {qq{                "$_" : "$requires{$_}"}}                            sort keys %requires;
        my $provides_as_json = join ",\n", map {qq{        "$_" : {\n            "file" : "$provides{$_}",\n            "version" : "$version"\n        }}} sort keys %provides;
        #                                          12345678          123456789012                          12345678

        open(FH_METAJSON,'>META.json') || die "Can't open file: META.json.\n";
        binmode FH_METAJSON;
        printf FH_METAJSON (<<'END', $name_as_dist_on_url, $version, $abstract, $author, $pmake::PMAKE_BAT_VERSION, $name_as_dist_on_url, $name_as_dist_on_url, $name_as_dist_on_url, $requires_as_json, $requires_as_json, $requires_as_json, $requires_as_json, $provides_as_json);
{
    "name" : "%s",
    "version" : "%s",
    "abstract" : "%s",
    "author" : [
        "%s"
    ],
    "dynamic_config" : 1,
    "generated_by" : "pmake.bat version %s",
    "license" : [
        "perl_5"
    ],
    "meta-spec" : {
        "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
        "version" : 2
    },
    "release_status" : "stable",
    "resources" : {
        "license" : [
            "http://dev.perl.org/licenses/"
        ],
        "bugtracker" : {
            "web" : "https://github.com/ina-cpan/%s/issues"
        },
        "repository" : {
            "url"  : "https://github.com/ina-cpan/%s",
            "web"  : "https://github.com/ina-cpan/%s",
            "type" : "git"
        }
    },
    "prereqs" : {
        "build" : {
            "requires" : {
%s
            }
        },
        "configure" : {
            "requires" : {
%s
            }
        },
        "runtime" : {
            "requires" : {
%s
            }
        },
        "test" : {
            "requires" : {
%s
            }
        }
    },
    "provides" : {
%s
    }
}
END
        close(FH_METAJSON);
        check_usascii('META.json');

        # write LICENSE
        open(FH_LICENSE,'>LICENSE') || die "Can't open file: LICENSE\n";
        binmode FH_LICENSE;
        print FH_LICENSE <<'LICENSING';
Terms of Perl itself

a) the GNU General Public License as published by the Free
   Software Foundation; either version 1, or (at your option) any
   later version, or
b) the "Artistic License"

----------------------------------------------------------------------------

                    GNU GENERAL PUBLIC LICENSE
                       Version 2, June 1991

 Copyright (C) 1989, 1991 Free Software Foundation, Inc.,
 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The licenses for most software are designed to take away your
freedom to share and change it.  By contrast, the GNU General Public
License is intended to guarantee your freedom to share and change free
software--to make sure the software is free for all its users.  This
General Public License applies to most of the Free Software
Foundation's software and to any other program whose authors commit to
using it.  (Some other Free Software Foundation software is covered by
the GNU Lesser General Public License instead.)  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
this service if you wish), that you receive source code or can get it
if you want it, that you can change the software or use pieces of it
in new free programs; and that you know you can do these things.

  To protect your rights, we need to make restrictions that forbid
anyone to deny you these rights or to ask you to surrender the rights.
These restrictions translate to certain responsibilities for you if you
distribute copies of the software, or if you modify it.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must give the recipients all the rights that
you have.  You must make sure that they, too, receive or can get the
source code.  And you must show them these terms so they know their
rights.

  We protect your rights with two steps: (1) copyright the software, and
(2) offer you this license which gives you legal permission to copy,
distribute and/or modify the software.

  Also, for each author's protection and ours, we want to make certain
that everyone understands that there is no warranty for this free
software.  If the software is modified by someone else and passed on, we
want its recipients to know that what they have is not the original, so
that any problems introduced by others will not reflect on the original
authors' reputations.

  Finally, any free program is threatened constantly by software
patents.  We wish to avoid the danger that redistributors of a free
program will individually obtain patent licenses, in effect making the
program proprietary.  To prevent this, we have made it clear that any
patent must be licensed for everyone's free use or not licensed at all.

  The precise terms and conditions for copying, distribution and
modification follow.

                    GNU GENERAL PUBLIC LICENSE
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

  0. This License applies to any program or other work which contains
a notice placed by the copyright holder saying it may be distributed
under the terms of this General Public License.  The "Program", below,
refers to any such program or work, and a "work based on the Program"
means either the Program or any derivative work under copyright law:
that is to say, a work containing the Program or a portion of it,
either verbatim or with modifications and/or translated into another
language.  (Hereinafter, translation is included without limitation in
the term "modification".)  Each licensee is addressed as "you".

Activities other than copying, distribution and modification are not
covered by this License; they are outside its scope.  The act of
running the Program is not restricted, and the output from the Program
is covered only if its contents constitute a work based on the
Program (independent of having been made by running the Program).
Whether that is true depends on what the Program does.

  1. You may copy and distribute verbatim copies of the Program's
source code as you receive it, in any medium, provided that you
conspicuously and appropriately publish on each copy an appropriate
copyright notice and disclaimer of warranty; keep intact all the
notices that refer to this License and to the absence of any warranty;
and give any other recipients of the Program a copy of this License
along with the Program.

You may charge a fee for the physical act of transferring a copy, and
you may at your option offer warranty protection in exchange for a fee.

  2. You may modify your copy or copies of the Program or any portion
of it, thus forming a work based on the Program, and copy and
distribute such modifications or work under the terms of Section 1
above, provided that you also meet all of these conditions:

    a) You must cause the modified files to carry prominent notices
    stating that you changed the files and the date of any change.

    b) You must cause any work that you distribute or publish, that in
    whole or in part contains or is derived from the Program or any
    part thereof, to be licensed as a whole at no charge to all third
    parties under the terms of this License.

    c) If the modified program normally reads commands interactively
    when run, you must cause it, when started running for such
    interactive use in the most ordinary way, to print or display an
    announcement including an appropriate copyright notice and a
    notice that there is no warranty (or else, saying that you provide
    a warranty) and that users may redistribute the program under
    these conditions, and telling the user how to view a copy of this
    License.  (Exception: if the Program itself is interactive but
    does not normally print such an announcement, your work based on
    the Program is not required to print an announcement.)

These requirements apply to the modified work as a whole.  If
identifiable sections of that work are not derived from the Program,
and can be reasonably considered independent and separate works in
themselves, then this License, and its terms, do not apply to those
sections when you distribute them as separate works.  But when you
distribute the same sections as part of a whole which is a work based
on the Program, the distribution of the whole must be on the terms of
this License, whose permissions for other licensees extend to the
entire whole, and thus to each and every part regardless of who wrote it.

Thus, it is not the intent of this section to claim rights or contest
your rights to work written entirely by you; rather, the intent is to
exercise the right to control the distribution of derivative or
collective works based on the Program.

In addition, mere aggregation of another work not based on the Program
with the Program (or with a work based on the Program) on a volume of
a storage or distribution medium does not bring the other work under
the scope of this License.

  3. You may copy and distribute the Program (or a work based on it,
under Section 2) in object code or executable form under the terms of
Sections 1 and 2 above provided that you also do one of the following:

    a) Accompany it with the complete corresponding machine-readable
    source code, which must be distributed under the terms of Sections
    1 and 2 above on a medium customarily used for software interchange; or,

    b) Accompany it with a written offer, valid for at least three
    years, to give any third party, for a charge no more than your
    cost of physically performing source distribution, a complete
    machine-readable copy of the corresponding source code, to be
    distributed under the terms of Sections 1 and 2 above on a medium
    customarily used for software interchange; or,

    c) Accompany it with the information you received as to the offer
    to distribute corresponding source code.  (This alternative is
    allowed only for noncommercial distribution and only if you
    received the program in object code or executable form with such
    an offer, in accord with Subsection b above.)

The source code for a work means the preferred form of the work for
making modifications to it.  For an executable work, complete source
code means all the source code for all modules it contains, plus any
associated interface definition files, plus the scripts used to
control compilation and installation of the executable.  However, as a
special exception, the source code distributed need not include
anything that is normally distributed (in either source or binary
form) with the major components (compiler, kernel, and so on) of the
operating system on which the executable runs, unless that component
itself accompanies the executable.

If distribution of executable or object code is made by offering
access to copy from a designated place, then offering equivalent
access to copy the source code from the same place counts as
distribution of the source code, even though third parties are not
compelled to copy the source along with the object code.

  4. You may not copy, modify, sublicense, or distribute the Program
except as expressly provided under this License.  Any attempt
otherwise to copy, modify, sublicense or distribute the Program is
void, and will automatically terminate your rights under this License.
However, parties who have received copies, or rights, from you under
this License will not have their licenses terminated so long as such
parties remain in full compliance.

  5. You are not required to accept this License, since you have not
signed it.  However, nothing else grants you permission to modify or
distribute the Program or its derivative works.  These actions are
prohibited by law if you do not accept this License.  Therefore, by
modifying or distributing the Program (or any work based on the
Program), you indicate your acceptance of this License to do so, and
all its terms and conditions for copying, distributing or modifying
the Program or works based on it.

  6. Each time you redistribute the Program (or any work based on the
Program), the recipient automatically receives a license from the
original licensor to copy, distribute or modify the Program subject to
these terms and conditions.  You may not impose any further
restrictions on the recipients' exercise of the rights granted herein.
You are not responsible for enforcing compliance by third parties to
this License.

  7. If, as a consequence of a court judgment or allegation of patent
infringement or for any other reason (not limited to patent issues),
conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot
distribute so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you
may not distribute the Program at all.  For example, if a patent
license would not permit royalty-free redistribution of the Program by
all those who receive copies directly or indirectly through you, then
the only way you could satisfy both it and this License would be to
refrain entirely from distribution of the Program.

If any portion of this section is held invalid or unenforceable under
any particular circumstance, the balance of the section is intended to
apply and the section as a whole is intended to apply in other
circumstances.

It is not the purpose of this section to induce you to infringe any
patents or other property right claims or to contest validity of any
such claims; this section has the sole purpose of protecting the
integrity of the free software distribution system, which is
implemented by public license practices.  Many people have made
generous contributions to the wide range of software distributed
through that system in reliance on consistent application of that
system; it is up to the author/donor to decide if he or she is willing
to distribute software through any other system and a licensee cannot
impose that choice.

This section is intended to make thoroughly clear what is believed to
be a consequence of the rest of this License.

  8. If the distribution and/or use of the Program is restricted in
certain countries either by patents or by copyrighted interfaces, the
original copyright holder who places the Program under this License
may add an explicit geographical distribution limitation excluding
those countries, so that distribution is permitted only in or among
countries not thus excluded.  In such case, this License incorporates
the limitation as if written in the body of this License.

  9. The Free Software Foundation may publish revised and/or new versions
of the General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

Each version is given a distinguishing version number.  If the Program
specifies a version number of this License which applies to it and "any
later version", you have the option of following the terms and conditions
either of that version or of any later version published by the Free
Software Foundation.  If the Program does not specify a version number of
this License, you may choose any version ever published by the Free Software
Foundation.

  10. If you wish to incorporate parts of the Program into other free
programs whose distribution conditions are different, write to the author
to ask for permission.  For software which is copyrighted by the Free
Software Foundation, write to the Free Software Foundation; we sometimes
make exceptions for this.  Our decision will be guided by the two goals
of preserving the free status of all derivatives of our free software and
of promoting the sharing and reuse of software generally.

                            NO WARRANTY

  11. BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
REPAIR OR CORRECTION.

  12. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

                     END OF TERMS AND CONDITIONS


----------------------------------------------------------------------------

The Artistic License

Preamble

The intent of this document is to state the conditions under which a Package
may be copied, such that the Copyright Holder maintains some semblance of
artistic control over the development of the package, while giving the users of the
package the right to use and distribute the Package in a more-or-less customary
fashion, plus the right to make reasonable modifications.

Definitions:

-    "Package" refers to the collection of files distributed by the Copyright
     Holder, and derivatives of that collection of files created through textual
     modification.
-    "Standard Version" refers to such a Package if it has not been modified,
     or has been modified in accordance with the wishes of the Copyright
     Holder.
-    "Copyright Holder" is whoever is named in the copyright or copyrights for
     the package.
-    "You" is you, if you're thinking about copying or distributing this Package.
-    "Reasonable copying fee" is whatever you can justify on the basis of
     media cost, duplication charges, time of people involved, and so on. (You
     will not be required to justify it to the Copyright Holder, but only to the
     computing community at large as a market that must bear the fee.)
-    "Freely Available" means that no fee is charged for the item itself, though
     there may be fees involved in handling the item. It also means that
     recipients of the item may redistribute it under the same conditions they
     received it.

1. You may make and give away verbatim copies of the source form of the
Standard Version of this Package without restriction, provided that you duplicate
all of the original copyright notices and associated disclaimers.

2. You may apply bug fixes, portability fixes and other modifications derived from
the Public Domain or from the Copyright Holder. A Package modified in such a
way shall still be considered the Standard Version.

3. You may otherwise modify your copy of this Package in any way, provided
that you insert a prominent notice in each changed file stating how and when
you changed that file, and provided that you do at least ONE of the following:

     a) place your modifications in the Public Domain or otherwise
     make them Freely Available, such as by posting said modifications
     to Usenet or an equivalent medium, or placing the modifications on
     a major archive site such as ftp.uu.net, or by allowing the
     Copyright Holder to include your modifications in the Standard
     Version of the Package.

     b) use the modified Package only within your corporation or
     organization.

     c) rename any non-standard executables so the names do not
     conflict with standard executables, which must also be provided,
     and provide a separate manual page for each non-standard
     executable that clearly documents how it differs from the Standard
     Version.

     d) make other distribution arrangements with the Copyright Holder.

4. You may distribute the programs of this Package in object code or executable
form, provided that you do at least ONE of the following:

     a) distribute a Standard Version of the executables and library
     files, together with instructions (in the manual page or equivalent)
     on where to get the Standard Version.

     b) accompany the distribution with the machine-readable source of
     the Package with your modifications.

     c) accompany any non-standard executables with their
     corresponding Standard Version executables, giving the
     non-standard executables non-standard names, and clearly
     documenting the differences in manual pages (or equivalent),
     together with instructions on where to get the Standard Version.

     d) make other distribution arrangements with the Copyright Holder.

5. You may charge a reasonable copying fee for any distribution of this Package.
You may charge any fee you choose for support of this Package. You may not
charge a fee for this Package itself. However, you may distribute this Package in
aggregate with other (possibly commercial) programs as part of a larger
(possibly commercial) software distribution provided that you do not advertise
this Package as a product of your own.

6. The scripts and library files supplied as input to or produced as output from
the programs of this Package do not automatically fall under the copyright of this
Package, but belong to whomever generated them, and may be sold
commercially, and may be aggregated with this Package.

7. C or perl subroutines supplied by you and linked into this Package shall not
be considered part of this Package.

8. The name of the Copyright Holder may not be used to endorse or promote
products derived from this software without specific prior written permission.

9. THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
PURPOSE.

The End

LICENSING
        close FH_LICENSE;
        check_usascii('LICENSE');

        # write CONTRIBUTING
        open(FH_CONTRIBUTING,'>CONTRIBUTING') || die "Can't open file: CONTRIBUTING\n";
        binmode FH_CONTRIBUTING;
        print FH_CONTRIBUTING <<'TO_CONTRIBUTE';
# Contributing to this project

Before you go crazy with huge changes, send some small e-mail to check
that we want to change the tools in that way. E-mail that have one logical
change are better.

Good e-mail, patches, improvements, new features - are a fantastic help.
They should remain focused in scope and avoid containing unrelated commits.

**Please ask first** before embarking on any significant e-mail (e.g.
implementing features, refactoring code, porting to a different language),
otherwise you risk spending a lot of time working on something that the
project's developers might not want to merge into the project.

Please adhere to the coding conventions used throughout a project
(indentation, accurate comments, etc.) and any other requirements (such
as test coverage).

**IMPORTANT**: By submitting a patch, you agree to allow the project owner
to license your work under the same license as that used by the project.
TO_CONTRIBUTE
        close FH_CONTRIBUTING;
        check_usascii('CONTRIBUTING');

        # write SECURITY.md
        open(FH_SECURITY,'>SECURITY.md') || die "Can't open file: SECURITY.md\n";
        binmode FH_SECURITY;
        print FH_SECURITY <<'TO_SECURITY';
# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this distribution, please report
it by e-mail to the author at ina.cpan@gmail.com.

Do NOT open a public GitHub issue for security vulnerabilities.  Please use
private e-mail so that a fix can be prepared before public disclosure.

You can expect an acknowledgement within a few days.  If you do not receive
a response within one week, please follow up.

## Supported Versions

Only the most recent release on CPAN is actively maintained.  Please
upgrade to the latest version before reporting security issues.
TO_SECURITY
        close FH_SECURITY;
        check_usascii('SECURITY.md');

        # check source files in MANIFEST (lib/*.pm lib/*.pl t/*.t eg/*.pl bin/*.pl etc.)
        _dist_check_sources(\@file, $dist_check1, $dist_check2);

        # make work directory
        my $dirname = (dirname($file[0]) eq 'bin') ? 'App' : dirname($file[0]);
        $dirname =~ tr#/#-#;
        my $basename = basename($file[0], '.pm','.pl','.bat');
        my $tardir = "$dirname-$basename-$version";
        $tardir =~ s#^lib-##;
        rmtree($tardir, 0, 0);

        if ($^O =~ /(?:solaris|linux)/i) {
            for my $file (@file) {
                if (-e $file) {
                    mkpath(dirname("$tardir/$file"), 0, 0777);
                    print STDERR "copy $file $tardir/$file\n";
                    copy($file, "$tardir/$file");
                    if ($file =~ m/ (?: Build\.PL | Makefile\.PL ) \z/oxmsi) {
                        chmod(0664, "$tardir/$file");
                    }
                    elsif ($file =~ m/\. (?: pl | bat | exe | com ) \z/oxmsi) {
                        chmod(0775, "$tardir/$file");
                    }
                    elsif ($file =~ m{^bin/}oxmsi) {
                        chmod(0775, "$tardir/$file");
                    }
                    else {
                        chmod(0664, "$tardir/$file");
                    }
                }
            }
            system(qq{tar -cvf $tardir.tar $tardir});
            system(qq{gzip $tardir.tar});
        }
        else {

#-----------------------------------------------------------------------------
# https://metacpan.org/search?q=Archive%3A%3ATar%3A%3AConstant
# https://metacpan.org/release/Archive-Tar-Streamed
#-----------------------------------------------------------------------------
            eval q{
                use Compress::Zlib;
                use Archive::Tar;
            };
            my $BLOCK_SIZE = 512;
            my $ZERO_BLOCK = "\0" x $BLOCK_SIZE;

            # make *.tar file
            open(FH_TAR, ">$tardir.tar") || die "Can't open file: $tardir.tar\n"; #'
            binmode FH_TAR;
            for my $file (@file) {
                if (-e $file) {
                    mkpath(dirname("$tardir/$file"), 0, 0777);
                    print STDERR "copy $file $tardir/$file\n";
                    copy($file, "$tardir/$file");

#-----------------------------------------------------------------------------
# Sunday December 21, 2008 07:38 PM
# Fixing world writable files in tarball before upload to CPAN [ #38127 ]
# http://use.perl.org/~bart/journal/38127 (dead link)
# Fix CPAN uploads for world writable files
# http://perlmonks.org/index.pl?node_id=731935
#-----------------------------------------------------------------------------
#                   $tar->add_files("$tardir/$file");
#-----------------------------------------------------------------------------
                    open(FH, $file) || die "Can't open file: $file\n"; #'
                    binmode FH;
                    local $/ = undef; # slurp mode
                    my $data = <FH>;
                    close FH;

#-----------------------------------------------------------------------------
# Kwalitee Indicator: buildtool_not_executable core
# The build tool (Build.PL/Makefile.PL) is executable. This is bad because
# you should specify which perl you want to use while installing.
#
# How to fix
# Change the permissions of Build.PL/Makefile.PL to not-executable.
#-----------------------------------------------------------------------------

                    my $tar = Archive::Tar->new;
                    if ($file =~ m/ (?: Build\.PL | Makefile\.PL ) \z/oxmsi) {
                        $tar->add_data("$tardir/$file", $data, {'mode' => 0664});
                    }
                    elsif ($file =~ m/\. (?: pl | bat | exe | com ) \z/oxmsi) {
                        $tar->add_data("$tardir/$file", $data, {'mode' => 0775});
                    }
                    else {
                        $tar->add_data("$tardir/$file", $data, {'mode' => 0664});
                    }
                    my $format_tar_file = $tar->write;
                    syswrite FH_TAR, $format_tar_file, length($format_tar_file) - length($ZERO_BLOCK . $ZERO_BLOCK);
                    undef $tar;

#-----------------------------------------------------------------------------
                }
                else {
                    die "file: $file is not exists.\n";
                }
            }

            # syswrite FH_TAR, $ZERO_BLOCK; makes "tar: A lone zero block at %s"
            syswrite FH_TAR, ($ZERO_BLOCK . $ZERO_BLOCK);

            close FH_TAR;
            rmtree($tardir, 0, 0);

            # make *.tar.gz file
            my $gz = gzopen("$tardir.tar.gz", 'wb');
            open(FH_TAR, "$tardir.tar") || die "Can't open file: $tardir.tar\n";
            binmode FH_TAR;
            while (sysread(FH_TAR, $_, 1024*1024)) {
                $gz->gzwrite($_);
            }
            close FH_TAR;
            $gz->gzclose;
            unlink "$tardir.tar";
        }

        # P.565 Cleaning Up Your Environment
        # in Chapter 23: Security
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        # local $ENV{'PATH'} = '.';
        local @ENV{qw(IFS CDPATH ENV BASH_ENV)};

        # untar test
        if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
            system(qq{pmake.bat ptar.bat});
            system(qq{ptar.bat xzvf $tardir.tar.gz});
        }
        else {
            system(qq{./pmake.bat ptar});
            system(qq{./ptar xzvf $tardir.tar.gz});
        }
    }

    # make ptar
    elsif ($target =~ /^ptar(?:\.bat)?$/) {

        my $ptar = <<'PTAR_END';
######################################################################
#
# ptar - tar of Perl Poor Tools
#
# Copyright (c) 2008, 2009, 2010, 2011, 2018, 2019, 2020, 2021, 2026 INABA Hitoshi <ina.cpan@gmail.com> in a CPAN
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

if (scalar(@ARGV) == 0) {
    die <<END;

usage: ptar xzvf file1.tar.gz file2.tar.gz ...

** This ptar supports xzvf option only. **

e(x)tract
(z)ip-file
(v)erbose
(f)ile

END
}

if ($ARGV[0] eq 'xzvf') {
    () = shift @ARGV;
}

for my $gzfile (grep m/\.tar\.gz$/xmsi, @ARGV) {

    if ($^O =~ /(?:solaris|linux)/i) {
        system(qq{gzip -cd $gzfile | tar -xvf -});
    }
    else {
        eval q{
            use Compress::Zlib;
            use Archive::Tar;
        };

        my $gz = gzopen($gzfile, 'rb');
        (my $tarfile = $gzfile) =~ s/\.gz$//xmsi;
        open(FH_TAR, ">$tarfile") || die "Can't open file: $tarfile\n";
        binmode FH_TAR;
        while ($gz->gzreadline(my $line)) {
            print FH_TAR $line;
        }
        $gz->gzclose;
        close FH_TAR;

        my $tar = Archive::Tar->new($tarfile, 1);
        for my $file ($tar->list_files){
            if (-e $file) {
                print STDERR "skip $file is already exists.\n";
            }
            else {
                print STDERR "x $file\n";
                $tar->extract($file);
            }
        }
        unlink $tarfile;
    }
}

__END__
PTAR_END

        # make ptar.bat
        if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
            open(FH_TARBAT, '>ptar.bat') || die "Can't open file: ptar.bat\n";
            print FH_TARBAT <<'END';
@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
@rem ';
#!perl
#line 14
undef @rem;
END
            print FH_TARBAT $ptar;
            print FH_TARBAT ":endofperl\n";
            close FH_TARBAT;
        }

        # make ptar
        else {
            open(FH_TARBAT, '>ptar') || die "Can't open file: ptar\n";
            print FH_TARBAT '#!', &which($^X), "\n";
            print FH_TARBAT $ptar;
            close FH_TARBAT;
            chmod 0755, 'ptar';
        }
    }

    # unzip and untar *.tar.gz
    elsif ($target =~ /^xzvf$/) {
        for my $gzfile (grep m/\.tar\.gz$/xmsi, @ARGV) {

            if ($^O =~ /(?:solaris|linux)/i) {
                system(qq{gzip -cd $gzfile | tar -xvf -});
            }
            else {
                eval q{
                    use Compress::Zlib;
                    use Archive::Tar;
                };

                my $gz = gzopen($gzfile, 'rb');
                (my $tarfile = $gzfile) =~ s/\.gz$//xmsi;
                open(FH_TAR, ">$tarfile") || die "Can't open file: $tarfile\n";
                binmode FH_TAR;
                while ($gz->gzreadline(my $line)) {
                    print FH_TAR $line;
                }
                $gz->gzclose;
                close FH_TAR;

                my $tar = Archive::Tar->new($tarfile, 1);
                for my $file ($tar->list_files){
                    if (-e $file) {
                        print STDERR "skip $file is already exists.\n";
                    }
                    else {
                        print STDERR "x $file\n";
                        $tar->extract($file);
                    }
                }
                unlink $tarfile;
            }
        }
        last;
    }

    # make pwget
    elsif ($target =~ /^pwget(?:\.bat)?$/) {

        my $pwget = <<'PWGET_END';
######################################################################
#
# pwget - wget of Perl Poor Tools
#
# Copyright (c) 2011, 2018, 2019, 2020, 2021, 2026 INABA Hitoshi <ina.cpan@gmail.com> in a CPAN
######################################################################

use Socket;

unless (@ARGV) {
    die <<END;

usage: pwget http://www.foo.com/bar/baz.tar.gz

END
}

my $url = $ARGV[0];
my $forward = 3;
while ($forward-- > 0) {
    my($hostname) = $url =~ m#http://([^/]+)/#;
    my $port = ($hostname =~ s/:([0-9]+)//) ? $1 : 80;

    socket(SOCKET,PF_INET,SOCK_STREAM,getprotobyname('tcp')) || die "Can't open TCP/IP socket.\n";
    connect(SOCKET,sockaddr_in($port,inet_aton($hostname)))  || die "Can't connect to $hostname:$port.\n";
    select SOCKET;
    $| = 1;
    select STDOUT;

    my $request = <<END;
GET $url HTTP/1.0
Accept: */*
User-Agent: $0

END
    $request =~ s/\n/\r\n/g;
    print SOCKET $request;

    my($head,$body) = split(/\r\n\r\n/,join('',<SOCKET>),2);
    close SOCKET;

    if ($head =~ m#^Location: (\S+)#ms) {
        $url = $1;
        print STDERR "Location: $url\n";
        next;
    }

    my($file) = $ARGV[0] =~ m#([^/]+)$#;
    open(FILE,">$file") || die "Can't open file: $file\n";
    binmode FILE;
    print FILE $body;
    close FILE;
    if ($head =~ m#Content-Length: ([0-9]+)#ms) {
        if (-s $file == $1) {
            print STDERR "ok - $file\n";
        }
        else {
            print STDERR "not ok - $file\n";
            unlink $file;
        }
    }
    last;
}

__END__
PWGET_END

        # make pwget.bat
        if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
            open(FH_WGETBAT, '>pwget.bat') || die "Can't open file: pwget.bat\n";
            print FH_WGETBAT <<'END';
@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
@rem ';
#!perl
#line 14
undef @rem;
END
            print FH_WGETBAT $pwget;
            print FH_WGETBAT ":endofperl\n";
            close FH_WGETBAT;
        }

        # make pwget
        else {
            open(FH_WGETBAT, '>pwget') || die "Can't open file: pwget\n";
            print FH_WGETBAT '#!', &which($^X), "\n";
            print FH_WGETBAT $pwget;
            close FH_WGETBAT;
            chmod 0755, 'pwget';
        }
    }
    # pmake selfcheck [--check1] [--check2]
    elsif ($target eq 'selfcheck') {
        my $do_check1 = 0;
        my $do_check2 = 0;
        for my $arg (@ARGV) {
            $do_check1 = 1 if $arg eq '--check1';
            $do_check2 = 1 if $arg eq '--check2';
        }
        # Default: both checks enabled when no flag is given
        if (!$do_check1 && !$do_check2) {
            $do_check1 = 1;
            $do_check2 = 1;
        }
        _selfcheck($do_check1, $do_check2);
        last;
    }
    else {
        warn "unknown target: $target.\n";
    }
}

sub which {
    if ($_[0] =~ m#\A / #oxms) {
        return $_[0];
    }
    else {
        for my $path (split(/:/,$ENV{'PATH'})) {
            if (-e qq{$path/$_[0]}) {
                return qq{$path/$_[0]};
            }
        }
        return $_[0];
    }
}

# Test::Harness::runtests cannot work heavy load.
sub _runtests {
    my @script = @_;
    my @fail_testno = ();
    my $ok_script = 0;
    my $not_ok_script = 0;
    my $total_ok = 0;
    my $total_not_ok = 0;
    my $total_skip = 0;

    # cygwin warning:
    #   MS-DOS style path detected: C:/cpan/Char-X.XX
    #   Preferred POSIX equivalent is: /cygdrive/c/cpan/Char-X.XX
    #   CYGWIN environment variable option "nodosfilewarning" turns off this warning.
    #   Consult the user's guide for more details about POSIX paths: #'
    #     http://cygwin.com/cygwin-ug-net/using.html#using-pathnames

    if (exists $ENV{'CYGWIN'}) {
        if ($ENV{'CYGWIN'} !~ /\b nodosfilewarning \b/x) {
            $ENV{'CYGWIN'} = join(' ', $ENV{'CYGWIN'}, 'nodosfilewarning');
        }
    }

    my $start_time = time();
    my $scriptno = 0;
    for my $script (@script) {
        next if not -e $script;

        my $ok = 0;
        my $not_ok = 0;
        my $skip = 0;
        if (my @result = qx{$^X $script}) {
            if (my($tests) = shift(@result) =~ /^1..([0-9]+)/) {
                for my $result (@result) {
                    # Read TAP test number directly to avoid offset from comment lines
                    if ($result =~ /^ok (\d+)/) {
                        my $tapno = $1;
                        if ($result =~ /\bSKIP\b/i) {
                            $skip++;
                        }
                        else {
                            $ok++;
                        }
                    }
                    elsif ($result =~ /^not ok (\d+)/) {
                        my $tapno = $1;
                        push @{$fail_testno[$scriptno]}, $tapno;
                        $not_ok++;
                    }
                    # TAP comment lines (^#) and other lines are silently ignored
                }
                if ($not_ok == 0) {
                    if ($skip > 0) {
                        printf("$script ok (skipped: %d)\n", $skip);
                    }
                    else {
                        printf("$script ok\n");
                    }
                    $ok_script++;
                }
                else {
                    printf("$script Failed %d/%d subtests\n", $not_ok, $ok+$not_ok+$skip);
                    $not_ok_script++;
                }
            }
        }
        $total_ok   += $ok;
        $total_not_ok += $not_ok;
        $total_skip += $skip;
        $scriptno++;
    }

    my $elapsed = time() - $start_time;

    if (scalar(@script) == $ok_script) {
        my $skip_msg = $total_skip > 0 ? " (skipped: $total_skip)" : '';
        printf("All tests successful.\n");
        printf("Files=%d, Tests=%d%s, %d wallclock secs\n",
            scalar(@script), $total_ok + $total_not_ok + $total_skip,
            $skip_msg, $elapsed);
        printf("Result: PASS\n");
    }
    else {
        print "\nTest Summary Report\n-------------------\n";
        my $scriptno = 0;
        for my $fail_testno (@fail_testno) {
            if (defined $fail_testno) {
                print $script[$scriptno], "\n";
                print '  Failed test:  ', join(', ', @{$fail_testno[$scriptno]}), "\n";
            }
            $scriptno++;
        }
        printf("Files=%d, Tests=%d, %d wallclock secs\n",
            scalar(@script), $total_ok + $total_not_ok + $total_skip, $elapsed);
        printf("Result: FAIL\n");
        printf("Failed %d/%d test programs. %d/%d subtests failed.\n",
            $not_ok_script, scalar(@script),
            $total_not_ok, $total_ok + $total_not_ok + $total_skip);
    }
}

######################################################################
# selfcheck: Perl 5.5.3 compat (--check1) and coding style (--check2)
#
# These routines check pmake.bat itself.
# All TAP harness, slurp, and scanner logic is embedded here
# so that no external modules beyond core are required.
######################################################################

# --- Embedded TAP harness (no Test::Simple / Test::More) ---

my ($SC_PLAN, $SC_RUN, $SC_FAIL) = (0, 0, 0);

sub _sc_plan {
    ($SC_PLAN, $SC_RUN, $SC_FAIL) = ($_[0], 0, 0);
    print "1..$SC_PLAN\n" if 0;
}

sub _sc_ok {
    my ($ok, $name) = @_;
    $SC_RUN++;
    $SC_FAIL++ unless $ok;
    if (not $ok) {
        print +($ok ? '' : 'not ') . "ok $SC_RUN"
            . (defined $name && length $name ? " - $name" : '') . "\n";
    }
    return $ok;
}

sub _sc_diag {
    for my $line (@_) {
        print "# $line\n";
    }
}

# --- File utilities ---

sub _sc_slurp {
    my ($path) = @_;
    local *SC_FH;
    open SC_FH, "< $path" or return '';
    local $/;
    my $c = <SC_FH>;
    close SC_FH;
    return defined $c ? $c : '';
}

sub _sc_slurp_lines {
    my ($path) = @_;
    local *SC_FH;
    open SC_FH, "< $path" or return ();
    my @lines = <SC_FH>;
    close SC_FH;
    return @lines;
}

# Mask here-document bodies, blanking each body line while keeping the
# introducer and terminator lines so that line numbers are preserved.
#
# Knowledge carried over from Perl500503Syntax::OrDie: a here-doc body is
# data, not code, and may legitimately contain post-5.005_03 example text
# (<<>>, $+[N], //=, signatures, ...). Left unmasked, such text leaks into
# the P/C/E/K scans and is wrongly reported. Two or more here-docs may
# share one introducer line (e.g. "$_ = <<'A'; $x = <<'B';"), so every
# sentinel is queued at its '<<' operator and all queued bodies are
# consumed, in order, before the next introducer line is processed.
#
# Only genuine here-doc forms are recognized -- <<'TAG', <<"TAG" (space
# allowed before the quote) and the adjacent bareword <<TAG whose TAG
# starts with a letter or underscore. This deliberately ignores the
# left-shift operator ($x << 2, $x <<= 1, $x << $y), which never starts a
# here-doc. The indented <<~ form is post-5.005_03 and is not produced by
# ina@CPAN code, so terminators are matched at column zero.
sub _sc_mask_heredocs {
    my ($text) = @_;
    my @in    = split /\n/, $text, -1;
    my @out   = ();
    my @queue = ();
    my $line;
    for $line (@in) {
        if (@queue) {
            my $tag = $queue[0];
            if ($line =~ /^\Q$tag\E\r?\z/) {
                shift @queue;
                push @out, $line;
            }
            else {
                push @out, '';
            }
            next;
        }
        # Detect here-doc introducers on this line, in order. A '#' comment
        # tail is removed first so a commented-out '<<WORD' is not mistaken
        # for an introducer; quotes are left intact because the TAG itself
        # may be quoted.
        my $probe = $line;
        $probe =~ s/\#.*\z//;
        while ($probe =~ /<<(?:\s*'(\w+)'|\s*"(\w+)"|(\w+))/g) {
            my $tag = defined $1 ? $1 : defined $2 ? $2 : $3;
            if (defined $3) {
                next unless $3 =~ /^[A-Za-z_]/;
            }
            push @queue, $tag;
        }
        push @out, $line;
    }
    return join "\n", @out;
}

# Strip here-doc bodies, __END__, POD, string literals, regexes, inline
# comments from code.  Returns cleaned text suitable for pattern matching.
# Here-doc bodies are masked first so that body text such as "__END__" or
# "=pod" cannot derail the __END__ / POD strippers that follow.
sub _sc_clean_code {
    my ($text) = @_;
    $text = _sc_mask_heredocs($text);
    $text =~ s/\n__END__\b.*\z//s;
    $text =~ s/^=[a-zA-Z].*?^=cut[ \t]*$//msg;
    return $text;
}

# Scan cleaned code line-by-line; return list of {line=>N, text=>STR} hits.
sub _sc_scan {
    my ($text, $pattern) = @_;
    my @hits;
    my $lineno = 0;
    for my $line (split /\n/, $text) {
        $lineno++;
        next if $line =~ /^\s*#/;
        my $clean = $line;
        $clean =~ s/'(?:[^'\\]|\\.)*'/''/g;
        $clean =~ s/"(?:[^"\\]|\\.)*"/""/g;
        # s///, m//, qr// are quote-like operators only when not preceded by
        # an identifier character, '*', '&', ':' or "'": e.g. "keys/2/",
        # "&s/...", "*s{...}", "Foo::s" and the apostrophe package separator
        # "jcode's" must NOT be stripped as quote-like. (Knowledge carried
        # over from Perl500503Syntax::OrDie.)
        $clean =~ s{(?<![\w*&:'])(?:s|m|qr)/[^/]*/[^/]*/[gimsex]*}{}g;
        $clean =~ s{/[^/]+/[gimsex]*}{}g;
        $clean =~ s/#.*$//;
        if ($clean =~ $pattern) {
            push @hits, { line => $lineno, text => $line };
        }
    }
    return @hits;
}

######################################################################
# Check 1: Perl 5.005_03 compatibility (P1-P12)
######################################################################

sub _selfcheck_p1p12 {
    my ($path, $code, $label) = @_;
    my $guarded = ($code =~ /if\s*\(\s*\$\]\s*>=\s*5\./);

    # P1: no bare 'use 5.006+'
    _sc_ok($code !~ /^\s*use\s+5\.0*[6-9][0-9]*\b/m,
        "$label P1: no bare use 5.006+");

    # P2: 3-arg open guarded or absent
    my $has_3arg = ($code =~ /\bopen\s*\(\s*(?:(?:my\s+)?\$\w+|[A-Z_][A-Z0-9_]*)\s*,\s*['"](?:>>?|<<?|\+>|\+<)['"]\s*,/);
    _sc_ok(!$has_3arg || $guarded,
        "$label P2: 3-arg open guarded or absent");

    # P3: open(my $fh...) guarded or absent
    do {
        # Scan per line, skipping comment lines and stripping quoted
        # strings, so the checker's own descriptive comments and message
        # strings are not mistaken for executable open(my $fh...) calls.
        # (Masking discipline carried over from Perl500503Syntax::OrDie.)
        my $has_lex = 0;
        for my $l (split /\n/, $code) {
            next if $l =~ /^\s*#/;
            my $s = $l;
            $s =~ s/'(?:[^'\\]|\\.)*'/''/g;
            $s =~ s/"(?:[^"\\]|\\.)*"/""/g;
            $s =~ s/#.*$//;
            if ($s =~ /\bopen\s*[\(\s]\s*my\s+\$\w+/) { $has_lex = 1; last }
        }
        _sc_ok(!$has_lex || $guarded,
            "$label P3: open(my \$fh...) guarded or absent");
    };

    # P4: use warnings guarded
    _sc_ok($code !~ /^\s*use\s+warnings\s*;/m
        || $code =~ /BEGIN\s*\{[^}]*warnings/,
        "$label P4: use warnings guarded");

    # P5: qr// informational (always pass)
    _sc_ok(1, "$label P5: qr// informational (always pass)");

    # P6: use parent/base guarded or absent
    _sc_ok($code !~ /^\s*use\s+(?:parent|base)\b/m || $guarded,
        "$label P6: use parent/base guarded or absent");

    # P7: no bare 'our' declaration
    _sc_ok($code !~ /^\s*our\s+[\$\@\%][A-Za-z]/m,
        "$label P7: no bare 'our' declaration");

    # P8: no //= operator (Perl 5.10+)
    do {
        # Scan per line with single/double-quoted strings and trailing
        # comments removed so that "//=" appearing inside a string literal
        # or a URL-like "://" is not mistaken for the 5.10 //= operator.
        my $p8_fail = 0;
        for my $p8_line (split /\n/, $code) {
            next if $p8_line =~ /^\s*#/;
            my $s = $p8_line;
            $s =~ s/'(?:[^'\\]|\\.)*'/''/g;
            $s =~ s/"(?:[^"\\]|\\.)*"/""/g;
            $s =~ s/#.*$//;
            next if $s =~ m{://};
            # Built from single characters so this detector does not itself
            # contain a literal defined-or-assignment token in its source.
            if (index($s, '/' . '/' . '=') >= 0) { $p8_fail = 1; last }
        }
        _sc_ok(!$p8_fail,
            "$label P8: no //= operator (Perl 5.10+)");
    };

    # P9: opendir(my $dh...) guarded or absent
    do {
        my $has_od_lex = 0;
        for my $l (split /\n/, $code) {
            next if $l =~ /^\s*#/;
            my $s = $l;
            $s =~ s/'(?:[^'\\]|\\.)*'/''/g;
            $s =~ s/"(?:[^"\\]|\\.)*"/""/g;
            $s =~ s/#.*$//;
            if ($s =~ /\bopendir\s*[\(\s]+my\s+\$/) { $has_od_lex = 1; last }
        }
        _sc_ok(!$has_od_lex || $guarded,
            "$label P9: opendir(my \$dh...) guarded or absent");
    };

    # P10: no bare say (Perl 5.10+)
    _sc_ok($code !~ /^\s*say\s/m && $code !~ /[;{(]\s*say\s/m,
        "$label P10: no bare say (Perl 5.10+)");

    # P11: no state variable (Perl 5.10+)
    _sc_ok($code !~ /\bstate\s+[\$\@\%]/m,
        "$label P11: no state variable (Perl 5.10+)");

    # P12: // defined-or guarded or absent
    do {
        # Mask single/double-quoted strings and trailing comments before
        # scanning, so a literal "//" appearing inside a string (e.g. a
        # diagnostic message such as "no defined-or // operator") is not
        # mistaken for the 5.10 defined-or operator. (Masking discipline
        # carried over from P8 and Perl500503Syntax::OrDie.)
        my $p12_fail = 0;
        for my $p12_line (split /\n/, $code) {
            next if $p12_line =~ /^\s*#/;
            my $s = $p12_line;
            $s =~ s/'(?:[^'\\]|\\.)*'/''/g;
            $s =~ s/"(?:[^"\\]|\\.)*"/""/g;
            $s =~ s/#.*$//;
            next if $s =~ /=~\s*[sm]?\//;
            # split/grep/map are regex-introducing list operators: an empty
            # pattern (as the first argument) immediately after one of them
            # is a pattern, never the 5.10 defined-or operator. (Knowledge
            # carried over from Perl500503Syntax::OrDie.)
            next if $s =~ /\b(?:split|grep|map)\s*\/\//;
            next if $s =~ m{://};
            if ($s =~ m{\s//[^/=]}) { $p12_fail = 1; last }
        }
        _sc_ok(!$p12_fail || $guarded,
            "$label P12: defined-or operator guarded or absent");
    };
}

######################################################################
# Check 2: ina@CPAN coding style (C-subset + E + K1-K3)
######################################################################

sub _selfcheck_style {
    my ($path, $raw_text, $code, $label) = @_;

    # C1: US-ASCII only (entire file, raw bytes)
    do {
        local *SC_ASCII_FH;
        my $bad = 0;
        if (open SC_ASCII_FH, "< $path") {
            binmode SC_ASCII_FH;
            while (<SC_ASCII_FH>) {
                if (/[^\x00-\x7F]/) { $bad = 1; last }
            }
            close SC_ASCII_FH;
        }
        else {
            $bad = 1;
        }
        _sc_ok(!$bad, "$label C1: US-ASCII only");
    };

    # C2: no trailing whitespace
    do {
        my @lines = split /\n/, $raw_text;
        my @bad;
        my $n = 0;
        for my $line (@lines) {
            $n++;
            # A 0x20/0x09 byte at end of line may be the trailing byte of a
            # double-byte (Shift_JIS/EUC-JP/...) character rather than real
            # whitespace, so the byte pattern /[ \t]+$/ is unreliable on
            # non-US-ASCII lines; skip them. (Knowledge carried over from
            # Perl500503Syntax::OrDie; ina@CPAN sources are US-ASCII by the
            # C1 house rule, so this only affects external multibyte files.)
            next if $line =~ /[^\x00-\x7F]/;
            push @bad, $n if $line =~ /[ \t]+\r?$/;
        }
        _sc_ok(!@bad,
            "$label C2: no trailing whitespace"
            . (@bad ? " (lines: @bad[0..(@bad<3?$#bad:2)])" : ''));
    };

    # C3: ends with newline
    _sc_ok(length($raw_text) && substr($raw_text, -1) eq "\n",
        "$label C3: ends with newline");

    # E: no '} else/elsif' on same line
    do {
        my @hits = _sc_scan($code, qr/^\s*\}\s*els(?:e|if)\b/);
        _sc_ok(!@hits,
            "$label E: no '} else/elsif' on same line"
            . (@hits ? " (lines: " . join(', ', map { $_->{line} } @hits[0..(@hits<3?$#hits:2)]) . ")" : ''));
    };

    # K1: comma followed by space
    do {
        my @k1_bad;
        my $lineno = 0;
        for my $raw_line (split /\n/, $code) {
            $lineno++;
            my $s = $raw_line;
            $s =~ s/^\s*#.*$//; next unless $s =~ /\S/;
            $s =~ s/'(?:[^'\\]|\\.)*'/''/g;
            $s =~ s/"(?:[^"\\]|\\.)*"/""/g;
            # Also strip q{} and qq{} literals (content may contain commas)
            $s =~ s/\bqq\{[^}]*\}/""/g;
            $s =~ s/\bq\{[^}]*\}/''/g;
            $s =~ s{(?<![\w*&:'])(?:s|m|qr|split\s*/)[^/]*/[^/]*/[gimsex]*}{}g;
            $s =~ s{/[^/]+/[gimsex]*}{}g;
            $s =~ s/#.*$//;
            # Allow comma immediately before $ (variable) or '' "" (empty string after strip)
            # and before quote characters (residue of stripped strings)
            if ($s =~ /,(?=[^\s\n\)\]\}\/'"\$])/) {
                push @k1_bad, $lineno;
            }
        }
        _sc_ok(!@k1_bad,
            "$label K1: comma followed by space"
            . (@k1_bad ? " (lines: @k1_bad[0..(@k1_bad<3?$#k1_bad:2)])" : ''));
    };

    # K2: \@array should be [ @array ]
    do {
        my @k2_bad;
        my $lineno = 0;
        for my $line (split /\n/, $code) {
            $lineno++;
            next if $line =~ /^\s*#/;
            my $cl = $line;
            $cl =~ s/'[^']*'//g; $cl =~ s/"[^"]*"//g;
            $cl =~ s/#.*$//;
            if ($cl =~ /(?:push|unshift|return|=)\s*\\\@\w/) {
                push @k2_bad, $lineno;
            }
        }
        _sc_ok(!@k2_bad,
            "$label K2: use [ \@array ] instead of \\\@array"
            . (@k2_bad ? " (lines: @k2_bad[0..(@k2_bad<3?$#k2_bad:2)])" : ''));
    };

    # K3: \%hash should be { %hash }  (exempt: \%env \%opts \%args)
    do {
        my $k3_exempt = 'env\b|opts\b|args\b';
        my @k3_bad;
        my $lineno = 0;
        for my $line (split /\n/, $code) {
            $lineno++;
            next if $line =~ /^\s*#/;
            my $cl = $line;
            $cl =~ s/'[^']*'//g; $cl =~ s/"[^"]*"//g;
            $cl =~ s/#.*$//;
            if ($cl =~ /\\\%(?!$k3_exempt)\w+/) {
                push @k3_bad, $lineno;
            }
        }
        _sc_ok(!@k3_bad,
            "$label K3: use { \%hash } instead of \\\%hash"
            . (@k3_bad ? " (lines: @k3_bad[0..(@k3_bad<3?$#k3_bad:2)])" : ''));
    };
}

######################################################################
# _selfcheck: entry point called by 'pmake selfcheck'
######################################################################

######################################################################
# _dist_check_sources: called from 'pmake dist' to check MANIFEST
# source files with check1 (Perl 5.5.3 compat) and/or check2 (style).
# Dies on any failure to abort dist.
######################################################################

sub _dist_check_sources {
    my ($files_ref, $do_check1, $do_check2) = @_;
    return unless $do_check1 || $do_check2;

    # Target: lib/*.pm, lib/*.pl, t/*.t, xt/*.t, eg/*.pl, bin/*.pl, bin/*.pm
    my @targets = grep {
        /^lib\/.*\.(pm|pl)$/i
        || /^t\/.*\.t$/i
        || /^xt\/.*\.t$/i
        || /^eg\/.*\.pl$/i
        || /^bin\/.*\.(pl|pm)$/i
    } @{$files_ref};
    @targets = grep { -f $_ } @targets;

    return unless @targets;

    my $total = scalar(@targets) * (($do_check1 ? 12 : 0) + ($do_check2 ? 7 : 0));
    print STDERR "pmake dist: running selfcheck on " . scalar(@targets) . " source file(s)...\n";

    $SC_PLAN = 0; $SC_RUN = 0; $SC_FAIL = 0;
    _sc_plan($total);

    for my $f (sort @targets) {
        my $raw_text = _sc_slurp($f);
        unless (length $raw_text) {
            print STDERR "# WARNING: cannot read $f, skipping\n";
            next;
        }
        my $code  = _sc_clean_code($raw_text);
        my $label = $f;
        _selfcheck_p1p12($f, $code, $label) if $do_check1;
        _selfcheck_style($f, $raw_text, $code, $label) if $do_check2;
    }

    if ($SC_FAIL) {
        printf STDERR ("pmake dist: selfcheck FAIL -- %d/%d tests failed.\n",
            $SC_FAIL, $SC_RUN);
        die "pmake dist aborted: source check failed.\n";
    }
    else {
        printf STDERR ("pmake dist: selfcheck PASS -- %d/%d ok.\n",
            $SC_RUN, $SC_RUN);
    }
}

sub _selfcheck {
    my ($do_check1, $do_check2) = @_;

    # Resolve path to this script
    my $path = $0;
    # On Windows, perl -x -S sets $0 to the script name; use FindBin as fallback
    unless (-f $path) {
        $path = "$FindBin::RealBin/$FindBin::RealScript";
    }
    $path =~ s{\\}{/}g;

    my $raw_text = _sc_slurp($path);
    unless (length $raw_text) {
        print "# Cannot read $path\n";
        print "1..0 # SKIP cannot read script file\n";
        return;
    }
    my $code = _sc_clean_code($raw_text);

    my $label  = 'pmake.bat';
    my $n_p1p12 = 12;    # P1-P12
    my $n_style = 7;     # C1+C2+C3+E+K1+K2+K3

    my $total = 0;
    $total += $n_p1p12 if $do_check1;
    $total += $n_style if $do_check2;

    _sc_plan($total);

    if ($do_check1) {
        _sc_diag("--- Check 1: Perl 5.005_03 compatibility (P1-P12) ---");
        _selfcheck_p1p12($path, $code, $label);
    }
    if ($do_check2) {
        _sc_diag("--- Check 2: ina\@CPAN coding style (C1-C3, E, K1-K3) ---");
        _selfcheck_style($path, $raw_text, $code, $label);
    }

    if ($SC_FAIL) {
        printf("# Result: FAIL (%d/%d failed)\n", $SC_FAIL, $SC_RUN);
        exit 1;
    }
    else {
        printf("# Result: PASS (%d/%d ok)\n", $SC_RUN, $SC_RUN);
        exit 0;
    }
}

sub check_usascii {
    my($file) = @_;
    if (open(FILE,$file)) {
        while (<FILE>) {
            if (not /^[\x0A\x20-\x7E]+$/) {
                die "error not US-ASCII: $file, q(;_;)bad!!";
            }
        }
        close(FILE);
    }
    else {
        die "error open: $file, q(;_;)bad!!";
    }
}

__END__

=pod

=head1 NAME

pmake - make of Perl Poor Tools

=head1 SYNOPSIS

  pmake.bat
  pmake.bat test
  pmake.bat xtest
  pmake.bat install
  pmake.bat dist
  pmake.bat ptar
  pmake.bat xzvf
  pmake.bat pwget
  pmake.bat selfcheck
  pmake.bat selfcheck --check1
  pmake.bat selfcheck --check2

=head1 ABSTRACT

pmake.bat is a portable Perl-based build tool used across ina's CPAN
distributions. It provides test, xtest, install, dist, ptar, xzvf, and
pwget targets, requiring only core Perl modules.

This distribution is the canonical unified source for pmake.bat, replacing
the per-distribution copies formerly shipped inside each ina CPAN package.

=head1 DEPENDENCIES

This software requires perl5.00503 or later.

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt> in a CPAN

This project was originated by INABA Hitoshi.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

:endofperl
