package File::KDBX::Safe;
# ABSTRACT: Keep strings encrypted while in memory

use warnings;
use strict;

use Crypt::PRNG qw(random_bytes);
use Devel::GlobalDestruction;
use Encode qw(encode decode);
use File::KDBX::Constants qw(:random_stream);
use File::KDBX::Error;
use File::KDBX::Util qw(erase erase_scoped);
use Ref::Util qw(is_arrayref is_coderef is_hashref is_scalarref);
use Scalar::Util qw(refaddr);
use namespace::clean;

our $VERSION = '0.901'; # VERSION


sub new {
    my $class = shift;
    my %args = @_ % 2 == 0 ? @_ : (strings => shift, @_);

    if (!$args{cipher} && $args{key}) {
        require File::KDBX::Cipher;
        $args{cipher} = File::KDBX::Cipher->new(stream_id => STREAM_ID_CHACHA20, key => $args{key});
    }

    my $self = bless \%args, $class;
    $self->cipher->finish;
    $self->{counter} = 0;

    my $strings = delete $args{strings};
    $self->{items} = [];
    $self->{index} = {};
    $self->add($strings) if $strings;

    return $self;
}

sub DESTROY { local ($., $@, $!, $^E, $?); !in_global_destruction and $_[0]->unlock }


sub clear {
    my $self = shift;
    $self->{items} = [];
    $self->{index} = {};
    $self->{counter} = 0;
    return $self;
}


sub lock { shift->add(@_) }

sub add {
    my $self    = shift;
    my @strings = map { is_arrayref($_) ? @$_ : $_ } @_;

    @strings or throw 'Must provide strings to lock';

    my $cipher = $self->cipher;

    for my $string (@strings) {
        my $item = {str => $string, off => $self->{counter}};
        if (is_scalarref($string)) {
            next if !defined $$string;
            $item->{enc} = 'UTF-8' if utf8::is_utf8($$string);
            if (my $encoding = $item->{enc}) {
                my $encoded = encode($encoding, $$string);
                $item->{val} = $cipher->crypt(\$encoded);
                erase $encoded;
            }
            else {
                $item->{val} = $cipher->crypt($string);
            }
            erase $string;
        }
        elsif (is_hashref($string)) {
            next if !defined $string->{value};
            $item->{enc} = 'UTF-8' if utf8::is_utf8($string->{value});
            if (my $encoding = $item->{enc}) {
                my $encoded = encode($encoding, $string->{value});
                $item->{val} = $cipher->crypt(\$encoded);
                erase $encoded;
            }
            else {
                $item->{val} = $cipher->crypt(\$string->{value});
            }
            erase \$string->{value};
        }
        else {
            throw 'Safe strings must be a hashref or stringref', type => ref $string;
        }
        push @{$self->{items}}, $item;
        $self->{index}{refaddr($string)} = $item;
        $self->{counter} += length($item->{val});
    }

    return $self;
}


sub lock_protected { shift->add_protected(@_) }

sub add_protected {
    my $self = shift;
    my $filter = is_coderef($_[0]) ? shift : undef;
    my @strings = map { is_arrayref($_) ? @$_ : $_ } @_;

    @strings or throw 'Must provide strings to lock';

    for my $string (@strings) {
        my $item = {str => $string, off => $self->{counter}};
        $item->{filter} = $filter if defined $filter;
        if (is_scalarref($string)) {
            next if !defined $$string;
            $item->{val} = $$string;
            erase $string;
        }
        elsif (is_hashref($string)) {
            next if !defined $string->{value};
            $item->{val} = $string->{value};
            erase \$string->{value};
        }
        else {
            throw 'Safe strings must be a hashref or stringref', type => ref $string;
        }
        push @{$self->{items}}, $item;
        $self->{index}{refaddr($string)} = $item;
        $self->{counter} += length($item->{val});
    }

    return $self;
}


