package Lemonldap::NG::Common::Logger::Dispatch;

use strict;

our $VERSION = '2.0.15';

sub new {
    no warnings 'redefine';
    my $self = bless {}, shift;
    my ( $conf, %args ) = @_;
    my ( %bck, $last );
    my $root = $args{user} ? 'userLogDispatch' : 'logDispatch';
    my $show = 1;
    die "At least, ${root}Error must be defined in conf"
      unless ( $conf->{ $root . 'Error' } );

    foreach my $l (qw(error warn notice info debug)) {
        if ($show) {
            $last = $conf->{ $root . ucfirst($l) } || $last;
            unless ( $bck{$last} ) {
                eval "require $last";
                die $@ if ($@);
                $bck{$last} = $last->new(@_);
            }
            my $obj = $bck{$last};
            eval "sub $l {
                shift;
                return \$obj->$l(\@_);
            }";
        }
        else {
            eval qq'sub $l {1}';
        }
        $show = 0 if ( $conf->{logLevel} eq $l );
    }
    die "Unknown logLevel $conf->{logLevel}" if $show;

    return $self;
}

1;
