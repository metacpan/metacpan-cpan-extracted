# PODNAME: Finance::Dogecoin::Utils::ProxyActions
# ABSTRACT: proxy and enhance RPC made to a Dogecoin Core node
use Object::Pad;

use strict;
use warnings;

class Finance::Dogecoin::Utils::ProxyActions {
    use JSON;
    use Path::Tiny;
    use feature 'say';

    field $rpc          :param;
    field $json         :param;
    field $addresses    :param;
    field $address_file :param;

    sub BUILDARGS( $class, %args ) {
        $args{json} //= JSON->new->utf8(1);
        $args{address_file} = path( $args{address_file} );
        $args{addresses} //= do {
            if ($args{address_file}->exists) {
                $args{json}->decode( $args{address_file}->slurp_utf8 );
            }
            else {
                {}
            }
        };

        return %args;
    }

    method setlabel( $address, $label ) {
        $addresses->{$label} = $address;
        return 1;
    }

    method getreceivedbylabel( $label, @args ) {
        if (my $address = $addresses->{$label}) {
            my $output = $rpc->call_method( getreceivedbyaddress => $address, @args );
            say $json->encode( $output );
        } else {
            warn "No address label '$label' found\n";
            return 0;
        };

        return 1;
    }

    method DESTROY {
        return unless $address_file;
        $address_file->spew_utf8( $json->encode( $addresses ) );
        undef $address_file;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Dogecoin::Utils::ProxyActions - proxy and enhance RPC made to a Dogecoin Core node

=head1 VERSION

version 1.20221211.2353

=head1 SYNOPSIS

Utilities to proxy RPC to a Dogecoin Core node.

=head1 COPYRIGHT

Copyright (c) 2022 chromatic

=head1 AUTHOR

chromatic

=head1 AUTHOR

chromatic <chromatic@wgz.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by chromatic.

This is free software, licensed under:

  The MIT (X11) License

=cut
