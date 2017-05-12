package Localizer::Dictionary;
use strict;
use warnings;
use utf8;
use 5.010_001;

use Class::Accessor::Lite 0.05 (
    ro => [qw(_entries)],
);

sub new {
    my $class = shift;
    bless {
        _entries => {},
    }, $class;
}

sub exists_msgid {
    my ($self, $msgid) = @_;
    exists $self->_entries->{$msgid}
}

sub add_entry_position {
    my ($self, $msgid, $file, $line) = @_;
    push @{$self->_entries->{$msgid}->{position}}, [$file, $line];
}

1;
__END__

=for stopwords msgid

=encoding utf-8

=head1 NAME

Localizer::Dictionary - Dictionary for Localizer::Scanner

=head1 DESCRIPTION

Dictionary for Localizer::Scanner class.
This module is ** IRRELEVANT ** to dictionary of L<Localizer::Resource>.

=head1 SYNOPSIS

    use Localizer::Dictionary;

    my $dict = Localizer::Dictionary->new();
    $dict->add_entry_position('Hi %1', 'path/to/foo.tt', 10);
    $dict->exists_msgid('Hi %1');  # => 1
    $dict->exists_msgid('foobar'); # => ''

=head1 METHODS

=over 4

=item * Localizer::Dictionary->new()

Constructor. It makes dictionary instance.

=item * $dictionary->add_entry_position($msgid, $file, $line)

Add entry into dictionary. C<$msgid> is the ID of message (similar to key of dictionary of L<Localizer::Resource>),
C<$file> is the location of file, and C<$line> is the line number where there is C<$msgid>.

=item * $dictionary->exists_msgid($msgid)

Returns whether C<$msgid> is registered in the dictionary.
If it exists, this method returns true value, otherwise it returns false value.

=back

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

