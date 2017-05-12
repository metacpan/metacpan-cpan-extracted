#!/usr/bin/perl -w
package Fuse::Simple; # in file Fuse/Simple.pm

=head1 NAME

Fuse::Simple - Simple way to write filesystems in Perl using FUSE

=head1 SYNOPSIS

  use Fuse::Simple qw(accessor main);
  my $var = "this is a variable you can modify. write to me!\n";
  my $filesystem = {
    foo => "this is the contents of a file called foo\n",
    subdir => {
      "foo"  => "this foo is in a subdir called subdir\n",
      "blah" => "this blah is in a subdir called subdir\n",
    },
    "blah" => \ "subdir/blah",        # scalar refs are symlinks
    "magic" => sub { return "42\n" }, # will be called to get value
    "var"  => accessor(\$var),        # read and write this variable
    "var2" => accessor(\$var),        # and the same variable
    "var.b" => accessor(\ my $tmp),   # and an anonymous var
  };
  main(
    "mountpoint" => "/mnt",      # actually optional
    "debug"      => 0,           # for debugging Fuse::Simple. optional
    "fuse_debug" => 0,           # for debugging FUSE itself. optional
    "threaded"   => 0,           # optional
    "/"          => $filesystem, # required :-)
  );

=head1 DESCRIPTION

B<Fuse> lets you write filesystems in Perl. B<Fuse::Simple> makes this
REALLY Simple, as you just need a hash for your root directory,
containing strings for files, more hashes for subdirs, or functions
to be called for magical functionality a bit like F</proc>.

=cut

######################################################################
# By "Nosey" Nick Waterman of Nilex
#   <perl@noseynick.org>   http://noseynick.org/
# (C) Copyright 2006 Nilex - All wrongs righted, all rights reserved.
######################################################################
# Requirements:
use 5.008;
use strict;
use warnings;
use Carp;
use Fuse;
use Errno qw(:POSIX);         # ENOENT EISDIR etc
use Fcntl qw(:DEFAULT :mode); # S_IFREG S_IFDIR, O_SYNC O_LARGEFILE etc.
use Switch;
# use diagnostics;

######################################################################
# Module stuff:
######################################################################
use Exporter;
our @ISA = qw(Exporter);
our $VERSION = '1.00';

# thou shalt not pollute, thou shalt not export more than thou needest.
our @EXPORT    = qw( );
our @EXPORT_OK = qw(
    main fetch runcode saferun fserr nocache wrap quoted
    dump_open_flags accessor easy_getattr
    fs_not_imp fs_flush fs_getattr fs_getdir fs_open fs_read fs_readlink
    fs_release fs_statfs fs_truncate fs_write
);
our %EXPORT_TAGS =
  (
      'all'     => \@EXPORT_OK,
      'DEFAULT' => \@EXPORT,
      'usual'   => [qw(main accessor fserr nocache)],
      'debug'   => [qw(wrap quoted dump_open_flags)],
      'tools'   => [qw(fetch runcode saferun easy_getattr)],
      'filesys' => [qw(
	  fs_not_imp fs_flush fs_getattr fs_getdir fs_open fs_read
	  fs_readlink fs_release fs_statfs fs_truncate fs_write
      )],
  );

=head1 IMPORT TAGS

B<Fuse::Simple> exports nothing by default, but individual functions
can be exported, or any ofthe following tags:

=over

=item :usual

Includes: main accessor fserr nocache

=item :debug

Includes: wrap quoted dump_open_flags

=item :tools

Includes: fetch runcode saferun easy_getattr

=item :filesys

Includes:
fs_not_imp fs_flush fs_getattr fs_getdir fs_open fs_read
fs_readlink fs_release fs_statfs fs_truncate fs_write

=back

=begin testing

BEGIN { use_ok( 'Fuse::Simple', qw(:usual :debug :tools :filesys)); }

=end testing

=cut

######################################################################
# Some useful stuff
######################################################################

our $debug = 0; # can be set if you really really need it to be
my $ctime = time();
my $uid   = $>;
my $gid   = $) + 0;
our $fs    = {
    # "empty" dir by default
    "README" => "You forgot to pass a '/' parameter to Fuse::Simple::main!\n"
};

######################################################################

=head1 MAIN FUNCTION

=over

=item B<main>(B<arg> => I<value>, ...)

Mount your filesystem, and probably never return. Arguments are:

