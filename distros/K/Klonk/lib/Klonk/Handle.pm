package Klonk::Handle 0.01;
use Klonk::pragma;
use parent 'IO::Handle';

method openr($class: $file) {
    open my $fh, '<:raw', $file
        or return undef;
    ${*$fh} = $file;
    bless $fh, $class
}

method path() {
    ${*$self}
}

1
__END__

=head1 NAME

Klonk::Handle - IO::Handle subclass that remembers filenames

=head1 SYNOPSIS

    use Klonk::Handle ();
    my $fh = Klonk::Handle->openr($filename)
        or die "Can't open $filename: $!";
    my $line = readline $fh;
    say "I read a line from ", $fh->path;

=head1 DESCRIPTION

This class provides one constructor and one instance method. All other
methods are inherited from L<IO::Handle>.

Objects of this class are meant to be used as L<PSGI> response bodies. The
provided C<path> method may allow some servers to serve the file directly and
more efficiently than repeatedly filling a buffer by calling methods on an
object.

=head2 Constructor

=over

=item C<< Klonk::Handle->openr($filename) >>

Opens C<$filename> for reading in binary mode (C<:raw>) and returns a handle
object. The object is usable as a filehandle with built-in functions like
C<readline> or C<seek>; it also supports the methods of L<IO::Handle>.

=back

=head2 Methods

=over

=item C<< $fh->path >>

Returns the name of the file that C<$fh> refers to. C<$fh> must have been
constructed by a call to L</C<< Klonk::Handle->openr($filename) >>>.

=back

=head1 SEE ALSO

L<IO::Handle>
