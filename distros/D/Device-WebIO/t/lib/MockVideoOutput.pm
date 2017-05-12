package MockVideoOutput;
use v5.12;
use Moo;

has 'stream_vid_file', is => 'ro';
has 'content_type',    is => 'ro';
has '_vid_width',       is => 'ro', default => sub {[]};
has '_vid_height',      is => 'ro', default => sub {[]};
has '_vid_fps',         is => 'ro', default => sub {[]};
has '_vid_kbps',        is => 'ro', default => sub {[]};
with 'Device::WebIO::Device::VideoOutput';


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
    my ($self, $pin) = @_;
    my $file = $self->stream_vid_file;
    open( my $fh, '<', $file ) or die "Can't open '$file': $!\n";
    return $fh;
}

1;
__END__

