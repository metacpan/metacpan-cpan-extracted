package Fukurama::Class::Version;
our $VERSION = 0.02;
use Fukurama::Class::Rigid;
use Fukurama::Class::Carp;

=head1 NAME

Fukurama::Class::Version - Pragma to set package-version

=head1 VERSION

Version 0.02 (beta)

=head1 SYNOPSIS

 package MyClass;
 use Fukurama::Class::Version('1.10');

=head1 DESCRIPTION

This pragma-like module provides a set method for package version. It check the correctness of version-value
at compiletime. Use Fukurama::Class instead, to get all the features for OO.

=head1 CONFIG

-

=head1 EXPORT

$YourClass::VERSION : this global variable would be set at compiletime.

=head1 METHODS

=over 4

=item version( version:DECIMAL ) return:BOOLEAN

Helper-method, which would executed by every pragma usage.

=back

=head1 AUTHOR, BUGS, SUPPORT, ACKNOWLEDGEMENTS, COPYRIGHT & LICENSE

see perldoc of L<Fukurama::Class>

=cut

# AUTOMAGIC void
sub import {
	my $class = $_[0];
	my $version = $_[1];
	
	my ($caller_class) = caller(0);
	$class->version($caller_class, $version, 1);
	return undef;
}
# boolean
sub version {
	my $class = $_[0];
	my $caller_class = $_[1];
	my $version = $_[2];
	my $import_depth = $_[3] || 0;
	
	if(!defined($version)) {
		_croak("Try to set undefined version to class '$caller_class'", $import_depth);
	} elsif($version !~ /^[0-9]+(?:[\._]?[0-9]+)*$/) {
		_croak("Try to set non-decimal version '$version' to class '$caller_class'", $import_depth);
	}
	
	no strict 'refs';
	
	${"$caller_class\::VERSION"} = $version;
	return 1;
}
1;
