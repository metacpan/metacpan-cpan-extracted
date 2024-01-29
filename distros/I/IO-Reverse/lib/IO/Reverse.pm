
package IO::Reverse;

use warnings;
use strict;
use IO::File;
use Fcntl;
use Data::Dumper;

=head1 NAME

IO::Reverse - read a file in reverse

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

 Read a file from the end of file, line by line

 create a test file from the Command Line

 $  for i in $( seq 1 10 )
 do
   echo "this is $i"
 done > t.txt


Now a small test script

 use IO::Reverse;

 my $f = IO::Reverse->new( 
	 FILENAME => './t.txt'
 );

 while ( my $line = $f->next ) {
	print "$line";
 }


=cut

=head1 METHODS

There are only 2 methods: new() and next();

=head2 new

 my $f = IO::Reverse->new(
    FILENAME => './t.txt'
 );

=head2 next

Iterate through the file

 while ( my $line = $f->next ) {
   print "$line";
 }


=cut


=head1 AUTHOR

Jared Still, C<< <jkstill at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-io-reverse at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Reverse>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Reverse


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-Reverse>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/IO-Reverse>

=item * Search CPAN

L<https://metacpan.org/release/IO-Reverse>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Jared Still.

This is free software, licensed under: 

  The MIT License

=cut


use Exporter qw(import);
#our @EXPORT = qw();
our @ISA=qw(Exporter);

sub new {
	my ($class, %args) = @_;
	my $fh = IO::File->new;

	$fh->open($args{FILENAME})  || die "Reverse: could not open file: $args{FILENAME} - $!\n";
	$args{FH}=$fh;
	$args{F_SIZE} = -s $args{FILENAME};
	$args{F_OFFSET} = -2; # offset continually decrements to allow reverse seek

	# set to EOF minus offset 
	# offset to avoid the end of line/file characters
	$fh->seek($fh->getpos, SEEK_END);
	$args{F_POS} =  $fh->getpos;

	my $self = bless \%args, $class;
	return $self;
}

sub next {
	my ($self) = @_;

	my $line='';
	if ( abs($self->{F_OFFSET}) > $self->{F_SIZE}) { return undef; }

	if (abs($self->{F_OFFSET}) < $self->{F_SIZE} ) {
		while (abs($self->{F_OFFSET}) <= $self->{F_SIZE}) {
			$self->{FH}->seek($self->{F_OFFSET}, 2);  # seek backward
			$self->{F_OFFSET} -= 1;
			my $char = $self->{FH}->getc;
			last if $char eq "\n";
			$line = $char . $line; 
			# just for fun, the line will be reversed
			#$line .= $char ;
		}
	}

  return "$line\n";

}

1;


