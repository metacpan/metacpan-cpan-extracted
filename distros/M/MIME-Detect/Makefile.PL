# -*- mode: perl; c-basic-offset: 4; indent-tabs-mode: nil; -*-

use strict;
use ExtUtils::MakeMaker qw(WriteMakefile);
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

my $module = 'MIME::Detect';
(my $main_file = "lib/$module.pm" ) =~ s!::!/!g;
my $repository = 'git://github.com/Corion/mime-detect.git';
(my $repository_web = $repository) =~ s!^git://github.com/(.*).git!https://github.com/$1!;
(my $distdir = $module) =~ s!::!_!g;

# I should maybe use something like Shipwright...
regen_README($main_file);
regen_INSTALL($main_file);
#regen_EXAMPLES();

my @tests = map { glob $_ } 't/*.t', 't/*/*.t';

# Do we need to load our backwards compatibility shim?
my @signatures = eval 'use feature "signatures"; 1'
                 ? ()
                 : ('Filter::signatures' => 0.05);

WriteMakefile1(
    NAME                => $module,
    AUTHOR              => q{Max Maischein <corion@cpan.org>},
    VERSION_FROM        => $main_file,
    ABSTRACT_FROM       => $main_file,
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                web => $repository_web,
                url => $repository,
                type => 'git',
            }
        },
    },
    
    # I saw some weirdo failures on 5.8.2,5.8.3 via CPANtesters
    # but I attribute them to some version of Filter::Simple
    MIN_PERL_VERSION => '5.006',

    'LICENSE'=> 'perl',

    PL_FILES            => {},
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    'PREREQ_PM'    => { 'XML::LibXML' => '1.70', # we want ->load_xml()
                        'Moo'         => 2,
                        'Carp'        => 0,
                        'Fcntl'       => 0,
                        'if'          => 0,
                        @signatures,
    }, # e.g., Module::Name => 1.1
    TEST_REQUIRES => {
        'Test::More' => 0,
    },

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTTP-Request-FromTemplate-*' },

    test            => { TESTS => join( ' ', @tests ) },
);

1;

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{TEST_REQUIRES}} };
        delete $params{TEST_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;
    
    WriteMakefile(%params);
}

sub regen_README {
    eval {
        require Pod::Readme;
        Pod::Readme->VERSION('1.0.2'); #0.11 may hang

        my $parser = Pod::Readme->new();

        # Read POD from Module.pm and write to README
        $parser->parse_from_file($_[0], 'README');
    };
    eval {
        require Pod::Markdown;

        my $parser = Pod::Markdown->new();

        # Read POD from Module.pm and write to README
        $parser->parse_from_file($_[0]);
        open my $fh, '>', 'README.mkdn'
            or die "Couldn't open 'README.mkdn': $!";
        print $fh $parser->as_markdown;
    };
}

sub regen_INSTALL {
    eval {
        open my $fh, '>', 'INSTALL'
            or die "Creating INSTALL: $!";
        binmode $fh;
        my $content = <<INSTALL;
=head1 INSTALLATION

These are the installation instructions for $module.

The module releases are hosted on CPAN. The module
can be installed:

=over

=item latest release from CPAN

  cpan $module

or

  cpanm $module

=item directly, as the latest development files

 cpanm $repository

=item manually cloninig the repository:

 git clone $repository
 cd $distdir
 perl Makefile.PL
 make
 make test
 make install

=back

INSTALL
        $content =~ s!\s$!\n!mg;
        print $fh $content;
    };
}

