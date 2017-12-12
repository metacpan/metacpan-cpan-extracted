#! perl -T
use strict;
use Test::More;

use Log::Log4perl;
use File::Temp  ();
use File::Path  ();
use File::Slurp ();

my $base_directory = File::Temp::tempdir();
my $log_folder     = 'test_folder';

my $conf = q|
log4perl.rootLogger=TRACE, Chunk

layout_class=Log::Log4perl::Layout::PatternLayout
layout_pattern=%m%n

log4perl.appender.Chunk=Log::Log4perl::Appender::Chunk
log4perl.appender.Chunk.store_class=File
log4perl.appender.Chunk.store_args.base_directory=|. $base_directory .q|
log4perl.appender.Chunk.store_args.log_folder=|. $log_folder .q|

log4perl.appender.Chunk.layout=${layout_class}
log4perl.appender.Chunk.layout.ConversionPattern=${layout_pattern}
|;

Log::Log4perl::init(\$conf);

ok( my $ca =  Log::Log4perl->appender_by_name('Chunk') , "Ok got Chunk appender");
ok( my $store = $ca->store(), "Ok got store for the logger");
is( $store->base_directory(), $base_directory, "Ok got a base_directory");
is( $store->log_folder(), $log_folder , "default log folder");

ok( $store->store('a_key' , 'Some big content'), "Ok can store stuff");

my $chunk_file = File::Spec->catfile($store->_logging_folder, 'a_key' );
my $file_content = File::Slurp::read_file( $chunk_file );
like($file_content, qr/Some big content/, 'the chunck file contains the right thing');

# some cleanup
END {
    File::Path::rmtree($base_directory)
}


done_testing();
