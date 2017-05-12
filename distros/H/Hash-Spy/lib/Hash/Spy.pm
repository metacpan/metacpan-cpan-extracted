package Hash::Spy;

our $VERSION = '0.01';

use strict;
use warnings;
use 5.010;
use Carp;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(spy_hash);

require XSLoader;
XSLoader::load('Hash::Spy', $VERSION);

my %cb_slot = ( delete => 0,
                store  => 1,
                clear  => 2,
                empty  => 3 );

sub spy_hash (\%@) {
    my $hash = shift;
    my $spy = _hash_get_spy($hash);
    while (@_) {
        my $name = shift;
        my $slot = $cb_slot{$name} //
            croak "bad spy callback '$name'";
        my $cb = shift;
        if (defined $cb) {
            UNIVERSAL::isa($cb, 'CODE')
                    or croak "spy callback '$name' is not a CODE ref";
        }
        $spy->_set_cb($slot, $cb);
    }
    1;
}

1;
__END__

=head1 NAME

Hash::Spy - run code when a has is changed

=head1 SYNOPSIS

  use Hash::Spy qw(spy_hash);

  my %h = (...)
  spy_hash %h, empty => sub { say "the hash is empty" };

  spy_hash %h, store  => sub { say "hash entry $_[0] => $_[1] is being added" },
               delete => sub { say "hash entry $_[0] is being deleted" },
               clear  => sub { say "the hash is being cleared" };

=head1 DESCRIPTION

This module allows to attach to a hash a set of callbacks that will be
invoked when it is changed in specific ways.

=head2 EXPORT

The following subroutine can be imported from the module:

=over 4

=item spy_hash(%hash, %hooks)

The acceptable hooks are as follows:

=over 4

=item store => sub { ... }

The given callback is invoked everytime a key/value pair is changed or
added to the hash.

The callback arguments are the key and the value.

=item delete = sub { ... }

The given callback is invoked when some entry is deleted from the
hash.

Note that this callback is not invoked when the C<delete> is used for
an entry that does not exists on the hash. For instance:

  my %a = (foo => 1, bar => 2);
  spy_hash(%a, delete => sub { say "deleting $_[0]" });
  delete $a{doz}; # the callback is not invoked!

=item clear => sub { ... }

The given callback is invoked when the hash is non empty and the clear
operation is called. That happens when a new set of keys/values is
assigned. For instance:

  %a = ();
  %a = (foo => 4, doz => 'juas');

=item empty => sub { ... }

The given callback is invoked when the last key on the hash is deleted
(via delete or clear).

Note that assigning a new set of values to a hash (due to the way that
operation is implemented internally, calling clear first and then
assigning the values) will cause the C<empty> callback to be also
invoked. For instance:

  %a = (foo => 4),
  spy_hash(%a, empty => sub { say "the hash is empty" });

  # the empty callback is called here:
  %a = (foo => 4, doz => 'juas');


=back

=back

=head1 SEE ALSO

L<perltie>

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Qindel FormaciE<ntilde>n y Servicios S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
