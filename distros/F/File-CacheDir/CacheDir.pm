#!/usr/bin/perl -w

package File::CacheDir;

use strict;
use vars qw(@ISA @EXPORT_OK $VERSION %EXTANT_DIR);
use Exporter;
use CGI qw();
use File::Path qw(mkpath);
use IO::Dir;

use POSIX qw( setsid _exit );

@ISA = ('Exporter');
@EXPORT_OK  = qw( cache_dir );
$VERSION = "1.30";

%EXTANT_DIR = ();

sub new {
  my $type = shift;
  my $hash_ref = $_[0];
  my @PASSED_ARGS = (ref $hash_ref eq 'HASH') ? %{$_[0]} : @_;
  my $cache_object;
  my @DEFAULT_ARGS = (
    base_dir          => "/tmp/cache_dir",
    cache_stats       => 1,
    carry_forward     => 1,
    cleanup_fork      => 1,
    # percentage of time to attempt cleanup run
    cleanup_frequency => 100,
    cleanup_length    => 3600,
    cleanup_suffix    => ".cleanup.lock",
    content_typed     => 0,
    cookie_brick_over => 0,
    cookie_name       => "cache_dir",
    cookie_path       => '/',
    filename          => time . $$,
    periods_to_keep   => 2,
    set_cookie        => 0,
    ttl               => "1 day",
  );
  my %ARGS = (@DEFAULT_ARGS, @PASSED_ARGS);
  $cache_object = bless \%ARGS, $type;

  # clean up a few blank things in the object
  unless($cache_object->{set_cookie}) {
    foreach(qw(set_cookie cookie_name cookie_path)) {
      delete $cache_object->{$_};
    }
  }
  foreach(qw(carry_forward)) {
    delete $cache_object->{$_} unless($cache_object->{$_});
  }

  return $cache_object;
}

sub ttl_mkpath {
  my $self = shift;
  my $_ttl_dir = shift;
  mkpath $_ttl_dir;
  die "couldn't mkpath '$_ttl_dir': $!" unless($self->dash_d($_ttl_dir));
}

sub expired_check {
  my $self = shift;
  my $_sub_dir = shift;
  my $diff = $self->{int_time} - $_sub_dir;
  if($diff > $self->{periods_to_keep}) {
    return 1;
  } else {
    return 0;
  }
}

### want to be able to easily track -d checks, and want to have
### all the cache_stats code in one place
sub dash_d {
  my $self = shift;
  my $_dir = shift;
  my $return = 0;
  if($self->{cache_stats} && $EXTANT_DIR{$_dir}) {
    $return = 1;
  } else {
    if(-d $_dir) {
      $return = 1;
      $EXTANT_DIR{$_dir} = 1;
    }
  }
  return $return;
}

### sub to wrap the cleanup code... this way we can control
### when cleanup should occur, even if somebody overides
### the cleanup logic

sub perhaps_cleanup {
  my $self = shift;
  my $_dir = shift;

  ### let's do this each time a cleanup might happen
  ### might be a little much, but shouldn't be anywhere
  ### near as bad as the pre-cache days
  foreach my $this_dir (keys %EXTANT_DIR) {
    delete $EXTANT_DIR{$this_dir} unless(-d $EXTANT_DIR{$this_dir});
  }

  ### might want to do cleanup only a portion of the time
  return undef if( rand(100) >= $self->{cleanup_frequency} );

  ### Do quick lock file checking... (only one process should handle a cleanup)
  my $file = "$_dir$self->{cleanup_suffix}";
  my @stat = stat $file;

  if( @stat && time - $stat[9] < $self->{cleanup_length} ){
    return undef;
  }

  ## all checks passed... (we're still here)
  ## make the lockfile, do the cleanup, and whatnot

  ### realize this won't work over nfs, but better than nothing
  open(FILE,">$file");
  flock(FILE, 6) or return undef;

  if($self->{cleanup_fork}) {
    return if strong_fork();
  }
  $self->cleanup( $_dir );
  close(FILE);
  unlink $file;
  child_exit() if($self->{cleanup_fork});
}

