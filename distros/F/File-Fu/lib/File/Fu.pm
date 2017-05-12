package File::Fu;
$VERSION = v0.0.8;

use warnings;
use strict;
use Carp;

=head1 NAME

File::Fu - file and directory objects

=head1 SYNOPSIS

The directory constructor:

  use File::Fu;

  my $dir = File::Fu->dir("bar");
  print "$dir\n"; # 'bar/'

  my $file = $dir + 'bar.txt';
  print "$file\n"; # 'bar/bar.txt'

  my $d2 = $dir % 'baz'; # 'barbaz/'
  my $d3 = $dir / 'bat'; # 'bar/bat/'

  my $file2 = $dir / 'bat' + 'foo.txt'; # 'bar/bat/foo.txt'

The file constructor:

  my $file = File::Fu->file("foo");
  $file->e and warn "$file exists";
  $file->l and warn "$file is a link";
  warn "file is in ", $file->dir;

=head1 ABOUT

This class provides the toplevel interface to File::Fu directory and
file objects, with operator overloading which allows precise path
composition and support for most builtin methods, as well as creation of
temporary files/directories, finding files, and more.

The interface and style are quite different than the perl builtins or
File::Spec.  The syntax is concise.  Errors are thrown with croak(), so
you never need to check a return code.

=cut

use Cwd ();

use File::Fu::File;
use File::Fu::Dir;
use File::Spec ();

use constant dir_class => 'File::Fu::Dir';
use constant file_class => 'File::Fu::File';

=head1 Constructors

The actual objects are in the 'Dir' and 'File' sub-namespaces.

=head2 dir

  my $dir = File::Fu->dir($path);

See L<File::Fu::Dir/new>

=cut

sub dir {
  my $package = shift;

  $package or croak("huh?");
  # also as a function call
  unless($package and $package->isa(__PACKAGE__)) {
    unshift(@_, $package);
    $package = __PACKAGE__;
  }

  $package->dir_class->new(@_);
} # end subroutine dir definition
########################################################################

=head2 file

  my $file = File::Fu->file($path);

See L<File::Fu::File/new>

=cut

sub file {
  my $package = shift;

  # also as a function call
  unless($package->isa(__PACKAGE__)) {
    unshift(@_, $package);
    $package = __PACKAGE__;
  }

  $package->file_class->new(@_);
} # end subroutine file definition
########################################################################

=head1 Class Constants

=head2 tmp

Your system's '/tmp/' directory (or equivalent of that.)

  my $dir = File::Fu->tmp;

=cut

{
my $tmp; # XXX needs locking?
sub tmp {
  my $package = shift;
  $tmp and return($tmp);
  return($tmp = $package->dir(File::Spec->tmpdir));
}}
########################################################################

=head2 home

User's $HOME directory.

  my $dir = File::Fu->home;

=cut

{
my $home; # XXX needs locking!
sub home {
  my $package = shift;
  $home and return($home);
  return($home = $package->dir($ENV{HOME}));
}} # end subroutine home definition
########################################################################

=head2 program_name

The absolute name of your program.  This will be relative from the time
File::Fu was loaded.  It dies if the name is '-e'.

  my $prog = File::Fu->program_name;

If File::Fu was loaded after a chdir and the $0 was relative, calling
program_name() throws an error.  (Unless you set $0 correctly before
requiring File::Fu.)

=head2 program_dir

Returns what typically corresponds to program_name()->dirname, but
just the compile-time cwd() when $0 is -e/-E.

  my $dir = File::Fu->program_dir;

=cut

{
# fun startup stuff and various logic:
my $prog = $0;
my $name_sub;
my $dir_sub;
if(lc($prog) eq '-e') {
  my $prog_dir = Cwd::cwd();
  $dir_sub  = eval(qq(sub {shift->dir("$prog_dir")}));
  $name_sub = eval(qq(sub {croak("program_name => '$prog'")}));
}
else {
  if(-e $prog) {
    my $prog_name = __PACKAGE__->file($prog)->absolutely;
    my $prog_dir = $prog_name->dirname;
    $name_sub = eval(qq(sub {shift->file('$prog_name')}));
    $dir_sub  = eval(qq(sub {shift->dir('$prog_dir')}));
  }
  else {
    # runtime error
    $dir_sub  = sub {croak("$prog not found => no program_dir known")};
    $name_sub = sub {croak("$prog not found => no program_name known")};
  }
}
*program_name = $name_sub;
*program_dir  = $dir_sub;
} # program_name/program_dir
########################################################################

