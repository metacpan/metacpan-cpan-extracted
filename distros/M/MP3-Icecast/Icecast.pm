package MP3::Icecast;

=head1 NAME

MP3::Icecast - Generate Icecast streams, as well as M3U and PLSv2 playlists.

=head1 SYNOPSIS

  use MP3::Icecast;
  use MP3::Info;
  use IO::Socket;


  my $listen_socket = IO::Socket::INET->new(
    LocalPort => 8000, #standard Icecast port
    Listen    => 20,
    Proto     => 'tcp',
    Reuse     => 1,
    Timeout   => 3600);

  #create an instance to find all files below /usr/local/mp3
  my $finder = MP3::Icecast->new();
  $finder->recursive(1);
  $finder->add_directory('/usr/local/mp3');
  my @files = $finder->files;

  #accept TCP 8000 connections
  while(1){
    next unless my $connection = $listen_socket->accept;

    defined(my $child = fork()) or die "Can't fork: $!";
    if($child == 0){
      $listen_socket->close;

      my $icy = MP3::Icecast->new;

      #stream files that have an ID3 genre tag of "jazz"
      while(@files){
        my $file = shift @files;
        my $info = new MP3::Info $file;
        next unless $info;
        next unless $info->genre =~ /jazz/i;
        $icy->stream($file,0,$connection);
      }
      exit 0;
    }

    #a contrived example to demonstrate that MP3::Icecast
    #can generate M3U and PLSv2 media playlists.
    print STDERR $icy->m3u, "\n";
    print STDERR $icy->pls, "\n";

    $connection->close;
  }


=head1 ABSTRACT

MP3::Icecast supports streaming Icecast protocol over socket
or other filehandle (including STDIN).  This is useful for writing
a streaming media server.

MP3::Icecast also includes support for generating M3U and PLSv2
playlist files.  These are common formats supported by most modern
media players, including XMMS, Windows Media Player 9, and Winamp.

=head1 SEE ALSO

  The Icecast project
  http://www.icecast.org

  Namp! (Apache::MP3)
  http://namp.sourceforge.net

  Unofficial M3U and PLS specifications
  http://forums.winamp.com/showthread.php?threadid=65772

=head1 AUTHOR

 Allen Day, E<lt>allenday@ucla.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003, Allen Day

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use strict;
use File::Spec;
use File::Basename 'dirname','basename','fileparse';
use URI::Escape;
use IO::File;
use MP3::Info;

use constant DEBUG => 0;

our $VERSION = '0.02';

our %AUDIO = (
               '.mp3' => 'audio/x-mp3',
             );
our %FORMAT_FIELDS = (
                      a => 'artist',
                      c => 'comment',
                      d => 'duration',
                      f => 'filename',
                      g => 'genre',
                      l => 'album',
                      m => 'min',
		              n => 'track',
                      q => 'samplerate',
		              r => 'bitrate',
		              s => 'sec',
		              S => 'seconds',
		              t => 'title',
		              y => 'year',
		                );


our $CRLF = "\015\012";

=head2 new

 Title   : new
 Usage   : $icy = MP3::Icecast->new(%arg);
 Function: create a new MP3::Icecast instance
 Returns : an MP3::Icecast object
 Args    : none


=cut

sub new{
  my($class,%arg) = @_;

  my $self = bless {}, $class;

  return $self;
}

=head2 add_directory

 Title   : add_directory
 Usage   : $icy->add_directory('/usr/local/mp3');
 Function: add a directory of files to be added to the playlist
 Returns : true on success, false on failure
 Args    : a system path


=cut

sub add_directory{
   my ($self,$dir) = @_;
   warn "adding directory $dir" if DEBUG;
   if(!-d $dir or !-r $dir){
     return undef;
   } else {
     $self->_process_directory($dir);
     return 1;
   }
}

=head2 _process_directory

 Title   : _process_directory
 Usage   : $icy->_process_directory('/usr/local/mp3');
 Function: searches a directory for files to add to the playlist
 Returns : true on success
 Args    : a system path to search for files


=cut

