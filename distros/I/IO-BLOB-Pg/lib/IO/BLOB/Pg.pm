package IO::BLOB::Pg;

# Copyright 2000 Mark A. Hershberger
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

require 5.005_03;
use strict;
use vars qw($VERSION $DEBUG $IO_CONSTANTS);
$VERSION = "0.91";  # $Date: 2002/08/12 06:14:57 $

use Symbol ();
use Carp;
use IO::Handle;

my $SEEK_SET = &IO::Handle::SEEK_SET;
my $SEEK_END = &IO::Handle::SEEK_END;

sub new
{
  my $class = shift;
  my $self = bless Symbol::gensym(), ref($class) || $class;

  tie *$self, $self;
  return $self->open(@_) ? $self : undef;
}

sub open
{
  my $self = shift;
  return $self->new(@_) unless ref($self);

  if (@_ == 2) {
    *$self->{dbi} = $_[0];
    *$self->{id}  = $_[1];
  } elsif(@_ == 1) {
    *$self->{dbi} = $_[0];
    *$self->{id}  = *$self->{dbi}->func(*$self->{dbi}->{pg_INV_READ} |
					*$self->{dbi}->{pg_INV_WRITE}, "lo_creat");
  } else {
    croak "open \$DBI[, \$id]";
  }
  croak "AutoCommit needs to be off"
    if *$self->{dbi}->{AutoCommit};
  *$self->{fh}  = *$self->{dbi}->func(*$self->{id},
				      *$self->{dbi}->{pg_INV_READ} |
				      *$self->{dbi}->{pg_INV_WRITE}, "lo_open");

  if(not defined *$self->{fh} || not defined *$self->{id}) {
    return undef;
  }
  *$self->{pos} = 0;
  *$self->{lno} = 0;

  $self;
}

sub oid {
  my $self = shift;
  return *$self->{id};
}

sub pad {
  my $self = shift;
  my $old = *$self->{pad};
  *$self->{pad} = substr($_[0], 0, 1) if @_;
  return "\0" unless defined($old) && length($old);
  $old;
}

sub dump
{
    require Data::Dumper;
    my $self = shift;
    print Data::Dumper->Dump([$self], ['*self']);
    print Data::Dumper->Dump([*$self{HASH}], ['$self{HASH}']);
}

sub TIEHANDLE
{
    print "TIEHANDLE @_\n" if $DEBUG;
    return $_[0] if ref($_[0]);
    my $class = shift;
    my $self = bless Symbol::gensym(), $class;
    $self->open(@_);
    $self;
}

sub DESTROY
{
    print "DESTROY @_\n" if $DEBUG;
}

sub close
{
    my $self = shift;
    *$self->{dbi}->func(*$self->{fh}, 'lo_close')
      if defined (*$self->{dbi} && defined *$self->{fh});
    delete *$self->{buf};
    delete *$self->{pos};
    delete *$self->{lno};

    $self;
}

sub opened
{
    my $self = shift;
    defined *$self->{buf};
}

sub getc
{
    my $self = shift;
    my $buf;
    return $buf if $self->read($buf, 1);
    return undef;
}

sub ungetc
{
    my $self = shift;
    $self->setpos($self->getpos() - 1)
}

sub eof
{
    my $self = shift;
    my $dbi = *$self->{dbi};
    my $id  = *$self->{id};
    my $tmp  = $self->tell;
    $self->seek(0, 2);
    my $end  = $self->tell;
    $self->seek($tmp, 0);

    $end <= $tmp;
}

sub print
{
    my $self = shift;
    if (defined $\) {
	if (defined $,) {
	    $self->write(join($,, @_).$\);
	} else {
	    $self->write(join("",@_).$\);
	}
    } else {
	if (defined $,) {
	    $self->write(join($,, @_));
	} else {
	    $self->write(join("",@_));
	}
    }
}
*printflush = \*print;

sub printf
{
    my $self = shift;
    print "PRINTF(@_)\n" if $DEBUG;
    my $fmt = shift;
    $self->write(sprintf($fmt, @_));
}


sub seek {
  my($self,$off,$whence) = @_;
  my $fh = *$self->{fh};
  my $pos;

  $pos = *$self->{dbi}->func($fh, $off, $whence, 'lo_lseek');
  carp "Error during seek: ", $DBI::errstr
    if $DBI::err || not defined $pos;

  if(defined $pos && $pos < 0) {
    $pos = 0;
    *$self->{lno} = 0;
  } elsif(defined $pos) {
    *$self->{pos} = $pos;
  }
  return 1 if defined $pos;
  return 0;
}

sub _length {
  my $self = shift;
  my $old = *$self->{pos};

  $self->seek(0, 2);
  my $len = $self->tell;
  $self->seek($old, 0);

  return $len;
}
*length   = \&_length;

