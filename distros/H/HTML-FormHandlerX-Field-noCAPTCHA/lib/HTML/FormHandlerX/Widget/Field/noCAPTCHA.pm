package HTML::FormHandlerX::Widget::Field::noCAPTCHA;

use Moose::Role;
use namespace::autoclean;

our $VERSION = '0.12'; # VERSION

sub render_element { return shift->_nocaptcha->html; }

sub render {
	my ( $self, $result ) = @_;
	$result ||= $self->result;
	my $output = $self->_nocaptcha->html;
	return $self->wrap_field( $result, $output );
}

1;
