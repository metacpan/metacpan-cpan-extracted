package GFX::Enhancer::ImageByteStream;

use parent 'GFX::Enhancer::Stream';

sub new {
	my ($class, $length, $bytes) = @_;
        my $self = $class->SUPER::new($length, $bytes);

}

### public methods



1;
