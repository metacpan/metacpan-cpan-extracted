package FactorOracle;

use 5.008002;
use strict;
use warnings;

our $VERSION = '0.01';

# Factor Oracle data structure is in the form of two contiguous
# strings of data (in memory or on disk)
# STATES: [suffix link(int)][initial via char][transitions link (int)]
# TRANSITIONS: [via char][state link (int)][next trans (int)]



sub new {
    my $class = shift;
    my $self = { S => '', T => '' };

    # initial state
    $self->{S} .= pack("lal", -1, 'a', -1);
    return bless $self, $class;
}

sub add {
    my $self = shift;
    my $string = shift;
    for my $i (0..length($string)-1){
        $self->add_char( substr($string, $i, 1) );
    }
}



sub add_char {
    my $self = shift;
    my $char = shift;
    my $Slen = length $self->{S};
    die "bad length" unless ($Slen % 9) == 0;
    my $m = $Slen/9 - 1; # index of final state
    my $final = $m*9; # string index position of final state
    my $sl = $self->sl($m); # suffix link of final state

    # set initial transition via $char
    substr($self->{S}, $final+4, 1) = $char;


    while($sl > -1){
        if(my $state = $self->trans_exists($sl, $char)){
            $sl = $state; # [state pointed to by state $sl via $char]
            last;
        }
        else {
            # Create transition, follow back
            $self->create_trans($sl, $char, $m+1);
            $sl = $self->sl($sl);
        }
    }
    $sl = ($sl < 0) ? 0 : $sl;

    # Add new state with just suffix link initialized.
    $self->{S} .= pack("lal", $sl, 0, -1);
}

sub trans_exists {
    my $self = shift;
    my $from = shift;
    my $via = shift;

    my ($to, $char, $extra) = unpack("lal", substr($self->{S}, $from*9, 9));
    return $from+1 if $char eq $via;

    # search transition string for $via
    while($extra > -1){
        ($char, $to, $extra) = unpack("all", substr($self->{T}, $extra*9, 9));
        return $to if $char eq $via;
        last unless $extra > -1;
    }
    # no such transition exists
    return undef;
}


sub create_trans {
    my $self = shift;
    my $from = shift;
    my $via = shift;
    my $to = shift;

    my $ntrans = length($self->{T})/9;
    my(undef, undef, $extra) = unpack("lal", substr($self->{S}, $from*9, 9));
    if($extra == -1){
        substr($self->{S}, $from*9+5, 4) = pack("l", $ntrans);
	}
    while($extra > -1){
        my $next = unpack("l", substr($self->{T}, $extra*9+5, 4));
        if($next == 0){
            # point last trans to new linked trans
            substr($self->{T}, $extra*9+5, 4) = pack("l", $ntrans);
            last;
        }
        $extra = $next;
	}
    $self->{T} .= pack("all", $via, $to, -1);
}

sub states {
    my $self = shift;
    return length($self->{S})/9;
}

sub transitions {
    my $self = shift;
    return length($self->{T})/9;
}

sub sl {
    my $self = shift;
    my $state = shift;

    return unpack("l", substr($self->{S}, $state*9, 4));
}


1;
__END__

=head1 NAME

FactorOracle 

=head1 SYNOPSIS

  use FactorOracle;
  blah blah blah

=head1 DESCRIPTION

Blah blah blah.


=head1 SEE ALSO


=head1 AUTHOR

Ira Woodhead, E<lt>ira at h5technologies dot comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ira Woodhead

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
