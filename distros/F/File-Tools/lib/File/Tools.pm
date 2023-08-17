package File::Tools;
use strict;
use warnings;

use base 'Exporter';
my @all = qw(
      basename
      catfile
      compare
      copy
      cwd
      date
      dirname
      fileparse
      find
      mkpath
      move
      popd
      pushd
      rm
      rmtree
      uniq
      );

our @EXPORT_OK = @all;
our %EXPORT_TAGS = (
    all => \@all,
);

our $VERSION = '0.10';

my @DIRS; # used to implement pushd/popd

sub _not_implemented {
  die "Not implemented\n";
}
=head1 NAME

File::Tools - UNIX tools implemented as Perl Modules and made available to other platforms as well

=head1 SYNOPSIS

use File::Tools qw(:all);

my $str = cut {bytes => "3-7"}, "123456789";

=head1 WARNING

This is Alpha version of the module.
Interface of the functions will change and some of the functions might even disappear.

=head1 REASON

Why this module?

=over 4

=item *

When I am writing filesystem related applications I always need to load several
standard modules such as File::Basename, Cwd, File::Copy, File::Path and maybe
others in order to have all the relevant functions.
I'd rather just use one module that will bring all the necessary functions.

=item *

On the other hand when I am in OOP mood I want all these functions to be methods of
a shell-programming-object. (Though probably L<Pipe> will answer this need better)

=item *

There are many useful commands available for the Unix Shell Programmer that usually need
much more coding than the Unix counterpart, specifically most of the Unix commands can work
recoursively on directory structures while in Perl one has to implement these.
There are some additional modules providing this functionality but then we get back again to
the previous issue.

=back

The goal of this module is to make it even easier to write scripts in Perl that
were traditionally easier to write in Shell.

Partially we will provide functions similar to existing UNIX commands
and partially we will provide explanation on how to rewrite various Shell
constructs in Perl.

=head1 DESCRIPTION

=cut

#=head2 awk
#
#Not implemented.
#
#=cut
#sub awk {
#  _not_implemented();
#}


=head2 basename

Given a path to a file or directory returns the last part of the path.

See L<File::Basename> for details.

=cut
sub basename {
  require File::Basename;
  File::Basename::basename(@_);
}

=head2 cat

Not implemented.

See L<slurp>

To process all the files on the command line and print them to the screen.

 while (my $line = <>) {
   print $line;
 }

In shell cut is usually used to concatenate two or more files. That can be achived
with the previous code redirecting it to a file using > command line redirector.

=cut
sub cat {
  _not_implemented();
}


=head2 catfile

Concatenating parts of a path in a platform independent way. See also L<File::Spec>

=cut
sub catfile {
  require File::Spec;
  File::Spec->catfile(@_);
}



=head2 cd

Use the built in chdir function.

=cut




=head2 chmod

Use the built in chmod function.

=cut



=head2 chown

For now use the built in chown function.

It accepts only UID and GID values, but it is easy to retreive them:

 chown $uid, $gid, @files;
 chown getpwnam($user), getgrname($group), @files;

For recursive application use the L<find> function.

 find( sub {chown $uid, $gid, $_}, @dirs);

Windows: See chmod above.

=cut


=head2 cmp

See C<compare>

=head2 compare

Compare two files
See L<File::Compare> for details.

=cut
sub compare {
    require File::Compare;
    File::Compare::compare(@_);
}


=head2 compress

Not implemented.

See some of the external modules

=cut




=head2 copy

Copy one file to another name.

For details see L<File::Copy>

For now this does not provide recourseive copy. Later we will provide that
too using either one of these modules: L<File::NCopy> or L<File::Copy::Recursive>.

=cut
sub copy {
  require File::Copy;
  File::Copy::copy(@_);
}


=head2 cut

Partially implemented but probably will be removed.

Returns some of the fields of a given string (or strings).
As a UNIX command it can work on every line on STDIN or in a list of files.
When implementing it in Perl the most difficult part is to parse the parameters
in order to account for all the overlapping possibilities which should actually
be considered as user error.

  cut -b 1 file
  cut -b 3,7 file
  cut -b 3-7 file
  cut -b -4,7-
  order within the parameter string does not matter

The same can be done in Perl for any single range:
  substr $str, $start, $length;

=cut
sub cut {
# --bytes
# --characters
# --fields
# --delimiter (in case --fields was used, defaults to TAB)
  my ($args, $str) = @_;
  if ($args->{bytes}) {
    my $chars;
    my @ranges = split /,/, $args->{bytes};
    my %chars;
    foreach my $range (@ranges) {
      if ($range =~ /^-/) {
        $range = "1$range";
      } elsif ($range =~ /-$/) {
        $range = $range . length($str)-1;
      }
      if ($range =~ /-/) {
        my ($start, $end) = split /-/, $range;
        $chars{$_}=1 for $start..$end;
      } else {
        $chars{$range} = 1;
      }
    }
    my $ret = "";
    foreach my $c (sort {$a <=> $b} keys %chars) {
      $ret .= substr($str, $c-1, 1);
    }
    return $ret;
  }

  return;
}

