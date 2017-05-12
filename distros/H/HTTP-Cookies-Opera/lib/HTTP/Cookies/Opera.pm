package HTTP::Cookies::Opera;

use strict;
use warnings;

use parent qw(HTTP::Cookies);
use Carp qw(croak);

our $VERSION = '0.08';
$VERSION = eval $VERSION;

use constant DEBUG    => !! $ENV{HTTP_COOKIES_OPERA_DEBUG};
use constant FILE_VER => 1;
use constant APP_VER  => 2;
use constant TAG_LEN  => 1;
use constant LEN_LEN  => 2;

sub load {
    my ($self, $file) = @_;
    $file ||= $self->{file} or return;

    open my $fh, '<', $file or die "$file: $!";
    binmode $fh;
    12 == read($fh, my $header, 12) or croak 'bad file header';
    my ($file_ver, $app_ver, $tag_len, $len_len) = unpack 'NNnn', $header;

    croak 'unexpected file format'
        unless FILE_VER == $file_ver >> 12 and APP_VER == $app_ver >> 12
            and TAG_LEN == $tag_len and LEN_LEN == $len_len;

    my (@domain_parts, @path_parts, %cookie);

    while (TAG_LEN == read $fh, my $tag, TAG_LEN) {
        $tag = unpack 'C', $tag;
        DEBUG and printf "tag: %#x\n", $tag;

        # End of domain component.
        if (0x84 == $tag) {
            pop @domain_parts;
        }
        # End of path component.
        elsif (0x85 == $tag) {
            pop @path_parts;

            # Add last constructed cookie as this path will have no more.
            $self->_add_cookie(\%cookie);
        }
        elsif (0x99 == $tag) { $cookie{secure} = 1 }
        elsif (0x3 == $tag) {
            # Add previous cookie now that it is fully constructed.
            $self->_add_cookie(\%cookie);

            # Reset cookie for new record.
            %cookie = (
                domain => join('.', reverse @domain_parts),
                path   => '/' . join('/', @path_parts),
            );
        }

        # Record is a flag and contains no payload.
        next if 0x80 & $tag;

        LEN_LEN == read $fh, my $len, LEN_LEN or croak 'bad file';

        # Tags have unique ids among top-level domain/path/cookie records as
        # well as the payload records, so simplify parsing by treating the
        # payload records as top-level records during the next iteration.
        next if 0x3 >= $tag;

        $len = unpack 'n', $len;
        DEBUG and printf "  len: %d\n", $len;
        $len == read $fh, my $payload, $len or croak 'bad file';

        if    (0x1e == $tag) { push @domain_parts, $payload }
        elsif (0x1d == $tag) { push @path_parts, $payload }
        elsif (0x10 == $tag) { $cookie{key} = $payload }
        elsif (0x11 == $tag) { $cookie{val} = $payload }
        elsif (0x12 == $tag) {
            # Time is stored in 8 bytes for Opera >=10, 4 bytes for <10.
            $payload = unpack 8 == $len ? 'x4N' : 'N', $payload;
            $cookie{maxage} = $payload - time;
            DEBUG and $payload = scalar localtime $payload;
        }
        elsif (0x1a == $tag) {
            # Version- not yet seen.
        }

        DEBUG and printf "  payload: %s\n", $payload;
    }

    close $fh;

    return 1;
}

sub _add_cookie {
    my ($self, $cookie) = @_;

    return unless exists $cookie->{key};

    $self->set_cookie(
        undef, @$cookie{qw(key val path domain)}, undef, undef,
        @$cookie{qw(secure maxage)}, undef, undef
    );
}

