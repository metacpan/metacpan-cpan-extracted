package FileHandle::Fmode;
use Fcntl qw(O_ACCMODE O_RDONLY O_WRONLY O_RDWR O_APPEND F_GETFL);
use strict;

require Exporter;
require DynaLoader;

*is_FH = \&is_arg_ok;

our $VERSION = '0.14';
#$VERSION = eval $VERSION;

@FileHandle::Fmode::ISA = qw(Exporter DynaLoader);

@FileHandle::Fmode::EXPORT_OK = qw(is_R is_W is_RO is_WO is_RW is_arg_ok is_A is_FH);

%FileHandle::Fmode::EXPORT_TAGS = (all => [qw
    (is_R is_W is_RO is_WO is_RW is_arg_ok is_A is_FH)]);

bootstrap FileHandle::Fmode $VERSION;

my $is_win32 = $^O =~ /mswin32/i ? 1 : 0;

sub is_arg_ok {
    my $fileno = eval{fileno($_[0])};
    if($@) {return 0}
    if(defined($fileno)) {
      if($fileno == -1) {
        if($] < 5.007) {return 0}
        return 1;
      }
      return 1;
    }
    return 0;
}

sub is_RO {
    my $fileno = fileno($_[0]);
    if(!defined( $fileno)) {die "Not an open filehandle"}
    if( $fileno == -1) {
      if($] < 5.007) {die "Illegal fileno() return"}
      if(perliol_readable($_[0]) && !perliol_writable($_[0])) {return 1}
      return 0;
    }
    if($is_win32) {
      if(win32_fmode($_[0]) & 1) {return 1}
      return 0;
    }
    my $fmode = fcntl($_[0], F_GETFL, my $slush = 0);
    if(defined($fmode) && ($fmode & O_ACCMODE) == O_RDONLY) {return 1}
    return 0;
}

sub is_WO {
    my $fileno = fileno($_[0]);
    if(!defined( $fileno)) {die "Not an open filehandle"}
    if( $fileno == -1) {
      if($] < 5.007) {die "Illegal fileno() return"}
      if(!perliol_readable($_[0]) && perliol_writable($_[0])) {return 1}
      return 0;
    }
    if($is_win32) {
      if(win32_fmode($_[0]) & 2) {return 1}
      return 0;
    }
    my $fmode = fcntl($_[0], F_GETFL, my $slush = 0);
    if(defined($fmode) && ($fmode & O_ACCMODE) == O_WRONLY) {return 1}
    return 0;
}

sub is_W {
    if(is_WO($_[0]) || is_RW($_[0])) {return 1}
    return 0;
}

sub is_R {
    if(is_RO($_[0]) || is_RW($_[0])) {return 1}
    return 0;
}

sub is_RW {
    my $fileno = fileno($_[0]);
    if(!defined( $fileno)) {die "Not an open filehandle"}
    if( $fileno == -1) {
      if($] < 5.007) {die "Illegal fileno() return"}
      if(perliol_readable($_[0]) && perliol_writable($_[0])) {return 1}
      return 0;
    }
    if($is_win32) {
      if(win32_fmode($_[0]) & 128) {return 1}
      return 0;
    }
    my $fmode = fcntl($_[0], F_GETFL, my $slush = 0);
    if(defined($fmode) && ($fmode & O_ACCMODE) == O_RDWR) {return 1}
    return 0;
}

sub is_A {
    my $fileno = fileno($_[0]);
    if(!defined( $fileno)) {die "Not an open filehandle"}
    if( $fileno == -1) {
      if($] < 5.007) {die "Illegal fileno() return"}
      return is_appendable($_[0]);
    }
    if($is_win32) {
      if($] < 5.006001) {die "is_A not currently implemented on Win32 for pre-5.6.1 perl"}
      return is_appendable($_[0]);
    }
    my $fmode = fcntl($_[0], F_GETFL, my $slush = 0);
    if($fmode & O_APPEND) {return 1}
    return 0;
}

1;

__END__

=head1 NAME


FileHandle::Fmode - determine whether a filehandle is opened for reading, writing, or both.

=head1 SYNOPSIS


 use FileHandle::Fmode qw(:all);
 .
 .
 #$fh and FH are open filehandles
 print is_R($fh), "\n";
 print is_W(\*FH), "\n";

=head1 FUNCTIONS

 $bool = is_FH($fh);
 $bool = is_FH(\*FH);
  This is just a (more intuitively named) alias for is_arg_ok().
  Returns 1 if its argument is an open filehandle.
  Returns 0 if its argument is something other than an open filehandle.

 $bool = is_arg_ok($fh);
 $bool = is_arg_ok(\*FH);
  Returns 1 if its argument is an open filehandle.
  Returns 0 if its argument is something other than an open filehandle.

 Arguments to the following functions  must be open filehandles. If
 any of those functions receive an argument that is not an open
 filehandle then the function dies with an appropriate error message.
 To ensure that your script won't suffer such a death, you could first
 check by passing the argument to is_FH(). Or you could wrap the
 function call in an eval{} block.

 Note that it may be possible that a filehandle opened for writing may
 become unwritable - if (eg) the disk becomes full. I don't know how
 the below functions would be affected by such an event. I suspect
 that they would be unaware of the change ... but I haven't actually
 checked.

 $bool = is_R($fh);
 $bool = is_R(\*FH);
  Returns true if the filehandle is readable.
  Else returns false.

 $bool = is_W($fh);
 $bool = is_W(\*FH);
  Returns true if the filehandle is writable.
  Else returns false

 $bool = is_RO($fh);
 $bool = is_RO(\*FH);
  Returns true if the filehandle is readable but not writable.
  Else returns false

 $bool = is_WO($fh);
 $bool = is_WO(\*FH);
  Returns true if the filehandle is writable but not readable.
  Else returns false

 $bool = is_RW($fh);
 $bool = is_RW(\*FH);
  Returns true if the filehandle is both readable and writable.
  Else returns false

 $bool = is_A($fh);
 $bool = is_A(\*FH);

  Returns true if the filehandle was opened for appending.
  Else returns false.
  Not currently implemented on Win32 with pre-5.6.1 versions of perl (and
  dies with appropriate error message if called on such a platform).


=head1 CREDITS


 Inspired (hmmm ... is that the right word ?) by an idea from BrowserUK
 posted on PerlMonks in response to a question from dragonchild. Win32
 code (including XS code) provided by BrowserUK. Zaxo presented the idea
 of using fcntl() in an earlier PerlMonks thread.

 Thanks to dragonchild and BrowserUK for steering this module in
 the right direction.

 Thanks to attn.steven.kuo for directing me to the perliol routines
 that enable us to query filehandles attached to memory objects.

 And thanks to Jost Krieger for helping to sort out the test failures that
 were occurring on Solaris (and some other operating systems too).


=head1 TODO

 I don't know that anyone still runs pre-5.6.1 perl on Win32. However, if
 someone likes to tell me how is_A() could be made to work on pre-5.6.1
 Win32 perl, I would be quite happy to implement it.


=head1 LICENSE


 This program is free software; you may redistribute it and/or
 modify it under the same terms as Perl itself.
 Copyright 2006-2008, 2009, 2010, 2012 Sisyphus

=head1 AUTHOR


 Sisyphus <sisyphus at cpan dot org>

=cut
