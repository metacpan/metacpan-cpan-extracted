package KiokuDB::LinkChecker::Results;
BEGIN {
  $KiokuDB::LinkChecker::Results::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::LinkChecker::Results::VERSION = '0.57';
use Moose;

use Set::Object;

use namespace::clean -except => 'meta';

# Set::Object of 1 million IDs is roughly 100mb of memory == 100 bytes per ID
# no need to scale anything more, if you have that many objects you should
# probably write your own tool
has [qw(seen root referenced unreferenced missing broken)] => (
    isa => "Set::Object",
    is  => "ro",
    default => sub { Set::Object->new },
);

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::LinkChecker::Results

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
