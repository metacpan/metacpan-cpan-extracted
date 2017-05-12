
use strict;
use warnings;

use Test::More 0.96;

use Gentoo::ChangeLog::Parser::Eventual;

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

  my @events;

  my $instance = Gentoo::ChangeLog::Parser::Eventual->new(
    callback => sub {
      my ( $self, $name, $opts ) = @_;

      # print "$name : "  . $opts->{content} . "\n";
      push @events, [ $name, $opts ];
    }
  );

  my $i = 0;

  for (@content) {
    $instance->handle_line( $_, { line => $i } );
    $i++;
  }

  #$instance->parse_lines(@content);

  #note explain \@events;

  pass("$file parses");
}

done_testing
