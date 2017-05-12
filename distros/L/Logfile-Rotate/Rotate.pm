#!/usr/bin/perl
###############################################################################
#
# $Id: Rotate.pm,v 1.5 2000/08/29 03:57:23 paulg Exp $ vim:ts=4
#
# Copyright (c) 1997-99 Paul Gampe. All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself. See COPYRIGHT section below.
#
###############################################################################

###############################################################################
##                 L I B R A R I E S / M O D U L E S
###############################################################################

package Logfile::Rotate;

use Config;    # do we have gzip
use Carp;
use IO::File;
use File::Copy;
use Fcntl qw(:flock); 

use strict;

###############################################################################
##                  G L O B A L   V A R I A B L E S
###############################################################################

use vars qw($VERSION $COUNT $GZIP_FLAG);

$VERSION = do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r};
$COUNT   =7; # default to keep 7 copies
$GZIP_FLAG='-qf'; # force writing over old logfiles

###############################################################################
##                         E X P O R T S
###############################################################################

###############################################################################
##                             M A I N
###############################################################################

sub new {
	my ($class, %args) = @_;

	croak("usage: new( File => filename 
				[, Count    => cnt ]
				[, Gzip     => lib or \"/path/to/gzip\" or no ] 
				[, Signal   => \&sub_signal ]
				[, Pre      => \&sub_pre ]
				[, Post     => \&sub_post ]
				[, Flock    => yes or no ]
				[, Persist  => yes or no ]
				[, Dir      => \"dir/to/put/old/files/into\"] )")
		unless defined($args{'File'});

	my $self = {};
	$self->{'Fh'}	  = undef;
	$self->{'File'}   = $args{'File'};
	$self->{'Count'}  = ($args{'Count'} or 7);
	$self->{'Signal'} = ($args{'Signal'} or sub {1;});
	$self->{'Pre'} = ($args{'Pre'} or sub {1;});
	$self->{'Post'} = ($args{'Post'} or sub {1;});
	$self->{'Flock'}  = ($args{'Flock'} or 'yes');
	$self->{'Persist'}  = ($args{'Persist'} or 'yes');

	# deprecated methods
	carp "Signal is a deprecated argument, see Pre/Post" if $args{'Signal'};

	# mutual excl
	croak "Can not define both Signal and Post" 
		if ($args{Signal} and $args{Post});

	(ref($self->{'Signal'}) eq "CODE")
		or croak "error: Signal is not a CODE reference.";

	(ref($self->{'Pre'}) eq "CODE")
		or croak "error: Pre is not a CODE reference.";

	(ref($self->{'Post'}) eq "CODE")
		or croak "error: Post is not a CODE reference.";

	# Process compression arg
	unless ($args{Gzip}) {
		if (_have_compress_zlib()) {
			$self->{Gzip} = 'lib';
		} else {
			$self->{Gzip} = $Config{gzip};
		}
	} else {
		if ($args{Gzip} eq 'no') {
			$self->{Gzip} = undef;
		} else {
			$self->{Gzip} = $args{Gzip};
		}
	}


	# Process directory arg

	if (defined($args{'Dir'})) {
		$self->{'Dir'} = $args{'Dir'};
		# don't know about creating directories ??
		mkdir($self->{'Dir'},0750) unless (-d $self->{'Dir'});
	} else {
		$self->{'Dir'} = undef;
	}

	# confirm existence of dir

	if (defined $self->{'Dir'} ) {
		croak "error: $self->{'Dir'} not writable" 
		unless (-w $self->{'Dir'});
		croak "error: $self->{'Dir'} not executable" 
		unless (-x $self->{'Dir'});
	}

	# open and lock the file
	if( $self->{'Flock'} eq 'yes'){
	    $self->{'Fh'} = new IO::File "$self->{'File'}", O_WRONLY|O_EXCL;
	    croak "error: can not lock open: ($self->{'File'})" 
		unless defined($self->{'Fh'});
		flock($self->{'Fh'},LOCK_EX);
	}
	else{
	    $self->{'Fh'} = new IO::File "$self->{'File'}";
	    croak "error: can not open: ($self->{'File'})" 
		unless defined($self->{'Fh'});
	}

	bless $self, $class;
}

sub rotate {
    my ($self, %args) = @_;

    my ($prev,$next,$i,$j);

    # check we still have a filehandle
    croak "error: lost file handle, may have called rotate twice ?"
        unless defined($self->{'Fh'});

    my $curr  =  $self->{'File'};
    my $currn =  $curr;
    my $ext   =  $self->{'Gzip'} ? '.gz' : '';

	# Execute and exit if Pre method fails
	eval { &{$self->{'Pre'}}($curr); } if $self->{Pre};
	croak "error: your supplied Pre function failed: $@" if ($@);

	# TODO: what is this doing ??
    my $dir   =  defined($self->{'Dir'}) ? "$self->{'Dir'}/" : "";
    $currn    =~ s+.*/([^/]*)+$self->{'Dir'}/$1+ if defined($self->{'Dir'});

    for($i = $self->{'Count'}; $i > 1; $i--) {
        $j = $i - 1;
            $next = "${currn}." . $i . $ext;
            $prev = "${currn}." . $j . $ext;
        if ( -r $prev && -f $prev ) {
            move($prev,$next)	## move will attempt rename for us
                or croak "error: move failed: ($prev,$next)";
        }
    }

    ## copy current to next incremental
    $next = "${currn}.1";
    copy ($curr, $next);        

	## preserve permissions and status
	if ( $self->{'Persist'} eq 'yes' ){
		my @stat = stat $curr;
		chmod( $stat[2], $next ) or carp "error: chmod failed: ($next)";
		utime( $stat[8], $stat[9], $next ) or carp "error: failed: ($next)";
		chown( $stat[4], $stat[5], $next ) or carp "error: chown failed: ($next)";
	}

    # now truncate the file
	if( $self->{'Flock'} eq 'yes' )
	{
		truncate $curr,0 or croak "error: could not truncate $curr: $!"; }
	else{
		local(*IN);
		open(IN, "+>$self->{'File'}") 
			or croak "error: could not truncate $curr: $!";
	}

	if ($self->{'Gzip'} and $self->{'Gzip'} eq 'lib') 
	{ 
		_gzip($next, $next.$ext);
	}
	elsif ($self->{'Gzip'})
	{ 
		# WARNING: may not be safe system call
        ( 0 == (system $self->{'Gzip'}, $GZIP_FLAG, $next) )
            or croak "error: ", $self->{'Gzip'}, " failed";
    }

	# TODO: deprecated: remove next release
	eval { &{$self->{'Signal'}}($curr, $next); } if ($self->{Signal});
	croak "error: your supplied Signal function failed: $@" if ($@);

	# Execute and exit on post method
	eval { &{$self->{'Post'}}($curr, $next); } if $self->{Post};
	croak "error: your supplied Post function failed: $@" if ($@);

	# if we made it here we have succeeded
	return 1;
}

sub DESTROY {
    my ($self, %args) = @_;
	return unless $self->{'Fh'};	# already gone
    flock($self->{'Fh'},LOCK_UN);
    undef $self->{'Fh'};    # auto-close
}

sub _have_compress_zlib {
	# try and load the compression library
	eval { require Compress::Zlib; };
	if ($@) {
		carp "warning: could not load Compress::Zlib, skipping compression" ;
		return undef;
	}
	return 1;
}

sub _gzip {
	my $in = shift;
	my $out = shift;

	# ASSERT
	croak "error: _gzip called without mandatory argument" unless $in;

	return unless _have_compress_zlib();

    my($buffer,$fhw);
	$fhw = new IO::File $in 
		or croak "error: could not open $in: $!";
    my $gz = Compress::Zlib::gzopen($out, "wb")
		or croak "error: could not gzopen $out: $!";
    $gz->gzwrite($buffer)
	while read($fhw,$buffer,4096) > 0 ;
    $gz->gzclose() ;
    $fhw->close;

	unlink $in or croak "error: could not delete $in: $!";

	return 1;
}

1;


__END__

=head1 NAME

Logfile::Rotate - Perl module to rotate logfiles.

=head1 SYNOPSIS

   use Logfile::Rotate;
   my $log = new Logfile::Rotate( File   => '/var/adm/syslog/syslog.log', 
                                  Count  => 7,
                                  Gzip  => 'lib',
                                  Post   => sub{ 
                                    open(IN, "/var/run/syslog.pid");
                                    kill("HUP", chomp(<IN>)); }
                                  Dir    => '/var/log/old',
                                  Flock	 => 'yes',
                                  Persist => 'yes',
                                );

   # process log file 

   $log->rotate();

   or
   
   my $log = new Logfile::Rotate( File  => '/var/adm/syslog', 
                                  Gzip   => '/usr/local/bin/gzip');
   
   # process log file 

   $log->rotate();
   undef $log;

=head1 DESCRIPTION

I have used the name space of L<Logfile::Base> package by I<Ulrich Pfeifer>, 
as the use of this module closely relates to the processing logfiles.

=over 4

=item new

C<new> accepts the following arguments, C<File>, C<Count>, C<Gzip>,
C<Pre>, C<Post>, C<Flock> and C<Dir> with only C<File> being mandatory.
C<new> will open and lock the file, so you may co-ordinate the
processing of the file with rotating it.  The file is closed and
unlocked when the object is destroyed, so you can do this explicitly by
C<undef>'ing the object.  

The C<Pre>/C<Post> arguments allow you to pass function references to
this method, which you may use as a callback for any processing you want
before or after the rotation. For example, you may notify the process
writing to the file that it has been rotated.

The C<Pre> function is passed the current filename to be rotated as an
argument and the C<Post> function is passed the current filename that
was rotated and that file's new filename including any extension added
by compression previously.

Both the C<Pre> and C<Post> function references you provide are executed
within an C<eval> statement inside the C<rotate> method.  If the C<eval>
returns an error then the C<rotate> method will croak at that point.

The C<Signal> argument is deprecated by the C<Post> argument.

The C<Flock> argument allows you to specify whether the perl function
C<flock> is used to lock the file during the rotation operation.
Apparently flock causes problems on some platforms and this option has
been added to allow you to control the programs behaviour.  By default
the file will be locked using C<flock>.

The C<Persist> argument allows you to control whether the program will
try and set the current log file ownership and permissions on any new
files that may be created by the rotation.  In some circumstances the
program doing the file rotation may not have sufficient permission to
C<chown> on the file.  By default the program will try and preserve
ownership and permissions.

=item rotate()

This method will copy the file passed in C<new> to a file of the same
name, with a numeric extension and truncate the original file to zero
length.  The numeric extension will range from 1 up to the value
specified by Count, or 7 if none is defined, with 1 being the most
recent file.  When Count is reached, the older file is discarded in a
FIFO (first in, first out) fashion. If the argument C<Dir> was given, 
all old files will be placed in the specified directory.

The C<Post> function is the last step executed by the rotate method so
the return code of rotate will be the return code of the function you
proved, or 1 by default.

The copy function is implemented by using the L<File::Copy> package, but
I have had a few people suggest that they would prefer L<File::Move>.
I'm still not decided on this as you would loose data if the move should
fail.  

=back 

=head2 Optional Compression

If available C<rotate> will also compress the file with the 
L<gzip> program or the program passed as the C<Gzip> argument.  

You may now also use C<lib> as a value for the C<Gzip> argument.  This
directs the program to load the C<Compress::Zlib> module, if available
and use it do the compression within perl.  B<This avoids the security
issues associated with spawning external programs and is the recommended
value for this option.>

If no argument is defined it will first check to see if the
C<Compress::Zlib> module can be loaded then check the perl L<Config> to
determine if gzip is available on your system. In this case the L<gzip>
must be in your current path to succeed, and accept the C<-f> option.  

See the L<"WARNING"> section below.

=head2 Optional Relocation Directory

If you specify an argument for C<Dir> then the file being rotated will
be relocated to the directory specified.  Along with any other files
that may have been rotated previously.  If the directory name specified
does not exist then it will be created with C<0750> permissions.  If you
wish to have other permissions on the directory then I would recommend
you create the directory before using this module.

See the L<"WARNING"> section below.

=head1 WARNING

If a system call is made to F<gzip> this makes this module vulnerable to
security problems if a rogue gzip is in your path or F<gzip> has been
sabotaged.  For this reason a STRONGLY RECOMMEND you DO NOT use this
module while you are ROOT.

For a more secure alternative install the C<Compress::Zlib> module and
use the B<lib> value for the C<Gzip> argument.

If you specify an argument for C<Dir> and the directory name you pass
does not exist, this module B<will create> the directory with
permissions C<0750>.

=head1 DEPENDANCIES

See L<File::Copy>.

If C<Gzip> is being used it must create files with an extension 
of C<.gz> for the file to be picked by the rotate cycle.

=head1 COPYRIGHT

Copyright (c) 1997-99 Paul Gampe. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY
FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
ARISING OUT OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY
DERIVATIVES THEREOF, EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE. 

THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
NON-INFRINGEMENT. THIS SOFTWARE IS PROVIDED ON AN ``AS IS'' BASIS, AND
THE AUTHORS AND DISTRIBUTORS HAVE NO OBLIGATION TO PROVIDE
MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. 

=head1 SEE ALSO

L<File::Copy>, L<Logfile::Base>, L<flock>
F<Changes> file for change history and credits for contributions.

=head1 RETURN

All functions return 1 on success, 0 on failure.

=head1 AUTHOR

Paul Gampe <paulg@apnic.net>

=cut

