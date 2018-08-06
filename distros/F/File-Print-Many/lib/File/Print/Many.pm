package File::Print::Many;

use warnings;
use strict;
use Carp;
use namespace::autoclean;
require Tie::Handle;

=head1 NAME

File::Print::Many - Print to more than one file descriptor at once

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our @ISA = ('Tie::Handle');

=head1 SYNOPSIS

Print to more than one file descriptor at once.

=head1 SUBROUTINES/METHODS

=head2 new

	my $many = File::Print::Many(fds => [$fout1, $fout2]);

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	my %params;
	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(ref($_[0]) eq 'ARRAY') {
		$params{'fds'} = shift;
	# } elsif(ref($_[0])) {
		# Carp::croak('Usage: new(fds => \@array)');
	} elsif(scalar(@_) % 2 == 0) {
		%params = @_;
	} else {
		Carp::croak('Usage: new(fds => \@array)');
	}

	if((ref($params{fds}) ne 'ARRAY') ||
	   !defined(@{$params{fds}}[0])) {
		Carp::croak('Usage: new(fds => \@array)');
	}

	return bless {
		_fds => $params{'fds'}
	}, $class;
}

=head2 print

Send output.

	$many->print("hello, world!\n");

=cut

# sub PRINT {
	# my $self = shift;
# 
	# foreach my $fd(@{$self->{'_fds'}}) {
		# print $fd @_;
	# }
# }

# sub TIEHANDLE {
	# bless \"$_[0]",$_[0];
# }

sub print {
	my $self = shift;
	my @data = @_;

	foreach my $fd(@{$self->{'_fds'}}) {
		print $fd @data;
	}
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-print-many at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Print-Many>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<HTTP::BrowserDetect>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Print::Many

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Print-Many>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Print-Many>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Print-Many>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Print-Many/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Nigel Horne.

This program is released under the following licence: GPL

=cut

1;
