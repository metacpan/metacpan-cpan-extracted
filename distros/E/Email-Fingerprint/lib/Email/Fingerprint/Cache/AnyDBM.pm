package Email::Fingerprint::Cache::AnyDBM;
use Class::Std;

use warnings;
use strict;

use Fcntl;
use AnyDBM_File;
use Carp qw(carp);
use File::Basename;
use LockFile::Simple;

=head1 NAME

Email::Fingerprint::Cache::AnyDBM - AnyDBM backend for Email::Fingerprint::Cache

=head1 VERSION

Version 0.48

=cut

our $VERSION = '0.48';

=head1 SYNOPSIS

    use Email::Fingerprint::Cache;

    my $foo = Email::Fingerprint::Cache->new({
        backend => 'AnyDBM',
    });
    ...

You never want to use this class directly; you always want to access it
through Email::Fingerpint::Cache.

=head1 ATTRIBUTES

=cut

my %file :ATTR( :init_arg<file>, :set<file> ) = ();
my %hash :ATTR( :init_arg<hash> )             = ();
my %lock :ATTR                                = ();
my %mgr  :ATTR                                = ();

=head1 FUNCTIONS

=head2 new

  $cache = new Email::Fingerprint::Cache::AnyDBM({
    file => $filename,  # Mandatory
  });

Method created automatically by C<Class::Std>.

=head2 BUILD

Internal helper method; never called directly by users.

=cut

sub BUILD {
    my ( $self, $ident, $args ) = @_;

    $mgr{$ident} = LockFile::Simple->make(
        -nfs       => 1,
        -warn      => 0,
        -efunc     => undef,
        -autoclean => 1,
    );
}

=head2 open

    $cache->open or die;

Open the associated file, and tie it to our hash. This method does not
lock the file, nor unlock it on failure. See C<lock> and C<unlock>.

=cut

sub open {
    my $self = shift;

    my $file = $file{ ident $self } || '';
    return unless $file;

    my $hash = $self->get_hash;

    tie %$hash, 'AnyDBM_File', $file, O_CREAT|O_RDWR, oct(600);

    if ( not $self->is_open ) {
        carp "Couldn't open $file";
        return;
    }

    1;
}

=head2 close

Unties the hash, which causes the underlying DB file to be written and
closed.

=cut

sub close {
    my $self = shift;

    return unless $self->is_open;

    untie %{ $self->get_hash };
}

=head2 is_open

Returns true if the cache is open; false otherwise.

=cut

sub is_open {
    my $self = shift;
    my $hash = $self->get_hash;

    return 0 unless defined $hash and ref $hash eq 'HASH';
    return 0 unless tied %{ $hash };
    return 1;
}

=head2 is_locked

Returns true if the cache is locked; false otherwise.

=cut

sub is_locked {
    my $self = shift;
    return defined $lock{ ident $self } ? 1 : 0;
}

=head2 lock

  $cache->lock or die;                  # returns immediately
  $cache->lock( block => 1 ) or die;    # Waits for a lock

Lock the DB file. Returns false on failure, true on success.

=cut

sub lock {
    my $self = shift;
    my %opts = @_;

    return 1 if exists $lock{ ident $self };    # Success if already locked

    return unless defined $file{ ident $self }; # Can't lock nothing!
    my $file = $file{ ident $self };

    my $mgr = $mgr{ ident $self };

    # Minor validation that LockFile::Simple doesn't perform
    if (not -w dirname($file)) {
        warn "Directory " . dirname($file) . " is not writable\n";
        return;
    }

    # Perform the lock
    my $lock
        = $opts{block}
        ? $mgr->lock($file)
        : $mgr->trylock($file);
    return unless $lock;

    # Remember the lock
    $lock{ ident $self } = $lock;

    1;
}

=head2 unlock

  $cache->unlock or cluck "Unlock failed";

Unlocks the DB file. Returns false on failure, true on success.

=cut

sub unlock {
    my $self = shift;
    my $lock = delete $lock{ ident $self } or return 1; # Success if no lock

    $lock->release();

    1;
}

=head1 PRIVATE METHODS

=head2 get_hash

Returns a reference to the hash which is tied to the backend storage.

=cut

sub get_hash : PRIVATE {
    my $self = shift;
    return $hash{ ident $self };
}

=head1 AUTHOR

Len Budney, C<< <lbudney at pobox.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-email-fingerprint at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Fingerprint>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::Fingerprint::Cache::AnyDBM

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-Fingerprint>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-Fingerprint>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Fingerprint>

=item * Search CPAN

L<http://search.cpan.org/dist/Email-Fingerprint>

=back

=head1 ACKNOWLEDGEMENTS

Email::Fingerprint::Cache is based on caching code in the
C<eliminate_dups> script by Peter Samuel and available at
L<http://www.qmail.org/>.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2011 Len Budney, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
