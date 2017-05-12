package Hash::Rename;
use strict;
use warnings;
use Exporter qw(import);
our $VERSION = '2.00';
our @EXPORT  = ('hash_rename');

sub hash_rename (\%@) {
    my ($hash, %args) = @_;
    my %new_hash;
    for my $key (sort keys %$hash) {
        my $orig_key = $key;
        $key = $args{prepend} . $key if defined $args{prepend};
        $key = $key . $args{append}  if defined $args{append};
        if (defined $args{code}) {
            ref $args{code} eq 'CODE'
              || die "'code' value is not a CODE reference";
            local $_ = $key;
            $args{code}->();
            $key = $_;
        }
        die "duplicate result key [$key] from original key [$orig_key]\n"
          if defined($args{strict}) && exists $new_hash{$key};

        # apply 'recurse' option, if given
        my $val = $hash->{$orig_key};
        if ($args{recurse} && (ref($val) || '') eq 'HASH') {

            # suppress "called too early to check prototype ..." warning
            &hash_rename($val, %args);
        }
        $new_hash{$key} = $val;
    }
    %$hash = %new_hash;
}
1;

=pod

=head1 NAME

Hash::Rename - Rename hash keys

=head1 SYNOPSIS

    use Hash::Rename;

    my %hash = (
        '-noforce' => 1,
        scheme     => 'http'
    );
    hash_rename %hash, code => sub { s/^(?!-)/-/ };

=head1 DESCRIPTION

Using this module you can rename a hash's keys in place.

=head1 FUNCTIONS

=head2 hash_rename

This function is automatically exported. It takes a hash to rename and another
hash of instructions on how to rename they keys.

The syntax is like this:

    hash_rename %hash, instruction1 => 'value1', instruction2 => 'value2';

The following instructions are supported:

=over 4

=item C<prepend>

    hash_rename %hash, prepend => '-';

The given value is prepended to each hash key.

=item C<append>

    hash_rename %hash, append => '-';

The given value is appended to each hash key.

=item C<code>

    hash_rename %hash, code => sub { s/^(?!-)/-/ };

Each hash key is localized to C<$_> and subjected to the code. Its new value
is the result of C<$_> after the code has been executed.

=item C<strict>

If present and set to a true value, the resulting keys are checked for
duplicates. C<hash_rename()> will die if it detects a duplicate resulting hash
key. They keys of the hash to change are processed in alphabetical order.

=item C<recurse>

Each hash value that is itself a hash reference is renamed with the same
arguments as the original hash.

=back

If several instructions are given, they are processed in the order in which
they are described above. So you can have:

    hash_rename %hash, prepend => '-', append => '=';

=head1 AUTHOR

The following person is the author of all the files provided in this
distribution unless explicitly noted otherwise.

Marcel Gruenauer <marcel@cpan.org>, L<http://marcelgruenauer.com>

=head1 CONTRIBUTORS

Masayuki Matsuki (@songmu) added the C<recurse> option.

=head1 COPYRIGHT AND LICENSE

The following copyright notice applies to all the files provided in this
distribution, including binary files, unless explicitly noted otherwise.

This software is copyright (c) 2014 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.
