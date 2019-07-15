package Hash::Subset;

our $DATE = '2019-07-10'; # DATE
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(hash_subset hashref_subset);

sub hash_subset {
    my ($hash, $keys_src) = @_;

    my %subset;
    my $ref = ref $keys_src;
    if ($ref eq 'ARRAY') {
        for (@$keys_src) {
            $subset{$_} = $hash->{$_} if exists $hash->{$_};
        }
    } elsif ($ref eq 'HASH') {
        for (keys %$keys_src) {
            $subset{$_} = $hash->{$_} if exists $hash->{$_};
        }
    } else {
        die "Second argument (keys_src) must be a hashref/arrayref";
    }
    %subset;
}

sub hashref_subset {
    my ($hash, $keys_src) = @_;

    my $subset = {};
    my $ref = ref $keys_src;
    if ($ref eq 'ARRAY') {
        for (@$keys_src) {
            $subset->{$_} = $hash->{$_} if exists $hash->{$_};
        }
    } elsif ($ref eq 'HASH') {
        for (keys %$keys_src) {
            $subset->{$_} = $hash->{$_} if exists $hash->{$_};
        }
    } else {
        die "Second argument (keys_src) must be a hashref/arrayref";
    }
    $subset;
}

1;
# ABSTRACT: Produce subset of a hash

__END__

=pod

=encoding UTF-8

=head1 NAME

Hash::Subset - Produce subset of a hash

=head1 VERSION

This document describes version 0.003 of Hash::Subset (from Perl distribution Hash-Subset), released on 2019-07-10.

=head1 SYNOPSIS

 use Hash::Subset qw(hash_subset hashref_subset);

 # using keys specified in an array
 my %subset = hash_subset   ({a=>1, b=>2, c=>3}, ['b','c','d']); # => (b=>2, c=>3)
 my $subset = hashref_subset({a=>1, b=>2, c=>3}, ['b','c','d']); # => {b=>2, c=>3}

 # using keys specified in another hash
 my %subset = hash_subset   ({a=>1, b=>2, c=>3}, {b=>20, c=>30, d=>40}); # => (b=>2, c=>3)
 my $subset = hashref_subset({a=>1, b=>2, c=>3}, {b=>20, c=>30, d=>40}); # => {b=>2, c=>3}

=head1 DESCRIPTION

=head1 FUNCTIONS

None exported by default.

=head2 hash_subset

Usage:

 my %subset  = hash_subset   (\%hash, \@keys);
 my $subset  = hashref_subset(\%hash, \@keys);
 my %subset  = hash_subset   (\%hash, \%another_hash);
 my $subset  = hashref_subset(\%hash, \%another_hash);

Produce subset of C<%hash>, returning the subset hash (or hashref, in the case
of C<hashref_subset> function).

Perl lets you produce a hash subset using the hash slice notation:

 my %subset = %hash{"b","c","d"};

The difference with C<hash_subset> is: 1) hash slice is only available since
perl 5.20 (in previous versions, only array slice is available); 2) when the key
does not exist in the array, perl will create it for you with C<undef> as the
value:

 my %hash   = (a=>1, b=>2, c=>3);
 my %subset = %hash{"b","c","d"}; # => (b=>2, c=>3, d=>undef)

So basically C<hash_subset> is equivalent to:

 my %subset = %hash{grep {exists $hash{$_}} "b","c","d"}; # => (b=>2, c=>3)

and available for perl earlier than 5.20.

=head2 hashref_subset

See L</hash_subset>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Hash-Subset>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Hash-Subset>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Hash-Subset>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Some other hash utilities: L<Hash::MostUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
