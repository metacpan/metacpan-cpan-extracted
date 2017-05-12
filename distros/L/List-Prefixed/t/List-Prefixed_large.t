# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl List-Prefixed.t'

#########################

use strict;
use warnings;

use Test::More;
use File::Basename;

BEGIN { use_ok('List::Prefixed') };

my (@all_names,@list_names);

my $all_names_path = dirname(__FILE__).'/data/modulenames.gz';
my $list_names_path = dirname(__FILE__).'/data/modulenames_List.gz';

# check for some gunzip utility
my $have_data;

# try IO::Zlib
unless ( $have_data ) {
  eval "use IO::Zlib";
  unless ( $@ ) {
    my ($fh);

    $fh = IO::Zlib->new($all_names_path, "rb") or die "Cannot open '$all_names_path'";
    @all_names = <$fh>;
    undef $fh; # automatically closes the file
    chomp(@all_names);

    $fh = IO::Zlib->new($list_names_path, "rb") or die "Cannot open '$list_names_path'";
    @list_names = <$fh>;
    undef $fh; # automatically closes the file
    chomp(@list_names);

    $have_data = 1;
  }
}

# try PerlIO::gzip
unless ( $have_data ) {
  eval "use PerlIO::gzip";
  unless ( $@ ) {

    open DATA, "<:gzip", $all_names_path or die "Cannot open '$all_names_path': $!";
    @all_names = <DATA>;
    binmode DATA, ":gzip(none)";
    close DATA;
    chomp(@all_names);

    open DATA, "<:gzip", $list_names_path or die "Cannot open '$list_names_path': $!";
    @list_names = <DATA>;
    binmode DATA, ":gzip(none)";
    close DATA;
    chomp(@list_names);

    $have_data = 1;
  }
}

# try /bin/gunzip
unless ( $have_data ) {
  if ( -x '/bin/gunzip' ) {

    open DATA, "/bin/gunzip -c $all_names_path |" or die "Cannot open '$all_names_path': $!";
    @all_names = <DATA>;
    close DATA;
    chomp(@all_names);

    open DATA, "/bin/gunzip -c $list_names_path |" or die "Cannot open '$list_names_path': $!";
    @list_names = <DATA>;
    close DATA;
    chomp(@list_names);

    $have_data = 1;
  }
}

#########################

if ( $have_data ) {

  my $prefixed = List::Prefixed->new(@all_names);

  my $re = $prefixed->regex;
  my $qr = qr/^$re$/;
  like $_ => $qr foreach @all_names;

  my $list = $prefixed->list('List::');
  is_deeply $list => [ sort { $a cmp $b } @list_names ];

  my $prefixed2 = List::Prefixed->unfold($re);
  is_deeply $prefixed2 => $prefixed;

}
else {
  warn "No gunzip utility could be found - tests skipped";
}

done_testing;
