package MockStillImageOutput;
use v5.12;
use Moo;

has 'file',         is => 'ro';
has 'content_type', is => 'ro';
has '_img_width',   is => 'ro', default => sub {[]};
has '_img_height',  is => 'ro', default => sub {[]};
has '_img_quality', is => 'ro', default => sub {[100]};
has '_img_fps',     is => 'ro', default => sub {[]};
has '_img_kbps',    is => 'ro', default => sub {[]};
with 'Device::WebIO::Device::StillImageOutput';


sub pin_desc
{
    # Placeholder
}

sub all_desc
{
    # Placeholder
}


sub img_channels { 1 }

sub img_width   { $_[0]->_img_width  ->[$_[1]] }
sub img_height  { $_[0]->_img_height ->[$_[1]] }
sub img_quality { $_[0]->_img_quality->[$_[1]] }

sub img_set_width   { $_[0]->_img_width  ->[$_[1]] = $_[2] }
sub img_set_height  { $_[0]->_img_height ->[$_[1]] = $_[2] }
sub img_set_quality { $_[0]->_img_quality->[$_[1]] = $_[2] }

sub img_allowed_content_types { ($_[0]->content_type) };

sub img_stream
{
    my ($self, $pin) = @_;
    my $file = $self->file;
    open( my $fh, '<', $file ) or die "Can't open '$file': $!\n";
    return $fh;
}

1;
__END__

