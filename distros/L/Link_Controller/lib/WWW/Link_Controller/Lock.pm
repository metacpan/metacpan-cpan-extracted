

=head1 NAME

WWW::Link_Controller::Lock - application locks on link database.

=head1 DESCRIPTION

This provides a very simple lock on the link database used for
stopping multiple processes which write to the database starting at
the same time.

We don't care about any of the other databases (e.g. schedule) 'cos
they ain't that critical and can be easily reconstructed if needed...
Hmm.

This should be replaced with something which works properly, probably
based on transactions as implemented in postgress (all read only
queries allways get an immediate answer, although it may be about a
time in the past).

=head1 IMPLEMENTATION

We create a symbolic link related to the name of the database file
with our process data in the target.

When the program ends we remove the lock automatically..

When we start up and the lock exists we tell the user the name of the
lock and ask them to remove it.

When asked to verify the lock, we check that the process data matches
our data.

=head1 ADVANTAGES

=over 4

=item *

Easy for people to understand the locks

=item *

Should work over NFS etc..

=item *

Reasonably safe

=back

=head1 FUNCTIONS

=cut

package WWW::Link_Controller::Lock;
$REVISION=q$Revision: 1.7 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );
use warnings;
use strict;
use English;
use vars qw($lock_file $link_data $localhost $lock_owner);
use Sys::Hostname;
use Cwd;

$lock_file=undef;
$lock_owner=0;
$link_data=undef;
$localhost=hostname;

$WWW::Link_Controller::Lock::silent = 0 unless defined
  $WWW::Link_Controller::Lock::silent;

=head2 WWW::Link_Controller::Lock::lock($linkfile)

Creates our lock_file (actually a symlink); dies if it can't.

=cut

sub lock ($) {
    my $name=shift;
    die "we can only do one lock" if defined $lock_file;
    my ($path,$file)=$name =~ m,((?:.*/)?)([^/]+),;

    $lock_file=$path . '#' . $file . '.lock';
    -e $lock_file and do {
	not -l $lock_file and
	    die "The lock file $lock_file exists and isn't a symbolic link!";
	my $existing_link_data=readlink $lock_file;
	die "lock_file $lock_file exists: seems to be simlink to "
	    . "$existing_link_data" ;
    };

    -l $lock_file and do {
	my $existing_link_data=readlink $lock_file;
	die "lock_file $lock_file exists: held by $existing_link_data;" .
	    " remove if stale";
    };

    $link_data=$PROCESS_ID . '@' . $localhost;
    print STDERR "W::L::Lock creating lock file $lock_file -> $link_data\n"
      unless $WWW::Link_Controller::Lock::silent;
    symlink $link_data, $lock_file
	or die "failed to create lock_file $lock_file";
    $lock_owner=1;
}


=head2 WWW::Link_Controller::Lock::checklock()

Checks that we still hold the lock we originally created.  Used to
minimise the chance of problems when the lock is broken by someone
careless.

Use this on long running programs just before writing to the
database.

=cut

sub checklock () {
    die "lock_file undefined; perhaps you didn't lock" unless $lock_file;
    die "linkdata undefined; error in Lock.pm" unless $link_data;
#    die "lock file $lock_file doesn't exist in " . cwd unless -e $lock_file;
    die "lock isn't a symlink" unless -l $lock_file;
    die "lock has been stolen" unless readlink $lock_file eq $link_data;
    print STDERR "WWW::Link_Controller::Lock: checked lock file $lock_file\n"
      unless $WWW::Link_Controller::Lock::silent;
    return 1;
}


sub END {

  #FIXME: this doesn't get called after signals, but it probably should

    return unless $lock_owner;
    do { warn "linkdata undefined; error in Lock.pm" ; $?=1 unless $?; return}
	unless $link_data;
    do { warn "lock isn't a symlink" ; $?=1 unless $?; return}
	unless -l $lock_file;
    do { warn "lock has been stolen" ; $?=1 unless $?; return}
	unless readlink $lock_file eq $link_data;
    print STDERR "W::L::Lock deleting lock file $lock_file  -> $link_data\n"
      unless $WWW::Link_Controller::Lock::silent;
    unlink $lock_file or warn "failed to delete lock file $lock_file"
	      if  $lock_owner
}

1;