sub unlock {
    my $self = shift;

    my $cipher = $self->cipher;
    $cipher->finish;
    $self->{counter} = 0;

    for my $item (@{$self->{items}}) {
        my $string  = $item->{str};
        my $cleanup = erase_scoped \$item->{val};
        my $str_ref;
        if (is_scalarref($string)) {
            $$string = $cipher->crypt(\$item->{val});
            if (my $encoding = $item->{enc}) {
                my $decoded = decode($encoding, $string->{value});
                erase $string;
                $$string = $decoded;
            }
            $str_ref = $string;
        }
        elsif (is_hashref($string)) {
            $string->{value} = $cipher->crypt(\$item->{val});
            if (my $encoding = $item->{enc}) {
                my $decoded = decode($encoding, $string->{value});
                erase \$string->{value};
                $string->{value} = $decoded;
            }
            $str_ref = \$string->{value};
        }
        else {
            die 'Unexpected';
        }
        if (my $filter = $item->{filter}) {
            my $filtered = $filter->($$str_ref);
            erase $str_ref;
            $$str_ref = $filtered;
        }
    }

    return $self->clear;
}


sub peek {
    my $self = shift;
    my $string = shift;

    my $item = $self->{index}{refaddr($string)} // return;

    my $cipher = $self->cipher->dup(offset => $item->{off});

    my $value = $cipher->crypt(\$item->{val});
    if (my $encoding = $item->{enc}) {
        my $decoded = decode($encoding, $value);
        erase $value;
        return $decoded;
    }
    return $value;
}


sub cipher {
    my $self = shift;
    $self->{cipher} //= do {
        require File::KDBX::Cipher;
        File::KDBX::Cipher->new(stream_id => STREAM_ID_CHACHA20, key => random_bytes(64));
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Safe - Keep strings encrypted while in memory

=head1 VERSION

version 0.901

=head1 SYNOPSIS

    use File::KDBX::Safe;

    $safe = File::KDBX::Safe->new;

    my $msg = 'Secret text';
    $safe->add(\$msg);
    # $msg is now undef, the original message no longer in RAM

    my $obj = { value => 'Also secret' };
    $safe->add($obj);
    # $obj is now { value => undef }

    say $safe->peek($msg);  # Secret text

    $safe->unlock;
    say $msg;               # Secret text
    say $obj->{value};      # Also secret

=head1 DESCRIPTION

This module provides memory protection functionality. It keeps strings encrypted in memory and decrypts them
as-needed. Encryption and decryption is done using a L<File::KDBX::Cipher::Stream>.

A safe can protect one or more (possibly many) strings. When a string is added to a safe, it gets added to an
internal list so it will be decrypted when the entire safe is unlocked.

=head1 ATTRIBUTES

=head2 cipher

    $cipher = $safe->cipher;

Get the L<File::KDBX::Cipher::Stream> protecting a safe.

=head1 METHODS

=head2 new

    $safe = File::KDBX::Safe->new(%attributes);
    $safe = File::KDBX::Safe->new(\@strings, %attributes);

Create a new safe for storing secret strings encrypted in memory.

If a cipher is passed, its stream will be reset.

=head2 clear

    $safe = $safe->clear;

Clear a safe, removing all store contents permanently. Returns itself to allow method chaining.

=head2 lock

=head2 add

    $safe = $safe->lock(@strings);
    $safe = $safe->lock(\@strings);

Add one or more strings to the memory protection stream. Returns itself to allow method chaining.

=head2 lock_protected

=head2 add_protected

    $safe = $safe->lock_protected(@strings);
    $safe = $safe->lock_protected(\@strings);

Add strings that are already encrypted. Returns itself to allow method chaining.

B<WARNING:> The cipher must be the same as was used to originally encrypt the strings. You must add
already-encrypted strings in the order in which they were original encrypted or they will not decrypt
correctly. You almost certainly do not want to add both unprotected and protected strings to a safe.

=head2 unlock

    $safe = $safe->unlock;

Decrypt all the strings. Each stored string is set to its original value, potentially overwriting any value
that might have been set after locking the string (so you probably should avoid modification to strings while
locked). The safe is implicitly cleared. Returns itself to allow method chaining.

This happens automatically when the safe is garbage-collected.

=head2 peek

    $string_value = $safe->peek($string);
    ...
    erase $string_value;

Peek into the safe at a particular string without decrypting the whole safe. A copy of the string is returned,
and in order to ensure integrity of the memory protection you should erase the copy when you're done.

Returns C<undef> if the given C<$string> is not in memory protection.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-KDBX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
