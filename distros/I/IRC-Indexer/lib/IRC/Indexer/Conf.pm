package IRC::Indexer::Conf;

use 5.10.1;
use strict;
use warnings;
use Carp;

use Scalar::Util qw/openhandle/;

use File::Find;

use YAML::XS ();

sub new { bless {}, shift }

sub slurp {
  my ($self, $path) = @_;
  
  my $slurped;
  
  if ( openhandle($path) ) {
    local $/; $slurped = <$path>;
  } else {
    open my $fh, '<:encoding(utf8)', $path 
      or croak "Conf open failed: $path: $!";
    { local $/; $slurped = <$fh> }
    close $fh;
  }

  return $slurped
}

sub parse_conf {
  my ($self, $path) = @_;
  my $yaml = $self->slurp($path);
  croak "No data returned from parse_conf: $path" 
    unless $yaml;

  my $ref = YAML::XS::Load($yaml);

  return $ref
}

sub parse_nets {
  my ($self, $dir) = @_;
  
  my $nethash = {};
  
  my @specfiles = ref $dir eq 'ARRAY' ?  @$dir
                  : $self->find_nets($dir) ;

  SERV: for my $specpath (@specfiles) {
    my $this_spec = $self->parse_conf($specpath);
    
    unless ($this_spec->{Server}) {
      croak "specfile missing Server definition: $specpath"
    }
    
    unless ($this_spec->{Network}) {
      croak "specfile missing Network definition: $specpath"
    }

    my $servname = $this_spec->{Server};
    my $netname  = $this_spec->{Network};
    
    $nethash->{$netname}->{$servname} = $this_spec;
  }

  return $nethash
}

sub find_nets {
  my ($self, $dir) = @_;
  
  croak "find_nets called with no NetworkDir"
    unless $dir;
  
  croak "find_nets called against non-directory $dir"
    unless -d $dir;
  
  my @found;
  find(
    sub {
      my $thisext = (split /\./)[-1] // return;
      push(@found, $File::Find::name)
        if $thisext eq 'server';
    },
    $dir
  );

  return wantarray ? @found : \@found ;
}


## Example CF

sub get_example_conf { get_example_cf(@_) }
sub get_example_cf {
  my ($self, $cftype) = @_;
  my $method = 'example_cf_'.$cftype;
  
  unless ($self->can($method)) {
    croak "Invalid example conf type: $cftype"
  }

  return $self->$method
}

sub write_example_conf { write_example_cf(@_) }
sub write_example_cf {
  my ($self, $cftype, $path) = @_;
  croak "write_example_cf requires a type and path"
    unless $cftype and $path;
  
  my $conf = $self->get_example_cf($cftype); 

  if ( openhandle($path) ) {
    print $path $conf;
  } else {
    open my $fh, '>', $path or die "open failed: $!\n";
    print $fh $conf;
    close $fh;
  }
}

sub example_cf_spec {
  my $conf = <<END;
---
### Example server spec file

Network: CobaltIRC
Server: eris.oppresses.us
Port: 6667
# Defaults are probably fine here:
#Nickname:
#BindAddr:
#UseIPV6:
#Timeout: 90
#Interval: 5

END

  return $conf
}

sub example_cf_httpd {
  my $conf = <<END;
---
### Example HTTPD conf

## ServerPort:
##
## Port to run this HTTPD instance on.
ServerPort: 8700

## BindAddr:
##
## Optional local address to bind HTTPD to.
#BindAddr: '0.0.0.0'

## NetworkDir:
##
## Network spec files will be found recursively under NetworkDir:
## A network spec file should end in ".server"
## These specs tie networks together under their specified Network:
## The files should be YAML, looking something like:
#   ---
#   Network: CobaltIRC
#   Server: eris.oppresses.us
#   Port: 6667
#   Timeout: 90
#   Interval: 5
##
## If you have multiple .server files for one Network, their Servers
## will be cycled.
## Specifying a round-robin will also generally do what you mean.
NetworkDir: /home/ircindex/networks

## CacheDir:
##
## Large pools of trawlers will store quite a bit of data after 
## a few runs have completed.
## This trades some performance for significant memory savings.
##
## You probably want this.
##
## If a CacheDir is not specified, resultsets will live in memory;
## additionally, due to the nature of the forking encoders,
## there will be some extra processing overhead when results are 
## cached.
CacheDir: /home/ircindex/jsoncache

## LogFile:
##
## Path to log file.
## If omitted, no logging takes place.
LogFile: /home/ircindex/indexer.log

## LogLevel:
##
## Log verbosity level.
## 'debug', 'info', or 'warn'
LogLevel: info

## LogHTTP:
##
## If true, log HTTP-related activity
## Defaults to ON
LogHTTP: 1

## LogIRC:
##
## If true, log trawling-related activity
## Defaults to ON
LogIRC: 1

## PidFile:
##
## If a PidFile is specified, the server's PID will be written to the 
## specified file.
#PidFile:

## TrawlInterval:
##
## Delay (in seconds) between trawl runs per-network.
## Can be overriden with the --interval command opt.
## Defaults to 600 (10 mins)
#TrawlInterval: 600

## Forking:
##
## If Forking is enabled, trawlers will be spawned as external
## processes rather than running asynchronously as part of a 
## single process.
##
## A trawler that is composing a very large list of channels
## can use a fair bit of CPU; if you can spare a little extra
## memory during runs and have the cores for it, fork them instead.
Forking: 0

## MaxTrawlers:
##
## If you are handling a lot of networks, you may want to limit
## the number of forked trawlers that can be running at a given 
## time.
##
## If Forking is not enabled, this controls the number of async 
## trawlers that will be ->run() at a time.
##
## Only one trawler will run per network; in other words, the 
## theoretical maximum number of trawlers if MaxTrawlers is not 
## set is the number of configured networks.
##
## You might want a shorter per-trawler timeout if you are severely 
## limiting your MaxTrawlers.
##
## Defaults to 20; 0 or empty string '' disables.
#MaxTrawlers: 10

## MaxEncoders:
##
## Workers are forked off to handle the potentially expensive 
## JSON encoding of server trawl results; if you're trawling 
## a lot of networks, you may want to throttle these to avoid
## resource starvation.
##
## It's perfectly safe to set to '1' -- the only downside is 
## increasing the odds of keeping more networks in memory 
## longer before they can be shuffled off to an encoder.
##
## Defaults to 20.
#MaxEncoders: 10

## ListChans:
##
## If ListChans is enabled, the server will create sorted lists of 
## channels as documented in IRC::Indexer::POD::ServerSpec
##
## Expensive in terms of CPU and space.
ListChans: 0

END

  return $conf
}

1;
__END__

=pod

=head1 NAME

IRC::Indexer::Conf - Handle Indexer configuration files

=head1 SYNOPSIS

  my $cfhash = IRC::Indexer::Conf->parse_conf($path);
  
  ## Recursively read server spec files:
  my $nethash = IRC::Indexer::Conf->parse_nets($specfile_dir);

=head1 DESCRIPTION

Handles IRC::Indexer configuration files in YAML format.

This module can also generate example configuration files.

=head1 METHODS

Methods can be called as either class or object methods.

=head2 parse_conf

Takes either a file path or a previously-opened filehandle.

Read and parse a specified YAML configuration file, returning the 
deserialized contents.

parse_conf will croak() if the path cannot be read or does not 
contain YAML.

L<YAML::XS> will throw an exception if the YAML is not valid.

=head2 parse_nets

Takes either a directory or an array reference containing a 
previously-discovered list of server spec files.

Calls L</find_nets> to discover server spec files.

  IRC::Indexer::Conf->parse_nets($spec_dir);
  IRC::Indexer::Conf->parse_nets(\@specfiles);

Returns a hash with the following structure:

  $NETWORK => {
    $ServerA => $spec_file_hash,
  }

=head2 find_nets

Locate C<.server> spec files recursively under a specified directory.

  my @specfiles = IRC::Indexer::Conf->find_nets($spec_dir);

Returns an array in list context or an array reference in scalar 
context.

=head2 get_example_cf

Returns the raw YAML for an example configuration file.

  IRC::Indexer::Conf->get_example_cf('httpd');

Valid types, as of this writing, are:

  httpd
  spec

=head2 write_example_cf

Writes an example configuration file to a specified path.

  IRC::Indexer::Conf->write_example_cf('httpd', $path);
  
  ## From a shell, perhaps:
  $ perl -MIRC::Indexer::Conf -e \
    'IRC::Indexer::Conf->write_example_cf("httpd", "myhttpd.cf")'

See L</get_example_cf> for a list of valid types.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
