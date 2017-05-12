use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		'AUTHOR'	=> 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT'	=> 'Slice an image into NxM tiles',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Image-Magick-Tiler-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'Image-Magick-Tiler',
	NAME		=> 'Image::Magick::Tiler',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'File::Basename'	=> 0,
		'File::Spec'		=> 0,
		'Image::Magick'		=> 0, # Expect Module::Version's mversion to return undef.
		'Moo'				=> 2.002004,
		'strict'			=> 0,
		'Types::Standard'	=> 1.000005,
		'warnings'			=> 0,
	},
	TEST_REQUIRES =>
	{
		'File::Temp'	=> 0,
		'Test::Pod'		=> 1.51,
		'Test::Simple'	=> 1.302052, # For Test::More.
	},
	VERSION_FROM => 'lib/Image/Magick/Tiler.pm',
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'perl';
}

if ($ExtUtils::MakeMaker::VERSION ge '6.46')
{
	$params{META_MERGE} =
	{
		'meta-spec' =>
		{
			version => 2,
		},
		resources =>
		{
			bugtracker =>
			{
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Image-Magick-Tiler',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Image-Magick-Tiler.git',
				web		=> 'https://github.com/ronsavage/Image-Magick-Tiler',
			},
		},
	};
}

WriteMakefile(%params);
