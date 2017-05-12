package HTML::YUI3::Menu::Util::Config;

use Config::Tiny;

use File::HomeDir;

use Hash::FieldHash ':all';

use Path::Class;

fieldhash my %config           => 'config';
fieldhash my %config_file_path => 'config_file_path';
fieldhash my %section          => 'section';

our $VERSION = '1.01';

# -----------------------------------------------

sub init
{
	my($self, $arg)         = @_;
	$$arg{config_file_path} ||= Path::Class::file(File::HomeDir -> my_dist_config('HTML-YUI3-Menu'), '.hthtml.yui3.menu.conf');

} # End of init.

# --------------------------------------------------

sub new
{
	my($class, %arg) = @_;

	$class -> init(\%arg);

	my($self) = from_hash(bless({}, $class), \%arg);

	$self -> read($path);

	return $self;

} # End of new.

# -----------------------------------------------

sub read
{
	my($self) = @_;
	my($path) = $self -> config_file_path;

	# Check [global].

	$self -> config(Config::Tiny -> read($path) );

	if (Config::Tiny -> errstr)
	{
		die Config::Tiny -> errstr;
	}

	$self -> section('global');

	if (! ${$self -> config}{$self -> section})
	{
		die "Config file '$path' does not contain the section [@{[$self -> section]}]\n";
	}

	# Check [x] where x is host=x within [global].

	$self -> section(${$self -> config}{$self -> section}{'host'});

	if (! ${$self -> config}{$self -> section})
	{
		die "Config file '$path' does not contain the section [@{[$self -> section]}]\n";
	}

	# Move desired section into config, so caller can just use $self -> config to get a hashref.

	$self -> config(${$self -> config}{$self -> section});

}	# End of read.

# --------------------------------------------------

1;
