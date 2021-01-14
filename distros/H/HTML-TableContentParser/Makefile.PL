use strict;
use warnings;

use 5.006002;

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

( my $mmv = ExtUtils::MakeMaker->VERSION ) =~ s/ _ //smxg;

my %arg = (
    'AUTHOR'		=> [
	'Simon Drabble (sdrabble@cpan.org)',
	'Tom Wyant (wyant at cpan dot org)',
    ],
    'ABSTRACT'		=> 'Extract tables from HTML',
    'NAME'		=> 'HTML::TableContentParser',
    'VERSION_FROM'	=> 'lib/HTML/TableContentParser.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	'Carp'		=> 0,
	'HTML::Parser'	=> 0,
	'parent'	=> 0,
	'strict'	=> 0,
	'warnings'	=> 0,
    }, # e.g., Module::Name => 1.1
);

$mmv >= 6.31
    and $arg{LICENSE} = 'perl_5';

$mmv >= 6.4501 and $arg{META_MERGE} = {
    'meta-spec'	=> {
	version	=> 2,
    },
    no_index	=> {
	directory	=> [ qw{ inc t xt } ],
    },
    resources => {
	bugtracker => {
	    web	=> 'https://github.com/trwyant/perl-HTML-TableContentParser/issues',
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

$mmv >= 6.4701
    and $arg{MIN_PERL_VERSION} = 5.006002;

$mmv >= 6.5702
    or $arg{AUTHOR} = join ', ', @{ $arg{AUTHOR} };

$arg{ $mmv >= 6.52 ? 'CONFIGURE_REQUIRES' : 'PREREQ_PM' }
    { 'ExtUtils::MakeMaker' } = 0;

$arg{ $mmv >= 6.64 ? 'TEST_REQUIRES' :
    $mmv >= 6.5503 ? 'BUILD_REQUIRES' : 'PREREQ_PM' }
    { 'Test::More' } = 0.88;

WriteMakefile( %arg );

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