sub pos {
  my $self = shift;
  my $old = *$self->{pos};
  _init_seek_constants() unless defined $SEEK_SET;

    if (@_) {
	my $pos = shift || 0;
	my $fh = *$self->{fh};
	my $len = $self->_length;
	$pos = $pos > $len ? $len : $pos;
	*$self->{dbi}->func($fh, $pos, $SEEK_SET, 'lo_lseek');
	*$self->{pos} = $pos;
	*$self->{lno} = 0;
    }
    $old;
}

sub getpos { shift->pos; }

*sysseek = \&seek;
*setpos  = \&pos;
*tell    = \&getpos;



sub getline
{
    my $self = shift;
    my $fh  = *$self->{fh};
    my $dbi = *$self->{dbi};
    my $len  = $self->_length();
    my $pos  = *$self->{pos};
    return if $pos >= $len;
    my $line = "";

    unless (defined $/) {  # slurp
	*$self->{pos} = $len;
	$dbi->func($fh, $line, $len - $pos, 'lo_read');
	return $line;
    }

    unless (length $/) {  # paragraph mode
	# XXX slow&lazy implementation using getc()
	my $para = "";
	my $eol = 0;
	my $c;
	while (defined($c = $self->getc)) {
	    if ($c eq "\n") {
		$eol++;
	    } elsif ($eol > 1) {
		$self->ungetc($c);
		last;
	    }
	    $para .= $c;
	}
	return $para;   # XXX wantarray
    }

    my $ret = "";
    my $tmp = "";
    my $br;
  READ:
    while (($br = $self->read($tmp, 512)) != 0) {
      my $idx = index($tmp, $/);
      if($idx > ($[ - 1)) {
	*$self->{pos} += $idx + length($/) - $br;
	$self->seek(*$self->{pos}, 0);
	$ret .= substr($tmp, 0, $idx+length($/));
	$. = ++*$self->{lno};
	return $ret;
      } else {
	$ret .= $tmp;
	*$self->{pos} += $br
      }
    }
    $. = ++*$self->{lno};

    return $ret;
}

sub getlines
{
    die "getlines() called in scalar context\n" unless wantarray;
    my $self = shift;
    my($line, @lines);
    push(@lines, $line) while defined($line = $self->getline);
    return @lines;
}

sub READLINE
{
    goto &getlines if wantarray;
    goto &getline;
}

sub input_line_number
{
    my $self = shift;
    my $old = *$self->{lno};
    *$self->{lno} = shift if @_;

    $old;
}

sub truncate {
  my $self = shift;
  my $len = shift || 0;
  my $fh = *$self->{fh};
  if ($self->_length > $len) {
    carp "Not Implemented";
#    substr($fh, $len) = '';
#    *$self->{pos} = $len if $len < *$self->{pos};
  } elsif ($self->_length < $len) {
    $self->seek(0, $SEEK_END);
    $self->write($self->pad x ($len - $self->_length))
  }
  $self;
}

sub read
{
    my $self = shift;
    my $fh = *$self->{fh};
    my $dbi = *$self->{dbi};
    my $tbuf = "";
    my $len = $_[1];
    my $pos = *$self->{pos};
    my $rem = $self->_length - $pos;

    my $nbytes = $dbi->func($fh, $tbuf, $len, "lo_read");

    if (@_ > 2) { # read offset
      substr($_[0],$_[2]) = $tbuf;
    } else {
      $_[0] = $tbuf;
    }
    *$self->{pos} += $nbytes;
    return $nbytes
}

sub write
{
    my $self = shift;
    my $fh = *$self->{fh};
    my $dbi = *$self->{dbi};

    my $pos = *$self->{pos};
    my $slen = length($_[0]);
    my $len = $slen;
    my $off = 0;
    if (@_ > 1) {
	$len = $_[1] if $_[1] < $len;
	if (@_ > 2) {
	    $off = $_[2] || 0;
	    die "Offset outside file" if $off > $slen;
	    if ($off < 0) {
		$off += $slen;
		die "Offset outside file" if $off < 0;
	    }
	    my $rem = $slen - $off;
	    $len = $rem if $rem < $len;
	}
    }

    my $nbytes = $dbi->func($fh, substr($_[0], $off), $len, "lo_write");
    *$self->{pos} += $nbytes;
    $nbytes;
}

*sysread = \&read;
*syswrite = \&write;

sub stat
{
    my $self = shift;
    return unless $self->opened;
    return 1 unless wantarray;
    my $len = $self->_length;

    return (
     undef, undef,  # dev, ino
     0666,          # filemode
     1,             # links
     $>,            # user id
     $),            # group id
     undef,         # device id
     $len,          # size
     undef,         # atime
     undef,         # mtime
     undef,         # ctime
     512,           # blksize
     int(($len+511)/512)  # blocks
    );
}

