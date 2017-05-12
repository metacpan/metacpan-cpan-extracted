# Copyrights 2008 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.05.
package HTTP::Server::VirtualHost;
use vars '$VERSION';
$VERSION = '0.11';

use warnings;
use strict;

use HTTP::Server::Multiplex;
use HTTP::Server::Directory;
use HTTP::Server::Directory::UserDirs;

use Log::Report 'httpd-multiplex', syntax => 'SHORT';

use HTTP::Status;
use List::Util   qw/first/;
use English      qw/$EUID/;
use File::Spec   ();


sub new(@)
{   my $class = shift;
    my $args  = @_==1 ? shift : {@_};
    (bless {}, $class)->init($args);
}

sub init($)
{   my ($self, $args) = @_;

    my $name = $self->{HSV_name} = $args->{name};
    defined $name
        or error __x"virtual host {pkg} has no name", pkg => ref $self;

    my $aliases = $args->{aliases}            || [];
    $self->{HSV_aliases}  = ref $aliases eq 'ARRAY' ? $aliases : [$aliases];

    $self->{HSV_rewrite}  = $args->{rewrite}  || sub {$_[0]};
    $self->{HSV_dirlist}  = $args->{directory_list};
    $self->{HSV_handlers} = $args->{handlers} || {};

    $self->{HSV_dirs}     = {};
    if(my $docroot = $args->{documents})
    {   File::Spec->file_name_is_absolute($docroot)
            or error __x"vhost {name} documents directory must be absolute"
                 , name => $name;
        -d $docroot
            or error __x"vhost {name} documents `{dir}' must point to dir"
                 , name => $name, dir => $docroot;
        $docroot =~ s/\\$//; # strip trailing / if present
        $self->addDirectory(path => '/', location => $docroot);
    }
    my $dirs = $args->{directories} || [];
    $self->addDirectory($_) for ref $dirs eq 'ARRAY' ? @$dirs : $dirs;

    my $ud;
    if(!exists $args->{user_dirs})
    {   $ud = HTTP::Server::Directory::UserDirs->new }
    elsif($ud = $args->{user_dirs})
    {   if(ref $ud eq 'HASH')
        {   $ud = HTTP::Server::Directory::UserDirs->new($ud) }
        elsif(not $ud->isa('HTTP::Server::Directory::UserDirs'))
        {   error __x"vhost {name} user_dirs is not an ::UserDirs object"
              , name => $self->name;
        }
    }
    $self->{HSV_udirs} = $ud;

    my $if = $args->{index_file};
    my @if = ref $if eq 'ARRAY' ? @$if
           : defined $if        ? $if
           : qw/index.html index.html/;
    $self->{HSV_indexfns} = \@if;

    $self;
}

#---------------------

sub name()    {shift->{HSV_name}}
sub aliases() {@{shift->{HSV_aliases}}}

#---------------------

sub requestForMe($)
{   my ($self, $uri) = @_;
    my $host = $uri->host;
    $host eq $self->name || first {$host eq $_} $self->aliases;
}


sub handleRequest($$)
{   my ($self, $conn, $req) = @_;

    my $uri = $self->rewrite($req->uri);
    if($uri ne $req->uri)
    {   info $req->id." rewritten to $uri";
        $self->requestForMe($uri)
            or return $conn->sendRedirect($req, RC_TEMPORARY_REDIRECT, $uri);
    }

    my $path = $uri->path;
    my $tree = $self->directoryOf($path)
        or return $conn->sendStatus($req, RC_FORBIDDEN, "$path not configured");

    $tree->allow($conn->client, $conn->session, $req, $uri)
        or return
             $conn->sendStatus($req, RC_FORBIDDEN, "$path access not allowed");

    if(my $handler = $self->{HSV_handlers}{$path})
    {   return $handler->($conn, $req, $uri);
    }

    my $item = $tree->filename($path);

    -f $item  # filename
        and return $conn->sendFile($req, $item);

    -d _      # neither file nor directory
        or return $conn->sendStatus($req, RC_NOT_FOUND
            , "special file cannot be accessed");

    substr($item, -1) eq '/'
        or return $conn->sendRedirect($req, RC_TEMPORARY_REDIRECT, $path .'/');

    foreach my $if (@{$self->{HSV_indexfns}})
    {   return $conn->sendFile($req, $item.$if, [Location => $path.$if])
            if -f $item.$if;
    }

    $self->{HSV_dirlist}
        or return $conn->sendStatus($req, RC_FORBIDDEN, "no directory list");

    # Directory handling

    $conn->directoryList($req, $item
      , sub { my $list = shift;
              return $list if UNIVERSAL::isa($list, 'HTTP::Response');
              $self->showDirectory($conn, $req, $path, $list);
            });
}


sub showDirectory($$$$)
{   my ($self, $conn, $req, $dir, $list) = @_;
    my $now  = localtime;
    my @rows;
    push @rows, <<__UP if $dir ne '/';
<tr><td colspan="5">&nbsp;</td><td><a href="../">(up)</a></td></tr>
__UP

    foreach my $item (sort keys %$list)
    {   my $d = $list->{$item};
        push @rows, <<__ROW;
<tr><td>$d->{flags}</td>
    <td>$d->{user}</td>
    <td>$d->{group}</td>
    <td align="right">$d->{size_nice}</td>
    <td>$d->{mtime_nice}</td>
    <td><a href="$d->{name}">$d->{name}</a></td></tr>
__ROW
    }

    local $" = "\n";
    $conn->sendResponse($req, RC_OK, [], <<__PAGE);
<html><head><title>$dir</title></head>
<style>TD { padding: 0 10px; }</style>
<body>
<h1>Directory $dir</h1>
<table>
@rows
</table>
<p><i>Generated $now</i></p>
</body></html>
__PAGE
}

#----------------------

sub rewrite($) { $_[0]->{HSV_rewrite}->($_[1]) }


sub allow($$$$)
{   my ($self, $client, $session, $req, $uri) = @_;

    if($EUID==0 && substr($uri->path, 0, 2) eq '/~')
    {   notice "deamon running as root, {session} only access to {path}"
          , session => $session->id, path => '/~user';
        return 0;
    }
    1;
}

#------------------

sub filename($)
{   my ($self, $uri) = @_;

    my $path = $uri->path;
    my $dir = $self->directoryOf($path);
    $dir ? $dir->filename($path) : undef;
}


sub addDirectory(@)
{   my $self = shift;
    my $dir  = @_==1 ? shift : HTTP::Server::Directory->new(@_);
    my $path = $dir->path || '';
    !exists $self->{HSV_dirs}{$path}
        or error __x"vhost {name} directory `{path}' defined twice"
             , name => $self->name, path => $path;
    $self->{HSV_dirs}{$path} = $dir;
}


sub directoryOf($)
{   my ($self, $path) = @_;
    return $self->{HSV_udirs}
        if $path =~ m!^/\~!;

    my $dirs = $self->{HSV_dirs};
    $path =~ s!/$!!;

    while(length $path)
    {   return $dirs->{$path} if $dirs->{$path};
        $path =~ s!/[^/]+$!! or return;
    }
    $dirs->{'/'} ? $dirs->{'/'} : ();
}



1;
