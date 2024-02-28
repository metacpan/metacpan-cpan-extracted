use strict;
use warnings;
package File::Meta::Cache;

our $VERSION="v0.3.0";

# Default Opening Mode
use Fcntl qw(O_RDONLY);

# NOTE: This contants will be depricated in a later version
use constant::more key_=>0, fd_=>1, fh_=>2, stat_=>3, valid_=>4, user_=>5;

# Use these keys instead
use constant::more qw<KEY=0 FD FH STAT VALID USER>;

use Object::Pad;

class File::Meta::Cache;
use feature qw<say state>;

use Log::ger;   # Logger
use Log::OK;    # Logger enabler



my ($_open, $_close, $_dup2);

if(eval "require IO::FD"){
  $_open=\&IO::FD::open;
  $_close=\&IO::FD::close;
  $_dup2=\&IO::FD::dup2;
}
else {
  require POSIX;
  $_open=\&POSIX::open;
  $_close=\&POSIX::close;
  $_dup2=\&POSIX::dup2;
}



field $_sweep_size;

field $_no_fh :param =undef;
field $_enabled;
field $_sweeper;
field %_cache;
field $_opener;
field $_closer;
field $_updater;
field $_http_headers;

BUILD{
  $_sweep_size//=100;
  $_enabled=1;
}

method sweeper {
  $_sweeper//= sub {
    my $cb=shift;
    my $i=0;
    my $entry;
    my $closer=$self->closer;
    for(keys %_cache){
      $entry=$_cache{$_};

      # If the cached_ field reaches 1, this is the last code to use it. so close it
      # 
      if($entry->[VALID]==1){
        $closer->($entry);
        $cb and $cb->($entry);
      }
      last if ++$i >= $_sweep_size;
    }
  }
}

# returns a sub to execute. Object::Pad method lookup is slow. so bypass it
# when we don't need it
#
method opener{
  $_opener//=
  sub {
    my ( $KEYpath, $mode, $force)=@_;
    my $in_fd;

    # Entry is identified by the path, however, the actual data can come from another file
    # 
    my $existing_entry=$_cache{$KEYpath};
    $mode//=O_RDONLY;
    if(!$existing_entry or $force){
        Log::OK::TRACE and log_trace __PACKAGE__.": Searching for: $KEYpath";

        my @stat=stat $KEYpath;
        
        # If the stat fail or is not a file return undef.
        # If this is a reopen(force), the force close the file to invalidate the cache
        #
        unless(@stat and -f _){
          $_closer->($existing_entry, 1) if $existing_entry;
          return undef;
        };

        my @entry;
        #$in_fd=POSIX::open($KEYpath, $mode);
        $in_fd=$_open->($KEYpath, $mode);



        if(defined $in_fd){
          
          if($existing_entry){
            # Duplicate and Close unused fd
            #POSIX::dup2 $in_fd, $existing_entry->[FD];
            $_dup2->($in_fd, $existing_entry->[FD]);
            #POSIX::close $in_fd;
            $_close->($in_fd);

            # Copy stat into existing array 
            $existing_entry->[STAT]->@*=@stat;
          }
          else {
            # Only create a file handle if its enabled
            open($entry[FH], "+<&=$in_fd") unless($_no_fh);

            $entry[STAT]=\@stat;
            $entry[KEY]=$KEYpath;
            $entry[FD]=$in_fd;
            $entry[VALID]=1;#$count;

            $existing_entry =\@entry;
            if($_enabled){
              $_cache{$KEYpath}=$existing_entry;
              $existing_entry->[VALID]++;
            }
          }
        }
        else {
          Log::OK::ERROR and log_error __PACKAGE__." Error opening file $KEYpath: $!";
        }
    }
    else {
      # Increment the  counter of existing
      #
      $existing_entry->[VALID]++;
    }

    $existing_entry;
  }
}


# Mark the cache as disabled. Dumps all values and closes
# all fds
#
method disable{
  $_enabled=undef;
  for(values %_cache){
    #POSIX::close($_cache{$_}[0]);
    $_close->($_->[FD]);
  }
  %_cache=();
  $self;
}

# Generates a sub to close a cached fd
# removes meta data from the cache also
#
method closer {
  $_closer//=sub {
      my $entry=$_[0];
      if(--$entry->[VALID] <=0 or $_[1]){
        # Delete from cache
        delete $_cache{$entry->[KEY]};
        # Attempt to close only if the entry exists
        $entry->[VALID]=0;  #Mark as invalid
        $entry->[FH]=undef;
        $_close->($entry->[FD]);
      }
  }
}

method updater{
  $_updater//=sub {
    # Do a stat on the entry 
    $_[0][STAT]->@*=stat $_[0][KEY];
    unless($_[0][STAT]->@* and -f _){
      # This is an error force close the file
      $_closer->($_[0], 1 );
    }
  }
}

# OO Interface
#

method open {
  $self->opener->&*;
}

# First argument is entry, second is force flag
method close {
  $self->closer->&*;
}

# First argument is entry
method update{
  $self->updater->&*;
}

# First argument is callback to call if close is called
method sweep {
  $self->sweeper->&*;
}

method enable{ $_enabled=1; $self }

1;

