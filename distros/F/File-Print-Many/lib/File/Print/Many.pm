package File::Print::Many;

use warnings;
use strict;
use Carp;
use Scalar::Util;
use namespace::autoclean;
# require Tie::Handle;

=head1 NAME

File::Print::Many - Print to more than one file descriptor at once

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';
# our @ISA = ('Tie::Handle');

=head1 SYNOPSIS

Print to more than one file descriptor at once.

=head1 SUBROUTINES/METHODS

=head2 new

    use File::Print::Many;
    open(my $fout1, '>', '/tmp/foo') or die "Cannot open file: $!";
    open(my $fout2, '>', '/tmp/bar') or die "Cannot open file: $!";
    my $many = File::Print::Many->new(fds => [$fout1, $fout2]);
    print $fout1 "this only goes to /tmp/foo\n";
    $many->print("this goes to both files\n");

=cut

sub new
{
	my ($class, @args) = @_;

	Carp::croak('Usage: new(fds => \@array)') unless(defined $class);

	# Handle hash or hashref arguments
	my %args = ref $args[0] eq 'HASH' ? %{ $args[0] }
		: ref $args[0] eq 'ARRAY' ? (fds => $args[0])
		: (scalar(@args) % 2) == 0 ? @args
		: Carp::croak('Usage: new(fds => \@array)');

	# If cloning an object, merge arguments
	if(Scalar::Util::blessed($class)) {
		return bless { %$class, %args }, ref($class);
	}

	# Validate file descriptor array
	Carp::croak('Usage: new(fds => \@array)')
		if(ref($args{'fds'}) ne 'ARRAY') || (!defined @{$args{fds}}[0]);

	# Ensure all elements in fds are valid filehandles
	foreach my $fd (@{$args{fds}}) {
		Carp::croak('Invalid filehandle') unless(defined fileno($fd));
	}

	# Create the object
	return bless { _fds => $args{fds} }, $class;
}

=head2 print

Send output.

    $many->print("hello, world!\n");
    $many->print('hello, ', "world!\n");
    $many->print('hello, ')->print("world!\n");

=cut

sub print
{
	my ($self, @data) = @_;

	# Sanity check: Ensure _fds exists and is an array reference
	unless(ref($self->{'_fds'}) eq 'ARRAY') {
		Carp::croak("BUG: Invalid file descriptors: '_fds' must be an array reference");
	}

	# Print data to each file descriptor
	foreach my $fd(@{$self->{'_fds'}}) {
		unless(print $fd @data) {
			Carp::croak("Failed to write to filehandle: $!");
		}
	}

	return $self;
}

# This code would add support for this, but I don't need it
# tie *MULTI, 'File::Print::Many', fds => [$fh1, $fh2];
# print MULTI "This goes to both files\n";

# =head2 TIEHANDLE
#
# Allows the object to be tied to a filehandle.
#
# =cut
#
# sub TIEHANDLE {
    # my ($class, @args) = @_;
    # return $class->new(@args);
# }
#
# =head2 PRINT
#
# Handles the 'print' operation when tied to a filehandle.
#
# =cut
#
# sub PRINT {
    # my $self = shift;
    # $self->print(@_);
# }

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-file-print-many at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Print-Many>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Print::Many

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Print-Many>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Print-Many>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2018-2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
