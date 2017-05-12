package MockVideoOutputCallback;
use v5.12;
use Moo;

has 'stream_vid_file', is => 'ro';
has 'content_type',    is => 'ro';
has '_vid_width',       is => 'ro', default => sub {[]};
has '_vid_height',      is => 'ro', default => sub {[]};
has '_vid_fps',         is => 'ro', default => sub {[]};
has '_vid_kbps',        is => 'ro', default => sub {[]};
has '_callbacks',       is => 'ro', default => sub {[]};
with 'Device::WebIO::Device::VideoOutputCallback';


sub pin_desc
{
    # Placeholder
}

sub all_desc
{
    # Placeholder
}


sub vid_channels { 1 }

sub vid_width  { $_[0]->_vid_width ->[$_[1]] }
sub vid_height { $_[0]->_vid_height->[$_[1]] }
sub vid_fps    { $_[0]->_vid_fps   ->[$_[1]] }
sub vid_kbps   { $_[0]->_vid_kbps  ->[$_[1]] }

sub vid_set_width  { $_[0]->_vid_width ->[$_[1]] = $_[2] }
sub vid_set_height { $_[0]->_vid_height->[$_[1]] = $_[2] }
sub vid_set_fps    { $_[0]->_vid_fps   ->[$_[1]] = $_[2] }
sub vid_set_kbps   { $_[0]->_vid_kbps  ->[$_[1]] = $_[2] }

sub vid_allowed_content_types { ($_[0]->content_type) };

sub vid_stream
{
    # placeholder
}

sub vid_stream_callback
{
    my ($self, $pin, $type, $callback) = @_;
    push @{ $self->_callbacks }, $callback;
    return 1;
}

sub vid_stream_begin_loop
{
    my ($self) = @_;
    # placeholder
    return 1;
}

sub trigger
{
    my ($self) = @_;
    $_->() for @{ $self->_callbacks };
    return 1;
}


1;
__END__