sub cleanup {
  my $self = shift;
  my $root = shift;
  return if($root =~ /$self->{cleanup_suffix}$/);
  return unlink $root if
    -l $root || !-d _;
  if (my $dir = IO::Dir->new($root)) {
    while (defined(my $node = $dir->read)) {
      next if $node =~ /^\.\.?$/;
      $node = $1 if $node =~ /(.+)/;
      $self->cleanup("$root/$node");
    }
  }
  return rmdir $root;
}

sub handle_ttl {
  my $self = shift;

  if($self->{ttl} =~ /^\d+$/) {
    # do nothing
  } elsif($self->{ttl} =~ s/^(\d+)\s*(\D+)$/$1/) {
    $self->{ttl} =  $1 if defined $1;
    my $units = (defined $2) ? $2 : '';
    if(($units =~ /^s/i) || (!$units)) {
      $self->{ttl} = $self->{ttl};
    } elsif ($units =~ /^m/i) {
      $self->{ttl} *= 60;
    } elsif ($units =~ /^h/i) {
      $self->{ttl} *= 3600;
    } elsif ($units =~ /^d/i) {
      $self->{ttl} *= 86400;
    } elsif ($units =~ /^w/i) {
      $self->{ttl} *= 604800;
    } else {
       die "invalid ttl '$self->{ttl}', bad units '$units'";
    }
  } else {
    die "invalid ttl '$self->{ttl}', not just number and couldn't find units";
  }
}

sub sub_mkdir {
  my $self = shift;
  my $_dir = shift;
  mkdir $_dir, 0755;
  die "couldn't mkpath '$_dir': $!" unless($self->dash_d($_dir));
}

sub cache_dir {
  my $self = $_[0];
  unless(UNIVERSAL::isa($self, __PACKAGE__)) {
    $self = File::CacheDir->new(@_);
  }

  delete $self->{carried_forward};

  $self->handle_ttl;

  $self->{base_dir} =~ s@/$@@;
  my $ttl_dir = "$self->{base_dir}/$self->{ttl}/";

  unless($self->dash_d($ttl_dir)) {
    $self->ttl_mkpath($ttl_dir);
  }

  $self->{int_time} = (int(time/$self->{ttl}));
  $self->{full_dir} = "$ttl_dir$self->{int_time}/";
  $self->{last_int_time} = $self->{int_time} - 1;
  $self->{last_dir} = "$ttl_dir$self->{last_int_time}/";

  if($self->{carry_forward}) {
    $self->{last_int_time} = $self->{int_time} - 1;
    $self->{last_int_dir} = "$ttl_dir$self->{last_int_time}/";
    $self->{carry_forward_filename} = "$self->{last_int_dir}$self->{filename}";
    if(-e $self->{carry_forward_filename}) {
      unless($self->dash_d($self->{full_dir})) {
        $self->sub_mkdir($self->{full_dir});
        die "couldn't mkpath '$self->{full_dir}': $!" unless($self->dash_d($self->{full_dir}));
      }

      $self->{full_path} = "$self->{full_dir}$self->{filename}";

      rename $self->{carry_forward_filename}, $self->{full_path};
      die "couldn't rename $self->{carry_forward_filename}, $self->{full_path}: $!" unless(-e $self->{full_path});

      $self->{carried_forward} = 1;

      if($self->{set_cookie}) {
        ($self->{cookie_value}) = $self->{full_path} =~ /^$self->{base_dir}(.+)/;
        $self->set_cookie;
      }
      return $self->{full_path};

    }
  }

  if($self->dash_d($self->{full_dir})) {
    $self->{full_path} = "$self->{full_dir}$self->{filename}";
    if($self->{set_cookie}) {
      ($self->{cookie_value}) = $self->{full_path} =~ /^$self->{base_dir}(.+)/;
      $self->set_cookie;
    }
    return $self->{full_path};
  } else {
    if( rand(100) < $self->{cleanup_frequency}) {
      opendir(DIR, $ttl_dir);
      while (my $sub_dir = readdir(DIR)) {
        next if($sub_dir =~ /^\.\.?$/);
        next if($sub_dir =~ /$self->{cleanup_suffix}/);
        $sub_dir = $1 if $sub_dir =~ /(.+)/;
        if($self->expired_check($sub_dir)) {
          $self->perhaps_cleanup("$ttl_dir$sub_dir");
        }
      }
      closedir(DIR);
    }
    $self->sub_mkdir($self->{full_dir});
    die "couldn't mkpath '$self->{full_dir}': $!" unless($self->dash_d($self->{full_dir}));
    $self->{full_path} = "$self->{full_dir}$self->{filename}";
    if($self->{set_cookie}) {
      ($self->{cookie_value}) = $self->{full_path} =~ /^$self->{base_dir}(.+)/;
      $self->set_cookie;
    }
    return $self->{full_path};
  }
}