=over

=item B<mountpoint> => I<"/mnt">,

This is actually optional. If you don't supply a mountpoint, it'll
take it from @ARGV !

=item B<debug> => I<0|1>,

Debug Fuse::Simple. All filesystem calls, arguments, and return values
will be dumped, a bit like L<strace> for perl.

=item B<fuse_debug> => I<0|1>,

Debug FUSE itself. More low-level than B<debug>

=item B<threaded> => I<0|1>,

See L<Fuse>

=item B<"/"> => { hash for your root directory },

=item B<chmod> B<chown> B<flush> B<fsync> B<getattr> B<getdir> etc

See L<Fuse>

You can replace any of the low-level functions if you want, but if
you wanted to mess around with the dirty bits, you'd probably not be
using L<Fuse::Simple>, would you?

=item others

If I've forgotten any L<Fuse> args, you can supply them too.

=back

=back

=cut

sub main {
    # some default args
    my %args = (
	"mountpoint"  => $ARGV[0] || "",
	"debug"       => $debug,
	"fuse_debug"  => 0,
	"threaded"    => 0,
	"/"           => $fs,
    );
    # the default subs
    my %fs_subs = (
	"chmod"       => \&fs_not_imp,
	"chown"       => \&fs_not_imp,
	"flush"       => \&fs_flush,
	"fsync"       => \&fs_not_imp,
	"getattr"     => \&fs_getattr,
	"getdir"      => \&fs_getdir,
	"getxattr"    => \&fs_not_imp,
	"link"        => \&fs_not_imp,
	"listxattr"   => \&fs_not_imp,
	"mkdir"       => \&fs_not_imp,
	"mknod"       => \&fs_not_imp,
	"open"        => \&fs_open,
	"read"        => \&fs_read,
	"readlink"    => \&fs_readlink,
	"release"     => \&fs_release,
	"removexattr" => \&fs_not_imp,
	"rmdir"       => \&fs_not_imp,
	"rename"      => \&fs_not_imp,
	"setxattr"    => \&fs_not_imp,
	"statfs"      => \&fs_statfs,
	"symlink"     => \&fs_not_imp,
	"truncate"    => \&fs_truncate,
	"unlink"      => \&fs_not_imp,
	"utime"       => sub{return 0},
	"write"       => \&fs_write,
    );
    my $name;
    # copy across the arg supplied to main()
    while ($name = shift) {
	$args{$name} = shift;
    }
    # except extract these ones back out.
    $debug = delete $args{"debug"};
    $args{"debug"} = delete( $args{"fuse_debug"} ) || 0;
    $fs = delete $args{"/"};
    # add the functions, if not already defined.
    # wrap in debugger if debug is set.
    for $name (keys %fs_subs) {
	my $sub = $fs_subs{$name};
	$sub = wrap($sub, $name) if $debug;
	$args{$name} ||= $sub;
    }
    Fuse::main(%args);
}

=head1 UTIL FUNCTIONS

These might be useful for people writing their own filesystems

=over

=item B<fetch>(I<$path, @args>)   (not exported)

Given F</a/path/within/my/fs/foo>, return the F<foo> dir or file or
whatever. @args will be passed to the final coderef if supplied.

=begin testing

is(fetch("README"), $Fuse::Simple::fs->{README}, "fetch() test");

=end testing

=cut

sub fetch {
    my ($path, @args) = @_;
    
    my $obj = $fs;
    for my $elem (split '/', $path) {
	next if $elem eq ""; # skip empty // and before first /
	$obj = runcode($obj); # if there's anything to run
	# the dir we're changing into must be a hash (dir)
	return fserr(ENOTDIR()) unless ref($obj) eq "HASH";
	# note that ENOENT and undef are NOT the same thing!
	return fserr(ENOENT()) unless exists $obj->{$elem};
	$obj = $obj->{$elem};
    }
    
    return runcode($obj, @args);
}

=item B<runcode>(I<$code, @args>)   (not exported)

B<IF WE'RE GIVEN A CODEREF>, run it, or return our cached version
return after all CODE refs have been followed.
also returns first arg if it wasn't a coderef.

=begin testing

