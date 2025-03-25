use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

sub MY::libscan {
    my( $mm, $file ) = @_;
    return if $file =~  /^push_to_GIT$/; # SKIP the git dir
    return if $file =~  /^tmp$/; # SKIP the git dir
    return if $file =~  /^bin$/; # SKIP the git dir
    return if $file =~  /^experiments$/; # private folder
    return if $file =~ /\.lock.*$/; # SKIP editor files
    return if $file =~ /\.pdf$/; # forgotten remnants
    return if $file =~ /\.aux$/; # forgotten remnants
    return if $file =~ /\.dvi$/; # forgotten remnants
    return if $file =~ /\.ps$/; # forgotten remnants
    return $file;
}

my %WriteMakefileArgs = (
    NAME             => 'LaTeX::Easy::Templates',
    AUTHOR           => q{Andreas Hadjiprocopis <bliako@cpan.org>},
    VERSION_FROM     => 'lib/LaTeX/Easy/Templates.pm',
    ABSTRACT_FROM    => 'lib/LaTeX/Easy/Templates.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
	'Test::More::UTF8' => '0',
	'Mojo::Log' => 0,
	'FindBin' => '0',
	'Capture::Tiny' => '0',
	'Test::TempDir::Tiny' => '0',
	'File::Find::Rule' => '0',
	'File::Spec' => '0',
	'File::Basename' => '0',
	'Data::Roundtrip' => '0.18',
	'File::Compare' => '0',
	'Text::Xslate' => '3.5.6',
    },
    PREREQ_PM => {
	'Exporter' => '0',
	'LaTeX::Driver' => '1.0.0',
	'Text::Xslate' => '3.5.6',
	'Mojo::Log' => '0',
	'File::Spec' => '0',
	'File::Temp' => '0',
	'File::Path' => '0',
	'File::Which' => '0',
	'Data::Roundtrip' => '0.18',
	'Cwd' => '0',
	'File::Copy::Recursive' => '0',
	'File::Basename' => '0',
	'Filesys::DiskUsage' => '0',
	'Clone' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'LaTeX-Easy-Templates-*' },
    postamble => {
        AUTHOR_TEST_FILES => 'xt/*.t',
    },
    # see https://perlmonks.org/?displaytype=displaycode;node_id=359256;part=1;abspart=1
    META_MERGE => {
          'meta-spec' => { version => 2 },
	  requires    => { perl => '5.0.10' },
          resources   => {
            license    => 'artistic_2',
	    homepage   => 'https://metacpan.org/module/LaTeX::Easy::Templates',
            repository => {
                url  => 'https://github.com/hadjiprocopis/LaTeX-Easy-Templates',
                web  => 'https://github.com/hadjiprocopis/LaTeX-Easy-Templates',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/hadjiprocopis/perl-LaTeX-Easy-Templates/issues',
            }
        },
    },
);


# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
    my (undef,%h) = @_;
    # require Data::Dumper; print STDERR Data::Dumper->Dump([\%h], [qw(mm_args{postamble})]);
    return "AUTHOR_TEST_FILES=$h{AUTHOR_TEST_FILES}\n"
	. <<'POSTAMBLE';
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

authortest :: $(AUTHOR_TEST_FILES)
	prove --blib $(INST_LIB) --blib $(INST_ARCHLIB) --verbose $^
POSTAMBLE
}

