
# $Id: Find.pm,v 1.14 2014-10-15 11:04:49 Martin Exp $

package Devel::Todo::Find;

=head1 NAME

Devel::Todo::Find - Search source code files for TODO comments

=head1 SYNOPSIS

  use Devel::Todo::Find;
  my $o = new Devel::Todo::Find;
  my @a = $o->todos;

=head1 DESCRIPTION

This class helps you search your file system recursively,
looking for files containing what looks like a Perl comment
expressing a TODO item.
This is an example of the format it looks for:

  # TODO: this is an example

You can tell it where to look (using the add_dirs method)
and
you can tell it folders to ignore (using the ignore_dirs method).
By default, it looks in the current working directory,
and
by default, it skips
folders in a Perl module development environment that a module author
typically wants to skip (such as CVS and blib),
as well as Emacs backup files (that end with tilde),
CM hidden folders (.git and .subversion), and
tar files (.tar).
Then you can get the list of TODO items by calling the todos method.

=head1 FUNCTIONS

=cut

use Data::Dumper;
use File::Find;

our
$VERSION = 1.205;

=head2 Constructor

=head3 new

Creates a new object and returns it.  Takes no arguments.

=cut

sub new
  {
  my $class = shift;
  my %hash;
  $hash{_dirs_} = [];
  $hash{_ignore_} = [];
  my $self = bless \%hash, $class;
  return $self;
  } # new

=head2 Methods

=over

=item add_dirs

Takes any number of arguments, either files or folders that will be
searched during the todos() process.

If you do not call this method to add any items,
only the Cwd will be processed by default.
(But, see ignore_dirs() below.)

=cut

sub add_dirs
  {
  my $self = shift;
  push @{$self->{_dirs_}}, @_;
  } # add_dirs


=item add_files

This is just a synonym for add_dirs() just above.

=cut

sub add_files
  {
  shift->add_dirs(@_);
  } # add_files


=item ignore_dirs

Takes any number of arguments, each argument is used as a regex such
that any file or folder matching any of the regexen will NOT be
searched during the todos() process.

If you do not call this method to ignore any items,
by default the following items will be ignored:

 qr{~\Z}i
 qr{blib}
 qr{CVS}i
 qr{\A\.git\Z}i,
 qr{\Ainc/}
 qr{\.subversion}i,
 qr{\.tar\Z}i,
 qr{\.yaml\Z}i

=cut

sub ignore_dirs
  {
  my $self = shift;
  push @{$self->{_ignore_}}, @_;
  } # ignore_dirs


=item ignore_files

This is a synonym for ignore_dirs() just above.

=cut

sub ignore_files
  {
  shift->ignore_dirs(@_);
  } # ignore_files


=item todos

In scalar mode, returns a human-readable string of all TODO items found.
In array mode, returns a list of Emacs-readable strings of TODO items.
Apologies if my concept of "human-readable" is different from yours.

=cut

sub todos
  {
  my $self = shift;
  $self->_gather_todos;
  my $sRet = q{};
  my @as;
  while (my ($sFname, $ra) = each %{$self->{_todo_}})
    {
    foreach my $rh (@$ra)
      {
      $sRet .= sprintf(qq{file=%s, line=%d, %s: %s\n},
                       $rh->{file}, $rh->{line}, $rh->{type}, $rh->{what});
      push @as, sprintf(qq{%s:%d:%s\n}, $rh->{file}, $rh->{line}, $rh->{what});
      } # foreach
    } # while
  return wantarray ? @as : $sRet;
  } # todos

# Private method which does the "heavy-lifting" of file-finding:

sub _gather_todos
  {
  my $self = shift;
  # Clear 'em out and start over:
  delete $self->{_todo_};
  my @asItem = @{$self->{_dirs_}};
  my @aIgnore = @{$self->{_ignore_}};
  # By default, (if user doesn't tell us otherwise), we will process
  # Cwd (and recursively all subdirectories):
  if (! @asItem)
    {
    push @asItem, q{.};
    } # if
  # By default, (if user doesn't tell us otherwise), we will ignore
  # items that a Perl module-author would want to ignore:
  if (! @aIgnore)
    {
    @aIgnore =(
               qr{blib},
               qr{CVS}i,
               qr{\Ainc/},
               qr{\.yaml\Z}i,
               qr{\A\.git\Z}i,
               qr{\.subversion}i,
               qr{\.tar\Z}i,
               qr{~\Z}i,
              );
    } # if
  # print STDERR qq{ DDD in _gather_todos, asItem is }, Dumper(\@asItem);
  find({
        no_chdir => 1,
        wanted => sub { $self->_wanted(\@aIgnore) },
       }, @asItem);
  } # todos


# Private method which is the "wanted" callback of File::Find

sub _wanted
  {
  my $self = shift;
  my $raIgnore = shift || [];
  my $sFname = $File::Find::name;
  foreach my $qr (@$raIgnore)
    {
    # print STDERR " DDD   compare =$sFname= to ignore pattern =$qr=\n";
    if ($sFname =~ m/$qr/)
      {
      $File::Find::prune = 1;
      return;
      } # if
    } # foreach
  # print STDERR qq{ DDD   in _wanted, F::F::name is $sFname\n};
  if (! -s $sFname)
    {
    # warn qq{ III $sFname is not -s};
    return;
    } # if
  if (! open FFF, q{<}, $sFname)
    {
    warn qq{ EEE cannot open $sFname for read: $!};
    return;
    } # if
  my $iLine = 1;
  while (my $sLine = <FFF>)
    {
    chomp $sLine;
    # print STDERR qq{ DDD     sLine $iLine is $sLine\n};
    if ($sLine =~ m/#\s*(TODO):?\s*(.+?)$/)
      {
      my %h = (
               file => $sFname,
               line => $iLine,
               type => $1,
               what => $2,
              );
      push @{$self->{_todo_}->{$sFname}}, \%h;
      } # if
    $iLine++;
    } # while
  close FFF or warn;
  } # _wanted

1;

__END__

=back

=head1 LICENSE

This software is released under the same license as Perl itself.

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=cut

The end.
