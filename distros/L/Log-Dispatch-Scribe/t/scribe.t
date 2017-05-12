#! perl

use strict;
use warnings;

use Test::MockObject;
use Test::More tests => 17;
use Data::Dumper;
use Test::Timer;

our $transport_ok = 1;
my @messages;

BEGIN {
    my $std_new = sub { 
	my $class = shift;
	my %opts = ref($_[0]) ? %{$_[0]} : ( @_ );
	return bless \%opts, ref($class) || $class;
    };

    my %subs = (
	'Thrift::FramedTransport' => {
	    new => $std_new,
	    open => sub {},
	    close => sub {},
	    isOpen => sub { return $transport_ok },
	},
	'Scribe::Thrift::scribeClient' => {
	    new => $std_new,
	    Log => sub { 
		die Thrift::TException->new(message => "Transport disconnected") unless $transport_ok;
		my $self = shift;
		my $args = shift;
		push(@messages, map { $_->{message} } @$args); 
		return 0; 
	    },
	},
	'Thrift::Socket' => {
	    new => $std_new,
	},
	'Thrift::BinaryProtocol' => {
	    new => $std_new,
	},
	'Scribe::Thrift::LogEntry' => {
	    new => $std_new,
	},
	'Scribe::Thrift::scribe' => {
	    new => $std_new,
	},
	'Thrift::TException' => {
	    new => $std_new,
	},
	);
    for my $mod (keys %subs) {
	Test::MockObject->fake_module( $mod, %{$subs{$mod}} );
    }

}

require_ok( 'Log::Dispatch::Scribe' );

my $scribe = Log::Dispatch::Scribe->new( 
    name       => 'scribe',
    min_level  => 'info',
    host       => 'localhost',
    port       => 1463,
    default_category => 'test',
    retry_plan_a => 'buffer',
    retry_buffer_size => 1,
    retry_plan_b => 'die',
    retry_delay => 1,
    retry_count => 2,
    );
isa_ok($scribe, 'Log::Dispatch::Scribe');

my $message1 = 'help';
$scribe->log_message(level => 0, message => $message1 );
is(scalar @messages, 1, 'Log success');
is($messages[0], $message1, 'Log message');
splice(@messages, 0);

$transport_ok = 0;
$scribe->log_message(level => 0, message => $message1 );
is(scalar @messages, 0, 'Retry plan a buffered: no message logged');
is(scalar @{$scribe->{_retry_buffer}}, 1, 'Retry plan a buffered: Log message buffered');
eval { $scribe->log_message(level => 0, message => $message1 ) };
my $died = $@;
ok($died, 'Retry plan b die: died');

$scribe->{retry_plan_b} = 'discard';
$scribe->log_message(level => 0, message => $message1 );
ok(@{$scribe->{_retry_buffer}} == 1, 'Retry plan b discard: discarded');
ok(@messages == 0, 'Retry plan b discard: nothing logged');

$transport_ok = 1;
$scribe->log_message(level => 0, message => $message1 );
ok(scalar @messages >= 1, 'Retry plan a buffered: recovery');
splice(@messages, 0);
   
$transport_ok = 0;
$scribe->{retry_plan_a} = 'die';
eval { $scribe->log_message(level => 0, message => $message1 ) };
$died = $@;
ok($died, 'Retry plan a die: died');

splice(@{$scribe->{_retry_buffer}}, 0);
$scribe->{retry_plan_a} = 'discard';
$scribe->log_message(level => 0, message => $message1 );
ok(@{$scribe->{_retry_buffer}} == 0, 'Retry plan a discard: discarded');

$scribe->{retry_plan_a} = 'wait_count';
time_atmost( sub { $scribe->log_message(level => 0, message => $message1 ); }, 4, 'Retry plan a wait_count: timeout');
{
    local $SIG{ALRM} = sub { $transport_ok = 1 };
    alarm 1;
    $scribe->log_message(level => 0, message => $message1 );
    is(scalar @messages, 1, 'Retry plan a wait_count: recovery');
    splice(@messages, 0);
    $transport_ok = 0;
}

time_atmost(sub {
    my $alarmed = 0;
    my $no_messages = 0;
    local $SIG{ALRM} = sub { $alarmed++; $no_messages++ if @messages == 0; $transport_ok = 1 };
    alarm 3;
    $scribe->{retry_plan_a} = 'wait_forever';
    $scribe->log_message(level => 0, message => $message1 ); 
    ok($alarmed && $no_messages, 'Retry plan a wait_forever: waiting');
    is(scalar @messages, 1, 'Retry plan a wait_forever: recovery');
    
}, 6, 'Retry plan a wait_forever completion');




package Scribe::Thrift::ResultCode;
use constant OK => 0;
use constant TRY_LATER => 1;


