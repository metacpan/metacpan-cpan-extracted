#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Carp 'confess';
use Log::Any;
use Log::Any::Adapter;
use Log::Any::Adapter::Util ':levels';

use_ok( 'Log::Any::Adapter::Daemontools' ) || BAIL_OUT;

my $buf;

sub reset_stdout {
	close STDOUT;
	$buf= '';
	open STDOUT, '>', \$buf or die "Can't redirect stdout to a memory buffer: $!";
}

my $cfg= Log::Any::Adapter::Daemontools->new_config;
my $log= Log::Any->get_logger(category => 'testing');
Log::Any::Adapter->set( 'Daemontools', config => $cfg );

my $log_call_file_name= __FILE__;
my $log_call_line_number= __LINE__ + 5;
sub test_format {
	my ($format, $method, $string, $result)= @_;
	$cfg->format($format);
	reset_stdout;
	$log->$method($string); # This line number is used in tests below.
	like( $buf, $result, "$string => $format" ) or diag explain( Log::Any->_manager->get_adapter('testing') );
}

my $log_call_file_name_brief= __FILE__;
$log_call_file_name_brief =~ s,^(.*)[\\/]log[\\/],,;

my @tests= (
	# Format                        Method      String    Result
	[ '"$level_prefix$_\n"',        info    =>  'Test',   qr/^Test\n$/ ],
	[ '"literal string"',           info    =>  'Test',   qr/^literal string$/ ],
	[ '"$_"',                       info    =>  'Test',   qr/^Test$/ ],
	[ 'lc($_)."\n"',                info    =>  'Test',   qr/^test\n$/ ],
	[ '$level',                     info    =>  'Test',   qr/^info$/ ],
	[ '"$level\n"',                 info    =>  'Test',   qr/^info\n$/ ],
	[ '"$level: ($category) $_\n"', info    =>  'Test',   qr/^info: \(testing\) Test\n$/ ],
	[ '"$_ at $file"',              info    =>  'Test',   qr/^Test at \Q$log_call_file_name\E$/ ],
	[ '"$_ at $file_brief"',        info    =>  'Test',   qr/^Test at \Q$log_call_file_name_brief\E$/ ],
	[ '"$_ (line $line)"',          info    =>  'Test',   qr/^Test \(line \Q$log_call_line_number\E\)$/ ],
	[ '"$_ ($package)"',            info    =>  'Test',   qr/^Test \(main\)$/ ],
	[ 'numeric_level($level) > NOTICE? "$_ at $file_brief:$line\n" : "$_\n"',
	                                notice  =>  'Test',   qr/^Test\n$/ ],
	[ 'numeric_level($level) > NOTICE? "$_ at $file_brief:$line\n" : "$_\n"',
	                                info    =>  'Test',   qr/^Test at \Q$log_call_file_name_brief:$log_call_line_number\E$/ ],
	# Also test using coderef as format
	[ sub { "$_[1]: (".$_[0]->category.") $_\n" },
	                                info    => 'Test', qr/^info: \(testing\) Test\n$/ ],
);
test_format(@$_) for @tests;

done_testing;
