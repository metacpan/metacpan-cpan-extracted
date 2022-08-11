package File::KDBX::Cipher;
# ABSTRACT: A block cipher mode or cipher stream

use warnings;
use strict;

use Devel::GlobalDestruction;
use File::KDBX::Constants qw(:cipher :random_stream);
use File::KDBX::Error;
use File::KDBX::Util qw(:class erase format_uuid);
use Module::Load;
use Scalar::Util qw(looks_like_number);
use namespace::clean;

our $VERSION = '0.905'; # VERSION

my %CIPHERS;


has 'uuid',         is => 'ro';
has 'stream_id',    is => 'ro';
has 'key',          is => 'ro';
has 'iv',           is => 'ro';
sub iv_size     {  0 }
sub key_size    { -1 }
sub block_size  {  0 }
sub algorithm   { $_[0]->{algorithm} or throw 'Block cipher algorithm is not set' }


sub new {
    my $class = shift;
    my %args = @_;

    return $class->new_from_uuid(delete $args{uuid}, %args) if defined $args{uuid};
    return $class->new_from_stream_id(delete $args{stream_id}, %args) if defined $args{stream_id};

    throw 'Must pass uuid or stream_id';
}

sub new_from_uuid {
    my $class = shift;
    my $uuid  = shift;
    my %args  = @_;

    $args{key} or throw 'Missing encryption key';
    $args{iv}  or throw 'Missing encryption IV';

    my $formatted_uuid = format_uuid($uuid);

    my $cipher = $CIPHERS{$uuid} or throw "Unsupported cipher ($formatted_uuid)", uuid => $uuid;
    ($class, my %registration_args) = @$cipher;

    my @args = (%args, %registration_args, uuid => $uuid);
    load $class;
    my $self = bless {@args}, $class;
    return $self->init(@args);
}

sub new_from_stream_id {
    my $class = shift;
    my $id    = shift;
    my %args  = @_;

    $args{key} or throw 'Missing encryption key';

    my $cipher = $CIPHERS{$id} or throw "Unsupported stream cipher ($id)", id => $id;
    ($class, my %registration_args) = @$cipher;

    my @args = (%args, %registration_args, stream_id => $id);
    load $class;
    my $self = bless {@args}, $class;
    return $self->init(@args);
}


sub init { $_[0] }

sub DESTROY { !in_global_destruction and erase \$_[0]->{key} }


sub encrypt { die 'Not implemented' }


sub decrypt { die 'Not implemented' }


sub finish { '' }


sub encrypt_finish {
    my $self = shift;
    my $out = $self->encrypt(@_);
    $out .= $self->finish;
    return $out;
}


sub decrypt_finish {
    my $self = shift;
    my $out = $self->decrypt(@_);
    $out .= $self->finish;
    return $out;
}


