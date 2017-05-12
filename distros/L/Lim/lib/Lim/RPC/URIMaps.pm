package Lim::RPC::URIMaps;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(weaken);

use Lim ();

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;
our %_MAP_CACHE_CODE;

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {
        logger => Log::Log4perl->get_logger($class),
        maps => []
    };
    bless $self, $class;
    weaken($self->{logger});

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
}

=head2 add

=cut

sub add {
    my ($self, $map) = @_;
    my (@regexps, @variables, $regexp, $n, $code, $call, $predata);

    #
    # See if this is a redirect call and check if we have the map in cache
    #

    if ($map =~ /^(\S+)\s+=>\s+(\w+)(?:\s+(\S+))?$/o) {
        ($map, $call, $predata) = ($1, $2, $3);
    }
    elsif ($map =~ /^(\S+)\s+(\S+)$/o) {
        ($map, $call, $predata) = ($1, '', $2);
    }
    else {
        $call = '';
    }

    my $map_key = $map.' '.$call;
    if (exists $_MAP_CACHE_CODE{$map_key} and defined $_MAP_CACHE_CODE{$map_key}) {
        push(@{$self->{maps}}, $_MAP_CACHE_CODE{$map_key});
        return $call;
    }

    #
    # Validate and pull out parts of the map used to generate regexp and code
    #

    foreach my $map_part (split(/\//o, $map)) {
        if ($map_part =~ /^\w+$/o) {
            push(@regexps, $map_part);
        }
        elsif ($map_part =~ /^((?:\w+\.)*\w+)=(.+)$/o) {
            push(@variables, $1);
            push(@regexps, '('.$2.')');
        }
        else {
            Lim::DEBUG and $self->{logger}->debug('Validation of map "', $map, '" failed');
            $@ = 'Map is not valid';
            return;
        }
    }

    #
    # Validate the regexp made from the map by compiling it with qr
    #

    $regexp = '^'.join('\/', @regexps).'$';
    eval {
        my $dummy = qr/$regexp/;
    };
    if ($@) {
        Lim::DEBUG and $self->{logger}->debug('Regexp compilation of map "', $map, '" failed: ', $@);
        return;
    }

    #
    # Generate the code that checked given URI with generated regexp and adds
    # data gotten by the regexp to the data structure defined by the map
    #

    $code = '';

    if ($predata) {
        foreach my $predata_variable (split(/,/o, $predata)) {
            if ($predata_variable =~ /^([^=]+)=(.+)$/o) {
                my ($variable, $value) = ($1, $2);

                $code .= '$data->{'.join('}->{', split(/\./o, $variable)).'} = \''.$value.'\';';
            }
            else {
                Lim::DEBUG and $self->{logger}->debug('Predata of map "', $map, '" invalid');
                $@ = 'Predata is not valid';
                return;
            }
        }
    }

    if (scalar @variables) {
        $code .= 'my (';

        $n = 1;
        while ($n <= scalar @variables) {
            $code .= '$v'.$n.($n != scalar @variables ? ',' : '');
            $n++;
        }

        $code .= ')=(';

        $n = 1;
        while ($n <= scalar @variables) {
            $code .= '$'.$n.($n != scalar @variables ? ',' : '');
            $n++;
        }

        $code .= ');';

        $n = 1;
        foreach my $variable (@variables) {
            $code .= '$data->{'.join('}->{', split(/\./o, $variable)).'} = $v'.($n++).';';
        }
    }

    #
    # Create the subroutine from the generated code
    #

    eval '$code = sub { my ($uri, $data)=@_; if($uri =~ /'.$regexp.'/o) { '.$code.' return \''.$call.'\';} return; };';
    if ($@) {
        Lim::DEBUG and $self->{logger}->debug('Code generation of map "', $map, '" failed: ', $@);
        return;
    }

    #
    # Verify code by calling it in eval
    #

    eval {
        $code->('', {});
    };
    if ($@) {
        Lim::DEBUG and $self->{logger}->debug('Verify code of map "', $map, '" failed: ', $@);
        return;
    }

    #
    # Store the generated subroutine and return success
    #

    $_MAP_CACHE_CODE{$map_key} = $code;
    weaken($_MAP_CACHE_CODE{$map_key});
    push(@{$self->{maps}}, $code);
    return $call;
}

=head2 process

=cut

sub process {
    my ($self, $uri, $data) = @_;

    unless (ref($data) eq 'HASH') {
        confess '$data parameter is not a hash';
    }

    foreach my $map (@{$self->{maps}}) {
        if (defined (my $ret = $map->($uri, $data))) {
            return $ret;
        }
    }
    return;
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Lim

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::RPC::URIMaps
