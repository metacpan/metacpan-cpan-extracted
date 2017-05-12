package Games::Lacuna::Task::Role::Logger;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose::Role;

use Games::Lacuna::Task::Utils qw(pretty_dump format_date);
use IO::Interactive qw(is_interactive);
use Term::ANSIColor qw(color);

our @LEVELS = qw(debug info notice warn error);
our @COLORS = qw(white cyan magenta yellow red);

has 'loglevel' => (
    is              => 'rw',
    isa             => Moose::Util::TypeConstraints::enum(\@LEVELS),
    default         => 'info',
    documentation   => 'Print all messages equal or above the given level [Default: info, Available: '.join(',',@LEVELS).']',
);

has 'debug' => (
    is              => 'rw',
    isa             => 'Bool',
    default         => 0,
    documentation   => 'Log all messages to debug.log',
);

sub abort {
    my ( $self, @msgs ) = @_;
    my ($level_name,$logmessage) = $self->_format_message('error',@msgs);
    die $logmessage;
}

sub _format_message {
    my ( $self, @msgs ) = @_;
    
    my $level_name = shift(@msgs)
        if $msgs[0] ~~ \@LEVELS;
    
    @msgs = map { pretty_dump($_) } @msgs;
    
    my $format = shift(@msgs) // '';
    my $logmessage = sprintf( $format, map { $_ // 'UNDEF' } @msgs );
    
    return ($level_name,$logmessage);
}

sub log {
    my ( $self, @msgs ) = @_;
    
    my ($level_name,$logmessage) = $self->_format_message(@msgs);
   
    if (is_interactive()) {
        my ($level_pos) = grep { $LEVELS[$_] eq $level_name } 0 .. $#LEVELS;
        my ($level_max) = grep { $LEVELS[$_] eq $self->loglevel } 0 .. $#LEVELS;   
 
        binmode STDOUT, ":utf8";
        if ($level_pos >= $level_max) {
            print color 'bold '.($COLORS[$level_pos] || 'white');
            printf "%6s: ",$level_name;
            print color 'reset';
            say $logmessage;
        }
    }
    
    if ($self->debug && $self->can('configdir')) {
        state $fh;
        $fh ||= Path::Class::File->new($self->configdir,'debug.log')->open('a',':encoding(UTF-8)');
        say $fh sprintf("%s\t%s\t%s",format_date(time),$level_name,$logmessage);
    }

    return ($level_name,$logmessage);
}

no Moose::Role;
1;

=encoding utf8

=head1 NAME

Games::Lacuna::Role::Logger - Prints log messages

=head1 ACCESSORS

=head2 loglevel

Specify the loglevel. Will print all log messages equal or above the given
level if running in an interactive shell. 

=head1 METHODS

=head2 log

Print a log message. You can use the sprintf syntax.

 $self->log($loglevel,$message,@sprintf_params);

=head2 abort

Dies with a pretty error message

 $self->abort($message,@sprintf_params);

=cut
