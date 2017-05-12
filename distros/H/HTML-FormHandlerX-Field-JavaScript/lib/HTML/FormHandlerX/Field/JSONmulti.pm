package HTML::FormHandlerX::Field::JSONmulti;
# ABSTRACT: a script tag which sets multiple vars using JSON 'data', encoded from list of perl data supplied via field for HTML::FormHandler.
$HTML::FormHandlerX::Field::JSONmulti::VERSION = '0.004';

use Moose;
extends 'HTML::FormHandlerX::Field::JSON';
use namespace::autoclean;

use JavaScript::Minifier::XS qw();

sub wrap_data {
	my $self      = shift;
	my @data_args = @_;

	my $data_key = $self->data_key;

	my $javascript = '';

	## This whole list bit seems a bit pointless right now, why not just create and array ref and assign the one json object?
	## The plan is to allow different data_key for each list element, but sensible implementation eludes me at present (IOW, $work doesn't need it)
	## At least we're not throwing away data if given a list; of course easier solution would have simply been to make an arrayref!!
	if ( @data_args > 1 ) {
		my $idx = 0;
		if ( $data_key =~ m/.+\..+/ ) {    # key contains 'dot' properties, so don't create a var, just set property, and assume property is an array
			$javascript .= qq{\n  ${data_key} = [];};
			foreach my $data (@data_args) {
				my $json = $self->deflator($data);
				chomp $json;

				$javascript .= qq{\n  ${data_key}[$idx] = $json;};
				$idx++;
			}
		} elsif ( $data_key =~ m/.+\.$/ )
		{ # key ends with 'dot', so assume data_key is object and field_name is property, don't create a var, just set property, and assume property is an array
			my $property_key = HTML::FormHandler::Field::convert_full_name( $self->full_name );
			$javascript .= qq{\n  $data_key${property_key} = [];};
			foreach my $data (@data_args) {
				my $json = $self->deflator($data);
				chomp $json;
				$javascript .= qq{\n  $data_key${property_key}[$idx] = $json;};
				$idx++;
			}
		} elsif ( $data_key =~ m/^\..+/ )
		{ # key starts with 'dot', so assume data_key is property and field_name is object, don't create a var, just set property, and assume property is an array
			my $object_key = HTML::FormHandler::Field::convert_full_name( $self->full_name );
			$javascript .= qq{\n  $object_key${data_key} = [];};
			foreach my $data (@data_args) {
				my $json = $self->deflator($data);
				chomp $json;
				$javascript .= qq{\n  $object_key${data_key}[$idx] = $json;};
				$idx++;
			}
		} else {
			foreach my $data (@data_args) {
				my $json = $self->deflator($data);
				chomp $json;
				$javascript .= qq{\n  var ${data_key}_$idx = $json;};
				$idx++;
			}
		} ## end else [ if ( $data_key =~ m/.+\..+/ ) ]

	} else {
		my $json = $self->deflator( $data_args[0] );
		chomp $json;

		if ( $data_key =~ m/.+\..+/ ) {    # key contains 'dot' properties, so don't create a var, just set property
			$javascript .= qq{\n  $data_key = $json;};
		} elsif ( $data_key =~ m/.+\.$/ )
		{                                  # key ends with 'dot', so assume data_key is object and field_name is property, don't create a var, just set property
			my $property_key = HTML::FormHandler::Field::convert_full_name( $self->full_name );
			$javascript .= qq{\n  $data_key$property_key = $json;};
		} elsif ( $data_key =~ m/^\..+/ )
		{ # key starts with 'dot', so assume data_key is property and field_name is object, don't create a var, just set property, and assume property is an array
			my $object_key = HTML::FormHandler::Field::convert_full_name( $self->full_name );
			$javascript .= qq{\n  $object_key$data_key = $json;};
		} else {
			$javascript .= qq{\n  var $data_key = $json;};
		}

	} ## end else [ if ( @data_args > 1 ) ]

	my $output = qq{\n<script type="text/javascript">};
	$output .= $self->do_minify ? JavaScript::Minifier::XS::minify($javascript) : $javascript;
	$output .= qq{\n</script>};

	return $output;
} ## end sub wrap_data



__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandlerX::Field::JSONmulti - a script tag which sets multiple vars using JSON 'data', encoded from list of perl data supplied via field for HTML::FormHandler.

=head1 VERSION

version 0.004

=head1 AUTHOR

Charlie Garrison <garrison@zeta.org.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Charlie Garrison.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
