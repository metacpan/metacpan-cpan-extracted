package File::KDBX::Transaction;
# ABSTRACT: Make multiple database edits atomically

use warnings;
use strict;

use Devel::GlobalDestruction;
use File::KDBX::Util qw(:class);
use namespace::clean;

our $VERSION = '0.905'; # VERSION


sub new {
    my $class   = shift;
    my $object  = shift;
    $object->begin_work(@_);
    return bless {object => $object}, $class;
}

sub DESTROY { !in_global_destruction and $_[0]->rollback }


has 'object', is => 'ro';


sub commit {
    my $self = shift;
    return if $self->{done};

    my $obj = $self->object;
    $obj->commit;
    $self->{done} = 1;
    return $obj;
}


sub rollback {
    my $self = shift;
    return if $self->{done};

    my $obj = $self->object;
    $obj->rollback;
    $self->{done} = 1;
    return $obj;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Transaction - Make multiple database edits atomically

=head1 VERSION

version 0.905

=head1 ATTRIBUTES

=head2 object

Get the object being transacted on.

=head1 METHODS

=head2 new

    $txn = File::KDBX::Transaction->new($object);

Construct a new database transaction for editing an object atomically.

=head2 commit

    $txn->commit;

Commit the transaction, making updates to the L</object> permanent.

=head2 rollback

    $txn->rollback;

Roll back the transaction, throwing away any updates to the L</object> made since the transaction began. This
happens automatically when the transaction is released, unless it has already been committed.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-KDBX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
