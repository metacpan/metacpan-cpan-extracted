package Mediawiki::Blame::Line;
use 5.008;
use utf8;
use strict;
use warnings;
use Class::Spiffy qw(-base field);
our $VERSION = '0.0.3';

my @field_names = qw(r_id timestamp contributor text);
for my $field_name (@field_names) {
    field $field_name;
};

sub _new {
    my $class = shift;
    my $self = {};
    bless $self, $class;

    $self->r_id(shift);
    $self->timestamp(shift);
    $self->contributor(shift);
    $self->text(shift);

    return $self;
};

1;

__END__

=encoding UTF-8

=head1 NAME

Mediawiki::Blame::Line - Revision line class

=head1 VERSION

This document describes Mediawiki::Blame::Line version 0.0.3

=head1 SYNOPSIS

    print join "\t",
        $rev->r_id,
        $rev->timestamp,
        $rev->contributor,
        $rev->text;

=head1 DESCRIPTION

This module represents an line of a certain revision, annotated with who
changed it last.

=head1 INTERFACE

=over

=item r_id

Returns the revision id of the revision when the line was changed last.
It is a natural number. Later revisions have higher numbers.

=item timestamp

Returns the timestamp when the line was changed last.
It is in ISO 8601 format, for instance C<2007-07-23T21:43:56Z>.

=item contributor

Returns the contributor who changed this line last.
This is either a Mediawiki username or an IP address.

=back

L</"r_id"> and L</"contributor"> can also return C<undef>. This means that the
line has been changed earlier than L</"timestamp"> and than revisions have been
fetched for analysing.

=over

=item text

Returns the text of the line. This is source text with Mediawiki markup, not in
HTML.

=back
