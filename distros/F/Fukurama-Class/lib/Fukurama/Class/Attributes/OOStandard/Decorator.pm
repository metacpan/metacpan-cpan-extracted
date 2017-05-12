package Fukurama::Class::Attributes::OOStandard::Decorator;
use Fukurama::Class::Version(0.02);
use Fukurama::Class::Rigid;

use Fukurama::Class::HideCaller;
Fukurama::Class::HideCaller->register_class(__PACKAGE__);

=head1 NAME

Fukurama::Class::Attributes::OOStandard::Decorator - Helper-class to decorate subroutines

=head1 VERSION

Version 0.02 (beta)

=head1 SYNOPSIS

 package MyClass;
 use Fukurama::Class::Attributes::OOStandard::Decorator();
 my $helper = 'Fukurama::Class::Attributes::OOStandard::DefinitionCheck';
 
 Fukurama::Class::Attributes::OOStandard::Decorator->decorate('CGI::param', \&CGI::param, $helper);

=head1 DESCRIPTION

A Helper class for Fukurama::Class::Attributes::OOStandard::DefinitionCheck to decorate subroutines
with a subroutine to check parameters and return values and remove the decoration.

=head1 EXPORT

-

=head1 METHODS

=over 4

=item decorate( method_identifier:STRING, actual_code_reference:\CODE, definition_checker:CLASS) return:VOID

Decorates the given method with some parameter and return value checks.

=item remove_decoration( method_identifier:STRING, actual_code_reference:\CODE ) return:VOID

Remove existing decorations for parameter and return value checks.

=back

=head1 AUTHOR, BUGS, SUPPORT, ACKNOWLEDGEMENTS, COPYRIGHT & LICENSE

see perldoc of L<Fukurama::Class>

=cut

# STATIC void
sub decorate {
	my $class = $_[0];
	my $identifier = $_[1];
	my $old = $_[2];
	my $helper = $_[3];
	
	no strict 'refs';
	no warnings 'redefine';
		
	*{$identifier} = sub {
		$helper->try_check_call($identifier, $_[0]);
		$helper->try_check_access($identifier);
		$helper->try_check_abstract($identifier);
		$helper->try_check_parameter($identifier, [@_[1..$#_]]);
			
		my $context = wantarray();
		if($context) {
			my @result = &$old;
			$helper->try_check_result($identifier, \@result, $context);
			return @result;
		} elsif(defined($context)) {
			my $result = &$old;
			$helper->try_check_result($identifier, [$result], $context);
			return $result;
		} else {
			goto &$old;
		}
	};
	return;
}
# STATIC void
sub remove_decoration {
	my $class = $_[0];
	my $identifier = $_[1];
	my $old = $_[2];
	
	no strict 'refs';
	no warnings 'redefine';
	
	*{$identifier} = $old;
	return;
}
1;
