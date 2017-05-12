package HtDig::Config;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $DEFAULT_CONFIG_LOCATION $DEFAULT_LOG_LOCATION $DEFAULT_HTDIG_LOCATION $sites $htdig_base_path $configdig_log_path);

use Data::Dumper;
use HtDig::Site;

require Exporter;
require AutoLoader;
$DEFAULT_CONFIG_LOCATION = '/opt/www/conf/configdig_sites.pl';
$DEFAULT_LOG_LOCATION = '/opt/www/logs';
$DEFAULT_HTDIG_LOCATION = '/opt/www';
@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();
$VERSION = '1.02';

##
#Constructor for the Config object
##
sub new {
  my ($class, %attribs) = @_;
  my $self = {};
  $self->{path} = $attribs{conf_path} ? $attribs{conf_path} : $DEFAULT_CONFIG_LOCATION;

  #Autocreate allows us to create a conf that doesn't
  # already exist.
  if ($attribs{auto_create}) {
    unless (-f $self->{path}) {
      #I avoid using "touch" on the file to ensure cross-platform
      # compatibility, opting instead to just open it for writing.
      open(TMP,">" . $self->{path}) or die "Couldn't auto_create configuration file at " . $self->{path} . ": $!";
      print TMP "1;\n";
      close(TMP);
    }
  }
  else {
    unless (-f $self->{path}) {
        die "Configuation file " . $self->{path} . " missing and auto_create not set.";
    }
  }
  
  require $self->{path};

  #These next few items are in the $self->{path} file "required" in the
  # previous line
  $self->{sites} = $sites;
  $self->{configdig_log_path} = $configdig_log_path || $DEFAULT_LOG_LOCATION;
  $self->{htdig_base_path} = $htdig_base_path || $DEFAULT_HTDIG_LOCATION;

  return bless $self, $class;
}

##
#Persist the site registry to the file
##
sub save {
  my ($self) = @_;
  my $sites_file = Data::Dumper->Dump([$self->{sites}], ["sites"]);
  open(CONF,">" . $self->{path}) or die "Couldn't open " . $self->{path} . " for writing.";
  print CONF $sites_file;
  print CONF qq|\n\$configdig_log_path = '| . $self->{configdig_log_path} . qq|';\n|;   
  print CONF q|$htdig_base_path = '| . $self->{htdig_base_path} . qq|';\n|;
  close CONF;
}

##
#Get an array of site names
##
sub sites {
  my ($self) = @_;
  return keys %{$self->{sites}};
}

##
#Get a Site object by name
##
sub get_site {
  my ($self, $site) = @_;
  if ($site and defined($self->{sites}->{$site})) {
    return HtDig::Site->new(conf_path=>$self->{sites}->{$site}, site_name=>$site, config=>$self);
  }
  else {
    return undef;
  }
}

##
#Add a registration for a particular site configuration
##
sub add_site {
  my ($self, %attribs) = @_;
  my $site;
  eval('$site = new HtDig::Site(%attribs)');
  if ($@) {
    $self->{errstr} = "Couldn't register site: $@";
    return undef;
  }
  if ($site) {
    $self->{sites}->{$attribs{site_name}} = $attribs{conf_path};
  }
  return $site;
}

##
#Remove registration for a particular site configuration
##
sub delete_site {
  my ($self, %attribs) = @_;
  delete($self->{sites}->{$attribs{site_name}});
  return 1;
}

