#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Log::Log4perl;
use Term::ANSIColor;

BEGIN {
    use_ok('Log::Log4perl::Layout::ColoredPatternLayout');
}

my %s;
$s{'rootLogger'}.='TRACE, SCREEN';
$s{'appender.SCREEN'} = 'Log::Log4perl::Appender::TestBuffer';
$s{'appender.SCREEN.stderr'}  = '0';
$s{'appender.SCREEN.layout'} = 'Log::Log4perl::Layout::ColoredPatternLayout';

$s{'appender.SCREEN.layout.ColorMap'} 
    = 'sub { return {
          m => "blue on_white",
          F => "cyan on_white", 
          p => sub { 
            my ($p) = @_;
            my $colors = {
                debug => "yellow on_white",
                info => "red on_white"
            };
            return +$colors->{ lc($p) };
        }}}';
$s{'appender.SCREEN.layout.ColorMap'} =~ s/\n//g;


my $message = "This is the message";        
    

my $file_pad_length = length( __FILE__ ) + 5;
my @formats = ({

    pattern => '[%p] %% file: %F message: %m%n',

    result => sub {
        my ($in) = @_;
        
        return '['.colored(
            $in->{p}->{value},
            $in->{p}->{color}
        ).'] % file: '.colored(
            __FILE__,
            $in->{F}->{color}
        ).' message: '.colored(
            $message,
            $in->{m}->{color}
        )."\n";
    }
}, {

    pattern => '%-5p %'.$file_pad_length.'F %m%n',

    result => sub {
        my ($in) = @_;

        my $plen = length( $in->{p}->{value} );
        my $p = colored( $in->{p}->{value}, $in->{p}->{color} );
            
        $p.= ' ' x (5 - $plen) if $plen < 5;
        my $F = ' ' x 5;
        $F.= colored(__FILE__, $in->{F}->{color});

        return $p.' '.$F.' '.colored(
            $message,
            $in->{m}->{color}
        )."\n";
    }
       
});    

my @test_data = ({
    p => {
        value => 'DEBUG',
        color => 'yellow on_white'
    },
    F => {
        color => "cyan on_white"
    },
    'm' => {
       color => "blue on_white"
    }
},{
    p => {
        value => 'INFO',
        color => 'red on_white'
    },
    F => {
        color => "cyan on_white"
    },
    'm' => {
       color => "blue on_white"
    }
}

); 

        

for my $i (0..$#formats){

    my $format = $formats[$i];

    $s{'appender.SCREEN.layout.ConversionPattern'} = $format->{pattern};

    Log::Log4perl->init( \%s );    

    for my $j (0..$#test_data){
        my $data = $test_data[$j];

        my $logger = Log::Log4perl->get_logger;

        my $method = lc( $data->{p}->{value} );
        $logger->$method( $message );
        my $expected = $format->{result}->( $data );

        is( Log::Log4perl->appenders->{SCREEN}->buffer(), $expected, "pattern $i data set $j" );
        Log::Log4perl->appenders->{SCREEN}->buffer('');
    }

}

done_testing();


