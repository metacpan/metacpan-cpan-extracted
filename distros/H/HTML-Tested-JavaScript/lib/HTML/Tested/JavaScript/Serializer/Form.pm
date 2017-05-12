use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript::Serializer::Form;
use base 'HTML::Tested::Value';
use HTML::Tested::JavaScript::Variable;

sub form_response {
	my ($self, $name, @args) = @_;
	my $htjv = 'HTML::Tested::JavaScript::Variable';
	my $al = join(", ", map { $htjv->encode_value($_) } @args);
	return <<ENDS
<html>
<head>
<script>
top.on_$name\_response($al);
</script>
</head>
<body></body>
</html>
ENDS
}

sub new {
	my ($class, $parent, $name, %args) = @_;
	my $self = $class->SUPER::new($parent, $name, %args);
	{
		no strict 'refs';
		*{ "$parent\::$name\_response" } = sub {
			my $par = shift;
			return $self->form_response($name, @_);
		};
	};
	return $self;
}

sub value_to_string {
	my ($self, $name, $val) = @_;
	return <<ENDS
<iframe id="$name\_iframe" name="$name\_iframe" style="display:none;"></iframe>
<form id="$name" name="$name" method="post" action="$val"
	enctype="multipart/form-data" target="$name\_iframe">
ENDS
}

1;
