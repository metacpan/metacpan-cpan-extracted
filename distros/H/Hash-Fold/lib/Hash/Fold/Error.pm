package Hash::Fold::Error;

use Moo;

extends 'Throwable::Error';

has path => (
    is => 'ro',
);

has type => (
    is => 'ro',
);

1;

__END__

=head1 NAME

    Hash::Fold::Error

=head1 SYNOPSIS

    use Hash::Fold::Error;

    Hash::Fold::Error->throw($message);

    Hash::Fold::Error->throw({
        message => $message,
        path    => $path,
        type    => $type,
    });

=head1 DESCRIPTION

L<Hash::Fold> throws an instance of this class on error.

=head1 ATTRIBUTES

=head3 path

If the C<path> attribute is defined, the error was thrown during merging or
unfolding, and the message indicates the location in the structure that was
inappropriately used as an array or a hash.

L</type> is set to either C<array> or C<hash>.

=head3 type

When defined, C<type> indicates the type of the structure which caused the error.

=cut
