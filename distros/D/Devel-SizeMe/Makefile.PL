#!/usr/bin/perl -w
use 5.005;
use ExtUtils::MakeMaker;
use File::Spec::Functions 'catfile';
use strict;

use Config;
(unpack "B*", pack "N", $Config{ptrsize}) =~ /^0+1(0+)$/
    or die "Your pointer size of $Config{ptrsize} is very confusing";
my $ptr_bits = length $1;

write_header(
    'refcounted_he.h' =>
    extract_chunk_from_file(catfile($Config{archlib}, 'CORE', 'hv.h'), qr/struct refcounted_he \{/, qr/\};/)
);


my %MakefileOpts = (
    NAME => 'Devel::SizeMe',
    VERSION_FROM => 'lib/Devel/SizeMe/Core.pm',
    DEFINE => "-DALIGN_BITS=$ptr_bits",
    PREREQ_PM => {
        'autodie' => '2.12',
        'XSLoader' => 0,
        'Moo' => '1.000007',
        'Test::More' => '0.98',
        'JSON::XS' => 0,
        'HTML::Entities' => 0,
        'Devel::Dwarn' => 0,
        'DBI' => '0',
        'DBD::SQLite' => '1.37',
        # Removed for now as it stops people using SizeMe with 5.8
        # sizeme_graph.pl will eventually become a separate module
        #'Mojolicious::Lite' => 0,
    },
    EXE_FILES => [ 'bin/sizeme_store.pl', 'bin/sizeme_graph.pl' ],
    clean => {
        FILES => 'refcounted_he.h',
    },
    META_MERGE => {
        resources => {
            'meta-spec' => { version => 2 },
            repository  => {
                type => 'git',
                url => 'git://github.com/timbunce/devel-sizeme.git',
                web => 'https://github.com/timbunce/devel-sizeme',
            },
            bugtracker => {
                web => 'https://github.com/timbunce/devel-sizeme/issues',
            },
            homepage    => 'https://github.com/timbunce/devel-sizeme',
        },
    },
    MIN_PERL_VERSION => '5.008',
    LICENSE => 'perl',
    dist  => {
        DIST_DEFAULT => 'clean distcheck disttest tardist',
        PREOP        => '$(MAKE) -f Makefile.old distdir',
        COMPRESS     => 'gzip -v9',
        SUFFIX       => 'gz',
    },
);

if (-d ".git") {
    $MakefileOpts{OPTIMIZE} = "-g";
    warn "Forcing OPTIMIZE=$MakefileOpts{OPTIMIZE}\n";
}

WriteMakefile1(%MakefileOpts);


sub WriteMakefile1 {
    #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params       = @_;
    my $eumm_version = $ExtUtils::MakeMaker::VERSION;
    $eumm_version = eval $eumm_version;
    die "EXTRA_META is deprecated" if ( exists( $params{EXTRA_META} ) );
    die "License not specified"    if ( !exists( $params{LICENSE} ) );
    if ( $params{BUILD_REQUIRES} and ( $eumm_version < 6.5503 ) ) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM} = { %{ $params{PREREQ_PM} || {} }, %{ $params{BUILD_REQUIRES} } };
        delete $params{BUILD_REQUIRES};
    }

    # more or less taken from Moose' Makefile.PL
    if ( $params{CONFLICTS} ) {
        my $ok = CheckConflicts(%params);
        exit(0) if ( $params{PREREQ_FATAL} and not $ok );
        my $cpan_smoker = grep { $_ =~ m/(?:CR_SMOKER|CPAN_REPORTER|AUTOMATED_TESTING)/ } keys %ENV;
        unless ( $cpan_smoker || $ENV{PERL_MM_USE_DEFAULT} ) {
            sleep 4 unless ($ok);
        }
        %{$params{META_MERGE}{conflicts}} = %{$params{CONFLICTS}};
        delete $params{CONFLICTS};
    }

    delete $params{CONFIGURE_REQUIRES} if ( $eumm_version < 6.52 );
    delete $params{MIN_PERL_VERSION}   if ( $eumm_version < 6.48 );
    delete $params{META_MERGE}         if ( $eumm_version < 6.46 );
    delete $params{META_ADD}           if ( $eumm_version < 6.46 );
    delete $params{LICENSE}            if ( $eumm_version < 6.31 );

    WriteMakefile(%params);
}


my $conflictMsg = <<EOCM;
***
    This version of Devel::SizeMe conflicts with the version of
    module %s (%s) you have installed.

    It's strongly recommended that you update it after
    installing this version of Devel::SizeMe.
***
EOCM

sub CheckConflicts {
    my %params    = @_;
    my %conflicts = %{ $params{CONFLICTS} };
    my $found     = 0;

    while ( my ( $module, $version ) = each(%conflicts) ) {
        undef $@;
        eval "require $module";
        next if $@;
        my $installed = eval "\$" . $module . "::VERSION";
        if ( $installed le $version ) {
            ++$found;
            my $msg = $conflictMsg;
            my $warning = sprintf( $msg, $module, $installed );
            warn $warning;
        }
    }

    return !$found;
}


sub extract_chunk_from_file {
    my ($file, $start_regex, $end_regex) = @_;
    $file =~ s/^~/$ENV{HOME}/ if $ENV{HOME};
    open my $fh, '<', $file or die $!;

    my $def;
    while (<$fh>) {
        next unless /$start_regex/ .. /$end_regex/;
        $def .= $_;
    }
    close $fh or die $!;

    return $def;
}


sub write_header {
    my ($filename, $contents) = @_;
    my $guard_name = uc $filename;
    $guard_name =~ tr/./_/;

    open my $fh, '>', $filename or die $!;
    print { $fh } "#ifndef ${guard_name}\n";
    print { $fh } "#define ${guard_name}\n";
    print { $fh } $contents if defined $contents;
    print { $fh } "#endif /* ${guard_name} */\n";
    close $fh or die $!;
}


# =====================================================================

package MY;

sub postamble {
    return qq{

ptest:  all
\t prove --blib --jobs 4 --shuffle

    \n};
}
