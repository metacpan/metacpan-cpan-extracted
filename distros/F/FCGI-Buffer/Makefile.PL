use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

my %prereq_pm = (
	'Carp' => 0,
	'CGI::Info' => 0.71,	# status() can set the status from this version
	'CSS::Packer' => 0,
	'Compress::Zlib' => 0,
	'Cwd' => 0,
	'File::Path' => 0,
	'Digest::MD5' => 0,
    	'Encode' => 0,
	# 'HTML::Clean' => 0.8,
	'HTML::Packer' => 1.000,
	'IO::String' => 0,
	'JavaScript::Packer' => 2.00,
	'HTTP::Date' => 0,
	'File::Basename' => 0,
	'File::Spec' => 0,
	'File::Temp' => 0,	# save_to
	'HTML::Lint' => 0,
	'Storable' => 0,
	'HTTP::Status' => 0,
	'DBI' => 0,
	'DBD::SQLite' => 0,	# save_to
	'Readonly' => 0,
	'Scalar::Util' => 0
);

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
    NAME                => 'FCGI::Buffer',
    AUTHOR              => q{Nigel Horne <njh@nigelhorne.com>},
    VERSION_FROM        => 'lib/FCGI/Buffer.pm',
    ABSTRACT_FROM       => 'lib/FCGI/Buffer.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'gpl_2')
      : ()),
    PL_FILES            => {},
    CONFIGURE_REQUIRES => {
	'ExtUtils::MakeMaker' => 6.64
    },
    TEST_REQUIRES => {
	'Test::Most' => 0,
	'Test::DescribeMe' => 0,
	'Test::HTML::Lint' => 0,
	'Test::NoWarnings' => 0,
	'Test::Needs' => 0,
	'Capture::Tiny' => 0,
	'DBI' => 0,
	'File::Find' => 0,
	'File::Temp' => 0,
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
		prereqs => {
			runtime => {
				recommends => {
					'CHI' => 0,	# the server-side cache and save_to
					'Compress::Zstd' => 0,	# zstd encoding
					'IO::Compress::Brotli' => 0,	# br encoding
					'Text::Diff' => 0	# debug logging of what changed
				}
			}, test => {
				recommends => {
					'Test::Log::Abstraction' => 0	# needs Perl 5.26
				}
			}
		}, resources => {
			homepage => 'https://metacpan.org/pod/FCGI::Buffer',
			repository => {
				type => 'git',
				url => 'https://github.com/nigelhorne/FCGI-Buffer.git',
				web => 'https://github.com/nigelhorne/FCGI-Buffer',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=FCGI-Buffer',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=FCGI-Buffer',
				# web => 'https://github.com/nigelhorne/FCGI-Buffer/issues',
				# url => 'https://github.com/nigelhorne/FCGI-Buffer/issues',
				mailto => 'bug-FCGI-Buffer@rt.cpan.org'
			}
		},
    },
    MIN_PERL_VERSION	=> '5.012'	# The latest DBI needs this
);
