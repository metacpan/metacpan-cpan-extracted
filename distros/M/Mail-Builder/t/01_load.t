# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::Most tests => 11 + 1;
use Test::NoWarnings;

use_ok( 'Mail::Builder' );
use_ok( 'Mail::Builder::List' );
use_ok( 'Mail::Builder::Image' );
use_ok( 'Mail::Builder::Image::File' );
use_ok( 'Mail::Builder::Image::Data' );
use_ok( 'Mail::Builder::Attachment' );
use_ok( 'Mail::Builder::Attachment::File' );
use_ok( 'Mail::Builder::Attachment::Data' );
use_ok( 'Mail::Builder::Address' );
use_ok( 'Mail::Builder::Role::File' );
use_ok( 'Mail::Builder::TypeConstraints' );
