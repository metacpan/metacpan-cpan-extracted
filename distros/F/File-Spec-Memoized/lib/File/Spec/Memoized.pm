package File::Spec::Memoized;

use 5.006_002;
use strict;

our $VERSION = '1.00';

use File::Spec;

# constants:
#   curdir, updir, rootdir, devnull
#
# already memoized:
#   tmpdir
#
# no memoized (no performance drain):
#   file_name_is_absolute, case_tolerant

my %cache;

# features return a scalar
foreach my $feature(qw(
    canonpath
    catdir
    catfile
    catpath
    abs2rel
    rel2abs
)) {
    my $orig = File::Spec->can($feature) or die "Oops: $feature";

    my $fs   = '$' . $feature;

    my $memoized = sub :method {
        my $self = shift;
        return $cache{$fs, @_} ||=  $self->$orig(@_);
    };
    no strict 'refs';
    *{$feature} = $memoized;
}

# features return a list
foreach my $feature(qw(
    no_upwards
    path
    splitpath
    splitdir
)) {
    my $orig = File::Spec->can($feature) or die "Oops: $feature";

    my $fl   = '@' . $feature;

    my $memoized = sub :method {
        my $self = shift;
        return @{ $cache{$fl, @_} ||= [$self->$orig(@_)] };
    };
    no strict 'refs';
    *{$feature} = $memoized;
}

sub flush_cache {
    undef %cache;
    return;
}

sub __cache { \%cache }

# Organize the class hierarchy:
# File::Spec -> File::Spec::Memoized -> File::Spec::$OS
#               ^^^^^^^^^^^^^^^^^^^^
our @ISA = @File::Spec::ISA;
@File::Spec::ISA = (__PACKAGE__);

1;
__END__

=head1 NAME

File::Spec::Memoized - Memoization of File::Spec to make it faster

=head1 VERSION

This document describes File::Spec::Memoized version 1.00.

=head1 SYNOPSIS

    # All you have to do is load this module.
    use File::Spec::Memoized;

    # Once this module is loaded, File::Spec features
    # will become faster.
    my $path = File::Spec->catfile('path', 'to', 'file.txt');

=head1 DESCRIPTION

File::Spec is used everywhere, but its performance is not so good
because a lot of internal calls of C<canonpath()> consumes CPU.

File::Spec::Memoized applies File::Spec with B<memoization> technique
(or data caching). Once you load this module, File::Spec methods
will become significantly faster. Moreover, some modules that depend
on File::Spec, e.g. C<Path::Class>, could become faster.

This module adopts File::Spec methods, so you need no changes in your
program. All you have to do is say C<use File::Spec::Memoized>.

=head1 INTERFACE

=head2 Cache control methods

=over 4

=item C<< File::Spec::Memoized->flush_cache() >>

Clears the cache and frees the memory used for the cache.

=back

=head1 DEPENDENCIES

Perl 5.6.2 or later.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 SEE ALSO

L<File::Spec>

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Goro Fuji (gfx). Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
