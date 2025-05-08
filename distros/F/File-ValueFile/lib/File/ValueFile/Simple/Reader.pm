# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for reading and writing ValueFile files

package File::ValueFile::Simple::Reader;

use v5.10;
use strict;
use warnings;

use parent 'Data::Identifier::Interface::Userdata';

use Carp;
use Fcntl qw(SEEK_SET);
use URI::Escape qw(uri_unescape);
use Encode ();

use Data::Identifier v0.06;
use File::ValueFile;

use constant {
    RE_ISE         => qr/^(?:[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}|[0-2](?:\.(?:0|[1-9][0-9]*))+|[a-zA-Z][a-zA-Z0-9\+\.\-]+:.*)$/,
    KEYWORD_OK     => qr/^[a-zA-Z0-9\-:\._~]*$/,
    FORMAT_ISE     => '54bf8af4-b1d7-44da-af48-5278d11e8f32',
    ASI_ISE        => 'ddd60c5c-2934-404f-8f2d-fcb4da88b633',
    TAGNAME_ISE    => 'bfae7574-3dae-425d-89b1-9c087c140c23',
    DOT_REPEAT_ISE => '2ec67bbe-4698-4a0c-921d-1f0951923ee6',
};

our $VERSION = v0.06;



sub new {
    my ($pkg, $in, %opts) = @_;
    my $fh;
    my $self = bless \%opts;

    if (ref $in) {
        $fh = $in;
    } else {
        open($fh, '<', $in) or croak $!;
    }

    $self->{fh} = $fh;

    foreach my $key (qw(supported_formats supported_features)) {
        $self->{$key} ||= 'all';
        if (ref($self->{$key}) ne 'ARRAY' && $self->{$key} ne 'all') {
            $self->{$key} = [$self->{$key}];
        }
        if (ref($self->{$key})) {
            foreach my $entry (@{$self->{$key}}) {
                $entry = Data::Identifier->new(ise => $entry) unless ref $entry;
            }
        }
    }

    if (ref($self->{supported_features})) {
        push(@{$self->{supported_features}}, Data::Identifier->new(ise => DOT_REPEAT_ISE));
    }

    $self->{utf8} = $opts{utf8} //= 'auto';
    if ($opts{utf8} && $opts{utf8} ne 'auto') {
        $self->{unescape} = \&_unescape_utf8;
    } else {
        $self->{unescape} = \&uri_unescape;
    }

    $self->{dot_repreat} = 0;

    return $self;
}

sub _special {
    my ($str) = @_;

    if ($str eq '!null') {
        return undef;
    } elsif ($str eq '!empty') {
        return '';
    } else {
        croak 'Invalid input';
    }
}

sub _check_supported {
    my ($self, $key, $value) = @_;
    my $list = $self->{$key};
    my $ise = $value->ise;

    return if $list eq 'all';

    foreach my $entry (@{$list}) {
        return if $entry->ise eq $ise;
    }

    croak 'Unsupported value for '.$key.': '.$ise;
}

