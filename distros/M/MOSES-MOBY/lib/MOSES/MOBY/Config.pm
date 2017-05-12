#-----------------------------------------------------------------
# MOSES::MOBY::Config
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Config.pm,v 1.6 2009/10/13 16:42:20 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::Config;
use Config::Simple;
use File::Spec;
use File::HomeDir;
use vars qw( $DEFAULT_CONFIG_FILE $ENV_CONFIG_DIR );
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.6 $ =~ /: (\d+)\.(\d+)/;

my %Config = ();     # here are all configuration parameters
my %Unsuccess = ();  # here are names (and reasons) of failed files
my %Success = ();    # here are names of successfully read files

BEGIN {
    $DEFAULT_CONFIG_FILE = 'moby-services.cfg';
    $ENV_CONFIG_DIR = 'BIOMOBY_CFG_DIR';
}

=head1 NAME

MOSES::MOBY::Config - A hash based configuration module based on Config::Simple

=head1 SYNOPSIS

 # use config allong with the MOSES config file
 use MOSES::MOBY::Config;

 # use config along with my properties.file
 use MOSES::MOBY::Config qw /'properties.file'/;

 # print the successfully read config files
 foreach my $file (MOSES::MOBY::Config->ok_files) {
    print "\t$file - successfully processed\n";
 }

 # print a list of files that failed to load
 my %failed = MOSES::MOBY::Config->failed_files;
 if (keys %failed > 0) {
    print "Failed configuration files:\n";
    foreach my $file (sort keys %failed) {
    my $msg = $failed{$file}; $msg =~ s/\n$//;
        print "\t$file => $msg\n";
    }
 }

 # print out the config params read thus far
 print "All configuration parameters:\n";
 foreach my $name (sort MOSES::MOBY::Config->param()) {
    print "\t$name => " . MOSES::MOBY::Config->param ($name);
 }

=head1 DESCRIPTION

A module for reading configuration files and maintaining configuration parameters 

=head1 AUTHORS

 Martin Senger (martin.senger [at] gmail [dot] com)
 Edward Kawas (edward.kawas [at] gmail [dot] com)

=head1 SUBROUTINES

=cut

# OO access; but there are no instance attributes - everything are
# class (shared) attributes

=head2 new

Instantiates a new MOSES::MOBY::Config reference. Mainly here for OO access. 
There are no instance attributes, only class attributes

=cut


sub new {
    my ($class, @args) = @_;

    # create an object
    my $self = bless {}, ref ($class) || $class;

    # initialize the object
    $self->import (@args);

    # done
    return $self;
}


# this allows to specify a configuration file in the use clause:
#    use MOSES::MOBY::Config ( 'my.file', 'your.file', { cachedir => 'somewhere' } )

sub import {
    shift->init ($DEFAULT_CONFIG_FILE, @_);
}

# @configs can be mix of scalars (names of configuration files) or
# hash references (direct configuration parameters); can be called
# more times - everything is appended

