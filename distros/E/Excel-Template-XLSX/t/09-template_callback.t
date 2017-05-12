#!perl

use strict;
use warnings;

use lib 't/lib';
use Excel::Writer::XLSX;
use Excel::Template::XLSX;
use Test::More;
use File::Temp qw(tempfile);
use Template::Tiny;

# Can be set to 1 to see the created template and output file during debugging
$File::Temp::KEEP_ALL = 0;

# Create expected workbook content
my ( $efh, $efilename ) = tempfile( SUFFIX => '.xlsx' );
my $wbk = Excel::Writer::XLSX->new($efilename);
$wbk->set_properties( 'subject' => '[% subject %]' );
my $sheet = $wbk->add_worksheet();
$sheet->set_header('&LReplace Template with [% template %]');
$sheet->write( 0, 0, '[% template %]' );

$wbk->close();

my $template = Template::Tiny->new( TRIM => 1 );

# Get workbook content as a template
my ( $gfh, $gfilename ) = tempfile( SUFFIX => '.xlsx' );
my ( $self, $twbk ) = Excel::Template::XLSX->new( $gfilename, $efilename );
$self->{template_callback} = sub {
   my ( $self, $textref ) = @_;
   $template->process(
      $textref,
      {  template => 'Output',
         subject  => 'Test Subject',
      },
      $textref
   );
};
$self->parse_template();

my $got1 = ( sort keys %{ $twbk->{_str_table} } )[0];
is( $got1, 'Output', "Shared Strings" );

my $got2 = $twbk->get_worksheet_by_name('Sheet1')->{_header};
is( $got2, '&LReplace Template with Output', "Header" );

is( $twbk->{_doc_properties}{subject}, 'Test Subject', "Properties" );

$twbk->close();

warn "Files \n$efilename\n$gfilename\n not deleted\n"
    if $File::Temp::KEEP_ALL;
done_testing;

