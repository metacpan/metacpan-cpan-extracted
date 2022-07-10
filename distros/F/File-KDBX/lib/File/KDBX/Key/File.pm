package File::KDBX::Key::File;
# ABSTRACT: A file key

use warnings;
use strict;

use Crypt::Digest qw(digest_data);
use Crypt::Misc 0.029 qw(decode_b64 encode_b64);
use Crypt::PRNG qw(random_bytes);
use File::KDBX::Constants qw(:key_file);
use File::KDBX::Error;
use File::KDBX::Util qw(:class :erase trim);
use Ref::Util qw(is_ref is_scalarref);
use Scalar::Util qw(openhandle);
use XML::LibXML::Reader;
use namespace::clean;

extends 'File::KDBX::Key';

our $VERSION = '0.904'; # VERSION


has 'type',     is => 'ro';
has 'version',  is => 'ro';
has 'filepath', is => 'ro';


sub init { shift->load(@_) }

sub load {
    my $self = shift;
    my $primitive = shift // throw 'Missing key primitive';

    my $data;
    my $cleanup;

    if (openhandle($primitive)) {
        seek $primitive, 0, 0;  # not using ->seek method so it works on perl 5.10
        my $buf = do { local $/; <$primitive> };
        $data = \$buf;
        $cleanup = erase_scoped $data;
    }
    elsif (is_scalarref($primitive)) {
        $data = $primitive;
    }
    elsif (defined $primitive && !is_ref($primitive)) {
        open(my $fh, '<:raw', $primitive)
            or throw "Failed to open key file ($primitive)", filepath => $primitive;
        my $buf = do { local $/; <$fh> };
        $data = \$buf;
        $cleanup = erase_scoped $data;
        $self->{filepath} = $primitive;
    }
    else {
        throw 'Unexpected primitive type', type => ref $primitive;
    }

    my $raw_key;
    if (substr($$data, 0, 120) =~ /<KeyFile>/
            and my ($type, $version) = $self->_load_xml($data, \$raw_key)) {
        $self->{type}    = $type;
        $self->{version} = $version;
        $self->_set_raw_key($raw_key);
    }
    elsif (length($$data) == 32) {
        $self->{type} = KEY_FILE_TYPE_BINARY;
        $self->_set_raw_key($$data);
    }
    elsif ($$data =~ /^[A-Fa-f0-9]{64}$/) {
        $self->{type} = KEY_FILE_TYPE_HEX;
        $self->_set_raw_key(pack('H64', $$data));
    }
    else {
        $self->{type} = KEY_FILE_TYPE_HASHED;
        $self->_set_raw_key(digest_data('SHA256', $$data));
    }

    return $self->hide;
}


sub reload {
    my $self = shift;
    $self->init($self->{filepath}) if defined $self->{filepath};
    return $self;
}


