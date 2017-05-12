package IO::Cat;

use strict;
use IO::File;
use Carp;
use vars qw($VERSION);

$VERSION = '1.01';



=head1 NAME

IO::Cat - Object-oriented Perl implementation of cat(1)

=head1 SYNOPSIS

  require IO::Cat;

  my $meow = new IO::Cat '/etc/motd';
  $meow->cat( \*STDOUT, \*STDERR )
	or die "Can't cat /etc/motd: $!";

=head1 DESCRIPTION

IO::Cat provides an intuitive, scalable, encapsulated interface to the
common task of printing to a filehandle. Use it a few times, and you'll
never know how you lived without it!

=head1 METHODS

=over

=item *

new I<FILENAME>

This constructor takes the name of a file to be catted and returns a
brand spanking new IO::Cat object. If you prefer, you can pass it no
args here and use the file() accessor method to set the filename
before calling cat().

=cut
#'

sub new {
    my ($class, $file) = @_;
    my $self = {};

    bless $self, $class;
    $self->file( $file ) if defined $file;
    
    return $self;
}


=item *

file I<FILENAME>

An accessor method that lets you set the filename or filehandle which
a particular IO::Cat object will cat. Returns the open filehandle
which it will cat from.

=cut

sub file {
    my $self = shift;

    if (@_) {
        if ($self->{fh}) {
            $self->{fh}->close();
        }
        
        $self->{file} = $_[0];
        $self->{fh} = IO::File->new( $_[0] );
        unless ($self->{fh}) {
            croak "Can't open file $_[0]: $!";
        }
    }

    return $self->{fh};
}

=item *

cat I<FILEHANDLE>

Copies data from a previously specified file to FILEHANDLE, or returns
false if an error occurred.

=cut


sub cat ($) {
	my ($self, $output) = @_;
    my $input = $self->file();
    
	while (<$input>) {
		print $output $_;
	}
    $input->seek( 0, 0 );
	
	return( 1 );
}



=pod

=item *

cattail I<FILEHANDLE>

Prints data from a previously specified file to FILEHANDLE --
backwards, line by line -- or returns false if an error occurred.

=cut



sub cattail ($) {
	my ($self, $output) = @_;
    my $input = $self->file();
	my @lines = (0);

	while (<$input>) {
		$lines[$.] = $input->tell();
	}

	pop @lines;
	while (defined ($_ = pop @lines)) {
		$input->seek( $_, 0 );
		print $output scalar(<$input>);
	}
    $input->seek( 0, 0 );

	return (1);
}



=back

=head1 AUTHOR

Dennis Taylor, E<lt>corbeau@execpc.comE<gt>

=head1 SEE ALSO

cat(1) and the File::Cat module.

=cut


1;
