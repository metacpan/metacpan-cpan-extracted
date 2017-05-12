# File::TinyLock.pm
# $Id: TinyLock.pm,v 1.20 2014/10/03 22:15:41 jkister Exp $
# Copyright (c) 2006-2014 Jeremy Kister.
# Released under Perl's Artistic License.

=head1 NAME

File::TinyLock - Utility for process locking and unlocking.

=head1 SYNOPSIS

  use File::TinyLock;

  my $LOCK = '/tmp/testing.lock';

  my $locksmith = File::TinyLock->new(lock => $LOCK);
  if( $locksmith->lock() ){
    warn "we have locked\n";
    $locksmith->unlock();
    warn "we have unlocked\n";
  }else{
    warn "could not lock..\n";
  }
												
=head1 DESCRIPTION

C<File::TinyLock> provides C<lock>, C<unlock>, and C<checklock> methods for
working with process locking.  This utility attempts to be useful when you
require one of a process to be running at a time, but someone could possibly
try to spawn off a second (such as having a crontab where you are *hoping*
one job ends before the next starts).

=head1 CONSTRUCTOR

=over 4

=item lock( [LOCK] [,OPTIONS] );

C<LOCK> is a mandatory lock file.

C<OPTIONS> are passed in a hash like fashion, using key and value
pairs.  Possible options are:

B<mylock>  - Unique file to identify our process (Default: auto-generated)
           - *must* be on the same filesystem as <LOCK>

B<retries> - Number of times to retry getting a lock (Default: 5)

B<retrydelay> - Number of seconds to wait between retries (Default: 60)

B<debug> - Print debugging info to STDERR (0=Off, 1=On) (Default: 0).

=head1 RETURN VALUE

Here are a list of return codes of the C<lock> function and what they mean:

=item 0 The process could not get a lock.

=item 1 The process has obtained a lock. 

.. and for the C<checklock> function:

=item 0 The process does not have a lock.

=item 1 The process has a lock.

.. and the C<unlock> function:

=item Note: method will die if we cannot modify <LOCK>

=head1 EXAMPLES

  # run the below code twice ( e.g. perl ./test.pl & ; perl ./test.pl )

  use strict;
  use File::TinyLock;

  my $lock = '/tmp/testing.lock';
  my $locksmith = File::TinyLock->new(lock => $lock, debug => 1);

  my $result = $locksmith->lock();
  if($result){
    print "We have obtained a lock\n";
  }
	
	# do stuff 

  sleep 30;

  $locksmith->unlock();
  exit;


=head1 CAVEATS

If you leave lock files around (from not unlocking the file before
your code exits), C<File::TinyLock> will try its best to clean up
and/or determine if the lock files are stale or not.  This is best
effort, and may yield false positives.  For example, if your code
was running as pid 1234 and crashed without unlocking, stale
detection may fail if there is a new process running with pid 1234.

=head1 RESTRICTIONS

Locking will only remain successfull while your code is active.  You
can not lock, let your code exit, and start your code again - doing
so will result in stale lock files left behind.  

start code -> get lock -> do stuff -> unlock -> exit;

=head1 AUTHOR

<a href="http://jeremy.kister.net./">Jeremy Kister</a>

=cut

package File::TinyLock;

use strict;
use warnings;

my %_mylocks;

our ($VERSION) = q$Revision: 1.20 $ =~ /(\d+\.\d+)/;

sub new {
    my $class = shift;
    my %args;
    if(@_ % 2){
        my $lock = shift;
        %args = @_;
        $args{lock} = $lock;
    }else{
        %args = @_;
    }

    die "$class: must specify lock\n" unless($args{lock});

    my $self = bless(\%args, $class);

    $self->{class}        = $class;
    $self->{retries}      = 5  unless(defined($args{retries}));
    $self->{retrydelay}   = 60 unless(defined($args{retrydelay}));
    $self->{_have_lock}   = 0;

    if( $self->{mylock} ){
        # must be on the same filesystem as {lock}
        if($self->{lock} eq $self->{mylock}){
            die "$class: lock and mylock may not be the same file\n";
        }elsif( $_mylocks{ $self->{mylock} } ){
            die "$class: already using mylock of $self->{mylock}\n";
        }elsif( -f $self->{mylock} ){
            die "$class: $self->{mylock} already exists\n";
        }
    }else{
        # generate mylock - we could be used several times in the same code
        for my $i (0 .. 10_000){ # could do while(1)...
            my $mylock = $self->{lock} . $i . $$;
            unless( $_mylocks{ $mylock } || -f $mylock ){
                $self->{mylock} = $mylock;
                last;
            }
        }
        die "$class: couldnt generate mylock: 10,000 found!\n" unless( $self->{mylock} );
    }
    $_mylocks{ $self->{mylock} } = 1;

    return($self);
}

sub lock {
    my $self = shift;

    $SIG{HUP} = $SIG{QUIT} = $SIG{INT} = $SIG{TERM} = sub { $self->_debug( "caught SIG$_[0]" ); exit; };

    if( open( my $fh, '>', $self->{mylock} ) ){
        print $fh "$$:$self->{mylock}\n";
        close $fh;

        for my $try (0 .. $self->{retries}){
            unless( $self->checklock() ){
                if( link($self->{mylock}, $self->{lock}) ){
                    $self->{_have_lock} = 1;
                    $self->_debug( "got lock." );
                    return 1;
                }
            }
            if($self->{retries} && ($try != $self->{retries})){
                $self->_debug( "retrying in $self->{retrydelay} seconds" );
                sleep $self->{retrydelay} unless($try == $self->{retries});
            }
        }
    }else{
        $self->_warn( "could not write to $self->{mylock}: $!" );
    }
    $self->_warn( "could not get lock" );
    unlink( $self->{mylock} );
    return 0;
}

sub checklock {
    my $self = shift;
    
    if( open(my $fh, $self->{lock}) ){
        chomp(my $line = <$fh>);
        close $fh;
        my($pid,$mylock) = split(/:/, $line, 2);

        $mylock ||= $self->{lock};

        $self->_debug( "found $pid in $self->{lock}" );

        if( kill(0, $pid) ){
            $self->_debug( "found valid existing lock for pid: $pid" );
            return 1;
        }else{
            unless( $self->{lock} eq $mylock ){
                unlink($mylock) || $self->_warn( "could not unlink $mylock: $!" );
            }
            unlink($self->{lock}) || die "could not unlink $self->{lock}: $!";
            $self->_debug( "found and cleaned stale lock." );
        }

    }else{
        $self->_debug( "could not read $self->{lock}: $!" );
    }
    return 0;
}


sub unlock {
    my $self = shift;

    if( -f $self->{mylock} ){
        unlink($self->{mylock}) || $self->_warn( "cannot unlink mylock ( $self->{mylock} ): $!" );
    }

    if($self->{_have_lock}){
        unlink($self->{lock}) || die "cannot unlink lock ( $self->{lock} ): $!\n";
        $self->{_have_lock} = 0;
    }
}

sub _version {
    $File::TinyLock::VERSION;
}

sub _warn {
    my $self = shift;
    my $msg = join('', @_);

    warn "$self->{class}: $msg\n";
}

sub _debug {
    my $self = shift;

    $self->_warn(@_) if($self->{debug});
}

sub DESTROY {
    my $self = shift;

    $self->_debug( "cleaning up.." );
    $self->unlock();

}

1;