##
#Attempt to find htdig configurations in suggested
# and default locations
##
sub autodetect {
  my ($self, %attribs) = @_;
  my $configs_detected = 0;

  #Clear error string
  $self->{errstr} = '';

  #A couple of educated guesses
  # (using a hash automatically prevents duplicates)
  my %paths = (
	       "/opt/www/conf"=> 1,
	       "/usr/local/htdig/conf"=> 1,
	      );

  #The user's desired search paths
  for my $path (@{$attribs{paths}}) {
    $paths{$path} = 1;
  }

  #If they asked us to, use the search path to find htdig
  #If found, then deduce the install directory, and add to
  # list of searched paths
  if ($attribs{use_env_path}) {
    chomp(my $potential_path = `which htdig`);
    if (-f $potential_path) {
      my @path = split(/\//, $potential_path);
      my $config_path = join("/", @path[0..($#path-2)]) . "/conf";
      $paths{$config_path} = 1;
    }
  }

  #Next check each path
  for my $path (keys %paths) {
    $configs_detected += $self->_proc_dir($path);
  }
  return $configs_detected;
}

##
#Get error message using this method
##
sub errstr {
  my ($self) = @_;
  return $self->{errstr};
}

##
#Some private methods
##
sub _proc_dir {
  my ($self, $config_path) = @_;
  my $configs_detected = 0;
  return 0 if !-d $config_path;

  opendir(CONFDIR, $config_path);
  while (my $file = readdir(CONFDIR)) {
    next if ($file eq '.' or $file eq '..');
    if ($file =~ /\.conf$/) {
      my $autoname = $file eq "htdig.conf" ? "default" : $file;
      eval( qq|
	    \$self->add_site(site_name=>'$autoname', conf_path=>"$config_path/$file");
      |);
      if ($@) {
	$self->{errstr} .= $@ . $! . " when adding $config_path/$file\n";
      }
      else {
	++$configs_detected;
      }
    }
  }
  return $configs_detected;
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

HtDig::Config - Perl extension for managing ht://Dig configuration files

=head1 SYNOPSIS

  use HtDig::Config;
  my $htdig = new HtDig::Config('/opt/www/conf/configdig_sites.pl');
  $htdig->autodetect();
  while (my ($site_name, $path) = each %{$htdig->sites()}) {
    print "Site $site_name found at $path\n";
  }
  my $site = $htdig->sites("default");
  #etc.
  #See the HtDig::Site module for information on using the Site object
  #

=head1 DESCRIPTION

HtDig::Config provides an object-oriented interface to the configuration files for ht://Dig, a popular, open-source content indexing and searching system.  

ht://Dig allows you to specify a configuration file to use when beginning an indexing run or doing a search, thus allowing you to maintain multiple databases of indexed web pages.  The Config object's main job is to help you keep track of all the site configuration files you have, using a sort of "registry" to keep track of sites you've registered with ConfigDig.  The HtDig::Site object works with the Config object to help you modify and save each site's configuration settings.

=head1 METHODS

=over 4

=item *new

  my $htdig = new HtDig::Config(conf_path=>'/opt/www/conf/configdig_sites.pl');

Returns a new Config object.  No required parameters.  If you don't pass in conf_path, the value for $DEFAULT_CONFIF_LOCATION is used.  You can change this to your own preference for convenience if you wish, with no ill effects.  You can also pass in auto_create=>1 to cause a blank file to be created at conf_path, if one doesn't already exist.  Dies on failure.

=item *save

  $htdig->save();

Causes the current Site registry to be written to the file at $config_object->{conf_path};

=item *sites

  my @site_list = $htdig->sites();

Returns an array listing the names of all the sites in the Site registry.

=item *get_site

  my $site = $htdig->get_site("default");

Returns an HtDig::Site object corresponding to the string name passed in.  Returns undef on failure, such as when the site name is not found in the Site registry.

=item *add_site

  $htdig->add_site(site_name=>"My Site", conf_path=>"/opt/www/conf/mysite.conf");

Adds a new site to the registry, giving it the name specified in site_name, and using the config file at conf_path.  Returns the Site object on success, undef on failure.

=item *delete_site

  $htdig->delete_site(site_name=>'My Site');

Removes the site specified in site_name from the registry.  The config file itself is not removed.

=item *autodetect

  $htdig->autodetect(paths=>['/users/jtillman/confs/', '/users/bob/htdig'], use_env_path=>1);

Causes the Config object to search the paths specified in paths for .conf files, attempting to add each file found to the registry.  If use_env_path is specified, the PATH environment variable is used to search for the htdig executable and the base htdig directory is determined using its location.  Then the [base_location]/conf directory is searched for .conf files.

The method also searches /opt/www/conf and /usr/local/htdig/conf by default.

=item *errstr

  print $htdig->errstr . "\n";

Returns the most recently generated error.  The Config object doesn't bother with error numbers, since they would be arbitrary and difficult to track.  This may change if demand is high enough for error numbers.

=back

=head1 KNOWN ISSUES

=over 4

=item *Autodetect isn't very clever or clean.  Error reporting could be better, and some attempt should be made to detect which .conf files really are htdig .conf files

=item *Should get_site require attrib=>value convention?  Nearly all the other methods do, even delete_site.

=back

=head1 AUTHOR

James Tillman <jtillman@bigfoot.com>
CPAN PAUSE ID jtillman

=head1 SEE ALSO

HtDig::Site.

perl(1).

=cut
