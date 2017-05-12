# Copyrights 2008 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.05.
use strict;
use warnings;

package HTTP::Server::Connection;
use vars '$VERSION';
$VERSION = '0.11';


use HTTP::Server::Multiplex;
use HTTP::Server::Session;

use HTTP::Request    ();
use HTTP::Response   ();
use HTTP::Status;
use HTTP::Date       qw(time2str str2time);
use URI              ();
use LWP::MediaTypes  qw(guess_media_type);
use Fcntl            qw(O_RDONLY);
use Scalar::Util     qw(weaken);
use Socket           qw(unpack_sockaddr_in inet_ntoa);
use Storable         qw(freeze thaw);
use Fcntl            qw(:mode);
use POSIX            qw(strftime);

use Log::Report 'httpd-multiplex', syntax => 'SHORT';

use constant
 { HTTP_0_9 => 'HTTP/0.9'
 , HTTP_1_0 => 'HTTP/1.0'
 , HTTP_1_1 => 'HTTP/1.1'
 };

my @stat_fields =
   qw/dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks/;

my @default_headers;
sub setDefaultHeaders(@) {my $class = shift; push @default_headers, @_};

# oops, dirty hack
sub HTTP::Request::id() { shift->{HSC_id} }


my $conn_id = 'C0000000';

sub new($$$$)
{   my ($class, $mux, $fh, $daemon) = @_;
    my $self = bless {}, $class;
    $self->{HSC_requests} = [];
    $self->{HSC_mux}      = $mux;
    $self->{HSC_fh}       = $fh;
    $self->{HSC_session}  = HTTP::Server::Session->new;  # will change

    $self->{HSC_daemon}   = $daemon;
    weaken $self->{HSC_daemon};

    $self->{HSC_connect}  = time;
    $self->{HSC_conn_id}  = ++$conn_id;
    $self->{HSC_reqcount} = 0;

    my $peername          = $fh->peername;
    my ($port, $addr)     = unpack_sockaddr_in $peername;
    my $ip                = inet_ntoa $addr;
    info "$self->{HSC_conn_id} contacted by $ip:$port";

    my %client            = (port => $port, ip => $ip, host => undef);
    $daemon->dnslookup($self, $ip, \$client{host});
    $self->{HSC_client}   = \%client;

    $self;
}

sub client()  {shift->{HSC_client}}
sub session() {shift->{HSC_session}}
sub id()      {shift->{HSC_conn_id}}

