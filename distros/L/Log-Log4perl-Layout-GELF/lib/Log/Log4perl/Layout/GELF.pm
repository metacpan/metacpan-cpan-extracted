##################################################
package Log::Log4perl::Layout::GELF;
##################################################

use 5.006;
use strict;
use warnings;

use JSON::XS;
use IO::Compress::Gzip qw( gzip $GzipError );
use Log::Log4perl;

use base qw(Log::Log4perl::Layout::PatternLayout);

# We need to define our own cspecs
$Log::Log4perl::ALLOW_CODE_IN_CONFIG_FILE = 1;

=head1 NAME

Log::Log4perl::Layout::GELF - Log4perl for graylog2

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Log4perl implementation of GELF. When used with
Log::Log4perl::Appender::Socket you can log directly
to a graylog2 server.

=cut

=head1 What is graylog?

Graylog is log management server that can be used to run analytics, 
alerting, monitoring and perform powerful searches over your whole 
log base. Need to debug a failing request? Just run a quick filter 
search to find it and see what errors it produced. Want to see all 
messages a certain API consumer is consuming in real time? Create 
streams for every consumer and have them always only one click away.

=cut

=head1 Configuration Sample

Code snippet. Replace the ip with your graylog server.

    use Log::Log4perl
    my $logger_conf = {
      'log4perl.logger.graylog'           => "DEBUG, SERVER",
      'log4perl.appender.SERVER'          => "Log::Log4perl::Appender::Socket",
      'log4perl.appender.SERVER.PeerAddr' => '10.211.1.94',
      'log4perl.appender.SERVER.PeerPort' => "12201",
      'log4perl.appender.SERVER.Proto'    => "udp",
      'log4perl.appender.SERVER.layout'   => "GELF"
    };
    Log::Log4perl->init( $logger_conf );
    my $LOGGER = Log::Log4perl->get_logger('graylog');
    $LOGGER->debug("Debug log");
    ...
=cut

=head1 SUBROUTINES/METHODS

=head2 new
    
    Can take most of options that Log::Log4perl::Layout::PatternLayout can.
    
    Additional Options:
        PlainText - outputs plaintext and not gzipped files.
    
=cut
sub new {
    my $class = shift;
    $class = ref ($class) || $class;
    
    my $options = ref $_[0] eq "HASH" ? shift : {};
    
    # Creating object to make changes easier
    my $gelf_format = { 
        "version" => "1.0",
        "host" => "%H",
        "short_message" => "%m{chomp}",
        "timestamp" => "%Z", # custom cspec
        "level"=> "%Y", # custom cspec
        "facility"=> "%M",
        "file"=> "%F",
        "line"=> "%L",
        "_pid" => "%P", 
    };
    # make a JSON string
    my $conversion_pattern = encode_json($gelf_format);
    
    $options->{ConversionPattern} = { value => $conversion_pattern } ;
    
    # Since we are building on top of PatternLayout, we can define our own
    # own patterns using a "cspec".
    $options->{cspec} = { 
        'Z' => { value => sub {return time } }, 
        'Y' => { value => \&_level_converter } ,
    };
    
    my $self = $class->SUPER::new($options);
    
    # to help with debugging. you can skip the bzipping.
    $self->{PlainText} = 0;
    if(defined $options->{PlainText}->{value} ){
        $self->{PlainText} = $options->{PlainText}->{value};
    }
    return $self;
}


# Maps over the syslog levels from Log4perl levels.

# Syslog Levels for Reference
# 0 Emergency: system is unusable 
# 1 Alert: action must be taken immediately 
# 2 Critical: critical conditions 
# 3 Error: error conditions 
# 4 Warning: warning conditions 
# 5 Notice: normal but significant condition 
# 6 Informational: informational messages 
# 7 Debug: debug-level messages
sub _level_converter {
    my ($layout, $message, $category, $priority, $caller_level) = @_;
    # TODO Replace with a case statement
    my $levels = {
        "DEBUG" => 7,
        "INFO"  => 6,
        "NOTICE"=> 5,
        "WARN"  => 4,
        "ERROR" => 3,
        "FATAL" => 2
    };
    return $levels->{$priority};
}

=head2 render
    
    Wraps the Log::Log4perl::Layout::PatternLayout return value so we can
    gzip the JSON string.
    
=cut

sub render {
    my($self, $message, $category, $priority, $caller_level) = @_;
    my $encoded_message = $self->SUPER::render($message, $category, $priority, $caller_level);
    
    # makes debugging easier
    if( defined $self->{PlainText} && $self->{PlainText} ){
        return $encoded_message;
    }
    
    # Graylog2 servers require gzipped messesages.
    my $gzipped_message;
    gzip \$encoded_message =>  \$gzipped_message or die "gzip failed: $GzipError\n";
    return  $gzipped_message;
}
1;
