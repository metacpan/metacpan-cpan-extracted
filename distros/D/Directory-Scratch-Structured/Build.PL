
use strict ;
use warnings ;

use Module::Build;

my %all_modules ;
my @split_modules ;

my @pm_files = qw(
lib/Directory/Scratch//Structured.pm
);

for(@pm_files)
	{
	$all_modules{$_} = $_ ;
	push @split_modules, $_ ;
	}

sub GetVersionAndRevisionFrom
{
my ($file) = @_ ;

my $version_from = File::Spec->catfile( split '/', $file );
my $version      = Module::Build->version_from_file($version_from);

return($version) ;
}

my $code = <<'EOC'

sub GetVersionAndRevisionFrom
{
my ($file) = @_ ;

my $version_from = File::Spec->catfile( split '/', $file );
my $version      = Module::Build->version_from_file($version_from);

return($version) ;
}

sub ACTION_author_test
{
my $self = shift;
local $self->{properties}{test_files} = 'xt/author/*.t' ;
$self->SUPER::ACTION_test();
}


EOC
;

my $class = Module::Build->subclass(class => 'Directory::Scratch::Structured', code => $code) ;

my $build = $class->new
	(
	module_name => 'Directory::Scratch::Structured',
	
	dist_version => GetVersionAndRevisionFrom('lib/Directory/Scratch/Structured.pm'),
	
	license => 'perl',
	
	requires => 
		{
		'Readonly'         => 0,
		'Sub::Exporter'     => 0,
		'Sub::Install'     => 0,
		'Data::TreeDumper' => 0,
		'Directory::Scratch' => 0,
		
		'Test::Block' => 0,
		'Test::Exception' => 0,
		'Test::NoWarnings' => 0,
		'Test::Warn' => 0,
		'Test::Strict' => 0,
		},
		
	pm_files     => \%all_modules,
	autosplit    => \@split_modules,
	
	#~ script_files => 'script/xxx.pl',
	dist_author  => 'Khemir Nadim ibn Hamouda. <nadim@khemir.net>',
	dist_abstract => 'creates temporary files and directories from a structured description',
	);
	
$build->create_build_script;
  
