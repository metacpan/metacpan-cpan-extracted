package KinoSearch1::Store::InvIndex;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        create => 0,
        path   => undef,
    );
}

__PACKAGE__->ready_get(qw( create path ));

=begin comment

    my $outstream = $invindex->open_outstream($filename);

Given a filename, return an OutStream object.

=end comment
=cut

sub open_outstream { shift->abstract_death }

=begin comment

    my $instream = $invindex->open_instream($filename);

Given a filename, return an InStream object.

=end comment
=cut

sub open_instream { shift->abstract_death }

=begin comment

    my @files = $invindex->list;

Return a list of all the files in the InvIndex

=end comment
=cut

sub list { shift->abstract_death }

=begin comment

    my $truth = $invindex->file_exists($filename);

Indicate whether the invindex contains a file with the given filename.

=end comment
=cut

sub file_exists { shift->abstract_death }

=begin comment

    $invindex->rename_file( $from, $to );

Rename a file.

=end comment
=cut

sub rename_file { shift->abstract_death }

=begin comment

   $invindex->delete_file($filename);

Delete a file from the invindex.

=end comment
=cut

sub delete_file { shift->abstract_death }

=begin comment

    my $file_contents = $invindex->slurp_file($filename);

Return a scalar with the file's contents.  Only for small files, obviously.

=end comment
=cut

sub slurp_file { shift->abstract_death }

=begin comment

   my $lock = $invindex->make_lock(
       lock_name => $name,
       timeout   => $timeout,  # milliseconds
   );

Factory method for creating a KinoSearch1::Store::Lock subclassed object.

=end comment
=cut

sub make_lock { shift->abstract_death }

=begin comment

    $invindex->run_while_locked(
        lock_name => $name,
        timeout   => $timeout,  # milliseconds
        do_body   => \&do_some_stuff,
    );

Create a Lock object and obtain a lock, run the subroutine specified by
the do_body parameter, then release the lock and discard the Lock object.
The hash-style argument labels include all the arguments to make_lock, plus
do_body.

=end comment
=cut

sub run_while_locked {
    my ( $self, %args ) = @_;
    my $do_body = delete $args{do_body};
    my $lock = $self->make_lock( %args, invindex => $self, );
    my $locked;
    eval {
        $locked = $lock->obtain;
        $do_body->();
    };
    $lock->release if $lock->is_locked;
    confess $@ if $@;
}

=begin comment

    $invindex->close()

Release any reserved resources.

=end comment
=cut

sub close { shift->abstract_death }

1;

__END__

=head1 NAME

KinoSearch1::Store::InvIndex - inverted index

=head1 SYNOPSIS

    # abstract base class

=head1 DESCRIPTION

An InvIndex is an abstract representation of an inverted index, KinoSearch1's
core data structure.  The archetypal implementation of an invindex,
FSInvIndex, is a single directory holding a collection of files.  However, to
allow alternative implementations such as RAMInvIndex, i/o and file
manipulation are abstracted out rather than executed directly by KinoSearch1's
classes.

A "file" within an invindex might be a real file -- or it might be a ram file,
or eventually a database record, etc.  Similarly,
C<< $invindex->delete_file($filename) >> might delete a file from the file
system, or a key-value pair from a hash, or something else.

=head1 SEE ALSO

L<KinoSearch1::Docs::FileFormat|KinoSearch1::Docs::FileFormat>

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut
