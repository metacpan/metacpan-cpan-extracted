package Hash::Subset;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-11'; # DATE
our $DIST = 'Hash-Subset'; # DIST
our $VERSION = '0.006'; # VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       hash_subset
                       hashref_subset
                       hash_subset_without
                       hashref_subset_without
               );

sub _routine {
    my ($which, $hash, @keys_srcs) = @_;

    my $reverse = $which =~ /_without\z/;
    my $return_ref = $which =~ /\Ahashref_/;

    my %subset;
    %subset = %$hash if $reverse;

    for my $keys_src (@keys_srcs) {
        my $ref = ref $keys_src;
        if ($ref eq 'ARRAY') {
            if ($reverse) {
                for (@$keys_src) {
                    delete $subset{$_};
                }
            } else {
                for (@$keys_src) {
                    $subset{$_} = $hash->{$_} if exists $hash->{$_};
                }
            }
        } elsif ($ref eq 'HASH') {
            if ($reverse) {
                for (keys %$keys_src) {
                    delete $subset{$_};
                }
            } else {
                for (keys %$keys_src) {
                    $subset{$_} = $hash->{$_} if exists $hash->{$_};
                }
            }
        } elsif ($ref eq 'CODE') {
            if ($reverse) {
                for (keys %$hash) {
                    delete $subset{$_} if $keys_src->($_, $hash->{$_});
                }
            } else {
                for (keys %$hash) {
                    $subset{$_} = $hash->{$_} if $keys_src->($_, $hash->{$_});
                }
            }
        } else {
            die "Key source ($keys_src) must be a hashref/arrayref/coderef";
        }
    } # for $keys_src

    if ($return_ref) {
        return \%subset;
    } else {
        return %subset;
    }
}

sub hash_subset    { _routine('hash_subset'   , @_) }
sub hashref_subset { _routine('hashref_subset', @_) }
sub hash_subset_without    { _routine('hash_subset_without'   , @_) }
sub hashref_subset_without { _routine('hashref_subset_without', @_) }

1;
# ABSTRACT: Produce subset of a hash

__END__

=pod

=encoding UTF-8

=head1 NAME

Hash::Subset - Produce subset of a hash

=head1 VERSION

This document describes version 0.006 of Hash::Subset (from Perl distribution Hash-Subset), released on 2020-06-11.

=head1 SYNOPSIS

 use Hash::Subset qw(
     hash_subset
     hashref_subset
     hash_subset_without
     hashref_subset_without
 );

 # using keys specified in an array
 my %subset = hash_subset   ({a=>1, b=>2, c=>3}, ['b','c','d']); # => (b=>2, c=>3)
 my $subset = hashref_subset({a=>1, b=>2, c=>3}, ['b','c','d']); # => {b=>2, c=>3}

 # using keys specified in another hash
 my %subset = hash_subset   ({a=>1, b=>2, c=>3}, {b=>20, c=>30, d=>40}); # => (b=>2, c=>3)
 my $subset = hashref_subset({a=>1, b=>2, c=>3}, {b=>20, c=>30, d=>40}); # => {b=>2, c=>3}

 # filtering keys using a coderef
 my %subset = hash_subset   ({a=>1, b=>2, c=>3}, sub {$_[0] =~ /[bc]/}); # => (b=>2, c=>3)
 my $subset = hashref_subset({a=>1, b=>2, c=>3}, sub {$_[0] =~ /[bc]/}); # => {b=>2, c=>3}

 # multiple filters: array, hash, coderef
 my %subset = hash_subset   ({a=>1, b=>2, c=>3, d=>4}, {c=>1}, [qw/b/], sub {$_[0] =~ /[bcd]/}); # => (b=>2, c=>3, d=>4)
 my $subset = hashref_subset({a=>1, b=>2, c=>3, d=>4}, {c=>1}, [qw/b/], sub {$_[0] =~ /[bcd]/}); # => {b=>2, c=>3, d=>4}

 # excluding keys
 my %subset = hash_subset_without   ({a=>1, b=>2, c=>3}, ['b','c','d']); # => (a=>1)
 my $subset = hashref_subset_without({a=>1, b=>2, c=>3}, ['b','c','d']); # => {a=>1}

A use case is when you use hash arguments:

 sub func1 {
     my %args = @_; # known arguments: foo, bar, baz
     ...
 }

 sub func2 {
     my %args = @_; # known arguments: all func1 arguments as well as qux, quux

     # call func1 with all arguments passed to us
     my $res = func1(hash_subset(\%args, [qw/foo bar baz/]));

     # postprocess result
     ...
 }

If you use L<Rinci> metadata in your code, this will come in handy, for example:

 my %common_args = (
     foo => {...},
     bar => {...},
     baz => {...},
 );

 $SPEC{func1} = {
    v => 1.1,
    args => {
        %common_args,
    },
 };
 sub func1 {
     my %args = @_;
     ...
 }

 $SPEC{func2} = {
    v => 1.1,
    args => {
        %common_args,
        # func2 supports all func1 arguments plus a couple of others
        qux  => { ... },
        quux => { ... },
    },
 };
 sub func2 {
     my %args = @_;

     # call func1 with all arguments passed to us
     my $res = func1(hash_subset(\%args, $SPEC{func1}{args}));

     # postprocess result
     ...
 }

=head1 DESCRIPTION

Keywords: hash arguments, hash picking, hash grep, hash filtering

=head1 FUNCTIONS

None exported by default.

=head2 hash_subset

Usage:

 my %subset  = hash_subset   (\%hash, @keys_srcs);
 my $subset  = hashref_subset(\%hash, @keys_srcs);

Where @keys_src elements can be arrayref, hashref, or coderef. Coderef will be
called with args($key, $value) and return true when key should be included.

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

and available for perl earlier than 5.20. In addition to that, hash_subset()
accepts arrayref as well as hashref/coderef, and several of them.

=head2 hashref_subset

See L</hash_subset>.

=head2 hash_subset_without

Like L</hash_subset>, but reverses the logic: will create subset that only
includes keys not in the specified arrays/hashes/coderefs.

=head2 hashref_subset_without

See L</hash_subset_without>.

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

L<Hash::MoreUtils> provides various ways to create hash subset ("slice") through
its C<slice_*> functions. It does not provide way to specify subset keys via the
keys of C<%another_hash>, but that can be done trivially using C<< keys
%another_hash >>. Hash::Subset is currently more lightweight than
Hash::MoreUtils.

L<Tie::Subset::Hash> to create a tied version of a hash subset (a "view" of a
subset of a hash).

L<Hash::Util::Pick> also allows you to create a hash subset by specifying the
wanted keys in a list or via filtering using a coderef. This XS module should
perhaps be preferred over Hash::Subset for its performance, but there are some
cases where you cannot use XS modules.

See some benchmarks in L<Bencher::Scenarios::HashPicking>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
