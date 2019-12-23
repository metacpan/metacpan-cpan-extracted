package Lemonldap::NG::Common::Logger::_Duplicate;

use strict;

our $VERSION = '2.0.6';

sub new {
    my $self = bless {}, shift;
    my ( $conf, %args ) = @_;
    eval "require $args{logger}";
    die $@ if ($@);
    $self->{logger} = $args{logger}->new(@_);
    $self->{dup}    = $args{dup} or die 'Missing dup';
    return $self;
}

sub AUTOLOAD {
    my $self = shift;
    no strict;
    $AUTOLOAD =~ s/.*:://;
    return if $AUTOLOAD eq 'DESTROY';
    $self->{logger}->$AUTOLOAD(@_);
    my $msg = shift;
    $msg = "[$AUTOLOAD] $msg";
    $self->{dup}->debug( $msg, @_ );
}

1;