sub _process_directory{
   my ($self,$dir) = @_;

   if(!-r $dir){
     return undef;
   } else {
     warn "processing directory: $dir" if DEBUG;

     opendir(my $d, $dir) or die "couldn't opendir($dir): $!";
     my @dirents = grep {$_ ne '.' and $_ ne '..'} readdir($d);
     closedir($d) or die "couldn't closedir($dir): $!";

     foreach my $dirent (@dirents){
       warn "found dirent: $dirent" if DEBUG;

       next if !-r File::Spec->catfile($dir,$dirent);
       if(-d File::Spec->catfile($dir,$dirent)){
         next unless $self->recursive;
         $self->_process_directory(File::Spec->catdir($dir,$dirent));
       } else {
         $self->add_file(File::Spec->catfile($dir,$dirent));
       }
     }
   }

   return 1;
}


=head2 add_file

 Title   : add_file
 Usage   : $icy->add_file('/usr/local/mp3/meow.mp3')
 Function: add a file to be added to the playlist
 Returns : true on success, false on failure
 Args    : a system path


=cut

sub add_file{
   my ($self,$file) = @_;

   my(undef,undef,$extension) = fileparse($file,keys(%AUDIO));
   warn "adding file $file" if DEBUG;
   warn $extension if DEBUG;

   if(!-f $file or !-r $file){
     warn "not a readable file: $file" if DEBUG;
     return undef;
   } elsif($AUDIO{lc($extension)}) {
     warn "adding $file" if DEBUG;
     push @{$self->{files}}, $file;
   } else {
     warn "not a usable mimetype: $file" if DEBUG;
     return undef;
   }

   return 1;
}

=head2 files

 Title   : files
 Usage   : @files = $icy->files
 Function: returns a list of all files that have been added
           from calls to add_file() and add_directory()
 Returns : a list of files
 Args    : none


=cut

sub files{
  my $self = shift;

  if(defined($self->{files})){
    if($self->shuffle){
      for (my $i=0; $i<@{$self->{files}}; $i++) {
        my $rand = rand(scalar @{$self->{files}});

        #swap;
        ($self->{files}->[$i],$self->{files}->[$rand])
          =
        ($self->{files}->[$rand],$self->{files}->[$i]);
      }
    }

    return @{$self->{files}};

  } else {
    return ();
  }

}

=head2 clear_files

 Title   : clear_files
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub clear_files{
   my ($self) = @_;
   $self->{files} = undef;
   return 1;
}

=head2 m3u

 Title   : m3u
 Usage   : $m3u_text = $icy->m3u
 Function: generates an Extended M3U string from the
           contents of the list returned by files().
           files not recognized by MP3::Info are
           silently ignored
 Returns : a Extended M3U string
 Args    : none


=cut

sub m3u{
   my $self = shift;

   my $output = undef;


   # The extended format is:
   #	#EXTM3U
   #	#EXTINF:seconds,title - artist (album)
   #	URL
   # but apparently you can override with this
   #	#EXTART:Britney Spears
   #	#EXTALB:Oops!.. I Did It Again
   #	#EXTTIT:Something or other
   # and there doesn't seem to be a way to escape the -, so that's safer
   # in theory, but if you send both it seems to ignore all but the EXTINF
   # and there's no way to send seconds without it anyway, so we'll just do
   # that.
   #
   # .... except that the second format breaks older versions of winamp
   # so we'll use EXTINF only!

   $output .= "#EXTM3U$CRLF" if $self->files;
   foreach my $file ($self->files){
     my $info = $self->_get_info($file);

     next unless defined($info);
     $file = $self->_mangle_path($file);

     my $time   = $info->secs   || -1;
     my $artist = $info->artist || 'Unknown Artist';
     my $album  = $info->album  || 'Unknown Album';
     my $title  = $info->title  || 'Unknown Title';

     $output .= sprintf("#EXTINF:%d,%s - %s (%s)",$time,$title,$artist,$album) . $CRLF;
     $output .= $file . $CRLF;
   }

   return $output;
}

=head2 pls

 Title   : pls
 Usage   : $pls_text = $icy->pls
 Function: generates a PLSv2 string from the
           contents of the list returned by files().
           files not recognized by MP3::Info are
           silently ignored.
 Returns : a PLSv2 string
 Args    : none


=cut

