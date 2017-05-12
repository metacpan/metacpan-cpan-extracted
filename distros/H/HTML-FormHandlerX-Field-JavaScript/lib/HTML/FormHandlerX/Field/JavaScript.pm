package HTML::FormHandlerX::Field::JavaScript;
# ABSTRACT: a script tag with javascript code supplied via field for HTML::FormHandler.
$HTML::FormHandlerX::Field::JavaScript::VERSION = '0.004';

use Moose;
extends 'HTML::FormHandler::Field::NoValue';
use namespace::autoclean;

use JavaScript::Minifier::XS qw();

has 'js_code' => (
	is => 'rw',
	isa     => 'Str',
	builder => 'build_js_code',
	lazy    => 1
);
sub build_js_code { '' }
has 'set_js_code' => ( isa => 'Str', is => 'ro' );
has '+do_label' => ( default => 0 );
#has '+do_wrapper' => ( default => 0 );
has 'do_minify' => ( isa => 'Bool', is => 'rw', default => 0 );

has 'render_method' => (
	traits    => ['Code'],
	is        => 'ro',
	isa       => 'CodeRef',
	lazy      => 1,
	predicate => 'does_render_method',
	handles   => { 'render' => 'execute_method' },
	builder   => 'build_render_method',
);

sub build_render_method {
	my $self = shift;

	my $set_js_code = $self->set_js_code;
	$set_js_code ||= "js_code_" . HTML::FormHandler::Field::convert_full_name( $self->full_name );
	return sub { my $self = shift; $self->wrap_js_code( $self->parent->$set_js_code($self) ); }
	  if ( $self->parent->has_flag('is_compound') && $self->parent->can($set_js_code) );
	return sub { my $self = shift; $self->wrap_js_code( $self->form->$set_js_code($self) ); }
	  if ( $self->form && $self->form->can($set_js_code) );
	return sub {
		my $self = shift;
		return $self->wrap_js_code( $self->js_code );
	};
} ## end sub build_render_method

sub _result_from_object {
	my ( $self, $result, $value ) = @_;
	$self->_set_result($result);
	$self->value($value);
	$result->_set_field_def($self);
	return $result;
}

sub wrap_js_code {
	my $self      = shift;
	my $javascript = shift;

	my $output = qq{\n<script type="text/javascript">};
	$output .= $self->do_minify ? JavaScript::Minifier::XS::minify($javascript) : "\n".$javascript;
	$output .= qq{\n</script>};

	return $output;
} ## end sub wrap_js_code



__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandlerX::Field::JavaScript - a script tag with javascript code supplied via field for HTML::FormHandler.

=head1 VERSION

version 0.004

=head1 SYNOPSIS

This class can be used for fields that need to supply JavaScript code
to control or modify the form. It will render the value returned by a
form's C<js_code_E<lt>field_nameE<gt>> method, or the field's C<js_code>
attribute.

  has_field 'user_update' => ( type => 'JavaScript',
     js_code => q`$('#fldId').on('change', myFunction);`
  );

or using a method:

  has_field 'user_update' => ( type => 'JavaScript' );
  sub js_code_user_update {
     my ( $self, $field ) = @_;
     if( $field->value == 'foo' ) {
        return q`$('#fldId').on('change', myFunction);`;
     }
     else {
        return q`$('#otherFldId').on('change', myOtherFunction);`;
     }
  }
  #----
  has_field 'usernames' => ( type => 'JavaScript' );
  sub js_code_usernames {
      my ( $self, $field ) = @_;
      return q`$('#fldId').on('change', myFunction);`;
  }

or set the name of the code generation method:

   has_field 'user_update' => ( type => 'JavaScript', set_js_code => 'my_user_update' );
   sub my_user_update {
     ....
   }

or provide a 'render_method':

   has_field 'user_update' => ( type => 'JavaScript', render_method => \&render_user_update );
   sub render_user_update {
       my $self = shift;
       ....
       return q(
   <script type="text/javascript">
     // code here
   </script>);
   }

The code generation methods should return a scalar string which will be
wrapped in script tags. If you supply your own 'render_method' then you
are responsible for calling C<$self-E<gt>wrap_data> yourself.

=head1 FIELD OPTIONS

We support the following additional field options, over what is inherited from
L<HTML::FormHandler::Field>

=over

=item js_code

String containing the JavaScript code to be rendered inside script tags.

=item set_js_code

Name of method that gets called to generate the JavaScript code.

=item do_minify

Boolean to indicate whether code should be minified using L<JavaScript::Minifier::XS>

=back

=head1 FIELD METHODS

The following methods can be called on the field.

=over

=item wrap_js_code

The C<wrap_js_code> method minifies the JavaScript code and wraps it in script tags.

=back

=head1 AUTHOR

Charlie Garrison <garrison@zeta.org.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Charlie Garrison.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
