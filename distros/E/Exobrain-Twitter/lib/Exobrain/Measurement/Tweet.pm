package Exobrain::Measurement::Tweet;

use 5.010;
use autodie;
use Moose;
use Method::Signatures;

# ABSTRACT: Tweet measurement packet
our $VERSION = '1.04'; # VERSION

# Declare that we will have a summary attribute. This is to make
# our roles happy.
sub summary;

# This needs to happen at begin time so it can add the 'payload'
# keyword.
BEGIN { with 'Exobrain::Measurement::Social'; }


has summary => (
    isa => 'Str', builder => '_build_summary', lazy => 1, is => 'ro'
);

method _build_summary() {
    return '@' . $self->from . " : " . $self->text;
}

1;

__END__

=pod

=head1 NAME

Exobrain::Measurement::Tweet - Tweet measurement packet

=head1 VERSION

version 1.04

=head1 DESCRIPTION

A tweet we may or may not care about.

Requires everything from Measurement::Social

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
