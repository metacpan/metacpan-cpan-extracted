
package IO::Reverse;

use v5.14;

use warnings;
use strict;
# the following only used for development
#use Data::Dumper;
#use lib './lib';  # local Verbose.pm
#use Verbose;

=head1 NAME

IO::Reverse - read a file in reverse

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

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
    {
       FILENAME => './t.txt'
    }
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
	my ($class, $args) = @_;

	open(my $fh,'<', $args->{FILENAME})  || die "Reverse: could not open file: $args->{FILENAME} - $!\n";
	$args->{FH}=$fh;
	$args->{F_SIZE} = -s $args->{FILENAME};
	# offset starts at penultimate character in file

	# uncomment if Verbose.pm needed again
	#$args->{verbose} = Verbose->new(
		#{
			#VERBOSITY=>$args->{VERBOSITY},
			#LABELS=>1,
			#TIMESTAMP=>0,
			##HANDLE=>*STDERR
			#HANDLE=>*STDOUT
		#} 
	#);

	$args->{DEBUG} ||= 0;
	$args->{CHUNKSIZE} ||= 2**20;

	# extra initial offset to avoid reading EOF	
	$args->{F_OFFSET} = ($args->{CHUNKSIZE}+1) * -1; # offset continually decrements to allow reverse seek

	if ( $args->{CHUNKSIZE} >= abs($args->{F_SIZE}) ) {
		$args->{CHUNKSIZE} = $args->{F_SIZE} ; 
		$args->{F_OFFSET} = ($args->{F_SIZE} * -1) +1 ;
		$args->{F_OFFSET} = $args->{CHUNKSIZE} * -1;
	}

	$args->{BOF} ||= 0; # true/false - have we reached beginning of file - control used in loadBuffer()

	seek $args->{FH}, $args->{F_OFFSET} , 2;

	# do not use getpos - described as 'opaque' in the docs
	# only useful for passing to setpos
	#$args->{F_POS} =  $args->{FH}->getpos;
	$args->{F_POS} =  tell($args->{FH});
	$args->{DEBUG} ||= 0;

	my $self = bless $args, $class;

	$self->showReadParameters;

	return $self;
}


# closure to preserve buffer across calls
{

my ($accumulator,@bufLines) = ('',());
my ($firstChar) = ('');
my %readHash = ();

sub showReadParameters {
	my ($self) = @_;
	# uncomment if Verbose.pm needed again
	#$self->{verbose}->print(3,"      fsize: $self->{F_SIZE}",[]);	
	#$self->{verbose}->print(3,"  chunkSize: $self->{CHUNKSIZE}",[]);	
	#$self->{verbose}->print(3,"     offset: $self->{F_OFFSET}",[]);	
}

sub setReadParameters {
	my ($self) = @_;

	if ( abs($self->{F_OFFSET}) + $self->{CHUNKSIZE} > $self->{F_SIZE} ) {
		$self->{CHUNKSIZE} = $self->{F_SIZE} - abs($self->{F_OFFSET}) ;#-1;
		$self->{F_OFFSET} = ($self->{F_SIZE} * -1) ; #+1;
	} else {
		$self->{F_OFFSET} += ($self->{CHUNKSIZE} * -1);
	}

	return;

}


sub dataRead {
	my ($self) = @_;
	my $buffer='';
	my $iter=0;

	while(1) {

		my $rsz = 0;
		if ($self->{CHUNKSIZE} > 0) {
			seek $self->{FH}, $self->{F_OFFSET} , 2;
			$rsz = read($self->{FH}, $buffer, $self->{CHUNKSIZE} );	
		}

		if ($rsz < 1) {
			@bufLines	= split(/\n/, $accumulator);
			$self->{BOF} = 1;
			return 1;
		}
		
		$accumulator = $buffer . $accumulator;
		
		$self->setReadParameters();

		last if $buffer =~ /\n/;

	}

	@bufLines = split(/\n/, $accumulator);

	$accumulator = shift  @bufLines; # possibly partial line
	if (@bufLines) {
		@bufLines = reverse @bufLines; # needs to be in reverse order if more than 1 element
	}

	return 1;
}

sub loadBuffer {
	my ($self) = @_;

	my $r = $self->dataRead();

	return $r;

}

sub next {
	my ($self) = @_;

	return undef if $self->{BOF};
	
	if (! @bufLines ) {
		$self->loadBuffer() ;
	} 
	
	if (@bufLines) {
		my $f = shift @bufLines;
		return $f . "\n";
	} else {
		push @bufLines, $accumulator if $accumulator;
	}

}

} # end of closure


1;


