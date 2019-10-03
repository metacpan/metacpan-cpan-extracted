#!perl

use strict;
use warnings;

use lib 't/lib';
use Excel::Writer::XLSX;
use Excel::Template::XLSX;
use Test::More;
use File::Temp qw(tempfile);

# Can be set to 1 to see the created template and output file during debugging
$File::Temp::KEEP_ALL = 0;

# Create expected workbook content
my ( $efh, $efilename ) = tempfile( SUFFIX => '.xlsx' );
my $wbk     = Excel::Writer::XLSX->new($efilename);
my $wksheet = $wbk->add_worksheet();

my $remap = {
   title       => 'title',
   subject     => 'subject',
   creator     => 'author',
   keywords    => 'keywords',
   description => 'comments',
   category    => 'category',
};

my %prop;
for ( values %$remap ) {
   $prop{$_} = "$_$_";
}
$wbk->set_properties(%prop);
$wbk->close();

$wbk->set_1904();

# Get workbook content as a template
my ( $gfh, $gfilename ) = tempfile( SUFFIX => '.xlsx' );
my ( $self, $twbk ) = Excel::Template::XLSX->new( $gfilename, $efilename );
$self->parse_template();

while ( my ( $k, $v ) = each %$remap ) {
   is( $twbk->{_doc_properties}{$v}, "$v$v", "Worksheet property $k/$v" );
}

my @pallete = qw[
    FFFFFF
    000000
    EEECE1
    1F497D
    4F81BD
    C0504D
    9BBB59
    8064A2
    4BACC6
    F79646
    0000FF
    800080
];

while ( my ( $i, $color ) = each @pallete ) {
   is( $self->{THEMES}{Color}[$i], $color, "Theme Color index $i" );
}

my $got = $wbk->get_1904();
is( $got, 1, 'Date Format 1904' );

warn "Files \n$efilename\n$gfilename\n not deleted\n"
    if $File::Temp::KEEP_ALL;
$twbk->close();

done_testing;