sub init {
    shift;    # ignore invocant
    my (@configs) = @_;

    # add parameters AND resolve file names
    foreach my $config (@configs) {
	if (ref ($config) eq 'HASH') {
	    %Config = (%Config, %$config);
	} else {
	    my $file = MOSES::MOBY::Config->_resolve_file ($config);
	    unless ($file) {
		$Unsuccess{$config} = 'File not found.';
		next;
	    }
	    eval {
		Config::Simple->import_from ($file, \%Config);
	      };
	    if ($@) {
		$@ =~ s| /\S+Config/Simple.pm line \d+, <FH>||;
#		print STDERR "Reading configuration file '$file' failed: $@";
		$Unsuccess{$file} = $@;
	    } else {
		$Success{$file} = 1;
	    }
	}
    }
    # I do not like default.XXX (done by Config::Simple) - so
    # replicate these keys without the prefix 'default'
    foreach my $key (keys %Config) {
	my ($realkey) = ($key =~ /^$Config::Simple::DEFAULTNS\.(.*)/);
	if ($realkey && ! exists $Config{$realkey}) {
	    $Config{$realkey} = $Config{$key};
	}
    }

    # Remove potential whitespaces from the keys (Config::Simple may
    # leave theme there)
    map { my $orig_key = $_;
	  s/\s//g and $Config{$_} = delete $Config{$orig_key}  } keys %Config;
}

# try to locate given $filename, return its full path:
#  a) as it is - if such file exists
#  b) as $ENV{BIOMOBY_CFG_DIR}/$filename
#  c) in one of the @INC directories
#  d) return undef

sub _resolve_file {
    shift;    # ignore invocant
    my ($filename) = @_;
    return $filename if -f $filename;


    my $realfilename;
    if ($ENV{$ENV_CONFIG_DIR}) {
	$realfilename = File::Spec->catdir ($ENV{$ENV_CONFIG_DIR}, $filename);
	return $realfilename if -f $realfilename;
    }
	
	$realfilename = undef;
	$realfilename = File::Spec->catfile( File::Spec->catdir (File::HomeDir->my_home,  "Perl-MoSeS"), $filename);
	return $realfilename if -f $realfilename;
    
    foreach my $prefix (@INC) {
	$realfilename = File::Spec->catfile ($prefix, $filename);
	return $realfilename if -f $realfilename;
    }
    return undef;
}

# return value of a configuration argument; or add a new argument

=head2 param

If called with no arguments, all of the possible config keys are returned. 
If called with a single argument, then that argument is assumed to be a key and the value for that key is returned. 

=cut

sub param {
    shift;

    # If called with no arguments, return all the
    # possible keys
    return keys %Config unless @_;

    # if called with a single argument, return the value
    # matching this key
    return $Config{$_[0]} if @_ == 1;

    # more arguments means adding...
#    return $Config{$_[0]} = $_[1];
    my $ret = $Config{$_[0]} = $_[1];
    MOSES::MOBY::Config->import_names ('MOBYCFG');
    return $ret;
}

# remove one, more, or all configuration arguments

=head2 delete

removes one or more of the configuration keys and their associated values.

=cut

sub delete {
    shift;

    # if called with no arguments, delete all keys
    %Config = () and return unless @_;

    # if called with arguments, delete the matching keys
    foreach my $key (@_) {
	delete $Config{$key};
    }
}

# return a stringified version of all configuration options; an
# optional argument is a name for variable into which it is
# stringified (I do not know how to express it better: simply speaking
# this argument is passed to the Data::Dumper->Dump as the variable
# name)

=head2 dump

Returns a stringified version of all configuration parameters;

If passed a scalar parameter, then the dump will be given that variable name.
This dump can be eval{}'ed.

=cut

sub dump {
    shift;
    my $varname = @_ ? shift : 'CONFIG';
    require Data::Dumper;
    return Data::Dumper->Dump ( [\%Config], [$varname]);
}

# imports names into the caller's namespace as global variables;
# adapted from the same method in Config::Simple

sub import_names {
    shift;
    my $namespace = @_ ? shift : (caller)[0];
    return if $namespace eq 'MOSES::MOBY::Config';

    no strict 'refs';
    no warnings;   # avoid "Useless use of a variable..."
    while ( my ($key, $value) = each %Config ) {
	$key =~ s/\W/_/g;
	${$namespace . '::' . uc($key)} = $value;
    }
}

# return a list of configuration files successfully read (so far)

=head2 ok_files

returns a list of the configuration files successfully read thus far ...

=cut

sub ok_files {
    return sort keys %Success;
}

# return a hash of configuration files un-successfully read (so far) -
# with corresponding error messages

=head2 failed_files

returns a hash of the configuration files unsuccessfully read thus far and their corresponding error messages.

=cut

sub failed_files {
    return %Unsuccess;
}

1;
__END__
