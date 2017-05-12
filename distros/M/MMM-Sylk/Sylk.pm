package MMM::Sylk;

use 5.006;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Sylk ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.02';

our $EOL = "\n";

# Preloaded methods go here.


sub new
{
	my @this;

	if( ref($_[1]) eq 'HASH' )
	{
		$this[1] = [ @{ $_[1]->{FirstRecord} } ];
	}

	$this[0] = [];
	return bless \@this;
}

sub push_record
{
	my $this = shift;

	if( ref($_[0]) eq 'ARRAY' )
	{
		push @{ $this->[0] }, $_[0];
	} else
	{
		push @{ $this->[0] }, [ @_ ];
	}
}

sub clear
{
	my $this = shift;
	@{ $this->[0] } = ();
}

sub _SYLK_HEAD { "ID;PWXL;N;E" . $EOL }
sub _SYLK_TAIL { "E" }


sub print
{
	my $this = shift;
	my $output = shift;
	my $headers = $this->[1];
	my $line = 0;
	
	if( ref($output) eq 'SCALAR' ) { $$output .= _SYLK_HEAD(); }
	else { print $output _SYLK_HEAD(); }

	if( $headers )
	{
		$line = 1;
		_print_sylk_line( $output, $line, $headers );
	}
	for my $r( @{ $this->[0] } )
	{
		++$line;
		_print_sylk_line( $output, $line, $r );
	}
	if( ref($output) eq 'SCALAR' ) { $$output .= _SYLK_TAIL(); }
	else { print $output _SYLK_TAIL(); }
}

sub as_string
{
	my $this = shift;
	my $output;
	$this->print(\$output);
	return $output;
}

my %encodings = 
(
 	'à' => 'NAa',
	'è' => 'NAe',
	'é' => 'NBe',
	'ò' => 'NAo',
	'ç' => 'NKc',
	'ì' => 'NAi',
	'°' => 'N0'
);

my $encodings_charlist = join "", keys %encodings;
sub _sylk_escape
{
	$_[0] =~ s/([$encodings_charlist])/chr(27) . $encodings{$1}/ge
}

sub _print_sylk_line
{
	my ($output, $line, $record ) = @_;

#	my $out = "C;Y$line;";
	my $out;

	my $count = 1;
	for my $f ( @$record )
	{
		_sylk_escape($f);
		$out .= "C;Y$line;X$count;K\"$f\"$EOL";
		++$count;
	}
	if( ref($output) eq 'SCALAR' ) { $$output .= $out; }
	else { print $output $out; }
}




# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Sylk - Perl extension for generating Sylk files

=head1 SYNOPSIS

  use MMM::Sylk;

  my $slk = new MMM::Sylk;

  # with static first line
  my $slk = new MMM::Sylk( { FistRecord => [ "head1", "head2", "head3" ] } );


  #push a record (1) 
  $slk->push_record( "1", "2", "3" ); #(data are copied)

  
  #push a record (2)
  # (record is stored as a reference to external data)
  #
  my @record = ( 1 ,2 ,3 4 );
  $slk->push_record( \@record );
  # or
  $slk->push_record( [ "1", "2", "3" ] );


  #clear all data
  $slk->clear();

  #print to file handler
  $slk->print( \*STDOUT );

  #get Sylk content as string
  my $str = $slk->as_string();


  
=head1 DESCRIPTION

The comments above will suffice.

=head2 EXPORT

$EOL   eol sequence (default "\n")

=head1 AUTHOR

Max Muzi <maxim@comm2000.it>

=head1 SEE ALSO

L<perl>.

=cut
