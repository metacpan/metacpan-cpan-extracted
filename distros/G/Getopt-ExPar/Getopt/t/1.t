# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Getopt::ExPar') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my($opt) = _new Getopt::ExPar( {'development_check' => 1,
				'switchglomming' => 1,
				'ignorecase' => 1,
			      } );
foreach ( qw/a b c d e f g h i j k l m n o p/ ) {
  $opt->_parameter( $_ );
  $opt->_help( $_, 'Just a switch.' );
}
$opt->_parameter( 'switch01' );
$opt->_help( 'switch01', 'Just a switch.' );
$opt->_multi_parameter( 'multiparam01', { 'mp01op01' => 'string', }, { 'mp01op02' => 'string', }, );
$opt->_keys( 'multiparam01', { 'mp01op02' => [ 'a', 'b', 'aa', 'bb', 'aaa', 'bbb', ], 'mp01op01' => [ 'a', 'b', 'cc', ], } );
$opt->_alias( 'multiparam01', 'mp01', );
$opt->_help( 'multiparam01', 'First parameter with multiple arguments.', );
$opt->_multi_parameter( 'multiparam02', { 'mp02op01' => 'file', }, { 'mp02op02' => 'file', }, { 'mp02op03' => 'integer', }, );
$opt->_unique( 'multiparam02', );
$opt->_help( 'multiparam02', 'Second parameter with multiple arguments.', );
$opt->_mp( 'multiparam03', { 'mp03op01' => 'string', }, { 'mp03op02' => 'file', }, );
$opt->_help( 'multiparam03', 'Third parameter with multiple arguments.', );
$opt->_p( 'param01', 'file', 'p01', );
$opt->_h( 'param01', 'First parameter, has alias of p01.' );
$opt->_p( 'param02', 'file' );
$opt->_h( 'param02', 'Second parameter.' );
$opt->_p( 'param03', 'file', 'p03' );
$opt->_h( 'param03', 'Third parameter, has alias of p03.' );
$opt->_req_grp( 'multiparam01', 'multiparam03', 'param01', 'param03', );
$opt->_p( 'param04', 'string', );
$opt->_default( 'param04', 'string04', );
$opt->_h( 'param04', 'Fourth parameter, has default of string04.' );
$opt->_p( 'PAram05', 'string', );
$opt->_required( 'PAram05', );
$opt->_h( 'PAram05', 'Fifth parameter, a required parameter.' );
$opt->_keys( 'PAram05', 'a', 'b', 'c', 'foo', 'bar' );
$opt->_p( 'param06', 'file', );
$opt->_unique( 'param06', );
$opt->_h( 'param06', 'Sixth parameter, requires unique values.' );
$opt->_help(<<End);
  This is the help description for the entire script $0.
  This is printed whenever -help is requested.
End

$opt->_special( 'numOpt', '^\-\d+' );
$opt->_help_option( 'numOpt', '-#' );
$opt->_help( 'numOpt', 'Matches any -# option.' );
foreach my $cmd ( 'a' .. 'd' ) {
  $opt->_special( "${cmd}Switch", '\+'.$cmd.'Switch\+.+' );
  $opt->_help_option( "${cmd}Switch", "+${cmd}Switch+<$cmd switch>" );
  $opt->_help( "${cmd}Switch", "Specify switch for $cmd.");
  $opt->_s( "${cmd}Option", '\+'.$cmd.'Option\+.+', 'string' );
  $opt->_help_option( "${cmd}Option", "+${cmd}Option+<$cmd option>" );
  $opt->_help( "${cmd}Option", "Specify option for $cmd." );
  $opt->_s( "${cmd}Default", '\+'.$cmd.'Default\+.+', 'string' );
  $opt->_help_option( "${cmd}Default", "+${cmd}Default+<$cmd option>" );
  $opt->_help( "${cmd}Default", "Specify default for $cmd." );
  $opt->_s( "${cmd}RemoveSwitch", '\+'.$cmd.'RemoveSwitch\+.+' );
  $opt->_help_option( "${cmd}RemoveSwitch", "+${cmd}RemoveSwitch+<$cmd switch>" );
  $opt->_help( "${cmd}RemoveSwitch", "Remove switch for $cmd." );
  $opt->_multi_special( "${cmd}RemoveOption", '\+'.$cmd.'RemoveOption\+.+', { 'arg1' => 'string', }, { 'arg2' => 'integer', }, { 'arg3' => 'string', } );
  $opt->_help_option( "${cmd}RemoveOption", "+${cmd}RemoveOption+<$cmd option>" );
  $opt->_help( "${cmd}RemoveOption", "Remove option for $cmd." );
}

