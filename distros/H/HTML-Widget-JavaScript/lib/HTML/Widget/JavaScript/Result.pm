package HTML::Widget::JavaScript::Result;

use warnings;
use strict;

use base 'HTML::Widget::Result';
__PACKAGE__->mk_attr_accessors(qw/onsubmit/);

=head1 NAME

HTML::Widget::JavaScript::Result - Result Class which supports JavaScript parameter validation

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This module adds the ability to output JavaScript validation code to 
L<HTML::Widget::Result>.

=head1 FUNCTIONS

See L<HTML::Widget::Result>.

=cut

=head2 $self->as_xml

Returns the widget's XML representation, including JavaScript validation code.

=cut

sub as_xml {
	my $self = shift;
	
	my $id = $self->name;

	# stop function taken from prototype.js
	my $js_code = <<EOJS;
<script type="text/javascript">
function __html__widget__validate__$id (event) {
	var form = document.getElementById('$id');
	var stop = function() {
		if (event.preventDefault) {
			event.preventDefault();
			event.stopPropagation();
		} else {
			event.returnValue = false;
			event.cancelBubble = true;
		}
	};

EOJS

	for my $constraint ( @{ $self->{_constraints} } ) {
		next unless UNIVERSAL::can($constraint, 'emit_javascript');
		for my $js_const ($constraint->emit_javascript('form')) {
			my $msg = $constraint->message;
			$msg =~ s/'/\\'/g;
			$msg =~ s/\\$/\\\\/;
			$js_code .= "	if $js_const { alert('$msg'); stop(); return false; }\n";
		}
		$js_code .= "\n";
	}

	$js_code .= <<EOJS;
	
	return true;
}
</script>
EOJS
	
	$self->onsubmit("__html__widget__validate__$id(event)");
	return $js_code . $self->SUPER::as_xml;
}

=head1 AUTHOR

Nilson Santos Figueiredo Júnior, C<< <nilsonsfj at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests directly to the author.
If you ask nicely it will probably get fixed or implemented.

=head1 COPYRIGHT & LICENSE

Copyright 2006, 2009 Nilson Santos Figueiredo Júnior, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::Widget::JavaScript::Result
