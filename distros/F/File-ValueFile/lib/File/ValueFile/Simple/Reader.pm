# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for reading and writing ValueFile files

package File::ValueFile::Simple::Reader;

use v5.10;
use strict;
use warnings;

use Carp;
use Fcntl qw(SEEK_SET);
use URI::Escape qw(uri_unescape);

use Data::Identifier;

use constant KEYWORD_OK => qr/^[a-zA-Z0-9\-:\._~]*$/;
use constant FORMAT_ISE => '54bf8af4-b1d7-44da-af48-5278d11e8f32';

our $VERSION = v0.02;



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

        return;
    } elsif ($marker eq 'Feature') {
        my $id;

        croak 'Feature marker with wrong number of arguments' unless scalar(@args) == 1;

        push(@{$self->{features} //= []}, $id = Data::Identifier->new(ise => $args[0]));

        $self->_check_supported(supported_features => $id) if $type eq '!';

        return;
    }
    croak 'Invalid marker: '.$marker;
}


sub read_to_cb {
    my ($self, $cb) = @_;
    my $fh = $self->{fh};

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
            $self->_handle_special($type, map{
                    $_ =~ KEYWORD_OK ? $_ :
                    $_ =~ /^\!/ ? _special($_) : uri_unescape($_)
                }(split(/\s+/, $line)));
            next;
        }

        $self->$cb(map{
                $_ =~ KEYWORD_OK ? $_ :
                $_ =~ /^\!/ ? _special($_) : uri_unescape($_)
            }(split(/\s+/, $line)));
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ValueFile::Simple::Reader - module for reading and writing ValueFile files

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use File::ValueFile::Simple::Reader;

This module provides a simple way to read ValueFile files.

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

This software is Copyright (c) 2024 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