is(runcode("foo"), "foo",                        "runcode with string");
is_deeply(runcode(["A","B","C"]), ["A","B","C"], "runcode with arrayref");
is_deeply(runcode({"A"=>"B"}), {"A"=>"B"},       "runcode with hashref");
is(runcode(undef), undef,                        "runcode with undef");
is(runcode(sub {return "foo"}), "foo",           "runcode with foo");
is(runcode(sub {return shift}, "foo"), "foo",    "runcode with an arg");
is_deeply(runcode(sub{return{"a"=>"b"}}, {"a"=>"b"}), {"a"=>"b"},
                                                 "runcode sub returns hash");

=end testing

=cut

my %codecache = ();
sub runcode {
    my ($obj, @args) = @_;
    
    while (ref($obj) eq "CODE") {
	my $old = $obj;
	if (@args) { # run with these args. don't cache
	    delete $codecache{$old};
	    print "running $obj(",quoted(@args),") NO CACHE\n" if $debug;
	    $obj = saferun($obj, @args);
	} elsif (exists $codecache{$obj}) { # found in cache
	    print "got cached $obj\n" if $debug;
	    $obj = $codecache{$obj}; # could be undef, or an error, BTW
	} else {
	    print "running $obj() to cache\n" if $debug;
	    $obj = $codecache{$old} = saferun($obj);
	}
	
	if (ref($obj) eq "NOCACHE") {
	    print "returned a nocache() value - flushing\n" if $debug;
	    delete $codecache{$old};
	    $obj = $$obj;
	}
	
	print "returning ",ref($obj)," ",
	  defined($obj) ? $obj : "undef",
	  "\n" if $debug;
    }
    return $obj;
}

=item B<saferun>(I<$sub>,I<@args>)

Runs the supplied $sub coderef, safely (IE catches die() etc),
returns something usable by the rest of Fuse::Simple.

=begin testing

is(saferun(sub{"foo"}), "foo", "saferun string");
is(saferun(sub{shift}, "foo"), "foo", "saferun arg");
is(ref(saferun(sub{die "foo"})), "ERROR", "saferun error");
is_deeply(saferun(sub{die ["foo"]}), ["foo"], "saferun array die");

=end testing

=cut

sub saferun {
    my ($sub, @args) = @_;
    
    my $ret = eval { &$sub(@args) };
    my $died = $@;
    if (ref($died)) {
	# we can die fserr(ENOTSUP) if we want!
	print "+++ Error $$died\n" if ref($died) eq "ERROR";
	return $died;
    } elsif ($died) {
	print "+++ $died\n";
	# stale file handle? moreorless?
	return fserr(ESTALE());
    }
    return $ret;
}

=item B<fserr>(I<$error_number>)

Used by called coderef files, to return an error indication, for example:

  return fserr(E2BIG());

=begin testing

is(ref(fserr("foo")), "ERROR", "fserr ref type");
is(${&fserr("foo")}, "foo", "fserr arg passed");

=end testing

=cut

sub fserr {
    return bless(\ shift, "ERROR"); # yup, utter abuse of bless   :-)
}

=item B<nocache>(I<$stuff_to_return>)

Used by called coderef files, to return something that should not be cached.

=begin testing

is(ref(nocache("foo")), "NOCACHE", "nocache ref type");
is(${&nocache("foo")}, "foo", "nocache arg passed");

=end testing

=cut

sub nocache {
    return bless(\ shift, "NOCACHE"); # yup, utter abuse of bless   :-)
}

=item B<wrap>(I<$sub, @name_etc>)

Wrap a function with something that'll dump args on the way in
and return values on the way out.
This is a debugging fuction, sorta like L<strace> for perl really.

=begin testing

my $test = wrap(sub {return "foo".(shift||"")}, "foo");
is(ref($test), "CODE", "wrap a coderef");
is(&$test(), "foo", "wrapped coderef returns expected");
is(&$test("bar"), "foobar", "wrapped coderef args work");

=end testing

=cut

my @indent = ();
sub wrap {
    my ($sub, @name_etc) = @_;
    
    return sub {
	print "@indent> @name_etc(", quoted(@_), ")\n";
	push @indent, "  ";
	my @ret = eval { &$sub(@_) };
	my $died = $@;
	pop @indent;
	die $died if ref($died); # die(some object), EG die(fserr(E2BIG))
	die "@indent! $died" if $died;
	print "@indent< =", quoted(@ret), "\n";
	return wantarray ? @ret : $ret[0];
    };
}

=item B<quoted>(I<@list>)

