use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

my %prereq_pm = (
	'Carp' => 0,
	'CGI::Info' => 0.51,
	'CSS::Packer' => 0,
	'Compress::Zlib' => 0,
	'File::Path' => 0,
	'File::Spec' => 0,
	'Digest::MD5' => 0,
    	'Encode' => 0,
	# 'HTML::Clean' => 0.8,
	'HTML::Packer' => 1.000,
	'IO::String' => 0,
	'JavaScript::Packer' => 2.00,
	'HTTP::Date' => 0,
	'File::Spec' => 0,
	'Time::localtime' => 0,
	'HTML::Lint' => 0,
	'Storable' => 0,
	'HTTP::Status' => 0,
	'DBI' => 0,
	'Readonly' => 0
);

if(($^O ne 'MSWin32') && ($^O ne 'openbsd') && ($^O ne 'freebsd')) {
	# Doesn't work on Windows or compile on OpenBSD/FreeBSD
	# Also doesn't compile on Arm on Linux, so let's give up
	# $prereq_pm{'IO::Compress::Brotli'} = 0.003;
}

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
    NAME                => 'FCGI::Buffer',
    AUTHOR              => q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM        => 'lib/FCGI/Buffer.pm',
    ABSTRACT_FROM       => 'lib/FCGI/Buffer.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES            => {},
    TEST_REQUIRES => {
	'Test::Most' => 0,
	'Test::DescribeMe' => 0,
	'Test::NoWarnings' => 0,
	'Test::Needs' => 0,
	'Capture::Tiny' => 0,
	'DateTime' => 0,
	'DateTime::Format::HTTP' => 0,
	# 'Test::Kwalitee' => 0,
	'autodie' => 0,
	'IPC::System::Simple' => 0,
	'Directory::Scratch' => 0,
	'CGI::Lingua' => 0,
	'HTTP::Response' => 0,
	'HTTP::Headers' => 0
    }, PREREQ_PM  => \%prereq_pm,
	dist => $dist,
    clean      => { FILES => 'FCGI-Buffer-*' },
    META_MERGE => {
    	'meta-spec' => { version => 2 },
    	resources => {
		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/FCGI-Buffer.git',
			web => 'https://github.com/nigelhorne/FCGI-Buffer',
			repository => 'https://github.com/nigelhorne/FCGI-Buffer',
		}, bugtracker => {
			# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=FCGI-Buffer',
			web => 'https://github.com/nigelhorne/FCGI-Buffer/issues',
			url => 'https://github.com/nigelhorne/FCGI-Buffer/issues',
			mailto => 'bug-FCGI-Buffer@rt.cpan.org'
		}
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