=head1 Class Methods

=head2 THIS_FILE

A nicer way to say __FILE__.

  my $file = File::Fu->THIS_FILE;

=cut

sub THIS_FILE {
  my $package = shift;
  my $name = (caller)[1];
  return $package->file($name);
} # end subroutine THIS_FILE definition
########################################################################

=head2 cwd

The current working directory.

  my $dir = File::Fu->cwd;

=cut

sub cwd {
  my $package = shift;

  defined(my $ans = Cwd::cwd()) or croak("cwd() failed");
  return $package->dir($ans);
} # end subroutine cwd definition
########################################################################

=head2 which

Returns File::Fu::File objects of ordered candidates for $name found in
the path.

  my @prog = File::Fu->which($name) or die "cannot find $name";

If called in scalar context, returns a single File::Fu::File object or throws an error if no candidates were found.

  my $prog = File::Fu->which($name);

=cut

sub which {
  my $package = shift;
  croak("must have an argument") unless(@_);
  my ($what) = @_;

  require File::Which;
  if(wantarray) {
    return map({$package->file($_)} File::Which::which($what));
  }
  else {
    my $found = scalar(File::Which::which($what)) or
      croak("cannot locate '$what' in PATH");
    return $package->file($found);
  }
} # which ##############################################################

=head1 Temporary Directories and Files

These class methods call the corresponding File::Fu::Dir methods on the
value of tmp().  That is, you get a temporary file/dir in the '/tmp/'
directory.

=head2 temp_dir

  my $dir = File::Fu->temp_dir;

=cut

sub temp_dir {
  my $package = shift;
  $package->tmp->temp_dir(@_);
} # end subroutine temp_dir definition
########################################################################

=head2 temp_file

  my $handle = File::Fu->temp_file;

=cut

sub temp_file {
  my $package = shift;
  $package->tmp->temp_file(@_);
} # end subroutine temp_file definition
########################################################################

=head1 Operators

If you choose not to use the overloaded operators, you can just say
C<$obj-E<gt>stringify()> or "$obj" whenever you want to drop the
object-y nature and treat the path as a string.

The operators can be convenient for building-up path names, but you
probably don't want to think of them as "math on filenames", because
they are nothing like that.

The '+' and '/' operators only apply to directory objects.

  op   method                     mnemonic
  --   ----------------           --------------------
  +    $d->file($b) ............. plus (not "add")
  /    $d->subdir($b) ........... slash (not "divide")

The other operators apply to both files and directories.

  op   method                     mnemonic
  --   ----------------           --------------------
  %=   $p->append($b) ........... mod(ify)
  %    $p->clone->append($b)      
  &=   $p->map(sub{...}) ........ invoke subref
  &    $p->clone->map(sub {...})

Aside:  It would be more natural to use C<.=> as append(), but the way
perl compiles C<"$obj foo"> into C<$obj . " foo"> makes it impossible to
do the right thing because the lines between object and string are too
ambiguous.

=head1 Subclassing

You may wish to subclass File:Fu and override the dir_class() and/or
file_class() class methods to point to your own Dir/File subclasses.

  my $class = 'My::FileFu';
  my $dir = $class->dir("foo");

See L<File::Fu::File> and L<File::Fu::Dir> for more info.

=head2 dir_class

  File::Fu->dir_class # File::Fu::Dir

=head2 file_class

  File::Fu->file_class # File::Fu::File

=head1 See Also

L<File::Fu::why> if I need to explain my motivations.

L<Path::Class>, from which many an idea was taken.

L<File::stat>, L<IO::File>, L<File::Spec>, L<File::Find>, L<File::Temp>,
L<File::Path>, L<File::Basename>, L<perlfunc>, L<perlopentut>.

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2008 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
