

package GPS::Magellan::Coord;

use strict;
use Data::Dumper;
use vars qw($AUTOLOAD);

sub new {
    my $proto = shift;
    my $raw_data = shift;

    die "GPS::Magellan::Coord::new() didn't get raw data\n" unless $raw_data; 

    my $class = ref($proto) || $proto;

    my $self = bless { }, $class;

    $self->fields( [ qw/longitude lnsign latitude ltsign altitude unknown name description icon/ ] );

    $self->_parse($raw_data);

    return $self;
}

sub _parse {
    my $self = shift;
    my $raw_data = shift or die "GPS::Magellan::Coord->new() didn't get raw data\n";

    my @fields = qw/longitude lnsign latitude ltsign altitude unknown name description icon/;
    
    foreach my $val (split /,/, $raw_data){
        my $field = shift @fields;
        $self->_set($field, $val);
    }
}


sub _dump {
    my $self = shift;

    my @fields = qw/longitude lnsign latitude ltsign altitude unknown name description icon/;
    foreach my $field (@fields){
       printf "%20s -> %20s\n", $field, $self->_get($field);
    }
}

# Accessors
sub _get {
    my $self = shift;
    my $attr = shift;
    return $self->{$attr};
}

sub _set {
    my $self = shift;
    my $attr = shift;
    my $value = shift || '';

    return unless $attr;

    $self->{$attr} = $value;
    return $self->_get($attr);
}

sub _debug_autoload {
    my $self = shift;
    $self->_set('_debug_autoload', shift) if @_;
    $self->_get('_debug_autoload');
}

    
sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;

    $attr =~ s/.*:://;

    return if $attr =~ /^_/;

    warn "AUTOLOAD: $attr\n" if $self->_debug_autoload;

    if(@_){
        $self->_set($attr, shift);
    }
    return $self->_get($attr);
}

sub DESTROY {

}


1;