sub set_cookie {
  my $self = shift;
  return unless($self->{set_cookie});
  my $old_cookie = CGI::cookie( -name => $self->{cookie_name} );
  if(!$self->{cookie_brick_over} && defined $old_cookie) {
    $self->{cookie_value} = $old_cookie;
    return $old_cookie;
  }
  $self->{cookie_value} =~ m@$self->{base_dir}(.+)@;
  my $new_cookie = CGI::cookie
    (-name  => $self->{cookie_name},
     -value => $1,
     -path  => $self->{cookie_path},
     );
  if ($self->{content_typed}) {
    print qq{<meta http-equiv="Set-Cookie" content="$new_cookie">\n};
  } else {
    print "Set-Cookie: $new_cookie\n";
  }
  return;
}

sub strong_fork {
  # Grab anonymous subroutine CODEREF or pointer to subroutine
  # if a CODEREF is not passed - the routine will behave like fork.
  my $routine=shift;
  # STDOUT buffer must be clean before fork() because
  # IO buffers are also replicated to the child process.
  # We can't have the data already sent to STDOUT to be sent
  # again by the child process!
  $| = 1;
  # Print nothing to STDOUT to force buffer to flush before fork() is called.
  # This causes even a 'tie'd STDOUT (FastCGI or mod_perl) to actually flush.
  print STDOUT "";
  # Create a pipe for the grandchild pid slide through
  pipe (*RPID, *WPID);
  # Fork is necessary to hide from apache's touch of death.
  my $child = fork;
  # Don't abort CGI if fork fails.
  if (!defined $child) {
    return undef;
  }
  # Parent should continue ASAP
  if ($child) {
    # I'm not going to put anything down this pipe.
    close WPID;
    my $grandchild_pid = '';
    # Waiting for Child to send the Grandchild pid
    sysread(*RPID, $grandchild_pid, 10);
    # It should be a number if the child fork()ed successfully.
    $grandchild_pid += 0;
    # Done with the pipe
    close RPID;
    if (!defined $grandchild_pid) {
      return undef;
    }

    # Intermediate Child should hopefully terminate very soon
    # (if it hasn't already).  Clean off the zombie that it
    # just became or wait until it dies.
    waitpid($child, 0);

    return $grandchild_pid;
  }
  # This is the Child process.

  # I'm not going to look at anything in this pipe.
  close RPID;

  # Double fork makes cleaning zombies very easy.
  # A defunct process always vanishes from existence
  # when its parent is terminated.  It is better than
  # SIGCHLD handlers because, unfortunately, under
  # mod_perl, the handler may get blown away by future
  # requests that also use it.
  my $grandchild_pid = fork;
  # If second fork fails, pretend like I am the grandchild and
  # make the parent process block until the subroutine completes.
  if (!defined $grandchild_pid) { # Fork failed
    print STDERR "Second process [$$] failed to fork for [$0]! [$!]\n";
    close WPID;
    _exit(0);
  } elsif ($grandchild_pid) { # Intermediate Child process
    # Stuff the magic grandchild id down the pipe
    # so grandpa knows who it is.  Intermediate process
    # does the stuffing so the grandchild process can
    # get to work as soon as possible.
    print WPID $grandchild_pid;
    close WPID;
    # This releases the waitpid() block above without
    # calling any DESTROY nor END blocks while the detach
    # variables are still within scope.  It also slams all
    # FD_CLOEXEC handles shut abruptly.
    _exit(0);
  }
  # This is the Grandchild process running.
  close WPID;

  # Setsid is necessary to escape Apache touch of death
  # when it is shutdown.  We do not want a TERM signal to
  # be sent to this strong_fork'ed child process just because
  # the root web server gets shutdown.
  setsid();

  # Untie is necessary to buttwag around those perl wrappers
  # that do not implement a CLOSE method correctly (mod_perl
  # and/or FastCGI) and in case STDOUT is tied and not a real
  # handle.
  untie *STDOUT if tied *STDOUT;

  # Shutdown STDOUT handle to trick apache into releasing
  # connection to client as soon as parent CGI finishes.
  # (The STDERR should still be redirected to the error_log.)
  close STDOUT;

  # look to see if we want to keep this process going
  # this makes us function more like the child process of a fork
  # this allows for safe fork
  if (! $routine || ! ref $routine) {
    open STDOUT, '>/dev/null' || die "Can't write /dev/null [$!]";
    open STDIN,  '</dev/null' || die "Can't read /dev/null  [$!]";
    return 0; # this is what fork returns on a child
  }

  # Finally play the CODEREF that was passed.
  $@ = ""; {
    # Eval to catch the "die" calls from causing Apache::exit
    # from being triggered leaving nasty dettached httpd
    # processes under mod_perl
    local $SIG{__DIE__} = 'DEFAULT';
    eval {
      &$routine;
    };
    # If an error occurred, log it and continue
    if ($@) {
      warn "strong_fork: $@";
    }
  }
  # Program must terminate to avoid duplicate execution
  # of code following this function in the caller program,
  # but the DESTROY methods and END blocks should be run.
  # Apache::exit should not be called since this is the
  # strong_fork'd child process.
  &child_exit();
}