sub save {
    my $self = shift;
    my %args = @_;

    my @cleanup;
    my $raw_key = $args{raw_key} // $self->raw_key // random_bytes(32);
    push @cleanup, erase_scoped $raw_key;
    length($raw_key) == 32 or throw 'Raw key must be exactly 256 bits (32 bytes)', length => length($raw_key);

    my $type        = $args{type} // $self->type // KEY_FILE_TYPE_XML;
    my $version     = $args{version} // $self->version // 2;
    my $filepath    = $args{filepath} // $self->filepath;
    my $fh          = $args{fh};
    my $atomic      = $args{atomic} // 1;

    my $filepath_temp;
    if (!openhandle($fh)) {
        $filepath or throw 'Must specify where to safe the key file to';

        if ($atomic) {
            require File::Temp;
            ($fh, $filepath_temp) = eval { File::Temp::tempfile("${filepath}-XXXXXX", UNLINK => 1) };
            if (!$fh or my $err = $@) {
                $err //= 'Unknown error';
                throw sprintf('Open file failed (%s): %s', $filepath_temp, $err),
                    error       => $err,
                    filepath    => $filepath_temp;
            }
        }
        else {
            open($fh, '>:raw', $filepath) or throw "Open file failed ($filepath): $!", filepath => $filepath;
        }
    }

    if ($type == KEY_FILE_TYPE_XML) {
        $self->_save_xml($fh, $raw_key, $version);
    }
    elsif ($type == KEY_FILE_TYPE_BINARY) {
        print $fh $raw_key;
    }
    elsif ($type == KEY_FILE_TYPE_HEX) {
        my $hex = uc(unpack('H*', $raw_key));
        push @cleanup, erase_scoped $hex;
        print $fh $hex;
    }
    else {
        throw "Cannot save $type key file (invalid type)", type => $type;
    }

    close($fh);

    if ($filepath_temp) {
        my ($file_mode, $file_uid, $file_gid) = (stat($filepath))[2, 4, 5];

        my $mode = $args{mode} // $file_mode // do { my $m = umask; defined $m ? oct(666) &~ $m : undef };
        my $uid  = $args{uid}  // $file_uid  // -1;
        my $gid  = $args{gid}  // $file_gid  // -1;
        chmod($mode, $filepath_temp) if defined $mode;
        chown($uid, $gid, $filepath_temp);
        rename($filepath_temp, $filepath)
            or throw "Failed to write file ($filepath): $!", filepath => $filepath;
    }
}

##############################################################################

sub _load_xml {
    my $self = shift;
    my $buf  = shift;
    my $out  = shift;

    my ($version, $hash, $data);

    my $reader  = XML::LibXML::Reader->new(string => $$buf);
    my $pattern = XML::LibXML::Pattern->new('/KeyFile/Meta/Version|/KeyFile/Key/Data');

    while ($reader->nextPatternMatch($pattern) == 1) {
        next if $reader->nodeType != XML_READER_TYPE_ELEMENT;
        my $name = $reader->localName;
        if ($name eq 'Version') {
            $reader->read if !$reader->isEmptyElement;
            $reader->nodeType == XML_READER_TYPE_TEXT
                or alert 'Expected text node with version', line => $reader->lineNumber;
            my $val = trim($reader->value);
            defined $version
                and alert 'Overwriting version', previous => $version, new => $val, line => $reader->lineNumber;
            $version = $val;
        }
        elsif ($name eq 'Data') {
            $hash = trim($reader->getAttribute('Hash')) if $reader->hasAttributes;
            $reader->read if !$reader->isEmptyElement;
            $reader->nodeType == XML_READER_TYPE_TEXT
                or alert 'Expected text node with data', line => $reader->lineNumber;
            $data = $reader->value;
            $data =~ s/\s+//g if defined $data;
        }
    }

    return if !defined $version || !defined $data;

    if ($version =~ /^1\.0/ && $data =~ /^[A-Za-z0-9+\/=]+$/) {
        $$out = eval { decode_b64($data) };
        if (my $err = $@) {
            throw 'Failed to decode key in key file', version => $version, data => $data, error => $err;
        }
        return (KEY_FILE_TYPE_XML, $version);
    }
    elsif ($version =~ /^2\.0/ && $data =~ /^[A-Fa-f0-9]+$/ && defined $hash && $hash =~ /^[A-Fa-f0-9]+$/) {
        $$out = pack('H*', $data);
        $hash = pack('H*', $hash);
        my $got_hash = digest_data('SHA256', $$out);
        $hash eq substr($got_hash, 0, length($hash))
            or throw 'Checksum mismatch', got => $got_hash, expected => $hash;
        return (KEY_FILE_TYPE_XML, $version);
    }

    throw 'Unexpected data in key file', version => $version, data => $data;
}

