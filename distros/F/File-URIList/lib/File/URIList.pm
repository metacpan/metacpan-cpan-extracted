# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for reading and writing RFC 2483 URI lists

package File::URIList;

use v5.20;
use strict;
use warnings;

use Fcntl qw(SEEK_SET);
use URI;
use URI::file;
use Carp;
use parent qw(Data::Identifier::Interface::Userdata Data::Identifier::Interface::Subobjects);

use constant {
    CRLF => "\015\012",
};

our $VERSION = v0.04;

my %_check_defaults = (
    blank_lines => 'die',
    extra_spaces => 'die',
    no_scheme => 'die',
    slash_as_local => undef,
);



#@returns __PACKAGE__
sub new {
    my ($pkg, $handle, %opts) = @_;
    my %check = %_check_defaults;
    my $self = bless {check => \%check}, $pkg;

    foreach my $key (keys %_check_defaults) {
        if (exists $opts{$key}) {
            $check{$key} = delete $opts{$key};
        }
    }

    if (defined(my $baseuri = delete $opts{baseuri})) {
        $baseuri = URI->new($baseuri) unless eval { $baseuri->isa('URI') };
        $self->{baseuri} = $baseuri;
    }

    croak 'Stray options passed' if scalar keys %opts;

    unless (ref $handle) {
        open(my $fh, '<', $handle) or die $!;
        $handle = $fh;
    }

    binmode($handle) or die $!;

    $self->{fh} = $handle;

    return $self;
}


sub write_comment {
    my ($self, @list) = @_;
    my $fh = $self->{fh};

    foreach my $ent (@list) {
        if (ref($ent) eq 'ARRAY') {
            $self->write_comment(@{$ent});
        } elsif (ref($ent)) {
            print $fh '# ';
            $self->write_list($ent);
        } else {
            foreach my $line (split/\015?\012/, $ent) {
                print $fh '# ', $line, CRLF;
            }
        }
    }
}


sub write_list {
    my ($self, @list) = @_;
    my $fh = $self->{fh};

    foreach my $ent (@list) {
        if (ref($ent) eq 'ARRAY') {
            $self->write_list(@{$ent});
        } elsif (ref($ent)) {
            if ($ent->isa('URI')) {
                print $fh $ent->as_string, CRLF;
            } elsif ($ent->isa('Data::Identifier')) {
                print $fh $ent->uri, CRLF;
            } elsif ($ent->isa('Data::URIID::Result')) {
                print $fh $ent->url, CRLF;
            } elsif ($ent->isa('Data::URIID::Base') || $ent->isa('Data::Identifier::Interface::Simple')) {
                print $fh $ent->as('uri'), CRLF;
            } elsif ($ent->isa('Data::Identifier::Cloudlet')) {
                $self->write_list($ent->roots);
            } elsif ($ent->isa(__PACKAGE__)) {
                $ent->read_to(sub {
                        print $fh $_[1]->as_string, CRLF;
                    });
            } else {
                croak 'Unsupported object passed';
            }
        } else {
            print $fh URI->new($ent)->as_string, CRLF;
        }
    }
}


sub read_to {
    my ($self, $cb, %opts) = @_;
    my $fh = $self->{fh};
    my $as = delete($opts{as}) // 'URI';

    croak 'Stray options passed' if scalar keys %opts;

    # Preload modules as needed:
    if ($as ne 'URI') {
        require Data::Identifier;
    }

    if (ref($cb) eq 'ARRAY') {
        my $list = $cb;
        $cb = sub { push(@{$list}, $_[1]) };
    }

    while (defined(my $line = <$fh>)) {
        $line =~ s/\015?\012$//;

        next if $line =~ /^#/;

        if ($line =~ /^\s/ || $line =~ /\s$/) {
            my $action = $self->{check}{extra_spaces} // '';

            if ($action eq 'die') {
                croak 'Input line with extra spaces, aborting';
            } elsif ($action eq 'trim') {
                $line =~ s/^\s+//;
                $line =~ s/\s+$//;
            } elsif ($action eq 'pass') {
                # no-op
            } else {
                croak 'Input line with extra spaces and bad handling action selected: '.$action;
            }
        }

        if ($line eq '') {
            my $action = $self->{check}{blank_lines} // '';

            if ($action eq 'die') {
                croak 'Blank line in input, aborting';
            } elsif ($action eq 'skip') {
                next;
            } elsif ($action eq 'undef') {
                $cb->($self, undef);
                next;
            } elsif ($action eq 'pass') {
                # no-op
            } else {
                croak 'Blank line in input and bad handling action selected: '.$action;
            }
        }

        if ($line =~ /^\// && $self->{check}{slash_as_local}) {
            $line = URI::file->new($line);
        }

        if (!ref($line) && !defined($self->{baseuri}) && $line !~ /^[a-zA-Z][a-zA-Z0-9\+\.\-]+:/) {
            my $action = $self->{check}{no_scheme} // '';

            if ($action eq 'die') {
                croak 'URI with no scheme, aborting';
            } elsif ($action eq 'pass') {
                # no-op
            } else {
                croak 'URI with no scheme and bad handling action selected: '.$action;
            }
        }

        unless (ref $line) {
            if (defined $self->{baseuri}) {
                $line = URI->new_abs($line, $self->{baseuri});
            } else {
                $line = URI->new($line);
            }
        }

        if ($as ne 'URI') {
            $line = $line->Data::Identifier::as($as);
        }

        $cb->($self, $line);
    }
}