sub save {
    my ($self, $file) = @_;
    $file ||= $self->{file} or return;

    open my $fh, '>', $file or die "$file: $!";
    binmode $fh;

    print $fh pack 'NNnn', FILE_VER << 12, APP_VER << 12, TAG_LEN, LEN_LEN;

    # Cannot call scan() as it iterates over the domains in lexical order,
    # but Opera requires the cookies to be stored in a hierarchy of domain
    # components (i.e. com -> opera -> www).
    my @domains = sort { $a->[0] cmp $b->[0] } map  {
        # Do not split IP addresses into components.
        my @parts = /^(?:\d+\.){3}\d+$/ ? ($_) : reverse split '\.';
        [ join('.', @parts), $_, \@parts ]
    } keys %{$self->{COOKIES}};

    # Add an empty domain field to close the last open domain record.
    push @domains, [];

    my @prev_domain;
    for my $aref (@domains) {
        my ($sort_key, $domain, $parts) = @$aref;

        # Opera does not support cross-subdomain cookies.
        #
        # TODO: if a domain cookie and a cross-subdomain cookie both exist
        # for the same key, which should take precedence?
        my $is_cross = $parts && length $parts->[-1] ? 0 : pop @$parts || 1;

        # Close domain component records for previous domain.
        for (my $i = @prev_domain - 1; 0 <= $i; $i--) {
            my $prev = $prev_domain[$i];
            if (length $prev and $prev ne ($parts->[$i] || '')) {
                DEBUG and print "  closing: $prev\n";
                pop @prev_domain;
                print $fh pack 'C', 0x84;
            }
        }

        last unless $domain;
        DEBUG and print "domain: $domain\n";

        # Open domain component records for next domain.
        for (my $i = @prev_domain; $i < @$parts;  $i++) {
            my $curr = $parts->[$i];
            if (length $curr and $curr ne ($prev_domain[$i] || '')) {
                DEBUG and print "  opening: $curr\n";
                push @prev_domain, $curr;
                print $fh pack 'Cn', 0x1, 3 + length($curr);
                print $fh pack 'Cn', 0x1e, length($curr);
                print $fh $curr;
                print $fh pack 'C', 0x85 if $i < @$parts - 1;
            }
        }

        my @paths = sort keys %{$self->{COOKIES}{$domain}};

        # Add an empty path field to close the last open path record.
        push @paths, '';

        my @prev_path;
        for my $path (@paths) {
            my @parts = split '/', $path;
            shift @parts;

            # Close path component records for previous path.
            for (my $i = @prev_path - 1; 0 <= $i; $i--) {
                my $prev = $prev_path[$i];
                if (length $prev and $prev ne ($parts[$i] || '')) {
                    DEBUG and print "    closing: $prev\n";
                    print $fh pack 'C', 0x85;
                    pop @prev_path;
                }
            }

            last unless $path;
            DEBUG and print "  path: $path\n";

            # Open path component records for next path.
            for (my $i = @prev_path; $i < @parts;  $i++) {
                my $curr = $parts[$i];
                if (length $curr and $curr ne ($prev_path[$i] || '')) {
                    DEBUG and print "    opening: $curr\n";
                    print $fh pack 'Cn', 0x2, 3 + length($curr);
                    print $fh pack 'Cn', 0x1d, length($curr);
                    print $fh $curr;
                    push @prev_path, $curr;
                }
            }

            my $href = $self->{COOKIES}{$domain}{$path};
            while (my ($key, $aref) = each %$href) {
                my (
                    $version, $val, $port, $path_spec, $secure, $expires,
                    $discard, $rest
                ) = @$aref;

                next if $discard and not $self->{ignore_discard};
                if (defined $expires and time > $expires) {
                    DEBUG and print "    expired cookie: $key\n";
                    next;
                }

                DEBUG and print "    cookie: $key -> $val\n";
                print $fh pack 'Cn', 0x3,
                    17 + length($key) + length($val) + !! $secure;
                print $fh pack('Cn', 0x10, length($key)), $key;
                print $fh pack('Cn', 0x11, length($val)), $val;
                print $fh pack 'Cnx4N', 0x12, 8, $expires;
                print $fh pack 'C', 0x99 if $secure;
            }
        }

        print $fh pack 'C', 0x85;
    }

    print $fh pack 'C', 0x84;
    close $fh;

    return 1;
}


1;

__END__

=head1 NAME

HTTP::Cookies::Opera - Cookie storage and management for Opera

=head1 SYNOPSIS

    use HTTP::Cookies::Opera;
    $cookie_jar = HTTP::Cookies::Opera->new(file => $file);

=head1 DESCRIPTION

The C<HTTP::Cookies::Opera> module is a subclass of C<HTTP::Cookies> that
can C<load()> and C<save()> Opera cookie files.

=head1 SEE ALSO

L<HTTP::Cookies>

L<http://www.opera.com/docs/operafiles/#cookies>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=HTTP-Cookies-Opera>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTTP::Cookies::Opera

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/http-cookies-opera>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTTP-Cookies-Opera>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTTP-Cookies-Opera>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Cookies-Opera>

=item * Search CPAN

L<http://search.cpan.org/dist/HTTP-Cookies-Opera/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2013 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
