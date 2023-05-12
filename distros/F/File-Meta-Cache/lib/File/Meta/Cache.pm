use strict;
use warnings;
package File::Meta::Cache;
our $VERSION="v0.1.1";
# Default Opening Mode
use Fcntl qw(O_RDONLY);
use enum qw<key_ fd_ fh_ stat_ valid_ user_>;

use Object::Pad;

class File::Meta::Cache;
use feature qw<say state>;

use Log::ger;   # Logger
use Log::OK;    # Logger enabler

use POSIX();



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
    my $i=0;
    my $entry;
    my $closer=$self->closer;
    for(keys %_cache){
      $entry=$_cache{$_};

      # If the cached_ field reaches 1, this is the last code to use it. so close it
      # 
      $closer->($entry) if($entry->[valid_]==1);
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
    my ( $key_path, $mode, $force)=@_;
    my $in_fd;

    # Entry is identified by the path, however, the actual data can come from another file
    # 
    my $existing_entry=$_cache{$key_path};
    $mode//=O_RDONLY;
    if(!$existing_entry or $force){
        Log::OK::TRACE and log_trace __PACKAGE__.": Searching for: $key_path";

        my @stat=stat $key_path;
        
        # If the stat fail or is not a file return undef.
        # If this is a reopen(force), the force close the file to invalidate the cache
        #
        unless(@stat and -f _){
          $_closer->($existing_entry, 1) if $existing_entry;
          return undef;
        };

        my @entry;
        $in_fd=POSIX::open($key_path, $mode);



        if(defined $in_fd){
          
          if($existing_entry){
            # Duplicate and Close unused fd
            POSIX::dup2 $in_fd, $existing_entry->[fd_];
            POSIX::close $in_fd;

            # Copy stat into existing array 
            $existing_entry->[stat_]->@*=@stat;
          }
          else {
            # Only create a file handle if its enabled
            open($entry[fh_], "+<&=$in_fd") unless($_no_fh);

            $entry[stat_]=\@stat;
            $entry[key_]=$key_path;
            $entry[fd_]=$in_fd;
            $entry[valid_]=1;#$count;

            $existing_entry =\@entry;
            $_cache{$key_path}=$existing_entry if($_enabled);
          }
        }
        else {
          Log::OK::ERROR and log_error __PACKAGE__." Error opening file $key_path: $!";
        }
    }

    # Increment the  counter 
    #
    $existing_entry->[valid_]++ if $existing_entry;
    $existing_entry;
  }
}


# Mark the cache as disabled. Dumps all values and closes
# all fds
#
method disable{
  $_enabled=undef;
  for(values %_cache){
    POSIX::close($_cache{$_}[0]);
  }
  %_cache=();
}

# Generates a sub to close a cached fd
# removes meta data from the cache also
#
method closer {
  $_closer//=sub {
      my $entry=$_[0];
      if(--$entry->[valid_] <=0 or $_[1]){
        my $actual=delete $_cache{$entry->[key_]};
        if($actual){
          # Attempt to close only if the entry exists
          $actual->[valid_]=0;  #Mark as invalid
          POSIX::close($actual->[fd_]);
          $actual->[fh_]=undef;
        }
        else {
          die "Entry does not exist";
        }
      }
  }
}

method updater{
  $_updater//=sub {
    # To a stat on the entry 
    $_[0][stat_]->@*=stat $_[0][key_];
    unless($_[0][stat_]->@* and -f _){
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

method close {
  $self->closer->&*;
}
method update{
  $self->updater->&*;
}

method sweep {
  $self->sweeper->&*;
}

method enable{ $_enabled=1; }

1;