sub child_exit {
  _exit(0);
}

1;

__END__

=head1 NAME

File::CacheDir - Perl module to aid in keeping track and cleaning up files, quickly and without a cron
$Id: CacheDir.pm,v 1.22 2006/05/17 00:05:34 earl Exp $

=head1 DESCRIPTION

CacheDir attempts to keep files around for some ttl, while
quickly, automatically and cronlessly cleaning up files that are too old.

=head1 ARGUMENTS

The possible named arguments (which can be named or sent in a hash ref,
see below for an example) are,

base_dir          - the base directory
                    default is '/tmp/cache_dir'

cache_stats       - whether or not to try and cache -d checks
                    default is 1

carry_forward     - whether or not to move forward the file
                    when time periods get crossed.  For example,
                    if your ttl is 3600, and you move from the
                    278711 to the 278712 hour, if carry
                    forward is set, it will refresh a cookie
                    (if set_cookie is true) and move the file
                    to the new location, and
                    set $self->{carried_forward} = 1
                    default is 1

cleanup_suffix    - in order to avoid having more than one process attempt cleanup,
                    a touch file, that looks like this "$cleanup_dir$self->{cleanup_suffix}"
                    is created and cleaned up
cleanup_fork      - fork on cleanup
                    default is 1
cleanup_frequency - percentage of time to attempt cleanup
cleanup_length    - seconds to allow for cleanup, that is, how old a touch file can be before
                    a new cleanup process will start

content_typed     - whether or not you have printed a
                    Content-type header
                    default is 0

cookie_brick_over - brick over an old cookie
                    default is 0
cookie_name       - the name of your cookie
                    default is 'cache_dir'

cookie_path       - the path for your cookie
                    default is '/'

filename          - what you want the file to be named
                    (not including the directory),
                    like "storebuilder" . time . $$
                    I would suggest using a script
                    specific word (like the name of the cgi),
                    time and $$ (which is the pid number)
                    in the filename, just so files
                    are easy to track and the filenames
                    are pretty unique
                    default is time . $$

