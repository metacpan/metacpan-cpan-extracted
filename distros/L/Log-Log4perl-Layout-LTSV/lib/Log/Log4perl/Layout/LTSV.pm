package Log::Log4perl::Layout::LTSV;

use 5.008_001;
use strict;
use warnings;
use Encode;
use Log::Log4perl;
use POSIX qw(strftime);
use base qw(Log::Log4perl::Layout::PatternLayout);

$Log::Log4perl::ALLOW_CODE_IN_CONFIG_FILE = 1;

=head1 NAME

Log::Log4perl::Layout::LTSV - Log4perl for LTSV

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

Log4perl implementation of LTSV.

=head1 CONFIGURATION SAMPLE

    use Log::Log4perl
    my $logger_conf = {
      'log4perl.logger.test'                     => 'DEBUG, SERVER',
      'log4perl.appender.SERVER'                 => 'Log::Log4perl::Appender::Socket',
      'log4perl.appender.SERVER.PeerAddr'        => '10.1.2.3',
      'log4perl.appender.SERVER.PeerPort'        => '514',
      'log4perl.appender.SERVER.Proto'           => 'tcp',
      'log4perl.appender.SERVER.layout'          => 'LTSV',
      'log4perl.appender.SERVER.layout.facility' => 'Custom facility'
    };
    Log::Log4perl->init($logger_conf);
    my $LOGGER = Log::Log4perl->get_logger('test');
    $LOGGER->debug('Debug log');
    ...

=cut

=head1 SUBROUTINES/METHODS

=head2 new

    Can take most of options that Log::Log4perl::Layout::PatternLayout can.

=cut

sub new {
    my $class = shift;
    $class = ref($class) || $class;
    my $options = ref $_[0] eq 'HASH' ? shift : {};
    my $record = {
        'time'     => '%Z',
        'host'     => '%H',
        'message'  => '%m{chomp}',
        'level'    => '%Y',
        'facility' => '%M',
        'file'     => '%F',
        'line'     => '%L',
        'pid'      => '%P',
    };
    while ( my ($key) = each %{ $options->{field} } ) {
        $record->{$key} = $options->{field}->{$key}->{value};
    }
    my $conversion_pattern = _encode_ltsv($record);
    $options->{ConversionPattern} = { value => $conversion_pattern };
    $options->{cspec} = {
        'Y' => { value => \&_level_converter },
        'Z' => {
            value => sub {
                return strftime( '[%Y-%m-%dT%H:%M:%SZ]', gmtime( time() ) );
              }
        }
    };
    return $class->SUPER::new($options);
}

sub _encode_ltsv {
    my $hash = shift;
    my @res;
    while ( my ($key, $value) = each %$hash ) {
        $value =~ s/[\r\n\t]/ /g;
        if ( not Encode::is_utf8( $value, 1 ) ) {
            $value = Encode::encode( 'UTF-8', $value, Encode::FB_CROAK );
            Encode::_utf8_on($value);
        }
        push( @res, join( ':', $key, $value ) );
    }
    return join( "\t", @res );
}

sub _level_converter {
    my ( $layout, $message, $category, $priority, $caller_level ) = @_;
    my $levels = {
        'FATAL'  => 2,
        'ERROR'  => 3,
        'WARN'   => 4,
        'NOTICE' => 5,
        'INFO'   => 6,
        'DEBUG'  => 7
    };
    return $levels->{$priority};
}

=head2 render

    Wraps the Log::Log4perl::Layout::PatternLayout return value

=cut

sub render {
    my ( $self, $message, $category, $priority, $caller_level ) = @_;
    return $self->SUPER::render( $message, $category, $priority, $caller_level )
      . "\n";
}
1;