return a nice printable version of the args, a little like
Data::Dumper would

=begin testing

is(quoted("foo"), '"foo"', "quoting");
is(quoted('\\'), '"\\\\"', "quoting backslash");
is(quoted("\$\@\"\t\r\n\f\a\e"), '"\$\@\"\t\r\n\f\a\e"', "quoting fun");
is(quoted('42'), '42', "unquoted numbers");
is(quoted(1,2,3), '1, 2, 3', "quoted list");

=end testing

=cut

my %escaped = (
    '$' => '$', '@' => '@', '"' => '"', "\\" => "\\",
    "\t" => "t", "\r" => "r", "\n" => "n",
    "\f" => "f", "\a" => "a", "\e" => "e",
);
sub quoted {
    my @ret = ();
    
    for my $n (@_) {
	# special case for undefined vars:
	if (not defined($n)) { push @ret, "undef"; next; }
	# digits (that are really digits without newlines) can be printed
	# without quoting:
	if ($n =~ /^-?\d+\.?\d*$/  &&  $n !~ /\n/) { push @ret, $n; next; }
	
	# other stuff needs quoting and escaping in fun ways:
	my $s = $n;
	$s =~ s/([\$\@\"\\\t\n\r\f\a\e])/\\$escaped{$1}/g;
	$s =~ s/([^ -~])/sprintf('\x{%x}',ord($1))/ge;
	push @ret, '"'.$s.'"';
    }
    return join(", ", @ret);
}

=item B<dump_open_flags>(I<$flags>)

Translate the flags to the open() call

=cut

sub dump_open_flags {
    my $flags = shift;
    
    printf "  flags: 0%o = (", $flags;
    for my $bits (
	[ O_ACCMODE(),   O_RDONLY(),     "O_RDONLY"    ],
	[ O_ACCMODE(),   O_WRONLY(),     "O_WRONLY"    ],
	[ O_ACCMODE(),   O_RDWR(),       "O_RDWR"      ],
	[ O_APPEND(),    O_APPEND(),    "|O_APPEND"    ],
	[ O_NONBLOCK(),  O_NONBLOCK(),  "|O_NONBLOCK"  ],
	[ O_SYNC(),      O_SYNC(),      "|O_SYNC"      ],
	[ O_DIRECT(),    O_DIRECT(),    "|O_DIRECT"    ],
	[ O_LARGEFILE(), O_LARGEFILE(), "|O_LARGEFILE" ],
	[ O_NOFOLLOW(),  O_NOFOLLOW(),  "|O_NOFOLLOW"  ],
    ) {
	my ($mask, $flag, $name) = @$bits;
	if (($flags & $mask) == $flag) {
	    $flags -= $flag;
	    print $name;
	}
    }
    printf "| 0%o !!!", $flags if $flags;
    print ")\n";
}

=item B<accessor>(I<\$var>)

return a sub that can be used to read and write the (scalar) variable $var:

  my $var = "default value";
  my $fs = { "filename" => accessor(\$var) };

This accessor is a bit over-simple, doesn't handle multi-block writes,
partial block writes, seeked reads, non-saclar values,
or anything particularly clever.

=begin testing

my $foo = undef;
my $acc = accessor(\$foo);

is(ref($acc), "CODE", "accessor is a coderef");
is($foo, undef, "undef at first");
is(&$acc(), undef, "undef thru accessor");

&$acc("foo");
is($foo, "foo", "foo was set");
is(&$acc(), "foo", "foo thru accessor");

$foo="bar";
is(&$acc(), "bar", "bar thru accessor");

=end testing

=cut

sub accessor {
    my $var_ref = shift;
    
    croak "accessor() requires a reference to a scalar var\n"
      unless defined($var_ref) && ref($var_ref) eq "SCALAR";
    
    return sub {
	my $new = shift;
	$$var_ref = $new if defined($new);
	return $$var_ref;
    }
}

=item B<easy_getattr>(I<$mode, $size>)

Internal function, to make it easier to return B<getattr()>s 13
arguments when there's probably only 2 you really care about.

Returns everything else that getattr() should.

=back

=cut

sub easy_getattr {
    my ($mode, $size) = @_;
    
    return (
	0, 0,       # $dev, $ino,
	$mode,
	1,          # $nlink, see fuse.sourceforge.net/wiki/index.php/FAQ
	$uid, $gid, # $uid, $gid,
	0,          # $rdev,
	$size,      # $size,
	$ctime, $ctime, $ctime, # actually $atime, $mtime, $ctime,
	1024, 1,    # $blksize, $blocks,
    );
}

=head1 FUSE FILESYSTEM FUNCTIONS

These can be overridden if you really want to get at the guts of the
filesystem, but if you really wanted to get that dirty, you probably
wouldn't be using Fuse::Simple, would you?

=over

=item B<fs_not_imp>()

return ENOSYS "Function not implemented" to the program that's
accessing this function.

=begin testing

is(fs_not_imp(), -38, "fs_not_imp -38");

=end testing

=cut

sub fs_not_imp { return -ENOSYS() }

=item B<fs_flush>(I<$path>)

=begin testing

is(fs_flush(), 0, "fs_flush");

=end testing

=cut

sub fs_flush {
    # we're passed a path, but finding my coderef stuff from a path
    # is a bit of a 'mare. flush the lot, won't hurt TOO much.
    print "Flushing\n" if $debug;
    %codecache = ();
    return 0;
}

=item B<fs_getattr>(I<$path>)

=cut

sub fs_getattr {
    my $path = shift;
    my $obj = fetch($path);
    
    # undef doesn't actually mean "file not found", it could be a coderef
    # file-sub which has returned undef.
    return easy_getattr(S_IFREG | 0200, 0) unless defined($obj);
    
    switch (ref($obj)) {
	case "ERROR" {  # this is an error to be returned.
	    return -$$obj;
	}
	case "" {       # this isn't a ref, it's a real string "file"
	    return easy_getattr(S_IFREG | 0644, length($obj));
	}
	# case "CODE" should never happen - already been run by fetch()
	case "HASH" {   # this is a directory hash
	    return easy_getattr(S_IFDIR | 0755, 1);
	}
	case "SCALAR" { # this is a scalar ref. we use these for symlinks.
	    return easy_getattr(S_IFLNK | 0777, 1);
	}
	else {          # what the hell is this file?!?
	    print "+++ What on earth is ",ref($obj)," $path ?\n";
	    return easy_getattr(S_IFREG | 0000, 0);
	}
    }
}

=item B<fs_getdir>(I<$path>)

=cut

sub fs_getdir {
    my $obj = fetch(shift);
    return -$$obj if ref($obj) eq "ERROR"; # THINK this is a good idea.
    return -ENOENT() unless ref($obj) eq "HASH";
    return (".", "..", sort(keys %$obj), 0);
}

=item B<fs_open>(I<$path, $flags>)

=cut

sub fs_open {
    # doesn't really need to open, just needs to check.
    my $obj = fetch(shift);
    my $flags = shift;
    dump_open_flags($flags) if $debug;
    
    # if it's undefined, and we're not writing to it, return an error
    return -EBADF() unless defined($obj) or ($flags & O_ACCMODE());
    
    switch (ref($obj)) {
	case "ERROR"  { return -$$obj; }
	case ""       { return 0 }          # this is a real string "file"
	case "HASH"   { return -EISDIR(); } # this is a directory hash
	else          { return -ENOSYS(); } # what the hell is this file?!?
    }
}

=item B<fs_read>(I<$path, $size, $offset>)

=cut

sub fs_read {
    my $obj = fetch(shift);
    my $size = shift;
    my $off = shift;
    
    return -ENOENT() unless defined($obj);
    return -$$obj if ref($obj) eq "ERROR";
    # any other types of refs are probably bad
    return -ENOENT() if ref($obj);
    
    if ($off >  length($obj)) {
	return -EINVAL();
    } elsif ($off == length($obj)) {
	return 0; # EOF
    }
    return substr($obj, $off, $size);
}

=item B<fs_readlink>(I<$path>)

=cut

sub fs_readlink {
    my $obj = fetch(shift);
    return -$$obj if ref($obj) eq "ERROR";
    return -EINVAL() unless ref($obj) eq "SCALAR";
    return $$obj;
}

=item B<fs_release>(I<$path, $flags>)

=cut

sub fs_release {
    my ($path, $flags) = @_;
    dump_open_flags($flags) if $debug;
    return 0;
}

=item B<fs_statfs>()

=cut

sub fs_statfs {
    return (
        255, # $namelen,
        1,1, # $files, $files_free,
        1,1, # $blocks, $blocks_avail, # 0,0 seems to hide it from df?
        2,   # $blocksize,
    );
}

=item B<fs_truncate>(I<$path, $offset>)

=cut

sub fs_truncate {
    my $obj = fetch(shift, ""); # run anything to set it to ""
    return -$$obj if ref($obj) eq "ERROR";
    return 0;
}

=item B<fs_write>(I<$path, $buffer, $offset>)

=cut

sub fs_write {
    my ($path, $buf, $off) = @_;
    my $obj = fetch($path, $buf, $off); # this runs the coderefs!
    return -$$obj if ref($obj) eq "ERROR";
    return length($buf);
}

1; # for use() or require()

__END__

=back

=head1 CODEREF FILES / ACCESSORS

coderefs in the filesystem tree will be called (with no args)
whenever they're read, and should return some contents (usually a
string, but see below).

They will be called with new contents and an offset if there's
something to be written to them, and can return almost anything,
which will be ignored unless it's an fserr().

It's also called with an empty string and an offset if it's to be
truncated, and can return almost anything, which will be ignored
unless it's an fserr().

  sub mysub {
    my ($contents, $off) = @_;
    if (defined $contents) {
      # we are writing to this file
    } else {
      # we are to return the contents
    }
  }
  my $fs = {
    "magic" => \&mysub,
  };

Will be called like:

  cat /mnt/magic
    mysub();           # the file is being read
  echo "123" > /mnt/magic
    mysub("123\n", 0); # the file is being written
  : > /mnt/magic
    mysub("", 0);      # the file is being truncated

You can return a string, which is the contents of the file.

You can return an fserr() for an error.

You can return a hashref (your sub will look like a directory!)

You can return a scalar ref (your sub will look like a symlink), etc.

You can even return another coderef, which will be called with the same args.

If your program die()s, you'll return ESTALE "Stale file handle".

If you die(fserr(E2BIG)), you'll return that specified error.

If you die(nocache("An error message\n")) you'll actually not return
an error, but return a file containing that error message.

It would be rather disgusting to suggest that you could also
die { "README" => "Contents\n" } to return a directory, so I won't  :-)

Now... This isn't actually the whole story. An "ls" command will also
"read" your "file", because it needs to know the length. To avoid
calling your routines TOO often, the result will be cached on the
first C<getdir()> type operation, and then returned when you REALLY
read it. The cache will then be cleared so, for example:

  ls /mnt/             # mysub("");
  ls /mnt/magic        # return cached copy
  ls -Fal /mnt/magic   # return cached copy
  cat /mnt/magic       # return cached copy, but clear cache
  cat /mnt/magic       # mysub("");          and clear cache
  ls /mnt/magic        # mysub("");
  ls /mnt/magic        # return cached copy
  echo foo >/mnt/magic # mysub("foo",0);
  ls /mnt/magic        # mysub("");
  ls /mnt/magic        # return cached copy

=head1 EXAMPLES

  see L</SYNOPSIS>

=head1 NOTES

Most things apart from coderefs can't be written, and nothing can be
renamed, chown()ed, deleted, etc. This is not considered a bug, but I
reserve the right to add something clever in a later release :-)

=head1 BUGS

accessor() is a bit thick, doesn't handle seeks, multi-block writes,
etc.

Please report any bugs or feature requests to
E<lt>bug-fuse-simple at rt.cpan.orgE<gt>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Fuse-Simple>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Fuse::Simple

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Fuse-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Fuse-Simple>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Fuse-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Fuse-Simple>

=back

=head1 ACKNOWLEDGEMENTS

Many thanks to:
Mark Glines, for the Fuse Perl module upon which this is based.
Dobrica Pavlinusic, for maintaining it.
Miklos Szeredi et al for the underlying FUSE itself.

=head1 SEE ALSO

L<Fuse>, by Mark Glines, E<lt>mark@glines.orgE<gt>

The FUSE documentation at L<http://fuse.sourceforge.net/>

L<http://noseynick.org/>

=head1 AUTHOR

"Nosey" Nick Waterman of Nilex
E<lt>perl@noseynick.orgE<gt>
L<http://noseynick.org/>

=head1 COPYRIGHT AND LICENSE

(C) Copyright 2006 "Nosey" Nick Waterman of Nilex.
All wrongs righted. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file
included with this module.

=cut