sub register {
    my $class   = shift;
    my $id      = shift;
    my $package = shift;
    my @args    = @_;

    my $formatted_id = looks_like_number($id) ? $id : format_uuid($id);
    $package = "${class}::${package}" if $package !~ s/^\+// && $package !~ /^\Q${class}::\E/;

    my %blacklist = map { (looks_like_number($_) ? $_ : File::KDBX::Util::uuid($_)) => 1 }
        split(/,/, $ENV{FILE_KDBX_CIPHER_BLACKLIST} // '');
    if ($blacklist{$id} || $blacklist{$package}) {
        alert "Ignoring blacklisted cipher ($formatted_id)", id => $id, package => $package;
        return;
    }

    if (defined $CIPHERS{$id}) {
        alert "Overriding already-registered cipher ($formatted_id) with package $package",
            id      => $id,
            package => $package;
    }

    $CIPHERS{$id} = [$package, @args];
}


sub unregister {
    delete $CIPHERS{$_} for @_;
}

BEGIN {
    __PACKAGE__->register(CIPHER_UUID_AES128,   'CBC',    algorithm => 'AES',     key_size => 16);
    __PACKAGE__->register(CIPHER_UUID_AES256,   'CBC',    algorithm => 'AES',     key_size => 32);
    __PACKAGE__->register(CIPHER_UUID_SERPENT,  'CBC',    algorithm => 'Serpent', key_size => 32);
    __PACKAGE__->register(CIPHER_UUID_TWOFISH,  'CBC',    algorithm => 'Twofish', key_size => 32);
    __PACKAGE__->register(CIPHER_UUID_CHACHA20, 'Stream', algorithm => 'ChaCha');
    __PACKAGE__->register(CIPHER_UUID_SALSA20,  'Stream', algorithm => 'Salsa20');
    __PACKAGE__->register(STREAM_ID_CHACHA20,   'Stream', algorithm => 'ChaCha');
    __PACKAGE__->register(STREAM_ID_SALSA20,    'Stream', algorithm => 'Salsa20');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Cipher - A block cipher mode or cipher stream

=head1 VERSION

version 0.905

=head1 SYNOPSIS

    use File::KDBX::Cipher;

    my $cipher = File::KDBX::Cipher->new(uuid => $uuid, key => $key, iv => $iv);

    my $ciphertext = $cipher->encrypt('plaintext');
    $ciphertext .= $cipher->encrypt('more plaintext');
    $ciphertext .= $cipher->finish;

    my $plaintext = $cipher->decrypt('ciphertext');
    $plaintext .= $cipher->decrypt('more ciphertext');
    $plaintext .= $cipher->finish;

=head1 DESCRIPTION

A cipher is used to encrypt and decrypt KDBX files. The L<File::KDBX> distribution comes with several
pre-registered ciphers ready to go:

=over 4

=item *

C<61AB05A1-9464-41C3-8D74-3A563DF8DD35> - AES128 (legacy)

=item *

C<31C1F2E6-BF71-4350-BE58-05216AFC5AFF> - AES256

=item *

C<D6038A2B-8B6F-4CB5-A524-339A31DBB59A> - ChaCha20

=item *

C<716E1C8A-EE17-4BDC-93AE-A977B882833A> - Salsa20

=item *

C<098563FF-DDF7-4F98-8619-8079F6DB897A> - Serpent

=item *

C<AD68F29F-576F-4BB9-A36A-D47AF965346C> - Twofish

=back

B<NOTE:> If you want your KDBX file to be readable by other KeePass implementations, you must use a UUID and
algorithm that they support. From the list above, AES256 and ChaCha20 are well-supported. You should avoid
AES128 for new databases.

You can also L</register> your own cipher. Here is a skeleton:

    package File::KDBX::Cipher::MyCipher;

    use parent 'File::KDBX::Cipher';

    File::KDBX::Cipher->register(
        # $uuid, $package, %args
        "\x12\x34\x56\x78\x9a\xbc\xde\xfg\x12\x34\x56\x78\x9a\xbc\xde\xfg" => __PACKAGE__,
    );

    sub init { ... } # optional

    sub encrypt { ... }
    sub decrypt { ... }
    sub finish  { ... }

    sub key_size   { ... }
    sub iv_size    { ... }
    sub block_size { ... }

=head1 ATTRIBUTES

=head2 uuid

    $uuid = $cipher->uuid;

Get the UUID if the cipher was constructed with one.

=head2 stream_id

    $stream_id = $cipher->stream_id;

Get the stream ID if the cipher was constructed with one.

=head2 key

    $key = $cipher->key;

Get the raw encryption key.

=head2 iv

    $iv = $cipher->iv;

Get the initialization vector.

=head2 iv_size

    $size = $cipher->iv_size;

Get the expected size of the initialization vector, in bytes.

=head2 key_size

    $size = $cipher->key_size;

Get the size the mode or stream expects the key to be, in bytes.

=head2 block_size

    $size = $cipher->block_size;

Get the block size, in bytes.

=head2 algorithm

Get the symmetric cipher algorithm.

=head1 METHODS

=head2 new

=head2 new_from_uuid

=head2 new_from_stream_id

    $cipher = File::KDBX::Cipher->new(uuid => $uuid, key => $key, iv => $iv);
    # OR
    $cipher = File::KDBX::Cipher->new_from_uuid($uuid, key => $key, iv => $iv);

    $cipher = File::KDBX::Cipher->new(stream_id => $id, key => $key);
    # OR
    $cipher = File::KDBX::Cipher->new_from_stream_id($id, key => $key);

Construct a new L<File::KDBX::Cipher>.

This is a factory method which returns a subclass.

=head2 init

    $self->init;

Initialize the cipher. Called by </new>.

=head2 encrypt

    $ciphertext = $cipher->encrypt($plaintext, ...);

Encrypt some data.

=head2 decrypt

    $plaintext = $cipher->decrypt($ciphertext, ...);

Decrypt some data.

=head2 finish

    $ciphertext .= $cipher->finish; # if encrypting
    $plaintext  .= $cipher->finish; # if decrypting

Finish the stream.

=head2 encrypt_finish

    $ciphertext = $cipher->encrypt_finish($plaintext, ...);

Encrypt and finish a stream in one call.

=head2 decrypt_finish

    $plaintext = $cipher->decrypt_finish($ciphertext, ...);

Decrypt and finish a stream in one call.

=head2 register

    File::KDBX::Cipher->register($uuid => $package, %args);

Register a cipher. Registered ciphers can be used to encrypt and decrypt KDBX databases. A cipher's UUID
B<must> be unique and B<musn't change>. A cipher UUID is written into each KDBX file and the associated cipher
must be registered with the same UUID in order to decrypt the KDBX file.

C<$package> should be a Perl package relative to C<File::KDBX::Cipher::> or prefixed with a C<+> if it is
a fully-qualified package. C<%args> are passed as-is to the cipher's L</init> method.

=head2 unregister

    File::KDBX::Cipher->unregister($uuid);

Unregister a cipher. Unregistered ciphers can no longer be used to encrypt and decrypt KDBX databases, until
reregistered (see L</register>).

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