# new text was received.  Collect it into an HTTP::Request
sub mux_input($$$)
{   my ($self, $mux, $fh, $refdata) = @_;
    my $req = $self->{HSC_next};

    # ignore input for closing, connection can still be writing
    if(!$req && $self->{HSC_no_more})
    {   $$refdata = '';
        return;
    }

    my $headers;
    if($req)
    {   $headers  = $req->headers;
    }
    else
    {   $$refdata =~ s/^\s+//s;                     # strip leading blanks
        $$refdata =~ s/(.*?)\r\n\r\n//s or return;  # not whole header yet
        $req  = $self->{HSC_next} = HTTP::Request->parse($1);
        $req->{HSC_id}
           = $self->{HSC_conn_id} . sprintf('-%02d', $self->{HSC_reqcount}++);

        my $proto = $req->protocol;
        $req->protocol($proto = HTTP_0_9)
            unless $proto;

        $headers  = $req->headers;
        $self->{HSC_no_more}++
            if $req->protocol lt HTTP_1_1
            || lc($headers->header('Connection') || '') ne 'keep-alive';

        if($proto lt HTTP_1_0)
        {   $self->{take_all}++;
            return;
        }
      
        if(my $expect = $headers->header('Expect'))
        {   if(lc $expect ne '100-continue')
            {   my $resp = $self->sendStatus($req, RC_EXPECTATION_FAILED);
                trace "Unsupported Expect value '$expect'";
                $self->cancelConnection;
                return $resp;
            }
            $self->sendStatus($req, RC_CONTINUE);
        }
    }

    my $te = lc($headers->header('Transfer-Encoding') || '');
    my $cl = $headers->header('Content-Length') || 0;

    if($te eq 'chunked')
    {   my ($starter, $len) = $$refdata =~ m/^((\S+)\r?\n)/ or return;
        if($len !~ m/^[0-9a-fA-F]+$/)
        {   my $resp = $self->sendStatus($req, RC_BAD_REQUEST);
            trace "Bad chunk header $len";
            $self->cancelConnection;
            return $resp;
        }
        my $need = hex $len;

        my $chunk_length = length($starter) + $need + 2;
        return if length($$refdata) < $chunk_length;
 
        if($need!=0)
        {   $req->add_content(substr $$refdata, length($starter), $need);
            substr($$refdata, 0, $chunk_length) = '';
            return;  # get more chunks
        }

        return if $$refdata !~ m/\n\r?\n/;  # need footer
        my ($footer) = $$refdata =~ s/^0+\r?\n(.*?\r?\n)\r?\n//;
        my $header   = $req->headers;
        HTTP::Message->parse($footer)->headers
                     ->scan(sub { $header->push_header(@_)} );

        $header->_header('Content-Length' => length ${$req->content_ref});
        $header->remove_header('Transfer-Encoding');
    }
    elsif($te ne '')
    {   my $resp = $self->sendStatus($req, RC_NOT_IMPLEMENTED);
        trace "Unsupported transfer encoding $te";
        $self->cancelConnection;
        return $resp;
    }
    elsif(defined $cl)
    {   return if defined $cl && length($$refdata) < $cl;
        $req->content(substr $$refdata, 0, $cl, '');
    }
    elsif(($headers->header('Content-Type') || '')
            =~ m/^multipart\/\w+\s*;.*boundary\s*=(["']?)\s*(\w+)\1/i)
    {   return unless $$refdata =~ s/(.*?\r?\n--\Q$2\E--\r?\n)//;
        $req->content($1);
    }
    else
    {   $self->closeConnection;
        $self->{take_all}++;
        # collect till eof
    }

    $mux->shutdown($fh, 0)
        if $self->{HSC_no_more};

    info $req->id.' '.$req->protocol.' '.$req->method.' '.$req->uri;
    if($self->{HSC_reqcount}==1)
    {   my $ua = $req->headers->header('User-Agent');
        info $req->id.' UA='.$ua   if $ua;
    }

    $self->addRequest(delete $self->{HSC_next});
}

sub mux_eof($$$)
{   my ($self, $mux, $fh, $refdata) = @_;

    my $req = delete $self->{HSC_next};
    if($req && length($$refdata) && $self->{take_all})
    {   $req->content_ref($refdata);
        $self->addRequest($req);
    }
    elsif($$refdata =~ m/\S/)
    {   trace "trailing data in request (".length($$refdata)." bytes) ignored";
    }

    $mux->shutdown($fh, 1);
}

# This is the most tricky part: each connection may have multiple
# requests queued.  If the handler returns a response object, the
# the response succeeded.  Otherwise, other IO will need to be performed:
# we simply stop.  When the other IO has completed, it will call this
# function again, to resolve the other requests.

sub addRequest($)
{   my ($self, $req) = @_;
    my $queue = $self->{HSC_requests};
    push @$queue, $req;

    # handler initiated by first request in queue, then auto-continues
    $self->handleRequests
        if @$queue==1;
}

sub handleRequests()
{   my ($self) = @_;
    my $queue  = $self->{HSC_requests};

  REQUEST:
    while(@$queue)
    {   my $req = shift @$queue;
        my $vhostn  = $req->header('Host');
        $vhostn     =~ s/\:(\d+)$//;   # strip optional port; ignored for now

        if(!defined $vhostn)
        {   if($req->protocol gt HTTP_1_1)
            {   $self->sendStatus($req, RC_MULTIPLE_CHOICES,
                "explicit virtual host required in protocol ".$req->protocol);
                next REQUEST;
            }
            $vhostn = 'default';
        }

        my $vhost   = $self->{HSC_daemon}->virtualHost($vhostn);
        unless(defined $vhost)
        {   $self->sendStatus($req, RC_NOT_FOUND, "no virtual host $vhostn");
            next REQUEST;
        }

        my $resp = $vhost->handleRequest($self, $req);
        defined $resp
            or last REQUEST;  # no answer==waiting in MUX
    }
}


sub sendResponse($$$;$)
{   my ($self, $req, $status, $header, $content) = @_;
    my $protocol = $req->protocol;
    defined $content or $content = '';

    if($protocol ge HTTP_1_0)
    {   push @$header
          , Date       => time2str(time)
          , Connection => ($self->{HSC_no_more} ? 'close' : 'keep-alive')
          , @default_headers;

        push @$header
          , ref $content eq 'CODE'
            ? ('Transfer-Encoding' => 'chunked')
            : ('Content-Length'    => length $content);
    }
    else
    {   undef $header;
    }

    my $resp = HTTP::Response->new($status, status_message($status),$header);
    $resp->request($req);
    $resp->protocol($protocol);

    my ($mux, $fh) = @$self{'HSC_mux', 'HSC_fh'};
    my $headtxt = $resp->as_string("\r\n");
    my $size    = length $headtxt;
    if($req->method eq 'HEAD')
    {   $mux->write($fh, $headtxt);
    }
    elsif(ref $content eq 'CODE')
    {   # create chunked
        $mux->write($fh, $headtxt);
        $size = 0;
        while(1)
        {   my $chunk = $content->();
            defined $chunk or last;
            length  $chunk or next;
            my $hexlen = sprintf "%x", length $chunk;
            $mux->write($fh, "$hexlen\r\n$chunk\r\n");
            $size     += length($hexlen) + length($chunk) + 4;
        }
        $mux->write($fh, "0\r\n\r\n");   # end chunks and no footer
        $size += 5;
    }
    else
    {   $resp->content_ref(\$content);
        $mux->write($fh, $headtxt.$content);
    }

    info $req->id." $status ${size}b";
    $resp;
}


sub sendStatus($$;$)
{   my ($self, $req, $status, $text) = @_;
    my $descr   = defined $text && length $text ? "\n<p>$text</p>" : '';
    my @headers = ('Content-Type' => 'text/html');
    my $message = status_message $status;

    $self->sendResponse($req, $status, \@headers, <<__CONTENT);
<html><head><title>$status $message</title></head>
<body><h1>$status $message</h1>$descr
</body></html>
__CONTENT
}


sub sendRedirect($$$;$)
{   my ($self, $req, $status, $location, $content) = @_;
    is_redirect $status
        or panic "Status '$status' is not redirect";

    my @headers = (Location => $location);
    if(defined $content && length $content)
    {   my $ct  = $content =~ m/^\s*\</ ? 'text/html' : 'text/plain';
        push @headers, 'Content-Type' => $ct;
    }

    $self->sendResponse($req, $status, \@headers, $content);
}


sub sendFile($$;$$)
{   my ($self, $req, $file, $headers, $user_callback) = @_;
    $user_callback ||= sub {};
    my ($callback, @headers);
    push @headers, @$headers if $headers;

    my $from_fh;
    if(ref $file)
    {   $from_fh = $file;
        $callback = sub
          { $user_callback->(@_);
            $self->handleRequests;
          };
    }
    else
    {   -e $file or return
            $self->sendStatus(RC_NOT_FOUND, "file $file does not exist");

        -f _ or return
            $self->sendStatus(RC_NOT_ACCEPTABLE, "not a file $file");

        sysopen $from_fh, $file, O_RDONLY
            or return $self->sendStatus(RC_FORBIDDEN, "no access to $file");

        $callback = sub
          { $user_callback->(@_);
            close $from_fh;  # read errors are ignored
            $self->handleRequests;
          };

        my ($ct, $ce) = guess_media_type $file;
        push @headers
          , Date       => time2str(time)
          , Connection => ($self->{HSC_no_more} ? 'close' : 'keep-alive')
          , @default_headers
          , 'Content-Type' => $ct;
        push @headers, 'Content-Encoding' => $ce if $ce;
    }

    my ($size, $mtime) = (stat $from_fh)[7,9];
    push @headers, 'Content-Length' => $size if $size;

    my $status = RC_OK;
    if($mtime)
    {   if(my $ims = $req->header('If-Modified-Since'))
        {   my $imstime = str2time $ims;
            $status     = RC_NOT_MODIFIED if $mtime==$imstime;
        }
        push @headers, 'Last-Modified' => time2str($mtime);
    }

    my $resp = HTTP::Response
        ->new($status, status_message($status), \@headers);

    $resp->request($req);
    $resp->protocol($req->protocol);

    my ($mux, $clientfh) = @$self{'HSC_mux', 'HSC_fh'};
    $mux->write($clientfh, $resp->as_string("\r\n"));

    if($req->method eq 'HEAD')
    {   info $req->id." sent head of $file";
        return $resp;
    }
    if($status==RC_NOT_MODIFIED)
    {   info $req->id." file $file was not modified";
        return $resp;
    }

    info $req->id." sent file $file, ${size}b";

    my $pump = _PUMP::PROXY->new($clientfh, $callback);
    $mux->add($from_fh);
    $mux->set_callback_object($pump, $from_fh);
    undef;
}


sub cancelConnection()
{   my $self = shift;
    info $self->id.' connection cancelled';
    delete @$self{'HSC_next', 'HSC_requests'};
    $self->closeConnection;
}


sub closeConnection()
{   my $self = shift;
    info $self->id.' connection closed';
    $self->{HSC_no_more}++;
}


my %filetype =
  ( &S_IFSOCK => 's', &S_IFLNK => 'l', &S_IFREG => '-', &S_IFBLK => 'b'
  , &S_IFDIR  => 'd', &S_IFCHR => 'c', &S_IFIFO => 'p');

my @flags    = ('---', '--x', '-w-', '-wx', 'r--', 'r-x', 'rw-', 'rwx');
    
sub directoryList($$$@)
{   my ($self, $req, $dirname, $callback, %opts) = @_;

    trace $self->id. " listing of directory $dirname";
    opendir my $from_dir, $dirname
        or return $self->sendStatus($req, RC_FORBIDDEN);

    my $names      = $opts{names} || qr/^[^.]/;
    my $prefilter
       = ref $names eq 'Regexp' ? sub { $_[0] =~ $names }
       : ref $names eq 'CODE'   ? $names
       : panic "directoryList(names) must be regexp or code, not $names";

    my $postfilter = $opts{filter} || sub {1};
    ref $postfilter eq 'CODE'
        or panic "directoryList(filter) must be code, not $postfilter";

    my $hide_symlinks = $opts{hide_symlinks};

    my $run_async = sub
      { my (%dirlist, %users, %groups);
        foreach my $name (grep {$prefilter->($_)} readdir $from_dir)
        {   my $path = $dirname.$name;
            my %d = (name => $name, path => $path);
            @d{@stat_fields}
                = $hide_symlinks ? stat($path) : lstat($path);

               if(!$hide_symlinks && -l _)
                        { @d{qw/kind is_symlink  /} = ('SYMLINK',  1)}
            elsif(-d _) { @d{qw/kind is_directory/} = ('DIRECTORY',1)}
            elsif(-f _) { @d{qw/kind is_file     /} = ('FILE',     1)}
            else        { @d{qw/kind is_other    /} = ('OTHER',    1)}

            $postfilter->(\%d)
                or next;

            if($d{is_symlink})
            {   my $sl = $d{symlink_dest} = readlink $path;
                $d{symlink_dest_exists} = -e $sl;
            }
            elsif($d{is_file})
            {   my ($s, $l) = ($d{size}, '  ');
                ($s,$l) = ($s/1024, 'kB') if $s > 1024;
                ($s,$l) = ($s/1024, 'MB') if $s > 1024;
                ($s,$l) = ($s/1024, 'GB') if $s > 1024;
                $d{size_nice} = sprintf +($s>=100?"%.0f%s":"%.1f%s"), $s,$l;
            }
            elsif($d{is_directory})
            {   $d{name} .= '/';
            }

            if($d{is_file} || $d{is_directory})
            {   $d{user}  = $users{$d{uid}} ||= getpwuid $d{uid};
                $d{group} = $users{$d{gid}} ||= getgrgid $d{gid};
                my $mode = $d{mode};
                my $b = $filetype{$mode & S_IFMT} || '?';
                $b   .= $flags[ ($mode & S_IRWXU) >> 6 ];
                substr($b, -1, -1) = 's' if $mode & S_ISUID;
                $b   .= $flags[ ($mode & S_IRWXG) >> 3 ];
                substr($b, -1, -1) = 's' if $mode & S_ISGID;
                $b   .= $flags[  $mode & S_IRWXO ];
                substr($b, -1, -1) = 't' if $mode & S_ISVTX;
                $d{flags}      = $b;
                $d{mtime_nice} = strftime "%F %T", localtime $d{mtime};
            }
            $dirlist{$name} = \%d;
        }
        \%dirlist;
      };

    $self->async($req, $run_async, $callback);
    undef;
}


sub async
{   my ($self, $req, $run, $after) = @_;

    my ($reader, $writer);
    unless(pipe $reader, $writer)
    {   $self->sendStatus($req, RC_INTERNAL_SERVER_ERROR, "pipe: $!");
        return 0;
    }
 
    my $pid = fork;
    unless(defined $pid)
    {   trace "failed to fork: $!";
        $self->sendStatus($req, RC_INTERNAL_SERVER_ERROR, "fork: $!");
        return 0;
    }

    if($pid==0)  # child
    {   close $reader;
        my %data;
        $data{user} = [ $run->() ];
        $writer->print(freeze \%data);
        exit 0;
    }

    # parent
    close $writer;
 
    my $mux = $self->{HSC_mux};
    $mux->add($reader);
    my $callback = sub
      { my $data = eval { thaw ${$_[0]} };
        $mux->remove($reader);
        waitpid $pid, 0;   # need to check return
        $after->(@{$data->{user}});
        $self->handleRequests;
      };

    $mux->set_callback_object(_PUMP::READFILE->new($callback), $reader);
    1;
}


sub load($$)
{   my ($self, $file, $cb) = @_;
    my ($f, $callback);

    if(ref $file)
    {   ($f, $callback) = ($file, $cb);
    }
    else
    {   open $f, '<', $file
            or return $cb->(undef);

        trace "reading file $file";
        $callback = sub
          { close $f;
            $cb->($_[0]);
          };
    }

    my $mux = $self->{HSC_mux};
    $mux->add($f);
    $mux->set_callback_object(_PUMP::READFILE->new($callback), $f);
    undef;
}

sub readFile(@) {die "readFile() renamed to load() in 0.11"}


sub save($$$)
{   my ($self, $file, $data, $cb) = @_;
    my ($f, $callback);
    my $mux = $self->{HSC_mux};

    if(ref $file)
    {   ($f, $callback) = ($f, $cb);
    }
    else
    {   # IO::Multiplex is not able to deal with write-only file-handles,
        # Therefore '+>' i.s.o. simply '>' rt.cpan.org#39131
        open $f, '+>', $file
            or return $cb->(undef);

        trace "writing file $file";
        $callback = sub
          { close $f;
            $mux->remove($f);
            $cb->(@_);
          };
    }

    $mux->add($f);
    $mux->set_callback_object(_PUMP::WRITEFILE->new($callback), $f);
    $mux->write($f, ref $data eq 'SCALAR' ? $$data : $data);
    undef;
}
sub writeFile(@) {die "writeFile() renamed to save() in 0.11"}

#------------------------


##### _PUMP::PROXY
# Copy from incoming file-handle to out-going filehandle.

package _PUMP::PROXY;
use vars '$VERSION';
$VERSION = '0.11';


# $class->new($outfh,$callback)
sub new($$) { my $class = shift; bless \@_, $class }

sub mux_input($$$)
{   my ($outfh, $mux, $refdata) = ($_[0][0], $_[1], $_[3]);
    $mux->write($outfh, $$refdata);
    $$refdata = '';
}

sub mux_close() { shift->[1]->() }

##### _PUMP::READFILE
# Copy from incoming file-handle into a variable

package _PUMP::READFILE;
use vars '$VERSION';
$VERSION = '0.11';


# $class->new($callback)
sub new($) { my $class = shift; bless \@_, $class }

sub mux_eof($$$$)
{   my ($self, $mux, $fh, $refdata) = @_;
    $self->[0]->($refdata);
}

##### _PUMP::WRITEFILE
# Copy data to a file, and then call the callback

package _PUMP::WRITEFILE;
use vars '$VERSION';
$VERSION = '0.11';


# $class->new($callback)
sub new($) { my $class = shift; bless \@_, $class }

sub mux_eof($$)
{   my ($self, $mux, $fh) = @_;
    $self->[0]->();
}

1;
