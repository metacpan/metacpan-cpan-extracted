use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

( my $mmv = ExtUtils::MakeMaker->VERSION ) =~ s/ _ //smxg;

my %arg = (
    'AUTHOR'		=> 'Simon Drabble (sdrabble@cpan.org)',
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

$mmv >= 6.4501 and $args{META_MERGE} = {
    resources => {
	bugtracker =>
	'https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-TableContentParser',
	license => 'http://dev.perl.org/licenses/',
    },
};

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

# ex: set textwidth=72 :
