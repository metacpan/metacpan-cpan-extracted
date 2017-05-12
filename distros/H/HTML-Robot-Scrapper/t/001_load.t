# -*- perl -*-
# t/001_load.t - check module loading and create testing directory
use Test::More;
use HTML::Robot::Scrapper;
use File::Path qw|make_path remove_tree|;
#use CHI;
use Cwd;
use Path::Class;
BEGIN { use_ok( 'HTML::Robot::Scrapper', 'use is fine' ); }

use HTML::Robot::Scrapper::Reader::TestReader;
use HTML::Robot::Scrapper::Writer::TestWriter;
#use CHI;

#   sub create_cache_dir {
#     my $dir  = dir(getcwd(), 'cache'); 
#     make_path( $dir, 'cache' );
#   }
#   &create_cache_dir;

my $robot = HTML::Robot::Scrapper->new (
    reader    => HTML::Robot::Scrapper::Reader::TestReader->new(),
    writer    => HTML::Robot::Scrapper::Writer::TestWriter->new(),
#   cache     => CHI->new(
#                   driver => 'BerkeleyDB',
#                   root_dir => dir( getcwd() , "cache" ),
#   ),
#   log       => HTML::Robot::Scrapper::Log::Default->new(),
#   parser    => HTML::Robot::Scrapper::Parser::Default->new(),
#   queue     => HTML::Robot::Scrapper::Queue::Default->new(),
#   useragent => HTML::Robot::Scrapper::UserAgent::Default->new(),
#   encoding  => HTML::Robot::Scrapper::Encoding::Default->new(),
);
isa_ok ($robot, 'HTML::Robot::Scrapper', 'is obj scrapper');

$robot->start();

my $site_visited = {
    bbc     => 0,
    zap     => 0,
    google  => 0,
    uol     => 0,
};

foreach my $item ( @{ $robot->writer->data_to_save } ) {
  $site_visited->{bbc}      = 1 if $item->{ url } =~ m/bbc.+/ig and length ($item->{ title })>0 ;
  $site_visited->{zap}      = 1 if $item->{ url } =~ m/zap.+/ig and length ($item->{ title })>0;
  $site_visited->{google}   = 1 if $item->{ url } =~ m/google.+/ig and length ($item->{ title })>0;
  $site_visited->{uol}      = 1 if $item->{ url } =~ m/uol.+/ig and length ($item->{ title })>0;
}

ok( $site_visited->{ uol }      == 1, 'visited uol' );
ok( $site_visited->{ google }   == 1, 'visited google' );
ok( $site_visited->{ zap }      == 1, 'visited zap' );
ok( $site_visited->{ bbc }      == 1, 'visited bbc' );

done_testing();
