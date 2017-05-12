
package GPS::Magellan::Message;

use strict;
use Data::Dumper;
use vars qw($AUTOLOAD);

sub new {
    my $proto = shift;
    my $raw_msg = shift;

    my $class = ref($proto) || $proto;

    my $self = bless {
        fields => [ qw/RAW COMMAND DATA CHECKSUM/ ],
    }, $class;
    
    $self->_init();

    return $self unless $raw_msg;

    $self->RAW($raw_msg);
    $self->_parse_message($raw_msg);
    $self;
}


sub _init {
    my $self = shift;

   foreach my $field (@{$self->fields}){
        $self->_set($field, "");
    }
}

sub verify_checksum {
    my $self = shift;
    $self->CHECKSUM eq $self->_checksum($self->RAW);
}

sub get {
    my $self = shift;
    $self->RAW(sprintf('PMGN%s,%s', $self->COMMAND, $self->DATA));
    sprintf('$%s*%s', $self->RAW, $self->_checksum($self->RAW));
}


sub _checksum {
    my $self = shift;
    my $msg = shift;
    
    my $chksum = 0;
    for (split //, $msg){
        $chksum ^= ord($_);
    }
    sprintf('%02X', $chksum);
}


sub _parse_message {
    my $self = shift;

    my @msg = $self->RAW =~ /
                     ^\$(
                            PMGN
                             ([A-Z]{3}),
                             (.*)
                        )
                        \*
                        ([A-Z0-9]{2})
                        $
                   /x or die sprintf("Cannot parse message: %s\n", $self->RAW);

    foreach my $field (@{$self->fields}){
        $self->_set($field, shift @msg);
    }
}

sub _dump {
    my $self = shift;
    Dumper($self);
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

__END__

=head1 NAME

GPS::Magellan::Message - Module encapsulating Magellan (NMEA) messages

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION

This class is being used internally by the L<GPS::Magellan> class.

=head1 METHODS

=over 4

=cut

=item new ( RAW_MESSAGE )


=cut


=back 4

=head1 PREREQUISITES

L<>

=head1 AUTHOR

Peter Banik E<lt>peter@geospaces.netE<gt>

=head1 SEE ALSO

L<GPS::Magellan>

=head1 VERSION

$Id: Message.pm,v 1.1.1.1 2004/02/29 21:45:16 peter Exp $

=head1 BUGS

Please report bugs to the author.

=head1 COPYRIGHT

Copyright (c) 1993 - 2003 

=cut