sub pls{
   my $self = shift;

   my $output = undef;

   $output .= "[playlist]$CRLF" if $self->files;
   my $c = 0;
   foreach my $file ($self->files){
     my $info = $self->_get_info($file);

     next unless defined($info);

     $c++;

     $file = $self->_mangle_path($file);

     my $time   = $info->secs   || -1;
     my $artist = $info->artist || 'Unknown Artist';
     my $album  = $info->album  || 'Unknown Album';
     my $title  = $info->title  || 'Unknown Title';

     $output .= uri_escape(sprintf("File%d=%s${CRLF}Title%d=%s - %s (%s)${CRLF}Length%d=%d$CRLF",$c,$file,$c,$title,$artist,$album,$c,$time));
   }

   $output .= "NumberOfEntries=$c$CRLF" if $self->files;
   $output .= "Version=2$CRLF"          if $self->files;

   return $output;
}

=head2 stream

 Title   : streamll: 1 at /raid5a/allenday/projects/MP3/Icecast.pm line 459.

 Usage   : $icy->stream('/usr/local/mp3/meow.mp3',0);
           $icy->stream('/usr/local/mp3/meow.mp3',0,$io_handle);
 Function: stream an audio file.  prints to STDOUT unless a
           third argument is given, in which case ->print() is
           called on the second argument.  An IO::Handle or
           Apache instance will work here.
 Returns : true on success, false on failure
 Args    : 1) system path to the file to stream
           2) offset in file to start streaming
           3) (optional) object to call ->print() on, rather
              than printing to STDOUT


=cut

sub stream{
   my ($self,$file,$offset,$handle) = @_;

   return undef unless -f $file;
   my $info = $self->_get_info($file);
   return undef unless defined($info);

   my $genre = $info->genre                    || 'unknown genre';
   my $description = $self->description($file) || 'unknown';
   my $bitrate = $info->bitrate                || 0;
   my $size = -s $file                         || 0;
   my $mime = $AUDIO{ lc((fileparse($file,keys(%AUDIO)))[2]) };
   my $path = $self->_mangle_path($file);

   my $fh = $self->_open_file($file) || die "couldn't open file $file: $!";
   binmode($fh);
   seek($fh,$offset,0);

   my $output = '';
   $output .= "ICY ". ($offset ? 206 : 200) ." OK$CRLF";
   $output .= "icy-notice1:<BR>This stream requires a shoutcast/icecast compatible player.<BR>$CRLF";
   $output .= "icy-notice2:MP3::Icecast<BR>$CRLF";
   $output .= "icy-name:$description$CRLF";
   $output .= "icy-genre:$genre$CRLF";
   $output .= "icy-url: $path$CRLF";
   $output .= "icy-pub:1$CRLF";
   $output .= "icy-br:$bitrate$CRLF";
   $output .= "Accept-Ranges: bytes$CRLF";
   if($offset){ $output .= "Content-Range: bytes $offset-" . ($size-1) . "/$size$CRLF" }
   $output .= "Content-Length: $size$CRLF";
   $output .= "Content-Type: $mime$CRLF";
   $output .= "$CRLF";

   if(!ref($handle)){
     print $output;
   } elsif($handle->can('print')) {
     $handle->print($output);
   } else {
     return undef;
   }

   my $bytes = $size;
   while($bytes > 0){
     my $data;
     my $b = read($fh,$data,2048) || last;
     $bytes -= $b;

     if(!ref($handle)){
       print $data;
     } else {
       $handle->print($data);
     }
   }

   return 1;
}

=head2 _open_file

 Title   : _open_file
 Usage   : $fh = $icy->open_file('/usr/local/mp3/meow.mp3');
 Function:
 Example :
 Returns :
 Args    :


=cut

sub _open_file{
  my ($self,$file) = @_;

  return undef unless $file;
  return IO::File->new($file,O_RDONLY);
}

=head2 _mangle_path

 Title   : _mangle_path
 Usage   : $path = $icy->_mangle_path('/usr/local/mp3/meow.mp3');
 Function: applies alias substitutions and prefixes to a system path.
           this is intended to be used to create resolvable URLs.
 Returns : a string
 Args    : a system path


=cut

sub _mangle_path{
   my ($self,$path) = @_;

   my $qpath = quotemeta($path);

   foreach my $alias ($self->alias){
     warn "replacing $alias..." if DEBUG;
     my $search = $alias;

     my $qalias = quotemeta($alias);

     next unless $path =~ /^$qalias/;

     my $replace = $self->alias($alias);
     $path =~ s/^$qalias/$replace/;
     last;
   }
   $self->_uri_path_escape(\$path);
   $path = join '', ($self->prefix ||'', $path ||'', $self->postfix ||'');
   return $path;
}

