package Flux::Out;
{
  $Flux::Out::VERSION = '1.03';
}

# ABSTRACT: output stream interface

use Moo::Role;

requires 'write';

requires 'write_chunk';

requires 'commit';


1;

__END__

=pod

=head1 NAME

Flux::Out - output stream interface

=head1 VERSION

version 1.03

=head1 SYNOPSIS

    $out->write($item);
    $out->write_chunk(\@items);
    $out->commit;

=head1 DESCRIPTION

C<Flux::Out> is the role which every writing stream must implement.

Consumers must implement C<write>, C<write_chunk> and C<commit> methods.

=head1 CONSUMER SYNOPSIS

    use Moo;
    with "Flux::Out";

    sub write {
        my ($self, $item) = @_;
        say "Item: $item";
    }

    sub write_chunk {
        my ($self, $chunk) = @_;
        say "Item: $_" for @$chunk;
    }

    sub commit {
        STDOUT->flush;
    }

=head1 INTERFACE

=over

=item B<write($item)>

It receives one scalar C<$item> as its argument.

At the implementor's choice, it can process C<$item> immediately or keep it until C<commit()> is called.

Return value semantics is not specified.

=item B<write_chunk($chunk)>

C<write_chunk> receives an arrayref with items ordered as they would be if C<write> method was used instead.

Return value semantics is not specified.

=item B<commit()>

C<commit> method can flush cached data, print statistics or do anything neccessary to make sure that writing is completed correctly.

Output stream implementation should make sure that stream is still usable after that.

=back

=head1 SEE ALSO

L<Flux::Storage> - role for persistent storages which are also output streams.

L<Flux::In::Role::Easy> - specialization of this role for those who don't want to bother with 3 methods, and want to just implement C<write()>.

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