sub read_as_list {
    my ($self, %opts) = @_;
    my $list = [];
    my $listas = delete $opts{listas};

    delete $opts{list}; # we are always in list mode

    $self->read_to($list, %opts);

    if (defined($listas)) {
        require Data::Identifier::Cloudlet;
        $list = Data::Identifier::Cloudlet->new(root => $list)->as($listas);
    }

    return $list;
}


sub rewind {
    my ($self) = @_;
    my $fh = $self->{fh};

    $fh->seek(0, SEEK_SET) or die $!;
    $fh->input_line_number(1);
}


sub clear {
    my ($self) = @_;
    my $fh = $self->{fh};

    $self->rewind;

    $fh->truncate(0);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::URIList - module for reading and writing RFC 2483 URI lists

=head1 VERSION

version v0.04

=head1 SYNOPSIS

    use File::URIList;

This module implements an interface to URI lists as defined by RFC 2483.

All methods in this module C<die> on error unless documented otherwise.

This module inherits from L<Data::Identifier::Interface::Userdata>, and L<Data::Identifier::Interface::Subobjects>.

=head1 METHODS

=head2 new

    my File::URIList $list = File::URIList->new($handle [, %opts ] );
    # or:
    my File::URIList $list = File::URIList->new($filename [, %opts ] );

Creates a new instance of a list object.

The possible access (read or write) depends on the mode C<$handle> was opened as.
If a filename (not a ref) is given, the file is opened for reading.

B<Note:>
The handle is automatically set to binary mode. See L<perlfunc/binmode> for details.

The following options are supported:

=over

=item C<blank_lines>

Defines how blank lines are handled.
One of
C<die> (default, recommended; aborts parsing),
C<skip> (skips blank lines),
C<undef> (passes them as undef), or
C<pass> (pass them on to L<URI>. This what RFC 2483 specifies, but often hides errors).

Applies to reading lists only.

=item C<extra_spaces>

Defines how extra spaces (spaces at begin or end of lines) are handled.

One of
C<die> (default, recommended; aborts parsing),
C<trim> (removes extra spaces), or
C<pass> (pass them on to L<URI>. This what RFC 2483 specifies, but often hides errors).

Applies to reading lists only.

=item C<no_scheme>

Defines how URIs with no scheme are handled.

One of
C<die> (default, recommended; aborts parsing),
C<pass> (pass them on to L<URI>. This what RFC 2483 specifies, but often hides errors).

Applies to reading lists only.

=item C<slash_as_local>

Defines how URIs that begin with a slash are handled.

If true the URIs are considerd local filenames (and parsed as such), if false (default) they are parsed as URIs.

Applies to reading lists only.

=item C<baseuri>

Sets the base URI for all relative URIs in the list. If set all URIs are converted to absolute URIs.
Must be an absolute L<URI> or URI string.

Applies to reading lists only.

B<Note:>
It is undefined how this interacts with C<slash_as_local> if C<slash_as_local> is set true.

B<Note:>
This will disable the check as defined by C<no_scheme> (acting like it was set to C<pass>).

B<Note:>
This option is very helpful if one tries to parse M3U files.

=back

=head2 write_comment

    $list->write_comment($comment0, $comment1, ...);
    # or:
    $list->write_comment([$comment0, $comment1, ...]);

Writes zero or more comments to the file.
Takes plain strings, or any object also supported by L</write_list>.

If the value is a plain string and contains new lines this method will create a multi-line comment.

=head2 write_list

    $list->write_list($uri0, $uri1, ...);
    # or:
    $list->write_list([$uri0, $uri1, ...]);

Writes the given URIs to the list.
This method can be called multiple times to add more URIs.

Currently
L<URI>,
L<Data::Identifier>,
L<Data::Identifier::Cloudlet>,
L<Data::Identifier::Interface::Simple>,
L<Data::URIID::Base> (including L<Data::URIID::Result>), and
L<File::URIList>
objects are supported. Other types might as well be supported.
If a URI is a plain string it is automatically converted using L<URI/new>.

=head2 read_to

    $list->read_to(sub { ... } [, %opts ] );

Reads the list, running a given callback for every entry.

The callback is called with C<$list> as first argument, and the URI as second argument.

The following, all optional, options are supported:

=over

=item C<as>

Tries to convert the resulting entries to the given type. This is implemented using L<Data::Identifier/as>.
See there for all supported values.
At least L<URI> (default) is supported, as well as L<Data::Identifier> (if installed).

=back

=head2 read_as_list

    my $entries = $list->read_as_list( [ %opts ] );

Reads the list into memory and returns an array ref with the elements of the list.

The following, all optional, options are supported. In addition all options from L</read_to> are supported.

=over

=item C<list>

Ignored for compatibility.

=item C<listas>

Converts the returned list to the given type (if any).
The default (C<undef>) is to return an arrayref.
If set to non-C<undef> value L<Data::Identifier::Cloudlet/as> is used to convert.

=back

=head2 rewind

    $list->rewind;

Rewinds the list.
This can be used to re-read the list from the start or read a list after it has been written.

B<Note:>
This method requires the filehandle (or file) passed to L</new> to be seekable.
If seeks cannot be performed this method C<die>s.

B<Note:>
If the list starts at some offset into the filehandle this method cannot be used.

B<Note:>
If you rewind and then write you may corrupt the list as this does not clear already existing data.

=head2 clear

    $list->clear;

Clears the list. This will delete all entries from the list.

B<Note:>
All limitation of L</rewind> apply. In addition the filehande (or file) passed to L</new> also needs to support changes in size.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
