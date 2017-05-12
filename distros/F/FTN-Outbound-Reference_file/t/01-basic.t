#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;
use Log::Log4perl ();
use Encode ();
use File::Temp ();
use File::Spec ();

BEGIN {
        use_ok( 'FTN::Outbound::Reference_file' );
}

my $t_dir = File::Temp -> newdir;
my $t_file = File::Temp -> new;

Log::Log4perl -> easy_init( $Log::Log4perl::INFO );

my $reference_file = FTN::Outbound::Reference_file
  -> new( File::Spec -> catfile( $t_dir, '00010001.flo' ),
          sub {
            Encode::decode( 'cp866', shift );
          },
          sub {
            Encode::encode( 'cp866', shift );
          },
          "\x0d\x0a",
        );

isa_ok( $reference_file, 'FTN::Outbound::Reference_file',
        '$reference_file is right class'
      );

$reference_file
  -> read_existing_file
  -> push_reference( '#', $t_file -> filename )
  -> write_file;


my $reference_file2 = FTN::Outbound::Reference_file
  -> new( File::Spec -> catfile( $t_dir, '00010001.flo' ),
          sub {
            Encode::decode( 'cp866', shift );
          },
        );

isa_ok( $reference_file2, 'FTN::Outbound::Reference_file',
        '$reference_file2 is right class'
      );

my @stored_referenced_files = $reference_file -> referenced_files;

cmp_ok( @stored_referenced_files, '==', 1,
        'we just stored only one file'
      );

cmp_ok( $stored_referenced_files[ 0 ]{ $_ -> [ 0 ] }, $_ -> [ 1 ], $_ -> [ 2 ],
        @$_ > 3 ? $_[ 3 ] : (),
      )
  for [ size => '==', 0, 'size should be 0' ],
  [ full_name => 'eq', $t_file -> filename, 'full_name should match' ],
  [ prefix => 'eq', '#', 'prefix should match' ],
  ;
