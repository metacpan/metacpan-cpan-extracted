use strict;
use warnings;

use 5.006002;

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

( my $mmv = ExtUtils::MakeMaker->VERSION ) =~ s/ _ //smxg;

my %args = (
    AUTHOR		=> [
	'Simon Drabble (sdrabble@cpan.org)',
	'Tom Wyant (wyant at cpan dot org)',
    ],
    ABSTRACT		=> 'Extract tables from HTML',
    NAME		=> 'HTML::TableContentParser',
    PL_FILES	=> {},	# Prevent old MakeMaker from running Build.PL
    PREREQ_PM		=> {
	'Carp'		=> 0,
	'HTML::Parser'	=> 0,
	'parent'	=> 0,
	'strict'	=> 0,
	'warnings'	=> 0,
    }, # e.g., Module::Name => 1.1
    realclean	=> {
	FILES	=> 'cover_db',
    },
    VERSION_FROM	=> 'lib/HTML/TableContentParser.pm', # finds $VERSION
);

$mmv >= 6.31
    and $args{LICENSE} = 'perl_5';

if ( $mmv >= 6.4501 ) {
    $args{META_ADD} = {
	no_index	=> {
	    directory	=> [ qw{ inc t xt } ],
	},
    };
    $args{META_MERGE} = {
	'meta-spec'	=> {
	    version	=> 2,
	},
	resources => {
	    bugtracker => {
		web	=> 'https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-TableContentParser',
		# web	=> 'https://github.com/trwyant/perl-HTML-TableContentParser/issues',
		mailto	=> 'wyant@cpan.org',
	    },
	    license => 'http://dev.perl.org/licenses/',
	    repository	=> {
		type	=> 'git',
		url	=> 'git://github.com/trwyant/perl-HTML-TableContentParser.git',
		web	=> 'https://github.com/trwyant/perl-HTML-TableContentParser',
	    },
	},
	provides(),
    };
}

my %build_requires = (
    'Test::More'	=> 0.88,
);

my %config_requires = (
    'ExtUtils::MakeMaker'	=> 0,
    strict	=> 0,
    warnings	=> 0,
);

$mmv >= 6.4701
    and $args{MIN_PERL_VERSION} = 5.006002;

$mmv >= 6.5702
    or $args{AUTHOR} = join ', ', @{ $args{AUTHOR} };

if ( $mmv >= 6.52 ) {
    $args{BUILD_REQUIRES} = \%build_requires;
    $args{CONFIGURE_REQUIRES} = \%config_requires;
} elsif ( $mmv >= 6.5501 ) {
    $args{BUILD_REQUIRES} = \%build_requires;
    $args{META_MERGE}{configure_requires} = \%config_requires;
} elsif ( $mmv >= 6.4501 ) {
    $args{META_MERGE}{build_requires} = \%build_requires;
    $args{META_MERGE}{configure_requires} = \%config_requires;
} else {
    foreach my $req ( \%build_requires, \%config_requires ) {
	foreach my $key ( keys %{ $req } ) {
	    exists $args{PREREQ_PM}{$key}
		or $args{PREREQ_PM}{$key} = $req->{$key};
	}
    }
}

WriteMakefile( %args );

sub MY::postamble {
    my ( $self, @args ) = @_;

    my $authortest = $self->test_via_harness(
	'$(FULLPERLRUN)', '$(AUTHORTEST_FILES)' );
    $authortest =~ s/ \s+ \z //smx;
    $authortest =~ s/ \A \s+ //smx;
    chomp $authortest;

    return <<"EOD";

AUTHORTEST_FILES = t/*.t xt/author/*.t

authortest :: pure_all
	AUTHOR_TESTING=1 $authortest

testcover :: pure_all
	cover -test
EOD
}

sub provides {
    -d 'lib'
	or return;
    local $@ = undef;
    my $provides = eval {
	require Module::Metadata;
	Module::Metadata->provides( version => 2, dir => 'lib' );
    } or return;
    return ( provides => $provides );
}

# ex: set textwidth=72 :
