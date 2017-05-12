# Copyrights 2008 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.05.
package HTTP::Server::Directory;
use vars '$VERSION';
$VERSION = '0.11';

use warnings;
use strict;

use Log::Report 'httpd-multiplex', syntax => 'SHORT';

use Net::CIDR    qw/cidrlookup/;
use File::Spec   ();

sub _allow_cleanup($);
sub _allow_match($$$$);
sub _filename_trans($$);


sub new(@)
{   my $class = shift;
    my $args  = @_==1 ? shift : {@_};
    (bless {}, $class)->init($args);
}

sub init($)
{   my ($self, $args) = @_;

    my $path = $self->{HSD_path}  = $args->{path} || '/';
    my $loc  = $args->{location}
        or error __x"directory definition requires location";

    if(ref $loc eq 'CODE') {;}
    else
    {   File::Spec->file_name_is_absolute($loc)
           or error __x"directory location {loc} for path {path} not absolute"
                , loc => $loc, path => $path;
        -d $loc
           or error __x"directory location {loc} for path {path} does not exist"
                , loc => $loc, path => $path;

        substr($loc,-1) eq '/' or $loc .= '/';
    }
    $self->{HSD_loc}   = $loc;
    $self->{HSD_fn}    = _filename_trans $path, $loc;

    $self->{HSD_allow} = _allow_cleanup $args->{allow};
    $self->{HSD_deny}  = _allow_cleanup $args->{deny};

    $self;
}

#-----------------

sub path()     {shift->{HSD_path}}
sub location() {shift->{HSD_location}}

#-----------------

sub allow($$$$)
{   my ($self, $client, $session, $req, $uri) = @_;
    if(my $allow = $self->{HSD_allow})
    {   $self->_allow_match($client, $session, $uri, $allow) or return 0;
    }
    if(my $deny = $self->{HSD_deny})
    {    $self->_allow_match($client, $session, $uri, $deny) and return 0;
    }
    1;
}

sub _allow_match($$$$)
{   my ($self, $client, $session, $uri, $rules) = @_;
    my ($ip, $host) = @$client{'ip', 'host'};
    first { $_->($ip, $host, $session, $uri) } @$rules ? 1 : 0;
}

sub _allow_cleanup($)
{   my $p = shift or return;
    my @p;
    foreach my $r (ref $p eq 'ARRAY' ? @$p : $p)
    {   push @p
          , ref $r eq 'CODE'    ? $r
          : index($r, ':') >= 0 ? sub {cidrlookup $_[0], $r}    # IPv6
          : $r !~ m/[a-zA-Z]/   ? sub {cidrlookup $_[0], $r}    # IPv4
          : $r =~ s/^\.//       ? sub {$_[1] =~ qr/(^|\.)\Q$r\E$/i} # Domain
          :                       sub {lc($_[1]) eq lc($r)}     # hostname
    }
    @p ? \@p : undef;
}


sub filename($) { $_[0]->{HSD_fn}->($_[1]) }

sub _filename_trans($$)
{   my ($path, $loc) = @_;
    return $loc if ref $loc eq 'CODE';
    sub
      { my $x = shift;
        $x =~ s!^\Q$path!$loc! or panic "path $x not within $path";
        $x;
      };
}


1;
