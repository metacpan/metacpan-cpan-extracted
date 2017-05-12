
package Email::Blaster::ConfigLoader;

use strict;
use warnings 'all';
use XML::Simple ();
$XML::Simple::PREFERRED_PARSER = 'XML::Parser';
use Email::Blaster::Config;
use Cwd 'cwd';

our $CONFIGFILE = 'email-blaster-config.xml';
our $Configs = { };

#==============================================================================
sub load
{
  my ($s) = @_;
  
  my $path = $s->config_path;
  return $Configs->{$path} if $Configs->{$path};
  
  my $xml = XML::Simple::XMLin( $path,
    ForceArray => [qw/ throttle handler lib server /],
    SuppressEmpty => '',
  );
  
  (my $where = $path) =~ s/\/conf\/[^\/]+$//;
  my $doc = Email::Blaster::Config->new( $xml, $where );
  
  return $Configs->{$path} = $doc;
}# end parse()

#==============================================================================
sub config_path
{
  my $path = $CONFIGFILE;
  
  my $root = $ENV{DOCUMENT_ROOT} || cwd();
  
  # Try test dir:
  if( -f "$root/t/conf/$CONFIGFILE" )
  {
    return "$root/t/conf/$CONFIGFILE";
  }# end if()
  
  # Start moving up:
  for( 1...10 )
  {
    my $path = "$root/conf/$CONFIGFILE";
    return $path if -f $path;
    $root =~ s/\/[^\/]+$//
      or last;
  }# end for()
  
  die "CANNOT FIND '$CONFIGFILE'";
}# end config_path()

1;# return true:

