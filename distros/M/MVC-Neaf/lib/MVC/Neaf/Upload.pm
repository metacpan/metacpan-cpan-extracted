package MVC::Neaf::Upload;

use strict;
use warnings;

=head1 NAME

MVC::Neaf::Upload - File upload object for Not Even A Framework

=head1 METHODS

Generally, this class isn't used directly; instead, it's returned by an
L<MVC::Neaf::Request> object.

=cut

our $VERSION = 0.17;
use Carp;

=head2 new(%options)

%options may include:

=over

=item * id (required) - the form id by which upload is known.

=item * tempfile - file where upload is stored.

=item * handle - file handle opened for readin. One of these is required.

=item * filename - user-supplied filename. Don't trust this.

=back

=cut

sub new {
    my ($class, %args) = @_;

    defined $args{id}
        or croak( "$class->new(): id option is required" );
    defined $args{tempfile} || defined $args{handle}
        or croak( "$class->new(): Either tempfile or handle option required" );

    my $self = bless \%args, $class;
    return $self;
};

=head2 id()

Return upload id.

=cut

sub id {
    my $self = shift;
    return $self->{id};
};

=head2 filename()

Get user-supplied file name. Don't trust this value.

=cut

sub filename {
    my $self = shift;

    $self->{filename} = '/dev/null' unless defined $self->{filename};
    return $self->{filename};
};

=head2 size()

Calculate file size.

B<CAVEAT> May return 0 if file is a pipe.

=cut

sub size {
    my $self = shift;

    return $self->{size} ||= do {
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

    return $self->{handle} ||= do {
        # need write?
        open my $fd, "<", $self->{tempfile}
            or die "Upload $self->{id}: Failed to open(r) $self->{tempfile}: $!";
        $fd;
    };
};

=head2 content()

Return file content (aka slurp), caching it in memory.

B<CAVEAT> May eat up a lot of memory. Be careful...

B<NOTE> This breaks file current position, resetting it to the beginning.

=cut

sub content {
    my $self = shift;

    if (!defined $self->{content}) {
        $self->rewind;
        my $fd = $self->handle;

        local $/;
        my $content = <$fd>;
        if (!defined $content) {
            my $fname = $self->{tempfile} || $fd;
            croak( "Upload $self->{id}: failed to read file $fname: $!");
        };

        $self->rewind;
        $self->{content} = $content;
    };

    return $self->{content};
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

sub DESTROY {
    # TODO kill the file
};

1;
