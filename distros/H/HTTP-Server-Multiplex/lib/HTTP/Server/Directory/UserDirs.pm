# Copyrights 2008 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.05.
use warnings;
use strict;

package HTTP::Server::Directory::UserDirs;
use vars '$VERSION';
$VERSION = '0.11';

use base 'HTTP::Server::Directory';

use Log::Report 'httpd-multiplex', syntax => 'SHORT';


sub init($)
{   my ($self, $args) = @_;

    my $subdirs = $args->{user_subdirs} || 'public_html';
    my %allow   = map { ($_ => 1) } @{$args->{allow_users} || []};
    my %deny    = map { ($_ => 1) } @{$args->{deny_users}  || []};
    $args->{location} ||= $self->userdirRewrite($subdirs, \%allow, \%deny);

    $self->SUPER::init($args);
    $self;
}

#-----------------

#-----------------

sub userdirRewrite($$$)
{   my ($self, $udsub, $allow, $deny) = @_;
    my %homes;  # cache
    sub { my ($user, $pathinfo) = $_[0] =~ m!^/\~([^/]*)(.*)!;
          return if keys %$allow && !$allow->{$user};
          return if keys %$deny  &&  $deny->{$user};
          return if exists $homes{$user} && !defined $homes{$user};
          my $d = $homes{$user} ||= (getpwnam $user)[7];
          $d ? "$d/$udsub$pathinfo" : undef;
        };
}

1;
