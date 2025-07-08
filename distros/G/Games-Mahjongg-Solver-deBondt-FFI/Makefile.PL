use ExtUtils::MakeMaker;
use File::Basename qw(dirname);
use File::Spec;
use strict;
use File::Path qw(make_path); unless (-e "ffi") { make_path("ffi") or die "could not mkdir ffi: $$!"; }

my $version_diff = 0; # we'll have to die if this becomes true
my $version_from;
my $trial = 0;
my $version;
{
  local $^W;
  $ExtUtils::MakeMaker::VERSION = eval $ExtUtils::MakeMaker::VERSION;
}
$version_from = File::Spec->catfile(split m{/}, "lib/Games/Mahjongg/Solver/deBondt/FFI.pm");
unshift @INC, "lib";
my $version = MM->parse_version($version_from); # MM is in MakeMaker
if ($trial) {
    $version .= "-TRIAL";
    if ($trial > 1) {
        $version .= $trial;
    }
}
{
    my $version_set_manually = 1;
    if ($ARGV[0] && $ARGV[0] eq "--setversion") {
        require Module::Signature;
        die "Your Module::Signature is a bit dated[$Module::Signature::VERSION].\nDo not make a release with it\n"
            if $Module::Signature::VERSION < 0.83;
        shift @ARGV;
        my $st;
        local $ENV{LANG} = "C";
        my $dirty = `git status --porcelain --untracked-files=no`;
        die "Not everything checked in or out?\n====\n$dirty====\n" if $dirty;

        if ($version_set_manually) {
            # we must control that the VERSION in this .pm is the same as in the Makefile
            open my $fh, "make the-release-name|" or die;
            my $have_version;
            while (<$fh>) {
                next unless /^version\s+([\d\._]+(?:-TRIAL)?)/;
                $have_version = $1;
            }
        }
        exit unless $version_diff;
    }
}
my @sign = (MM->can("signature_target") ? (SIGN => 1) : ());

use FFI::Build::MM;
my $fbmm = FFI::Build::MM->new;
WriteMakefile(
    $fbmm->mm_args(
        AUTHOR    => 'Andreas Koenig <andk@cpan.org>',
        ABSTRACT_FROM  => $version_from, # retrieve abstract from module
        NAME      => 'Games::Mahjongg::Solver::deBondt::FFI',
        DISTNAME  => 'Games-Mahjongg-Solver-deBondt-FFI',
        VERSION   => $version,
        PREREQ_PM => {
            'FFI::Platypus'            => 1,
            'FFI::Platypus::Lang::CPP' => 1,
            'FFI::Platypus::Memory'    => 0,
            'FFI::CheckLib'            => 0,
            'File::Path'               => 0,
        },
        TEST_REQUIRES => {
            'Test::More'            => 0,
            'YAML::XS'              => 0,
        },
        CONFIGURE_REQUIRES => {
            'FFI::Build::MM'           => 0,
        },
        META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository => {
                    repository => 'https://github.com/andk/Games-Mahjongg-Solver-deBondt-FFI',
                    type => 'git',
                    url => 'git://github.com/andk/Games-Mahjongg-Solver-deBondt-FFI.git',
                    web => 'https://github.com/andk/Games-Mahjongg-Solver-deBondt-FFI'
                },
                bugtracker => {
                    url => 'https://github.com/andk/Games-Mahjongg-Solver-deBondt-FFI/issues',
                    web => 'https://github.com/andk/Games-Mahjongg-Solver-deBondt-FFI/issues',
                }
            },
        },
        @sign,
        dist => {
            DIST_DEFAULT => join(" ", # note: order matters!
                                 "verify-no-subdir",
                                 "verify-changes-date",
                                 "verify-changes-version",
                                 "Makefile",
                                 "META.yml",
                                 "setversion",
                                 "all",
                                 "tardist",
                             ),
            COMPRESS => 'gzip -9',
         },
     )
);

if ($version_diff){
  die "
==> I had to update some \$VERSIONs <==
==> Your Makefile has been rebuilt. <==
==> Please rerun the make command.  <==
";
}

package MY;
sub top_targets {
    my $self = shift;
    my @m;
    push @m, $self->SUPER::top_targets;
    push @m, q{
pure_all :: ffi/mjsolver_ffi.cpp

ffi/mjsolver_ffi.cpp : mjsolver.cpp.in ffi.cpp.in
	$(PERL) -e 'use File::Path qw(make_path); exit if -e "ffi"; make_path("ffi") or die "could not mkdir ffi: $$!"'
	@echo '#define QUARTER' > $@
	$(PERL) -ple 's/\cM//' mjsolver.cpp.in >> $@
	$(PERL) -ple '' ffi.cpp.in >> $@
};
    return join "", @m;
}

sub postamble {
    my @m;
    push @m, $fbmm->mm_postamble;
    push @m, q{
OKDIRS=ffi|lib|t

verify-no-subdir:
	@$(PERL) -e 'my$$s=join",",grep{!/^($(OKDIRS))\z/x&&-d($$_)}glob"*";' \
		-e 'die"unexpected dir:$$s"if$$s'

verify-changes-date:
	@$(PERL) -ne 'BEGIN{my@t=(localtime)[5,4,3];$$t[0]+=1900;$$t[1]++;$$t=sprintf"%04d-%02d-%02d",@t}' \
		-e '$$ok++,exit if /^$$t\s/; END{die "Alert: did not find <$$t> in Changes file" unless $$ok}' Changes

verify-changes-version:
	@$(PERL) -ne '$$ok++,exit if /\b$(VERSION)\b/; END{die "Alert: did not find <$(VERSION)> in Changes file" unless $$ok}' Changes

META.yml: metafile
	$(CP) $(DISTVNAME)/META.yml  ./META.yml
	-$(CP) $(DISTVNAME)/META.json  ./META.json

setversion:
	$(PERL) Makefile.PL --setversion

the-release-name :
	$(NOECHO) $(ECHO) 'version ' $(VERSION)
	$(NOECHO) $(ECHO) 'release-name ' $(DISTVNAME).tar$(SUFFIX)


};
    join "", @m;
}
