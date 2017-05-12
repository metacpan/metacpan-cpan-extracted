package Mail::TieFolder;

require 5.005_62;
use strict;
use warnings;
use vars qw(@ISA);

require Exporter;
use AutoLoader qw(AUTOLOAD);

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mail::TieFolder ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.03';


=head1 NAME

Mail::TieFolder - Tied hash interface for mail folders 

=head1 SYNOPSIS

  use Mail::TieFolder;

  # assuming inbox is an MH folder, and the 
  # Mail::TieFolder::mh module is installed:
  tie (%inbox, 'Mail::TieFolder', 'mh', 'inbox');

  # get list of all message IDs in folder
  @messageIDs = keys (%inbox);

  # fetch message (as Mail::Internet object) by ID 
  $msg = $inbox{'9287342.2138749@foo.com'};

=head1 DESCRIPTION

Mail::TieFolder implements a tied hash interface for manipulating
folder contents.  Messages in the hash are accessed by Message-Id.

See the Mail::TieFolder::* modules on CPAN for supported folder
formats.  If the format you're looking for isn't supported, please
feel free to implement your own module and upload it to CPAN as
Mail::TieFolder::yourformat.  New formats are by design relatively
easy to implement -- see L<"IMPLEMENTING A NEW MAILBOX FORMAT"> for
guidelines.

=head1 COMPARISON WITH OTHER MODULES

As with all things in Perl, There Is More Than One Way To Do It.

Mail::TieFolder and the Mail::TieFolder::* modules provide a
lightweight API for manipulating the contents of mail folders in
various formats.  These modules only put, fetch, create, delete, or
refile messages in folders, using Message-ID as the message handle.
They don't pretend to know anything about the internal formatting of
the messages themselves (leaving that to Mail::Internet), they don't
do indexing, searches, address books, or other MUA stuff, nor do they
pretend to provide any overall management of your folders.  They
can, however, be used to move or copy messages between folders, and
will create a new folder if you name a non-existent folder in the
tie(). 

The Mail::Folder, Mail::Box, and Mail::MsgStore modules also provide
for managing folders and their contents.  Those modules generally have
more of a concept of managing your whole mail world of multiple
folders, including address books, folder searches, indexes, and
other MUA tools.  I didn't need this, and the additional overhead
was prohibitive.  The additional capabilities of those modules also
mean that implementing modules to support new folder formats is a
more complex undertaking.  

I went with a tie() interface for Mail::TieFolder because it
constrained the API to a reasonably small and well-defined set of
functions.  This lowers the bar of entry for other authors who want to
add Mail::TieFolder::* modules to support additional folder formats.

Both Mail::Folder and the Mail::Box::Tie modules use message sequence
numbers as the primary key into a folder.  Message sequence numbers
are not fixed attributes uniquely attached to one and only one
message, and can change as a folder is resorted and packed, and as
messages are moved between folders.  

For Mail::TieFolder, I instead used Message-ID as the key into a mail
folder, since it's theoretically a globally unique identifier.  This
way you can sort, renumber, pack, and so on, and still have safe,
immutable, persistent handles on individual messages.  

(Note that Mail::Box does support a messageID() method, and if you
were so inclined, you could use Mail::Box as the backend for a
Mail::TieFolder::* module, provided that the correct Mail::Box::*
module exists to support your desired folder format.  This would be
putting a lightweight and constrained interface on the front of a much
more capable and heavyweight engine, but might meet your needs.)

=head1 IMPLEMENTING A NEW MAILBOX FORMAT

Mail::TieFolder::* modules to support additional mailbox formats are
easy to implement; you only need to support the API functions for a
tied hash (TIEHASH, FETCH, FIRSTKEY, NEXTKEY, EXISTS, STORE, and
DELETE).  See the Perl Cookbook, L<perltie> or the Mail::TieFolder::mh
module code for examples.  I'd suggest using 'h2xs -Xn` to create a
template for your module.

To ensure compatibility with other Mail::TieFolder::* modules, make a
./t directory under the distribution tree for your new module, then
copy the test scripts and other data files from the ./t directory of
the Mail::TieFolder::mh distribution into the ./t directory of your
own module's tree, and edit them accordingly to get rid of the
mh-specific stuff and add any setup which your mailbox format needs.

These test scripts will exercise your new module via the
Mail::TieFolder module to make sure they are talking to each other
correctly. 

Make sure when you edit the test scripts that you change the folder
format in the tie() calls.  You'll also want to delete the dummy
./test.pl script which h2xs generated and then re-run 'perl
Makefile.PL' to generate a Makefile which recognizes the ./t
subdirectory.

If you run into "can't find subroutine" problems, you may not be
doing the inheritance right -- careful, Mail::TieFolder ISA
Mail::TieFolder::yourformat, not the other way around.  See the
TIEHASH functions in Mail::TieFolder and Mail::TieFolder::mh -- note
in particular the @ISA stuff in Mail::TieFolder and the ref() calls in
the Mail::TieFolder::mh bless().  Also make sure you've removed the
'our @ISA' line in your new h2xs generated code -- it masks the @ISA
in Mail::TieFolder.

When you're happy with your module, you'll want to upload it to CPAN
-- see ftp://cpan.org/pub/CPAN/modules/04pause.html.

=cut

sub TIEHASH
{
  my $class = shift;
  my $format = shift;
  my @args = @_;

  my $self={};
  bless $self, $class;

  my $module = $class . "::$format";
  eval "use $module";
  push @ISA, $module;

  return $self->SUPER::TIEHASH(@args);
}

sub supported
{
  my $class = ref(shift) if ref($_[0]);
  $class = "Mail::TieFolder" unless $class;
  my $relpath = $class;
  $relpath =~ s/::/\//g;
  my $format = shift;

  if ($format)
  {
    # is it supported?
    my $module = $class . "::$format";
    return eval "require $module";
  }
  else
  {
    # find all supported
    my @supported;
    for (@INC)
    {
      my $dir="$_/$relpath";
      opendir(DIR,$dir);
      for(readdir(DIR))
      {
	next unless /^(\w+).pm$/;
	push @supported, $1;
      }
    }
    return @supported;
  }
}

=head1 AUTHOR

Steve Traugott, stevegt@TerraLuna.Org

=head1 SEE ALSO

L<perltie>, 
L<Mail::TieFolder::mh>,
L<Mail::Folder>,
L<Mail::MsgStore>,
L<Mail::Box>

=cut

1;
__END__

