package MVC::Neaf::Upload;

use strict;
use warnings;

=head1 NAME

MVC::Neaf::Upload - File upload object for Not Even A Framework

=head1 METHODS

Generally, this class isn't used directly; instead, it's returned by an
L<MVC::Neaf::Request> object.

=cut

our $VERSION = 0.2601;
use Carp;
use Encode;
use PerlIO::encoding;

=head2 new(%options)

%options may include:

=over

=item * id (required) - the form id by which upload is known.

=item * tempfile - file where upload is stored.

=item * handle - file handle opened for readin. One of these is required.

=item * filename - user-supplied filename. Don't trust this.

=item * utf8 - if set, all data read from the file will be utf8-decoded.

=back

=cut

# TODO 0.30 figure out if GLOBs are worth the hassle
# We use GLOB objects so that <$upload> works as expected.
# This may turn out to be not worth it, so it's not even in the docs yet.
# See also t/*diamond*.t

my %new_opt;
my @copy_fields = qw(id tempfile filename utf8);
$new_opt{$_}++ for @copy_fields, "handle";
sub new {
    my ($class, %args) = @_;

    # TODO 0.30 add "unicode" flag to open & slurp in utf8 mode

    my @extra = grep { !$new_opt{$_} } keys %args;
    croak( "$class->new(): unknown options @extra" )
        if @extra;
    defined $args{id}
        or croak( "$class->new(): id option is required" );

    my $self;
    if ($args{tempfile}) {
        open $self, "<", $args{tempfile}
            or croak "$class->new(): Failed to open $args{tempfile}: $!";
    } elsif ($args{handle}) {
        open $self, "<&", $args{handle}
            or croak "$class->new(): Failed to dup handle $args{handle}: $!";
    } else {
        croak( "$class->new(): Either tempfile or handle option required" );
    };

    if ($args{utf8}) {
        local $PerlIO::encoding::fallback = Encode::FB_CROAK;
        binmode $self, ":encoding(UTF-8)"
    };
    bless $self, $class;

    *$self->{$_} = $args{$_}
        for @copy_fields;

    return $self;
};

=head2 id()

Return upload id.

=cut

sub id {
    my $self = shift;
    return *$self->{id};
};

=head2 filename()

Get user-supplied file name. Don't trust this value.

=cut

sub filename {
    my $self = shift;

    *$self->{filename} = '/dev/null' unless defined *$self->{filename};
    return *$self->{filename};
};

=head2 size()

Calculate file size.

B<CAVEAT> May return 0 if file is a pipe.

=cut

sub size {
    my $self = shift;

    return *$self->{size} ||= do {
        # calc size
        my $fd = $self->handle;
        my @stat = stat $fd;
        $stat[7] || 0;
    };
};

=head2 handle()

Return file handle, opening temp file if needed.

=cut

sub handle {
    my $self = shift;

    return $self;
};

=head2 content()

Return file content (aka slurp), caching it in memory.

B<CAVEAT> May eat up a lot of memory. Be careful...

B<NOTE> This breaks file current position, resetting it to the beginning.

=cut

sub content {
    my $self = shift;

    # TODO 0.30 remember where the  file was 1st time
    if (!defined *$self->{content}) {
        $self->rewind;
        my $fd = $self->handle;

        local $/;
        my $content = <$fd>;
        if (!defined $content) {
            my $fname = *$self->{tempfile} || $fd;
            croak( "Upload *$self->{id}: failed to read file $fname: $!");
        };

        $self->rewind;
        *$self->{content} = $content;
    };

    return *$self->{content};
};

=head2 rewind()

Reset the file to the beginning. Will fail silently on pipes.

Returns self.

=cut

sub rewind {
    my $self = shift;

    my $fd = $self->handle;
    seek $fd, 0, 0;
    return $self;
};

# TODO 0.30 kill the tempfile, if any?
# sub DESTROY { };

=head1 LICENSE AND COPYRIGHT

This module is part of L<MVC::Neaf> suite.

Copyright 2016-2018 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
