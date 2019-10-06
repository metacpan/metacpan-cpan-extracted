# Copyrights 2001-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Net;
use vars '$VERSION';
$VERSION = '3.008';


use strict;
use warnings;

use base 'Mail::Box';

use Mail::Box::Net::Message;

use Mail::Message::Body::Lines;
use Mail::Message::Body::File;
use Mail::Message::Body::Delayed;
use Mail::Message::Body::Multipart;

use Mail::Message::Head;
use Mail::Message::Head::Delayed;

use Carp;
use File::Copy;
use File::Spec;
use File::Basename;


sub init($)
{   my ($self, $args)     = @_;

    $args->{lock_type}  ||= 'NONE';
    $args->{body_type}  ||= 'Mail::Message::Body::Lines';
    $args->{trusted}    ||= 0;

    my ($scheme, $s, $port, $u, $pwd, $f);
    if(my $d = $args->{folderdir})
    {   # cannot use URI, because some scheme's are fake
        ($scheme, $u, $pwd, $s, $port, $f) = $d =~
          m! ^ (\w+) \://                # scheme
               (?: ( [^:\@/]+ )          # username
                   (?:  \: ( [^\@/]+ ))? # password
                   \@ )?
               ( [a-zA-Z0-9.-]+ )?       # hostname
               (?: \: ([0-9]+)  )?       # port
               ( / .* )?                 # path
          !x;
        $args->{folderdir} =~ s!/$!!;
    }

    $args->{folder}     ||= $f || '/';

    $self->SUPER::init($args);

    $self->{MBN_hostname} = $args->{server_name}  || $s;
    $self->{MBN_port}     = $args->{server_port}  || $port;
    $self->{MBN_username} = $args->{username}     || $u;
    $self->{MBN_password} = $args->{password}     || $pwd;

    $self->log(WARNING => "The term 'hostname' is confusing wrt folder. You probably need 'server_name'")
         if exists $args->{hostname};

    $self;
}


sub create(@) {shift->notImplemented}
sub organization() { 'REMOTE' }

sub url()
{   my $self = shift;

    my ($user, $pass, $host, $port)
       = @$self{ qw/MBN_username MBN_password MBN_hostname MBN_port/ };

    my $perm = '';
    $perm    = $user if defined $user;
    if(defined $pass)
    {   $pass  =~ s/(\W)/sprintf "%%%02X", ord $1/ge;
        $perm .= ':'.$pass;
    }

    $perm   .= '@'       if length $perm;

    my $loc  = $host;
    $loc    .= ':'.$port if length $port;

    my $name = $self->name;
    $loc    .= '/'.$name if $name ne '/';
    
    $self->type . '://' . $perm . $loc;
}

1;