sub _handle_special {
    my ($self, $type, $marker, @args) = @_;
    my $line = $self->{fh}->input_line_number;

    if ($marker eq 'ValueFile') {
        @args = @args[0,1] if scalar(@args) == 4 && !defined($args[-1]) && !defined($args[-2]);
        croak 'ValueFile (magic) marker at wrong line' unless $line == 1;
        croak 'ValueFile (magic) marker not marked required' unless $type eq '!';
        croak 'ValueFile (magic) marker with wrong number of arguments' unless scalar(@args) && scalar(@args) <= 2;
        croak 'ValueFile (magic) marker not using supported format' unless $args[0] eq FORMAT_ISE;

        if (scalar(@args) > 1) {
            $self->_check_supported(supported_formats => $self->{format} = Data::Identifier->new(ise => $args[1]));
        }

        $self->_check_utf8($marker => $self->{format}) if $self->{utf8} eq 'auto';

        return;
    } elsif ($marker eq 'Feature') {
        my $id;

        croak 'Feature marker with wrong number of arguments' unless scalar(@args) == 1;

        push(@{$self->{features} //= []}, $id = Data::Identifier->new(ise => $args[0]));

        $self->_check_supported(supported_features => $id) if $type eq '!';
        $self->_check_utf8($marker => $id) if $self->{utf8} eq 'auto';
        $self->{dot_repreat} ||= $id->eq(DOT_REPEAT_ISE);

        return;
    }

    croak 'Invalid marker: '.$marker;
}

sub _check_utf8 {
    my ($self, $marker, $id) = @_;
    if (File::ValueFile->_is_utf8($id)) {
        $self->{unescape} = \&_unescape_utf8;
        $self->{utf8} = 1;
    }
}


sub read_to_cb {
    my ($self, $cb) = @_;
    my $fh = $self->{fh};
    my $unescape = $self->{unescape};
    my @last_line;

    $fh->seek(0, SEEK_SET);
    $fh->input_line_number(0);

    delete $self->{format};
    delete $self->{features};

    while (my $line = <$fh>) {
        $line =~ s/\r?\n$//;
        $line =~ s/#.*$//;
        $line =~ s/^\xEF\xBB\xBF//; # skip BOMs.
        $line =~ s/\s+/ /g;
        $line =~ s/ $//;
        $line =~ s/^ //;

        next unless length $line;

        if ($line =~ s/^\!([\!\?\&])//) {
            my $type = $1;

            if ($self->{dot_repreat}) {
                my @line = split(/\s+/, $line);
                my $x = 0;
                foreach my $e (@line) {
                    if ($e eq '.') {
                        $e = $last_line[$x];
                    } elsif ($e =~ s/^\.\.+$//) {
                        # done in match
                    } elsif ($e =~ KEYWORD_OK) {
                        # no-op
                    } elsif ($e =~ /^\!/) {
                        $e = _special($_);
                    } else {
                        $e = $unescape->($e);
                    }
                    $x++;
                }

                $self->_handle_special($type, @line);
                @last_line = @line;
            } else {
                $self->_handle_special($type, map{
                        $_ =~ KEYWORD_OK ? $_ :
                        $_ =~ /^\!/ ? _special($_) : $unescape->($_)
                    }(split(/\s+/, $line)));
            }

            # Reload:
            $unescape = $self->{unescape};

            next;
        }

        if ($self->{dot_repreat}) {
            my @line = split(/\s+/, $line);
            my $x = 0;
            foreach my $e (@line) {
                if ($e eq '.') {
                    $e = $last_line[$x];
                } elsif ($e =~ /^\.+$/) {
                    $e =~ s/^\.//;
                } elsif ($e =~ KEYWORD_OK) {
                    # no-op
                } elsif ($e =~ /^\!/) {
                    $e = _special($e);
                } else {
                    $e = $unescape->($e);
                }
                $x++;
            }

            $self->$cb(@line);
            @last_line = @line;
        } else {
            $self->$cb(map{
                    $_ =~ KEYWORD_OK ? $_ :
                    $_ =~ /^\!/ ? _special($_) : $unescape->($_)
                }(split(/\s+/, $line)));
        }
    }
}


sub read_as_hash {
    my ($self) = @_;
    my %hash;

    $self->read_to_cb(sub {
            my (undef, @line) = @_;
            croak 'Invalid data: Not key-value' unless scalar(@line) == 2;
            croak 'Invalid data: Null key' unless defined($line[0]);
            croak 'Invalid data: Duplicate key: '.$line[0] if exists $hash{$line[0]};
            $hash{$line[0]} = $line[1];
        });

    return \%hash;
}


sub read_as_hash_of_arrays {
    my ($self) = @_;
    my %hash;

    $self->read_to_cb(sub {
            my (undef, @line) = @_;
            croak 'Invalid data: Not key-value' unless scalar(@line) == 2;
            croak 'Invalid data: Null key' unless defined($line[0]);
            push(@{$hash{$line[0]} //=[]}, $line[1]);
        });

    return \%hash;
}


sub read_as_simple_tree {
    my ($self) = @_;
    my $tree;

    $self->read_to_cb(sub {
            my (undef, @line) = @_;
            my $root = \$tree;

            while (scalar(@line) > 1) {
                my $el = shift(@line);

                if (ref(${$root})) {
                    $root = \${$root}->{$el};
                } else {
                    ${$root} = {
                        (defined(${$root}) ? (_ => ${$root}) : ()),
                        $el => undef,
                    };
                    $root = \${$root}->{$el};
                }
            }

            if (ref(${$root}) eq 'ARRAY') {
                push(@{${$root}}, @line);
            } elsif (defined ${$root}) {
                croak 'Invalid data with mixed number of levels' if ref ${$root};
                ${$root} = [${$root}, @line];
            } else {
                ${$root} = $line[0];
            }
        });

    return $tree;
}


sub read_as_taglist {
    state $tagpool_source_format = Data::Identifier->new(uuid => 'e5da6a39-46d5-48a9-b174-5c26008e208e', displayname => 'tagpool-source-format');
    state $tagpool_taglist_format_v1 = Data::Identifier->new(uuid => 'afdb46f2-e13f-4419-80d7-c4b956ed85fa', displayname => 'tagpool-taglist-format-v1');
    state $tagpool_httpd_htdirectories_format = Data::Identifier->new(uuid => '25990339-3913-4b5a-8bcf-5042ef6d8b5e', displayname => 'tagpool-httpd-htdirectories-format');
    my ($self) = @_;
    my %list;
    my $format;

    $self->read_to_cb(sub {
            my (undef, @line) = @_;
            my $tag;

            $format //= $self->format(default => undef);

            if ((Data::Identifier::eq($format, $tagpool_source_format) || Data::Identifier::eq($format, $tagpool_taglist_format_v1)) && scalar(@line) >= 2 && defined($line[0]) && defined($line[1])) {
                if ($line[0] eq 'tag' && scalar(@line) == 3) {
                    $tag = Data::Identifier->new(ise => $line[1], displayname => $line[2]);
                } elsif ($line[0] eq 'tag-metadata' && scalar(@line) == 7 && defined($line[2]) && !defined($line[3]) && defined($line[4]) && !defined($line[5]) && defined($line[6]) && $line[2] eq ASI_ISE && $line[4] eq TAGNAME_ISE) {
                    $tag = Data::Identifier->new(ise => $line[1], displayname => $line[6]);
                } elsif ($line[0] =~ /^tag(?:-.+)?$/ || $line[0] eq 'rule' || $line[0] eq 'filter' || $line[0] eq 'subject') {
                    $tag = Data::Identifier->new(ise => $line[1]);
                }
            } elsif (Data::Identifier::eq($format, $tagpool_httpd_htdirectories_format) && scalar(@line) == 3 && defined($line[0]) && defined($line[1]) && defined($line[2]) && $line[0] eq 'directory') {
                $tag = Data::Identifier->new(ise => $line[1]);
            } elsif (!defined($format)) {
                if (scalar(@line) > 1 && defined($line[0]) && defined($line[1]) && $line[0] =~ /^tag-(?:ise|metadata|relation)$/) {
                    if ($line[0] eq 'tag-metadata' && scalar(@line) == 7 && defined($line[2]) && !defined($line[3]) && defined($line[4]) && !defined($line[5]) && defined($line[6]) && $line[2] eq ASI_ISE && $line[4] eq TAGNAME_ISE) {
                        $tag = Data::Identifier->new(ise => $line[1], displayname => $line[6]);
                    } else {
                        $tag = Data::Identifier->new(ise => $line[1]);
                    }
                } elsif ($line[0] eq 'tag' && scalar(@line) == 3) {
                    $tag = Data::Identifier->new(ise => $line[1], displayname => $line[2]);
                }

                unless (defined $tag) {
                    foreach my $entry (@line) {
                        if (defined($entry) && $entry =~ RE_ISE) {
                            my $tag = Data::Identifier->new(ise => $entry);
                            $list{$tag->ise} //= $tag;
                        }
                    }
                }
            }

            if (defined $tag) {
                my $ise = $tag->ise;
                my $old = $list{$ise};

                if (defined $old) {
                    $tag = $old if defined $old->displayname(default => undef, no_defaults => 1);
                }

                $list{$tag->ise} = $tag;
            }
        });

    return [values %list];
}


#@returns Data::Identifier
sub format {
    my ($self, %opts) = @_;
    return $self->{format} if defined $self->{format};
    return $opts{default} if exists $opts{default};
    croak 'No value for format';
}


sub features {
    my ($self, %opts) = @_;
    return @{$self->{features}} if defined $self->{features};
    return @{$opts{default}} if exists $opts{default};
    croak 'No value for features';
}


# ---- Private helpers ----

sub _unescape_utf8 {
    my ($text) = @_;
    state $utf8 = Encode::find_encoding('UTF-8');
    return $utf8->decode(uri_unescape($text));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ValueFile::Simple::Reader - module for reading and writing ValueFile files

=head1 VERSION

version v0.06

=head1 SYNOPSIS

    use File::ValueFile::Simple::Reader;

This module provides a simple way to read ValueFile files.

This module inherit from L<Data::Identifier::Interface::Userdata>.

=head1 METHODS

=head2 new

    my $reader = File::ValueFile::Simple::Reader->new($in [, %opts ]);

Opens a reader for the given input file.
C<$in> can be an open file handle that must support seeking or a filename.

This method dies on any problem.

In addition the following options (all optional) are supported:

=over

=item C<supported_formats>

The list of supported formats. This can be a single format, a arrayref of formats, or C<'all'>.
Formats can be given by ISE or as L<Data::Identifier>.

=item C<supported_features>

The list of supported features. This can be a single format, a arrayref of formats, or C<'all'>.
Formats can be given by ISE or as L<Data::Identifier>.

=item C<utf8>

The UTF-8 flag for the decoded data. If set to true, values are decoded as UTF-8.
If set to (non-C<undef>) false values are decoded as 8-bit strings (binary).
If set to C<auto> the UTF-8 flag is automatically detected using the format and features.
This is the default.

=back

=head2 read_to_cb

    $reader->read_to_cb(sub {
        my ($reader, @line) = @_;
        # ...
    });

Reads the file calling a callback for every data line (record).
The callback is passed the reader as first argument and the line as the rest of the arguments.

=head2 read_as_hash

    my $hashref = $reader->read_as_hash;

Reads the file as a hash. This is only possible if the file contains only key-value pairs.
If there are more than one value for any given key this method fails. If that is needed L</read_as_hash_of_arrays> can be used.

If there is any error, this method dies.

=head2 read_as_hash_of_arrays

    my $hashref = $reader->read_as_hash_of_arrays;

Reads the file into a hash of arrays. Each hash element is a reference to an array of all values for the given key.
If only one value is valid per key consider using L</read_as_hash>.

If there is any error, this method dies.

=head2 read_as_simple_tree

    my $tree = $reader->read_as_simple_tree;

Reads the file into a simple tree. This is similar to L</read_as_hash_of_arrays> however allowing for multiple levels of keys.
Each element on any of the levels of the tree can be a reference to a hash if there are more levels,
a reference to an array if there are multiple values,
or a scalar holding the actual value.

For every branch values must be on the same level. Values and subkeys on the same level are not permitted.

If there is any error, this method dies.

=head2 read_as_taglist

    my $list = $reader->read_as_taglist;

Reads the file as a tag list. Returns the list of found tags as an arrayref of L<Data::Identifier> elements.

This method supports a number of standard formats.
If the format is not known the code falls back to a generic handler.

If there is any error, this method dies.

See also:
L<File::ValueFile::Simple::Writer/write_taglist>.

=head2 format

    my Data::Identifier $format = $reader->format;
    # or:
    my Data::Identifier $format = $reader->format(default => $def);

Returns the format of the file. This requires the file to be read first.
If no format is set yet the default is returned.
If no default is given this method dies.

=head2 features

    my @features = $reader->features;
    # or:
    my @features = $reader->features(default => [...]);

Returns the list of features requested by the file. This requires the file to be read first.
If no features are requested the default is returned.
If no default is given this method dies.

Elements of the list returned are instances L<Data::Identifier>.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