sub blocking {
    my $self = shift;
    my $old = *$self->{blocking} || 0;
    *$self->{blocking} = shift if @_;
    $old;
}

my $notmuch = sub { return };

*fileno    = $notmuch;
*error     = $notmuch;
*clearerr  = $notmuch;
*sync      = $notmuch;
*flush     = $notmuch;
*setbuf    = $notmuch;
*setvbuf   = $notmuch;

*untaint   = $notmuch;
*autoflush = $notmuch;
*fcntl     = $notmuch;
*ioctl     = $notmuch;

*GETC   = \&getc;
*PRINT  = \&print;
*PRINTF = \&printf;
*READ   = \&read;
*WRITE  = \&write;
*CLOSE  = \&close;

1;

__END__

=head1 NAME

IO::BLOB::Pg - Emulate IO::File interface for PostgreSQL Large Objects

=head1 SYNOPSIS

 use IO::BLOB::Pg;
 use DBI;

 $dbh = DBI->connect("dbi:Pg:dbname=template1", "", "",
                     {RaiseError=>1,
                      AutoCommit=>0}) # <- Absolutely necessary!
 $io = IO::BLOB::Pg->new($dbi);	# Create a new blob
 tie *IO, 'IO::BLOB::Pg';

 # write data
 print $io "string\n";
 $io->print(@data);
 syswrite($io, $buf, 100);

 select $io;
 printf "Some text %s\n", $str;

 # seek
 $pos = $io->getpos;
 $io->setpos(0);        # rewind
 $io->seek(-30, -1);

 # read data
 <$io>;
 $io->getline;
 read($io, $buf, 100);

 # get the blob's oid
 $oid = $io->oid;

 # close up
 $io->close;

 # open a previously created blob
 $io = IO::BLOB::Pg->new($dbi, $oid);

=head1 **** WARNING ****

To use this module, you *must* feed your DBI connection
`AutoCommit => 0'.  See the PostgreSQL documentation for more details.

=head1 DESCRIPTION

The C<IO::BLOB::Pg> module provide the C<IO::File> interface for Large
Objects (aka BLOBs) in a PostgreSQL database.  An C<IO::BLOB::Pg> object
can be attached to a Large Object ID, and will make it possible to use
the normal file operations for reading or writing data, as well as
seeking to various locations of the object.

This provides a tremendous amount of convenience since you can treat
the object just like a regular file and operate on it as you would
normally in Perl instead of doing all sorts of funky stuff like:

  $dbh->func($lobjfd, $buff, $len, "lo_read");

you get:

  <$lobjfd>

I based this code on Gisle Aas' IO::String.

The C<IO::BLOB::Pg> module provides an interface compatible with
C<IO::File> as distributed with F<IO-1.20>, but the following methods
are not available; new_from_fd, fdopen, format_write,
format_page_number, format_lines_per_page, format_lines_left,
format_name, format_top_name.

The following methods are specific for the C<IO::BLOB::Pg> class:

=over 4

=item $io = IO::BLOB::Pg->new( $dbh[, $objid] )

The constructor returns a newly created C<IO::BLOB::Pg> object.  You
must supply it with a database handle.  It takes an optional argument
which is oid of the large objectto read from or write into.  If no
$objid argument is given, then a new large object is created.

The C<IO::BLOB::Pg> object returned will be tied to itself.  This means
that you can use most perl IO builtins on it too; readline, <>, getc,
print, printf, syswrite, sysread, close.

=item $io->open( $dbh[, $objid] )

Attach an existing IO::BLOB::Pg object to some other $objid, or create
a new large object if no $objid is given.  The position is reset back
to 0.

=item $io->oid

This method will return the oid of the large object.  This is useful
for when you create a large object and what to put a reference to it
in another table.

=item $io->pad( [$char] )

The pad() method makes it possible to specify the padding to use if
the object is extended by either the truncate() method.  It
is a single character and defaults to "\0".

=item $io->pos( [$newpos] )

Yet another interface for reading and setting the current read/write
position within the object (the normal getpos/setpos/tell/seek
methods are also available).  The pos() method will always return the
old position, and if you pass it an argument it will set the new
position.

=item $io->length

Convenience method that gives you the size of the Blob.

=back

One more difference compared to IO::Handle, is that the write() and
syswrite() methods allow the length argument to be left out.

=head1 BUGS

The perl TIEHANDLE interface is still not complete.  There are quite a
few file operations that will not yet invoke any method on the tied
object.  See L<perltie> for details.

=head1 SEE ALSO

L<IO::File>, L<IO::String>

=head1 COPYRIGHT

Copyright 2000 Mark A. Hershberger, <mah@everybody.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
