#!perl -w

require 5.008;

use strict;
use warnings;
use lib qw( inc );

use Config qw(%Config);
use ExtUtils::MakeMaker;
use File::Spec;
use Devel::CheckLib;

# Check that we have a C compiler
check_lib_or_exit();

my @extra = ();
if ( $^O eq 'VMS' ) {
  if ( defined( $Config{ccname} ) ) {
    if ( grep( /VMS_VAX/, @INC ) && ( $Config{ccname} eq 'DEC' ) ) {
      # VAX compiler optimizer even as late as v6.4 gets stuck
      push( @extra, OPTIMIZE => "/Optimize=(NODISJOINT)" );
    }
  }
}

push( @extra, 'INSTALLDIRS' => 'perl' )
 if $] >= 5.008;
push @extra, 'LICENSE' => 'perl'
 if eval( $ExtUtils::MakeMaker::VERSION ) >= "6.30";

my $oe = $Config{obj_ext};
my @obj = ( "MD6$oe", make_obj_list( 'src', $oe, 'md6sum.c' ) );

WriteMakefile(
  NAME         => 'Digest::MD6',
  AUTHOR       => 'Andy Armstrong <andy@hexten.net>',
  VERSION_FROM => 'MD6.pm',
  PREREQ_PM    => {
    'Digest::base' => '1.00',
    'File::Spec'   => 0,
    'Test::More'   => 0,
    'XSLoader'     => 0,
  },
  @extra,
  DIR => ['src'],
  #  OPTIMIZE => '-g',
  OBJECT => join( ' ', @obj ),
  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

sub make_obj_list {
  my ( $dir, $ext, @exc ) = @_;
  my $exc = join '|', map { "(?:\Q$_\E)" } @exc;
  opendir my $dh, $dir or die "Can't read $dir: $!\n";
  return map { File::Spec->catfile( $dir, $_ ) }
   map { $_ =~ s/\.c$/$ext/ && $_ }
   grep { /\.c$/i }
   grep { !/^$exc$/ }
   grep { !/^\./ } readdir $dh;
}