periods_to_keep   - how many old periods you would like to keep

set_cookie        - whether or not to set a cookie
                    default is 0

ttl               - how long you want the file to stick around
                    can be given in seconds (3600) or like
                    "1 hour" or "1 day" or even "1 week"
                    default is '1 day'

=head1 COOKIES

Since CacheDir fits in so nicely with cookies, I use a few CGI methods to automatically set cookies,
retrieve the cookies, and use the cookies when applicable.  The cookie methods make it near trivial
to handle session information.  Taking the advice of Rob Brown <rbrown@about-inc.com>, I use CGI.pm,
though it increases load time and nearly doubles out of the box memory required.

The cookie that gets set is the full path of the file with your base_dir swapped out.  This makes it nice
for users to not know full path to your files.  The filename that gets returned from a cache_dir call,
however is the full path.

=head1 METHOD OVERRIDES

Most of the time, the defaults will suffice, but using your own object
methods, you can override most everything CacheDir does.  To show
which methods are used, I walk through the code with a simple example.

my $cache_dir = File::CacheDir->new({
  base_dir => '/tmp/example',
  ttl      => '2 hours',
  filename => 'example.' . time . ".$$",
});

An object gets created, with the hash passed getting blessed in.

my $filename = $cache_dir->cache_dir;

The ttl gets converted to seconds, here 7200.  The

$ttl_dir = $base_dir . $ttl;

In our example, $ttl_dir = "/tmp/example/7200";

$self->ttl_mkpath - if the ttl directory does not exist, it gets made

Next, the number of ttl units since epoch, here it is something like 137738.  This is

$self->{int_time} = int(time/$self->{ttl});

Now, the full directory can be formed

$self->{full_dir} = $ttl_dir . $self->{int_time};

If $self->{full_dir} exists, $self->{full_dir} . $self->{filename} gets returned.  Otherwise, I look through
the $ttl_dir, and for each directory that is too old (more than $self->{periods_to_keep}) I run

$self->cleanup - just deletes the old directory, but this is where a backup could take place,
or whatever you like.

Finally, I

$self->sub_mkdir - makes the new directory, $self->{full_dir}

and return the $filename

=head1 SYNOPSIS

  #!/usr/bin/perl -w

  use strict;
  use File::CacheDir qw(cache_dir);

  my $filename = cache_dir({
    base_dir => '/tmp',
    ttl      => '2 hours',
    filename => 'example.' . time . ".$$",
  });

  `touch $filename`;

=head1 THANKS

Thanks to Rob Brown for discussing general concepts, helping me think through
things, offering suggestions and doing the most recent code review.  The idea for carry_forward was pretty
well all Rob.  I didn't see a need, but Rob convinced me of one.  Since Rob first introduced the idea to
me, I have seen CacheDir break three different programmers' code.  With carry_forward, no problems.  Finally,
Rob changed my non-CGI cookie stuff to use CGI, thus avoiding many a flame war.  Rob also recently wrote a
taint clean version of rmtree.  He also wrote an original version of strong_fork, recently adopted here, and
got my logic right on fork'ing and exit'ing.

Thanks to Paul Seamons for listening to my ideas, offerings suggestions, using CacheDir
and giving feedback.  Using the namespace File::CacheDir, the case of CacheDir and cache_dir
are all from Paul.  Paul helped me cut down strong_fork to what we actually need here.  Finally,
thanks to Paul for the idea of this THANKS section.

Thanks to Wes Cerny for using CacheDir, and giving feedback.  Also, thanks to Wes
for a last minute code review.  Wes had me change the existence check on $self->{carry_forward_filename} to a
plain file check based on his experience with CacheDir.

Thanks to Allen Bettilyon for discovering some problems with the cleanup scheme.  Allen had the ideas of using
touch files and cleanup_frequency to avoid concurrent clean ups.  He also convinced me to use perhaps_cleanup
to allow for backward compatibility with stuff that might be using cleanup.
