package t::TestStdLogger;

use strict;

our $VERSION = '2.0.15';

sub new {
    no warnings 'redefine';
    my $level = $_[1]->{logLevel} || 'info';
    my $show  = 1;
    my $self  = bless {}, shift;

    foreach my $l (qw(error warn notice info debug)) {
        if ($show) {
            $self->{$l} = sub { logprint( $l, $_[0] ) };
        }
        else {
            $self->{$l} = sub { 1 };
        }
        $show = 0 if ( $level eq $l );
    }
    die "Unknown logLevel $level" if $show;

    return $self;
}

sub error  { $_[0]->{error}->( $_[1] ) }
sub warn   { $_[0]->{warn}->( $_[1] ) }
sub notice { $_[0]->{notice}->( $_[1] ) }
sub info   { $_[0]->{info}->( $_[1] ) }
sub debug  { $_[0]->{debug}->( $_[1] ) }

sub logprint {
    my ( $level, $message ) = @_;
    my $tag =
      @main::currenthandler
      ? ( "[" . join( "->", @main::currenthandler ) . "] " )
      : "";
    print STDERR "[" . localtime . "] ${tag}[$level] $message\n";
}

1;
