package Git::Demo::Action::Git;
use strict;
use warnings;
use File::Spec::Functions;

sub new{
    my $class = shift;
    my $args = shift;

    my $self = {};
    my $logger = Log::Log4perl->get_logger( __PACKAGE__ );
    $self->{logger} = $logger;

    bless $self, $class;
    return $self;
}

sub run{
    my( $self, $character, $event ) = @_;

    # Git output is slung to warn... catch and deal with warnings a bit better!
    local $SIG{__WARN__} = sub
      {
          foreach( @_ ){
              # Stupidly, not all Git output goes to output... some goes to warnings...
              print "Git WARN: $_\n";
          }
          # Allow a repeat
          if( pause() ){
              return $self->run( $character, $event );
          }
      };

    my $git = $character->git();
    my @cmd = $event->action();
    push( @cmd, @{ $event->args() } );
    $self->{logger}->info( sprintf( "Git (%s): git %s", $character->name(), join( ' ', @cmd ) ) );
    my $rtn = $git->run( @cmd );
    if( $rtn !~ m/^\s*$/ ){
        $rtn .= "\n";
    }
    return $rtn;
}

sub pause{
    print "Repeat (r) or Continue ([enter])?";
    my $in = <STDIN>;
    chomp( $in );
    if( lc( $in ) eq 'r' ){
        return 1;
    }
    return undef;
}

1;
