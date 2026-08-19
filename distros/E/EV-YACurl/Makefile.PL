use strict;
use warnings;
use 5.010000;

use ExtUtils::MakeMaker;
use Alien::curl;
use EV::MakeMaker;
use Config;
use File::Spec;
use FindBin qw($Bin);

my @inc;
{
    my @flags = grep { length } split /\s+/, Alien::curl->cflags;
    while (defined(my $flag = shift @flags)) {
        push @inc, $flag =~ /\A-I(.+)\z/       ? $1
                 : $flag eq '-isystem'         ? (shift(@flags) // ())
                 : $flag =~ /\A-isystem(.+)\z/ ? $1
                 : ();
    }
}

sub find_curl_h {
    my @search = @inc;

    for my $curl_config (curl_configs()) {
        chomp(my $prefix = `$curl_config --prefix 2>/dev/null` || '');
        push @search, File::Spec->catdir($prefix, 'include') if length $prefix;
    }

    push @search, split(/\s+/, $Config{incpth}), '/usr/include';

    if ($^O eq 'darwin') {
        chomp(my $sdk = `xcrun --show-sdk-path 2>/dev/null` || '');
        push @search, File::Spec->catdir($sdk, 'usr', 'include') if length $sdk;
    }

    for my $path (@search) {
        my $header = File::Spec->catfile($path, 'curl', 'curl.h');
        return $header if -f $header;
    }

    die "Could not locate curl/curl.h; looked in:\n"
      . join('', map { "  $_\n" } @search);
}

sub curl_configs {
    return (map({ File::Spec->catfile($_, 'curl-config') } Alien::curl->bin_dir), 'curl-config');
}

sub warn_unless_asynchdns {
    for my $curl_config (curl_configs()) {
        my $features = `$curl_config --features 2>/dev/null` or next;
        return if $features =~ /AsynchDNS/;
        warn "EV::YACurl: libcurl was built without AsynchDNS, so name lookups\n"
           . "will block the event loop. Continuing anyway.\n";
        return;
    }
}

warn_unless_asynchdns();
system($^X, "$Bin/sync-curlopt.pl", find_curl_h()) == 0
    or die "sync-curlopt failed\n";

my %ev = EV::MakeMaker::ev_args();

my ($version) = do {
    open my $fh, '<', 'lib/EV/YACurl.pm' or die "lib/EV/YACurl.pm: $!\n";
    local $/;
    <$fh> =~ /our \$VERSION = '([^']+)'/;
};
die "could not find \$VERSION\n" unless defined $version;

WriteMakefile(
    NAME             => 'EV::YACurl',
    VERSION_FROM     => 'lib/EV/YACurl.pm',
    ABSTRACT_FROM    => 'lib/EV/YACurl.pm',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010000',
    XS               => { 'YACurl.xs' => 'YACurl.c' },
    # Without this MakeMaker sweeps the top-level *.pl generators into blib.
    PM               => { 'lib/EV/YACurl.pm' => '$(INST_LIB)/EV/YACurl.pm' },
    OBJECT           => 'YACurl$(OBJ_EXT)',
    INC              => Alien::curl->cflags . " -I. $ev{INC}",
    LIBS             => [ Alien::curl->libs ],
    CONFIGURE_REQUIRES => {
        'Alien::curl'         => 0,
        'EV::MakeMaker'       => 0,
        'ExtUtils::MakeMaker' => '6.64',
    },
    PREREQ_PM => {
        'EV'          => '4.11',
        'Alien::curl' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0.98',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides => {
            'EV::YACurl' => {
                file    => 'lib/EV/YACurl.pm',
                version => $version,
            },
            'EV::YACurl::Response' => {
                file    => 'lib/EV/YACurl.pm',
                version => $version,
            },
        },
        prereqs => {
            test => {
                recommends => {
                    'Test::LeakTrace' => 0,
                },
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-ev-yacurl.git',
                web  => 'https://github.com/vividsnow/perl5-ev-yacurl',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-ev-yacurl/issues',
            },
        },
        no_index => {
            directory => ['bench', 'eg', 't', 'xt'],
        },
    },
    clean => { FILES => 'YACurl.c' },
);
# README is generated from the module's POD; regenerate it whenever the POD
# moves ahead of it, and always before rolling a distribution.
sub MY::postamble {
    return <<'MAKE';
README : lib/EV/YACurl.pm
	$(PERL) -MPod::Text -e "Pod::Text->new(width => 78)->parse_from_file(q(lib/EV/YACurl.pm), q(README))"

# create_distdir copies the MANIFEST, so README has to exist before it runs.
create_distdir : README
all :: README

MAKE
}
