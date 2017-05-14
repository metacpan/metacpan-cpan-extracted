package IP::QQWry::Decoded;

use 5.008;
use warnings;
use strict;
use base 'IP::QQWry';
use Encode;

sub new {
    my ( $class, $db, $encoding ) = @_;
    my $self = {};
    bless $self, $class;
    if ($db) {
        $self->set_db($db);
    }

    if ( $encoding ) {
        $self->{encoding} = $encoding;
    }

    return $self;
}

sub encoding {
    return $_[0]->{encoding};
}

sub query {
    my $self = shift;
    my @ret = $self->SUPER::query(@_);
    return unless @ret;
    my @converted;

    if ($self->encoding) {
        @converted = map { decode( $self->encoding, $_ ) } @ret;
    }
    else {
        # then it's either gbk or big5
        eval {
            @converted = map { decode( 'gbk', $_ ) } @ret;
        };

        if ($@) {
            @converted = map { decode( 'big5', $_ ) } @ret;
        }
    }

    die "failed to decode" unless @converted;
    return wantarray ? @converted : join '', @converted;
}

1;

__END__

=head1 NAME

IP::QQWry::Decoded - a simple interface for QQWry IP database(file).


=head1 SYNOPSIS

    use IP::QQWry::Decoded;
    my $qqwry = IP::QQWry::Decoded->new('QQWry.Dat', 'gbk');
    my $info = $qqwry->query('166.111.166.111');

=head1 DESCRIPTION

Use this to get decoded info.

=head1 SEE ALSO

L<IP::QQWry>

=head1 AUTHOR

sunnavy  C<< <sunnavy@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2011, sunnavy C<< <sunnavy@gmail.com> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