$opt->_mutex( 'switch01', 'aSwitch' );

#  $opt->_parse();
#  
#  #Now test the actual methods to return data: _arg, _args, _arge, _argl, _argh
#  
#  #switches always return 0/1
#  foreach ( qw/a b c d e f g h i j k l m n o p/ ) {
#    print "$_: ", $opt->_arg($_), "\n";
#  }
#  print "switch01: ", $opt->switch01(), "\n";
#  
#  #regular parameters will return undef() so check _arge first
#  print "param01: ", $opt->param01(), " exists, ", $opt->param01_argc(), " arguments.\n" if $opt->param01_arge();
#  print "param02: ", $opt->param02(), " exists, ", $opt->param02_argc(), " arguments.\n" if $opt->param02_arge();
#  print "param03: ", $opt->param03(), " exists, ", $opt->param03_argc(), " arguments.\n" if $opt->param03_arge();
#  print "param04: ", $opt->param04(), " exists, ", $opt->param04_argc(), " arguments.\n" if $opt->param04_arge();
#  print "param05: ", $opt->PAram05(), " exists, ", $opt->PAram05_argc(), " arguments.\n" if $opt->PAram05_arge();
#  print "param06: ", $opt->param06(), " exists, ", $opt->param06_argc(), " arguments.\n" if $opt->param06_arge();
#  print "multiparam01: ", join(', ', @{$opt->multiparam01()}), " exists, ", $opt->multiparam01_argc(), " arguments.\n" if $opt->multiparam01_arge();
#  print "multiparam02: ", join(', ', @{$opt->multiparam02()}), " exists, ", $opt->multiparam02_argc(), " arguments.\n" if $opt->multiparam02_arge();
#  print "multiparam03: ", join(', ', @{$opt->multiparam03()}), " exists, ", $opt->multiparam03_argc(), " arguments.\n" if $opt->multiparam03_arge();
#  
#  #special parameters always return array refs when accessing each element
#  print "aSwitch: ", join(', ', @{$opt->aSwitch()}), " exists, ", $opt->aSwitch_argc(), " arguments.\n" if $opt->aSwitch_arge();
#  print "cOption: ", join(', ', @{$opt->cOption()}), " exists, ", $opt->cOption_argc(), " arguments.\n" if $opt->cOption_arge();
#  print "dRemoveOption: ", join(', ', @{$opt->dRemoveOption()}), " exists, ", $opt->dRemoveOption_argc(), " arguments.\n" if $opt->dRemoveOption_arge();
#  print "numOpt: ", join(', ', @{$opt->numOpt()}), " exists, ", $opt->numOpt_argc(), " arguments.\n" if $opt->numOpt_arge();
#  
#  #argl loops through all arguments of specified parameter
#  while ( my $v = $opt->param06_argl() ) {
#    print "param06: $v\n";
#  }
#  while ( my $v = $opt->multiparam02_argl() ) {
#    print "multiparam06: @{$v}\n";
#  }
#  
#  #argh returns hashes with all arguments available
#  my($h) = $opt->param02_argh();
#  foreach ( sort { $a<=>$b; } keys %{$h} ) {
#    print "param02($_) => $h->{$_}\n";
#  }
#  $h = $opt->multiparam02_argh();
#  foreach my $i ( sort { $a<=>$b; } keys %{$h} ) {
#    foreach ( sort keys %{$h->{$i}} ) {
#      print "multiparam02($i, $_) => $h->{$i}->{$_}\n";
#    }
#  }
#  print "multiparam02(2, 'mp02op02') => ", $opt->multiparam02_argh()->{2}->{'mp02op02'}, "\n";
#  $h = $opt->cOption_argh();
#  foreach my $i ( sort { $a<=>$b; } keys %{$h} ) {
#    foreach ( sort keys %{$h->{$i}} ) {
#      print "cOption($i, $_) => $h->{$i}->{$_}\n";
#    }
#  }
#  $h = $opt->dRemoveOption_argh();
#  foreach my $i ( sort { $a<=>$b; } keys %{$h} ) {
#    foreach ( sort keys %{$h->{$i}} ) {
#      print "dRemoveOption($i, $_) => $h->{$i}->{$_}\n";
#    }
#  }
#  
