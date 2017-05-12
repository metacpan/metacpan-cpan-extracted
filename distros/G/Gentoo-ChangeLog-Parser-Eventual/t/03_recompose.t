
use strict;
use warnings;

use Test::More 0.96;

use Gentoo::ChangeLog::Parser::Eventual::Simple;

use Path::Class qw( file );
use FindBin;

my $corpus = file($FindBin::Bin)->parent->subdir("corpus");
my $parse  = $corpus->subdir('parse');

my %testmap = (
  '01_basic'                    => [],
  '02_no_changelog_for'         => [],
  '03_no_copyright'             => [],
  '04_wrong_changelog_for'      => [],
  '05_wrong_copyright'          => [],
  '06_no_cvs_header'            => [],
  '07_wrong_line_changelog_for' => [],
  '08_duplicate_changelog_for'  => [],
  '09_duplicate_copyright'      => [],
  '10_duplicate_header'         => [],
  '11_wrong_license'            => [],
  '20_real_01'                  => [],
);

for my $file ( sort keys %testmap ) {

  my @content = $parse->file($file)->slurp( chomp => 1 );

  my $arrayerf = Gentoo::ChangeLog::Parser::Eventual::Simple->parse_lines( \@content );

  my @output = ();

  for my $entry ( @{$arrayerf} ) {
    if ( exists $entry->{blank} ) {
      $output[ $entry->{line} ] = $entry->{blank}->{content};
      next;
    }
    if ( exists $entry->{release} ) {
      $output[ $entry->{line} ] = $entry->{release}->{content};
      next;
    }
    if ( exists $entry->{header} ) {
      for my $comment ( @{ $entry->{header} } ) {
        $output[ $comment->{line} ] = $comment->{content};
      }
      next;
    }
    if ( exists $entry->{change} ) {
      for my $line ( @{ $entry->{change}->{header} } ) {
        $output[ $line->{line} ] = $line->{content};
      }
      for my $line ( @{ $entry->{change}->{body} } ) {
        $output[ $line->{line} ] = $line->{content};
      }
      next;
    }
    die "WHAT";
  }

  is_deeply( \@content, \@output, "Recomposed data equals input data" ) or do {
    for ( 0 .. $#output ) {
      note "output: $output[$_] content: $content[$_]";
    }
  };

  #$instance->parse_lines(@content);

  #note explain $arrayerf;

  #ok("$file parses");
}

done_testing
