package Fukurama::Class::Rigid;
our $VERSION = 0.02;
use strict;
use warnings;
use Fukurama::Class::Carp;

our $PACKAGE_NAME_CHECK = 1;
our $DISABLE = 0;

=head1 NAME

Fukurama::Class::Rigid - Pragma to set strict and warnings pragma and check classnames

=head1 VERSION

Version 0.02 (beta)

=head1 SYNOPSIS

 package MyClass;
 use Fukurama::Class::Rigid;

=head1 DESCRIPTION

This pragma-like module provides set the B<strict> and B<warnings> pragma in the caller module. It will also
check the class- and filename of the package and croak at compiletime, if they are inconsistent.

=head1 CONFIG

You can disable the class- and filename check by setting. You have to do this at compiletime BEFORE any
B<use Fukurama::Class::Rigid;> is executed.

 $Fukurama::Class::Rigid::PACKAGE_NAHE_CHECK = 0;

You even can disable warnings by saying:

 $Fukurama::Class::Rigid::DISABLE = 1;

to speed up your code (Warnings are even executed at runtime).

=head1 EXPORT

nothing, bit the behavior of the strict and warnings pragmas.

=head1 METHODS

=over 4

=item rigid( import_depth:INT ) return:VOID

export warning() and strict() behavior to the caller and check the package name of callers class. With the
import_depht parameter you can define for which caller, the first, second etc, this behavior should be exported.

B<ATTENTION!> This method can only be called inside of an B<import()> method at compiletime. Otherwise warnings() and
strict() would not work.

=back

=head1 AUTHOR, BUGS, SUPPORT, ACKNOWLEDGEMENTS, COPYRIGHT & LICENSE

see perldoc of L<Fukurama::Class>

=cut


# AUTOMAGIC void
sub import {
	my $class = $_[0];
	my $import_depth = $_[1] || 0;
	
	$class->rigid($import_depth + 1);
	return undef;
}
# boolean
sub rigid {
	my $class = $_[0];
	my $import_depth = $_[1] || 0;
	
	strict::import();
	warnings::import() if(!$DISABLE);
	if($PACKAGE_NAME_CHECK) {
		my $caller = [caller($import_depth)];
		if($caller->[0] ne 'main' && $caller->[0] ne '__ANON__' && $caller->[1] !~ m/^\(eval.+\)$/) {
			my $filename = $class->_guess_packagename($caller->[1]);
			$filename =~ s/\.[a-z]*$//i;
			$filename =~ s/^\.+\/+//;

			my @path = split(/[\/\\]/, $filename);
			my $should = join('::', splice(@path, 0, scalar(@path)));
			if($should ne $caller->[0]) {
				_croak("Wrong package name '$caller->[0]'. " . ($should ? "You should use '$should'" : "Can't guess correct package name. Maybe an inline-class or a test?."), $import_depth);
			}
		}
	}
	return 1;
}
# string
sub _guess_packagename {
	my $class = $_[0];
	my $filename = $_[1];
	
	do {
		return $filename if($INC{$filename});
	} while($filename =~ s/^[^\/]*\///);
	return '';
}
1;