=head2 _path_escape

 Title   : _path_escape
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub _uri_path_escape{
   my ($self,$uri) = @_;

   $$uri =~ s!([^a-zA-Z0-9_/.-])!uc sprintf("%%%02x",ord($1))!eg;
}


=head2 _get_info

 Title   : _get_info
 Usage   : $mp3_info = $icy->_get_info($file)
 Function: constucts and returns an MP3::Info object.  the intended
           use here is to access MP3 metadata (from ID3 tags,
           filesize, etc).
 Returns : a new MP3::Info object on success, false on failure
 Args    : a system path to a file


=cut

sub _get_info{
   my ($self,$file) = @_;

   return undef unless $file;
   return new MP3::Info $file;
}


=head2 alias

 Title   : alias
 Usage   : #returns 1
           $icy->alias('/home/allenday/mp3' => '/mp3');

           #returns '/mp3'
           $icy->alias('/home/allenday/mp3');

           #returns 1
           $icy->alias('/usr/local/share/mp3' => '/share/mp3'); #returns 1

           #returns qw(/mp3 /share/mp3)
           $icy->alias();
 Function: this method provides similar behavior to Apache's Alias directive.
           it allows mapping of system paths to virtual paths for usage by,
           for instance, a webserver.  the mapping is simple: when examining
           a file, MP3::Icecast tries to match the beginning of the file's
           full path to a sorted list of aliases.  the first alias to match
           is accepted.  this may cause unexpected behavior in the event that
           a file's path matches multiple alias entries.  patches welcome.
 Returns : see Usage
 Args    : see Usage


=cut

sub alias{
   my ($self,$search,$replace) = @_;

   if(defined($search) and defined($replace)){
     $self->{alias}{$search} = $replace;
   } elsif(defined($search)) {
     return $self->{alias}{$search};
   } else {
     return sort keys %{$self->{alias}};
   }
}

=head2 prefix

 Title   : prefix
 Usage   : $icy->prefix('http://');
 Function: prefix all entries in the playlist with this value.
           this string is *not* uri or system path escaped.
 Returns : value of prefix (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub prefix{
    my $self = shift;

    return $self->{'prefix'} = shift if @_;
    return $self->{'prefix'};
}

=head2 postfix

 Title   : postfix
 Usage   : $obj->postfix($newval)
 Function: postfix all entries in the playlist with this value.
           this string is *not* uri or system path escaped.
           uri escaped.
 Returns : value of postfix (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub postfix{
    my $self = shift;

    return $self->{'postfix'} = shift if @_;
    return $self->{'postfix'};
}

=head2 recursive

 Title   : recursive
 Usage   : $obj->recursive($newval)
 Function: flag determining whether a directory is recursively
           searched for files when passed to ::add_directory().
           default is false (no recursion).
 Example : 
 Returns : value of recursive (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub recursive{
    my $self = shift;

    return $self->{'recursive'} = shift if @_;
    return $self->{'recursive'};
}

=head2 shuffle

 Title   : shuffle
 Usage   : $obj->shuffle($newval)
 Function: 
 Example : 
 Returns : value of shuffle (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub shuffle{
    my $self = shift;

    return $self->{'shuffle'} = shift if @_;
    return $self->{'shuffle'};
}

=head2 description

 Title   : description
 Usage   : $description = $icy->description('/usr/local/mp3/meow.mp3');
 Function: returns a description string of an MP3.  this is extracted
           from the ID3 tags by MP3::Info.  the description format can
           be customized, see the description_format() method.
 Returns : a description string
 Args    : a valid system path


=cut

sub description{
  my $self = shift;
  my $file = shift;
  my $data = new MP3::Info $file;
  my $description;
  my $format = $self->description_format;
  if ($format) {
    ($description = $format) =~ s{%([atfglncrdmsqS%])}
      {$1 eq '%' ? '%'
	 : $data->{$FORMAT_FIELDS{$1}}
       }gxe;
  } else {
    $description = $data->{title} || basename($file, qw(.mp3 .MP3 .mp2 .MP2) );
    $description .= " - $data->{artist}" if $data->{artist};
    $description .= " ($data->{album})"  if $data->{album};
  }
  return $description;
}

=head2 description_format

 Title   : description_format
 Usage   : $icy->description_format($format_string)
 Function: 
 Returns : value of description_format (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub description_format{
    my $self = shift;

    return $self->{'description_format'} = shift if @_;
    return $self->{'description_format'};
}
1;
