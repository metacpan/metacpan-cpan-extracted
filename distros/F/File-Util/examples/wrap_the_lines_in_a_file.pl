# ABSTRACT: open a file, wrap its lines, save the file with the newly formatted content

use strict; # always
use warnings;
use File::Util qw( NL );
use Text::Wrap qw( wrap );

$Text::Wrap::columns = 72; # wrap text at this many columns

my $ftl  = File::Util->new();
my $file = 'example.txt'; # file to wrap and save (must already exist)

$ftl->write_file(
  filename => $file,
  content => wrap('', '', $ftl->load_file( $file ))
);

# display the newly formatted file
print $ftl->load_file( $file );

exit;
