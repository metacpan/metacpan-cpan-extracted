package File::Navigate;
use strict;
use warnings;

=head1 NAME

File::Navigate - Navigate freely inside a text file

=head1 DESCRIPTION

The module is a glorified wrapper for tell() and seek(). 

It aims to simplify the creation of logfile analysis tools by 
providing a facility to jump around freely inside the contents
of large files without creating the need to slurp excessive 
amounts of data.

=head1 SYNOPSIS

  use File::Navigate;
  my $nav = File::Navigate->new('/var/log/messages');

  # Read what's below the "cursor":
  my $first = $nav->get;

  # Advance the cursor before reading:
  my $second = $nav->getnext;
  my $third  = $nav->getnext;

  # Advance the cursor by hand:
  $nav->next;
  my $fourth = $nav->get;

  # Position the cursor onto an arbitrary line:
  $nav->cursor(10);
  my $tenth  = $nav->get;

  # Reverse the cursor one line backward:
  $nav->prev;
  my $ninth  = $nav->get;

  # Reverse the cursor before reading:
  my $eigth  = $nav->getprev;

  # Read an arbitrary line:
  my $sixth  = $nav->get(6);

=cut

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw();
our $VERSION   = '1.0';

=head1 CLASS METHODS

=head2 I<new()>

Open the file and create an index of the lines inside of it.

  my $mapper = File::Navigate->new($filename);

=cut

sub new($){
	my $class = shift;
	my $file;
	unless ($file = shift){ 
		die "No file specified\n";
	}
	unless (-e $file){
		die "File not found: $file\n";
	}
	unless (-r $file){
		die "File not readable: $file\n";
	}
	my $self = {};
	   $self->{'cursor'}         = 1;
	   $self->{'lineindex'}      = {};
	   $self->{'lineindex'}->{1} = 0;
	open my $fh, "$file" 
		or die "Can't open $file: $!\n";
	while (<$fh>){
		my $thisline = $.;
		my $nextline = $thisline + 1;
		$self->{'lineindex'}->{$nextline} = tell $fh;
	}
	$self->{'length'} = scalar(keys %{$self->{'lineindex'}}) - 1 ;
	$self->{'fh'} = $fh;
	bless $self;
}

=head1 OBJECT METHODS

=head2 I<count()> 

Returns the number of lines in the file ("wc -l")

  my $lines = $nav->count;

=cut

sub length(){
	my $self = shift;
	return $self->{'length'};
}

=head2 I<cursor()> 

Returns the current cursor position and/or sets the cursor.

  my $cursor = $nav->cursor();   # Query cursor position.
  my $cursor = $nav->cursor(10); # Set cursor to line 10

=cut

sub cursor($){
	my $self = shift;
	if (my $goto = shift){
		$self->{'cursor'} = $goto;
	}
	return $self->{'cursor'};
}

=head2 I<get()>

Gets the line at the cursor position or at the given position.

  my $line = $nav->get();   # Get line at cursor
  my $line = $nav->get(10); # Get line 10

=cut

sub get($){
	my $self = shift;
	my $fh   = $self->{'fh'};

	my $getline;
	$getline = $self->{'cursor'} unless ($getline = shift);

	if ($getline < 1){
		warn "WARNING: Seek before first line.";
		return undef;
	}elsif($getline > $self->{'length'}){
		warn "WARNING: Seek beyond last line.";
		return undef;
	}
	seek ($fh, $self->{'lineindex'}->{$getline}, 0);
	my $gotline = <$fh>;
	chomp $gotline;
	return $gotline;
}	

=head2 I<next()>

Advance the cursor position by one line. Returns the new cursor position.
Returns I<undef> if the cursor is already on the last line. 

  my $newcursor = $nav->next(); 

=cut

sub next(){
	my $self = shift;
	if ($self->{'cursor'} == $self->{'length'}){
		return undef;
	}
	$self->{'cursor'}++;
	return $self->{'cursor'};
}

=head2 I<prev()>

Reverse the cursor position by one line. Returns the new cursor position.
Returns I<undef> if the cursor is already on line 1. 

  my $newcursor = $nav->prev(); 

=cut

sub prev(){
	my $self = shift;
	if ($self->{'cursor'} == 1){
		return undef;
	}
	$self->{'cursor'}--;
	return $self->{'cursor'};
}

=head2 I<getnext()> 

Advance to the next line and return it.
Returns I<undef> if the cursor is already on the last line. 

  my $newcursor = $nav->getnext(); 

=cut

sub getnext(){
	my $self = shift;
	$self->next or return undef;
	return $self->get;
}

=head2 I<getprev()> 

Reverse to the previous line and return it:
Returns I<undef> if the cursor is already on line 1. 

  my $newcursor = $nav->getprev(); 

=cut

sub getprev(){
	my $self = shift;
	$self->prev or return undef;
	return $self->get;
}

=head2 I<find()>

Find lines containing given regex. Returns array with line numbers.

  my @lines = @{$nav->find(qr/foo/)};

=cut

sub find($){
	my $self = shift;
	my $regex = shift;
		
	my @results;
	for (my $lineno = 1; $lineno <= $self->{'length'}; $lineno++){
		my $line = $self->get($lineno);
			if ($line =~ $regex){
			push @results, $lineno;
		}
	}
	return \@results;
}

sub DESTROY(){
	my $self = shift;
	close $self->{'fh'};
}

=head1 EXAMPLE

I<tac>, the opposite of I<cat>, in Perl using File::Navigate:

  #!/usr/bin/perl -w
  use strict;
  use File::Navigate;
  
  foreach my $file (reverse(@ARGV)){
          my $nav = File::Navigate->new($file);
          # Force cursor beyond last line
          $nav->cursor($nav->length()+1);
          print $nav->get()."\n" while $nav->prev();
  }

=head1 BUGS

Seems to lack proper error handling. 

=head1 LIMITATIONS

Works only on plain text files. Sockets, STDIO etc. are not supported.

=head1 PREREQUISITES

Tested on Perl 5.6.1.

=head1 STATUS

Mostly harmless.

=head1 AUTHOR

Martin Schmitt <mas at scsy dot de>

=cut

1;