=head2 cp

See L<copy> instead.

=cut


=head2 cwd

Returns the current working directory similar to the pwd UNIX command.

See L<Cwd> for details.

=cut
sub cwd {
  require Cwd;
  Cwd::cwd();
}

=head2 date

Can be used to display time in the same formats the date command would do.

See POSIX::strftime for details.

=cut
sub date {
  require POSIX;
  POSIX::strftime(@_);
}

=head2 df

Not implemented.

See L<Filesys::DiskSpace>

=cut
sub df {
  _not_implemented();
}

=head2 diff

Not implemented.

See L<Text::Diff> for a possible implementation.

=cut
sub diff {
  _not_implemented();
}

=head2 dirname

Given a path to a file or a directory this function returns the directory part.
(the whole string excpet the last part)

See L<File::Basename> for details.

=cut
sub dirname {
  require File::Basename;
  File::Basename::dirname(@_);
}

=head2 dirs

Not implemented.

=cut



=head2 dos2unix

Not implemented.

=cut



=head2 du

Not implemented.

L<Filesys::DiskUsage>

=cut


=head2 echo

Not implemented.

The print function in Perl prints to the screen (STDOUT or STDERR).

If the given string is in double quotes "" the backslash-escaped characters take effect (-e mode).

Within single quotes '', they don't have an effect.

For printing new-line include \n withn the double quotes.

=cut



=head2 ed - editor

Not implemented.

=cut



=head2 expr

Not implemented.

In Perl there is no need to use a special function to evaluate an expression.

=over 4

=item *

match

=item *

substr - built in substr

=item *

index - built in index

=item *

length - built in length

=back

=cut



=head2 file

Not implemented.

=cut



=head2 fileparse

This is not a UNIX command but it is provided by the same standard L<File::Basename>
we already use.

=cut
sub fileparse {
  require File::Basename;
  File::Basename::fileparse(@_);
}



=head2 find

See L<File::Find> for details.

See also find2perl

TODO: Probably will be replaced by L<File::Find::Rule>

=cut
sub find {
  require File::Find;
  File::Find::find(@_);
}


=head2 ftp

See L<Net::FTP>

=cut

=head2 move

Move a file from one directory to any other directory with any name.

One can use the built in rename function but it only works on the same filesystem.

See L<File::Copy> for details.

=cut
sub move {
  require File::Copy;
  File::Copy::move(@_);
}



=head2 getopts

Not implemented.

See L<Getops::Std> and L<Getops::Long> for possible implementations we will use here.

=cut




=head2 grep

Not implemented.

A basic implementation of grep in Perl would be the following code:

 my $p = shift;
 while (<>) {
   print if /$p/
 }

but within real code we are going to be more interested doing such operation
on a list of values (possibly file lines) already in memory in an array or
piped in from an external file. For this one can use the grep build in function.

 @selected = grep { $_ =~ /REGEX/ } @original;

TODO: See also L<File::Grep>

=cut



=head2 gzip


Not implemented.

=cut



=head2 head

Not implemented.

=cut


=head2 id

Normally the id command shows the current username, userid, group and gid.
In Perl one can access the current ireal UID as $<  and the effective UID as $>.
The real GID is $(  and the effective GID is $) of the current user.

To get the username and the group name use the getpwuid($uid) and getpwgrid($gid)
functions respectively in scalar context.


=cut


=head2 kill

See built in kill function.

=cut



=head2 less

Not implemented.

This is used in interactive mode only. No need to provide this functionality here.

=cut


=head2 ln

Not implemented.

See the build in L<link> and L<symlink> functions.

=cut


=head2 ls

Not implemented.

See glob and the opendir/readdir pair for listing filenames
use stat and lstat to retreive information needed for the -l
display mode of ls.

=cut



=head2 mail

Sending e-mails.

See L<Mail::Sendmail> and L<Net::SMTP>

=cut


=head2 mkdir

Not implemented.

See the built in mkdir function.

See also L</mkpath>

=cut


=head2 mkpath

Create a directory with all its parent directories.
See L<File::Path> for details.

=cut
sub mkpath {
  require File::Path;
  File::Path::mkpath(@_);
}



=head2 more

Not implemented.

This is used in interactive mode only. No need to provide this functionality here.

=cut


=head2 mv

See L<move> instead.

=cut


=head2 paste

Not implemented.

=cut


=head2 patch

Not implemented.

=cut

=head2 ping

