#!/usr/bin/perl

use Test::More tests => 3;
use File::Spec;
use File::Temp;
use File::Basename;

my $module = 'EPublisher';
use_ok( $module );

my $debug = "";

my $dir       = File::Spec->rel2abs( dirname( __FILE__ ) );
my $include   = File::Spec->catfile( $dir, 'lib' );
my $txt       = File::Temp->new;

$txt->unlink_on_destroy( 1 );

my $config = {
    Test => {
        source => {
          type => 'Module',
          lib  => [ $include ],
          name => 'Text',
        },
        target => {
            type => 'Text',
            output => $txt->filename,
        },
    }
};

my $obj = $module->new( debug => \&debug );
$obj->{__config} = $config;

$obj->run( ['Test'] );

my $check = q!100: Module 101: =pod

=head1 Text - a test library for text output 200: Text !;
is( $debug, $check, 'debug' );


my $txt_check   = "Text - a test library for text output\n    Ein Absatz im POD.\n\n";
my $txt_content = do{ local( @ARGV, $/) = $txt->filename; <> };
is ( $txt_content, $txt_check, 'check generated text' );

sub debug{
    $debug .= $_[0] . " ";
}
