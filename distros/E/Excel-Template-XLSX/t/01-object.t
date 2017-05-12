#!perl 

use strict;
use warnings;

use lib 't/lib';
use Excel::Writer::XLSX;
use Excel::Template::XLSX;
use Test::More;
use File::Temp qw(tempfile);

# Can be set to 1 to see the created template and output file during debugging
$File::Temp::KEEP_ALL = 1;

###############################################################################

# Create expected workbook content
my ( $efh, $efilename ) = tempfile( SUFFIX => '.xlsx' );
my $wbk     = Excel::Writer::XLSX->new($efilename);
my $wksheet = $wbk->add_worksheet();
$wbk->close();

# Get workbook content as a template
my ( $gfh, $gfilename ) = tempfile();
my ( $self, $twbk ) = Excel::Template::XLSX->new( $gfilename, $efilename );
$self->parse_template();

isa_ok( $self,                   'Excel::Template::XLSX' );
isa_ok( $twbk,                   'Excel::Writer::XLSX' );
isa_ok( $self->{EWX},            'Excel::Writer::XLSX' );
isa_ok( $self->{DEFAULT_FORMAT}, 'Excel::Writer::XLSX::Format' );

$twbk->close();

our $CAPTURE;

my ( $gfh2, $gfilename2 ) = tempfile();
test_new( $gfh2, "Can't open filehandle as a zip file, ", 'Bad file handle' );
test_new( $gfilename2, "Can't open file '$gfilename2' as a zip file, ",
   'Bad file' );
test_new(
   \q[not-a-file],
   "Argument to 'new' must be a filename or open filehandle.  ",
   'ref to not-a-file'
);
done_testing;

###############################################################################
sub test_new {
   my ( $template, $expected, $msg ) = @_;

   # Setup to capture warnings
   my $sig = $SIG{__WARN__};
   $SIG{__WARN__} = sub { $CAPTURE = $_[0] };

   # Test for filehandle warning
   my ( $gfh, $gfilename ) = tempfile();
   my ( $self, $twbk ) = Excel::Template::XLSX->new( $gfilename, $template );

   # Restore previous warn handler
   $SIG{__WARN__} = $sig;

   # remove file name and line number from the warning
   ( my $got = $CAPTURE ) =~ s/skipping.*//s;
   is( $got, $expected, $msg );
}