See L<Net::Ping>

=cut

=head2 popd

Change directory to last place where pushd was called.

=cut
sub popd {
  my $dir = pop @DIRS;
  if (chdir $dir) {
    return cwd();
  } else {
    return;
  }
}

=head2 pushd

Change directory and save the current directory in a stack. See also L<popd>.

=cut
sub pushd {
  my ($dir) = @_;
  push @DIRS, cwd;
  if (chdir $dir) {
    return cwd();
  } else {
    return;
  }
}

=head2 printf

Not implemented.

See the build in L<printf> function.

=cut


=head2 ps

Not implemented.

=cut



=head2 pwd

See L<cwd> instead.

=cut


=head2 read

Not implemented.

 read x y z

will read in a line from the keyboard (STDIN) and put the first word into x,
the second word in y and the third word in z

In perl one can implement similar behavior by the following code:

 my ($x, $y, $z) = split /\s+/, <STDIN>;

=cut



=head2 rm

Not implemented.

For removing files, see the built in L<unlink> function.

For removing directories see the built in L<rmdir> function.

For removing trees (rm -r) see L<rmtree>

See also L<File::Remove>

=cut
sub rm {
  _not_implemented();
}





=head2 rmdir

Not implemented.

For removing empty directories use the built in rmdir function.

For removing tree see L<rmtree>

=cut




=head2 rmtree

Removes a whole directory tree. Similar to rm -rf.
See also L<File::Path>

=cut
sub rmtree {
  require File::Path;
  File::Path::rmtree(@_);
}


=head2 scp

See also L<Net::SCP>

=cut



#=head2 sed
#
#Not implemented.
#
#=cut
#sub sed {
#  _not_implemented();
#}


=head2 slurp

=cut
sub slurp {
  my $content = "";
  foreach my $filename (@_) {
    if (open my $fh, "<", $filename) {
      local $/ = undef;
      $content .= <$fh>;
    } else {
      warn "Could not open '$filename'\n";
    }
  }
  return $content;
}


=head2 snmp

L<Net::SNMP>

=cut


=head2 ssh

L<Net::SSH>

=cut


=head2 shift

Not implemented.

=cut



=head2 sort

Not implemented.

See the built in sort function.

=cut




=head2 tail

Not implemented.

Return the last n lines of a file, n defaults to 10

=cut
sub tail {
  _not_implemented();
}


=head2 tar

Not implemented.

See L<Archive::Tar>

=cut

=head2 telnet

L<Net::Telnet>

=cut


=head2 time

See also L<Benchmark>

=cut


=head2 touch

Not implemented.

=head2 tr

Not implemented.

See the built in L<tr> function.


=head2 umask

Not implemented.

=cut


=head2 uniq

The uniq unix command eliminates duplicate values following each other 
but does not enforce uniqueness through the whole input.
For examle for the following list of input values:  a a a b a a a    
ths UNIX uniq would return                          a b a

For completeness we also provide uniqunix that behaves just like the UNIX command.

See also L<Array::Unique>

=cut
sub uniq {
  my (@uniq, %seen);
  for (@_) {
    push @uniq, $_ if not $seen{$_}++;
  }
  return @uniq;
}

=head2 uniqunix

Similar to the UNIX uniq command.

=cut
sub uniqunix {
  my (@uniq, $last);
  for (@_) {
    next if defined $last and $last eq $_;
    $last = $_;
    push @uniq, $last;
  }
  return @uniq;
}


=head2 unix2dos

Not implemented.

=head2 wc

Not implemented.

=head2 who

Not implemented.

=head2 who am i

Not implemented.

=head2 zip

Not implemented.


=head2 redirections and pipe

<
>
<
|

Ctr-Z, & fg, bg
set %ENV

=head2 Arguments

$#, $*, $1, $2, ...

$$ - is also available in Perl as $$

=head2 Other

$? error code of last command

if test ...
string operators

=head1 TODO

File::Basename::fileparse_set_fstype
File::Compare::compare_text
File::Compare::cmp
File::Copy::syscopy
File::Find
File::Spec
File::Temp

=head1 AUTHOR

Gabor Szabo <gabor@szabgab.com>

=head1 Copyright

Copyright 2006-2012 by Gabor Szabo <gabor@szabgab.com>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=head1 SEE ALSO

Tim Maher has a book called Miniperl http://books.perl.org/book/240 that might be very useful.
I have not seen it yet, but according to what I know about it it should be a good one.

L<http://perllinux.sourceforge.net/>

The UNIX Reconstruction Project, L<http://search.cpan.org/dist/ppt/>

L<http://perl5maven.com/the-most-important-file-system-tools>


L<Pipe>

Related Discussions:

L<http://www.perlmonks.org/?node_id=541826>

=cut

1;