sub _save_xml {
    my $self    = shift;
    my $fh      = shift;
    my $raw_key = shift;
    my $version = shift // 2;

    my @cleanup;

    my $dom = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $doc = XML::LibXML::Element->new('KeyFile');
    $dom->setDocumentElement($doc);
    my $meta_node = XML::LibXML::Element->new('Meta');
    $doc->appendChild($meta_node);
    my $version_node = XML::LibXML::Element->new('Version');
    $version_node->appendText(sprintf('%.1f', $version));
    $meta_node->appendChild($version_node);
    my $key_node = XML::LibXML::Element->new('Key');
    $doc->appendChild($key_node);
    my $data_node = XML::LibXML::Element->new('Data');
    $key_node->appendChild($data_node);

    if (int($version) == 1) {
        my $b64 = encode_b64($raw_key);
        push @cleanup, erase_scoped $b64;
        $data_node->appendText($b64);
    }
    elsif (int($version) == 2) {
        my @hex = unpack('(H8)8', $raw_key);
        my $hex = uc(sprintf("\n      %s\n      %s\n    ", join(' ', @hex[0..3]), join(' ', @hex[4..7])));
        push @cleanup, erase_scoped $hex, @hex;
        $data_node->appendText($hex);
        my $hash = digest_data('SHA256', $raw_key);
        substr($hash, 4) = '';
        $hash = uc(unpack('H*', $hash));
        $data_node->setAttribute('Hash', $hash);
    }
    else {
        throw 'Failed to save unsupported key file version', version => $version;
    }

    $dom->toFH($fh, 1);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Key::File - A file key

=head1 VERSION

version 0.904

=head1 SYNOPSIS

    use File::KDBX::Constants qw(:key_file);
    use File::KDBX::Key::File;

    ### Create a key file:

    my $key = File::KDBX::Key::File->new(
        filepath    => 'path/to/file.keyx',
        type        => KEY_FILE_TYPE_XML,   # optional
        version     => 2,                   # optional
        raw_key     => $raw_key,            # optional - leave undefined to generate a random key
    );
    $key->save;

    ### Use a key file:

    my $key2 = File::KDBX::Key::File->new('path/to/file.keyx');
    # OR
    my $key2 = File::KDBX::Key::File->new(\$secret);
    # OR
    my $key2 = File::KDBX::Key::File->new($fh); # or *IO

=head1 DESCRIPTION

A file key (or "key file") is the type of key where the secret is a file. The secret is either the file
contents or is generated based on the file contents. In order to lock and unlock a KDBX database with a key
file, the same file must be presented. The database cannot be opened without the file.

Inherets methods and attributes from L<File::KDBX::Key>.

There are multiple types of key files supported. See L</type>. This module can read and write key files.

=head1 ATTRIBUTES

=head2 type

    $type = $key->type;

Get the type of key file. Can be one of from L<File::KDBX::Constants/":key_file">:

=over 4

=item *

C<KEY_FILE_TYPE_BINARY>

=item *

C<KEY_FILE_TYPE_HEX>

=item *

C<KEY_FILE_TYPE_XML>

=item *

C<KEY_FILE_TYPE_HASHED>

=back

=head2 version

    $version = $key->version;

Get the file version. Only applies to XML key files.

=head2 filepath

    $filepath = $key->filepath;

Get the filepath to the key file, if known.

=head1 METHODS

=head2 load

    $key = $key->load($filepath);
    $key = $key->load(\$string);
    $key = $key->load($fh);
    $key = $key->load(*IO);

Load a key file.

=head2 reload

    $key->reload;

Re-read the key file, if possible, and update the raw key if the key changed.

=head2 save

    $key->save;
    $key->save(%options);

Write a key file. Available options:

=over 4

=item *

C<type> - Type of key file (default: value of L</type>, or C<KEY_FILE_TYPE_XML>)

=item *

C<verson> - Version of key file (default: value of L</version>, or 2)

=item *

C<filepath> - Where to save the file (default: value of L</filepath>)

=item *

C<fh> - IO handle to write to (overrides C<filepath>, one of which must be defined)

=item *

C<raw_key> - Raw key (default: value of L</raw_key>)

=item *

C<atomic> - Write to the filepath atomically (default: true)

=back

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
