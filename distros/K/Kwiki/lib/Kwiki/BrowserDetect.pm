package Kwiki::BrowserDetect;
use Kwiki::Plugin -Base;
use HTTP::BrowserDetect;

const class_id => 'browser_detect';

field 'browser_detect';

sub AUTOLOAD {
    our $AUTOLOAD;
    my ($method) = $AUTOLOAD =~ /::(\w+)$/;
    return if $method eq 'DESTROY';
    $self->browser_detect(HTTP::BrowserDetect->new)
      unless $self->browser_detect;
    $self->browser_detect->$method(@_);
}
