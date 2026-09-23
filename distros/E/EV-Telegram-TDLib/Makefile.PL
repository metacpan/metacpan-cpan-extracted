use strict;
use warnings;
use Config;
use File::Spec;
use File::Temp ();
use ExtUtils::MakeMaker;
use EV::MakeMaker;
use Alien::TDLib;

# "OS unsupported" and a Makefile-less exit 0 is what a smoker reads as "this
# distribution cannot run here", which is the honest grade for both checks
# below. Dying instead is graded as a broken distribution.
if ($Config{ivsize} < 8) {
    warn "OS unsupported: EV::Telegram::TDLib needs a perl with 64-bit "
       . "integers (ivsize=$Config{ivsize}); Telegram message ids do not "
       . "fit in an NV\n";
    exit 0;
}

# tdpump.h needs C11 atomics. Appending -std=gnu11 unconditionally, as this
# used to, fails the build outright on a compiler that does not know the
# option -- and a build failure is graded as a broken distribution rather
# than as one that cannot be built here. Probe for what is actually needed:
# nothing at all on a compiler whose default is C11 or later.
sub _c11_ok {
    my ($extra) = @_;
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $src = File::Spec->catfile($dir, 'probe.c');
    open my $fh, '>', $src or return 0;
    print {$fh} <<'PROBE';
#include <stdatomic.h>
// a line comment, as TDLib's own public header uses
static _Atomic int flag;
int main(void) { atomic_store(&flag, 1); return atomic_load(&flag) - 1; }
PROBE
    close $fh or return 0;
    my $obj = File::Spec->catfile($dir, "probe$Config{obj_ext}");
    my $out = `$Config{cc} $Config{ccflags} $extra -c -o "$obj" "$src" 2>&1`;
    return ($? == 0 && -s $obj) ? 1 : 0;
}

my $cstd = '';
unless (_c11_ok('')) {
    ($cstd) = grep { _c11_ok($_) } qw(-std=gnu11 -std=c11);
    unless (defined $cstd) {
        warn "OS unsupported: this compiler cannot build C11 atomics "
           . "(<stdatomic.h> and _Atomic), which the TDLib reader thread "
           . "needs\n";
        exit 0;
    }
}

# The shipped catalogue, the POD's factual claims and the thread-local
# buffer assumption in CAVEATS are all tied to one TDLib version, but the pin
# lives in Alien::TDLib -- another distribution, which can move without this
# one changing at all. Warn rather than die: an unknown function still passes
# through, so a mismatch is a reason to re-verify, not to refuse to build.
{
    my $want = do {
        my $v;
        if (open my $fh, '<', 'lib/EV/Telegram/TDLib/Schema.pm') {
            while (<$fh>) { $v = $1, last if /\$TDLIB_VERSION\s*=\s*'([^']+)'/ }
        }
        $v;
    };
    my $got = eval { Alien::TDLib->version };
    warn "*** This build uses TDLib $got, but the shipped schema catalogue\n"
       . "*** was generated from $want. Unknown functions still pass through,\n"
       . "*** but re-check the pinned assumptions in CAVEATS.\n"
        if defined $want && defined $got && $want ne $got;
}

my %ev = EV::MakeMaker::ev_args();

WriteMakefile(
    NAME             => 'EV::Telegram::TDLib',
    VERSION_FROM     => 'lib/EV/Telegram/TDLib.pm',
    ABSTRACT         => 'asynchronous Telegram client on TDLib and EV',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.012',
    XS               => { 'TDLib.xs' => 'TDLib.c' },
    OBJECT           => 'TDLib$(OBJ_EXT)',
    INC              => Alien::TDLib->cflags . ' ' . $ev{INC},
    LIBS             => [ Alien::TDLib->libs . ' -lpthread' ],
    CCFLAGS          => join(' ', $Config{ccflags}, $cstd ? $cstd : ()),
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
        'EV::MakeMaker'       => 0,
        'Alien::TDLib'        => 0,
    },
    # Alien::TDLib is deliberately absent: it is needed to configure and
    # build, where CONFIGURE_REQUIRES asks for it, and TDLib is linked
    # statically, so nothing loads it at runtime.
    PREREQ_PM => {
        'EV'               => '4.11',
        'Cpanel::JSON::XS' => '4.00',
        # core since well before the perl floor, but declared because the
        # module uses them
        'Carp'             => 0,
        'Encode'           => 0,
        'MIME::Base64'     => 0,
        'Scalar::Util'     => 0,
        'XSLoader'         => 0,
    },
    TEST_REQUIRES => { 'Test::More' => '0.98' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        # xt ships a helper module in its own top-level namespace; provides
        # already pins what gets indexed, and this makes doubly sure
        no_index => { directory => [ 'xt' ] },
        # xt/ ships, so say what running it needs; smokers never do
        prereqs => {
            develop => {
                requires => {
                    'Test::Pod'             => '1.41',
                    'Test::Kwalitee::Extra' => 0,
                    'JSON::PP'              => 0,
                    'Alien::TDLib'          => 0,
                },
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-ev-telegram-tdlib.git',
                web  => 'https://github.com/vividsnow/perl5-ev-telegram-tdlib',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-ev-telegram-tdlib/issues',
            },
        },
        provides => {
            'EV::Telegram::TDLib' => {
                file    => 'lib/EV/Telegram/TDLib.pm',
                version => MM->parse_version('lib/EV/Telegram/TDLib.pm'),
            },
            map {
                +("EV::Telegram::TDLib::$_" => {
                    file    => "lib/EV/Telegram/TDLib/$_.pm",
                    version => MM->parse_version('lib/EV/Telegram/TDLib.pm'),
                })
            } qw(Users Chats Messages Files Connection Bots
                 WebApps Forum Folders Payments Secret Stories Stickers Stars
                 Business Schema),
        },
    },
);

sub MY::postamble {
    return <<"MAKE";
README : lib/EV/Telegram/TDLib.pm
	pod2text lib/EV/Telegram/TDLib.pm > README

# create_distdir, not distdir: make appends to EUMM's own
# "distdir : create_distdir distmeta", so hanging README off distdir
# regenerates it after manicopy has already taken the stale one
create_distdir : README

MAKE
}
