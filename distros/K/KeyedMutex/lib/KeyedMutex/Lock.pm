use strict;
use warnings;

package KeyedMutex::Lock;

sub _new {
    my ($klass, $km) = @_;
    $klass = ref($klass) || $klass;
    bless \$km, $klass;
}

sub DESTROY {
    my $self = shift;
    ${$self}->release;
}

1;

__END__

=head1 NAME

KeyedMutex::Lock - A lock object for KeyedMutex

=head1 DESCRIPTION

There are no public methods exposed from the module.  See documentation of C<KeyedMutex> for detail.

=head1 AUTHOR

Copyright (c) 2007 Cybozu Labs, Inc.  All rights reserved.

written by Kazuho Oku E<lt>kazuhooku@gmail.comE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under th
e same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut


