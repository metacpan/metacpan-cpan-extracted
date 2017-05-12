package HTTP::Cookies::w3m;
use base qw( HTTP::Cookies );
use strict;
use warnings;
use Carp qw(carp);

our $VERSION = '0.01';

use constant SECURE  =>  2;
use constant PATH    =>  8;
use constant DISCARD => 16;

use constant EPOCH_OFFSET => $^O eq "MacOS" ? 21600 : 0;

sub load {
    my($self, $file) = @_;
    $file ||= $self->{'file'} || return;

    my $fh;
    unless (open $fh, $file) {
        carp "Could not open file [$file]: $!";
        return;
    }

    my $now = time() - EPOCH_OFFSET;
    while (<$fh>) {
        next if /^\s*$/;
        s/[\r\n]//g;

        my($url, $name, $value, $expires, $domain, $path, $flag, $version, $portlist) = split /\t/;
        my $port = undef;
        $port = $1 if $portlist =~ /(\d+)/;
        $self->set_cookie($version, $name, $value, $path, $domain, $port,
            ($flag & PATH), ($flag & SECURE), $expires - $now, ($flag & DISCARD));
    }
    close($fh);

    1;
}

sub save {
    warn 'save method is not supported...';
    return;
}

1;

=head1 NAME

HTTP::Cookies::w3m - Cookie storage and management for w3m

=head1 SYNOPSIS

  use HTTP::Cookies::w3m;
  $cookie_jar = HTTP::Cookies::w3m->new(file => '/home/user/.w3m/cookie');

=head1 DESCRIPTION

This package overrides the load() and save() methods of HTTP::Cookies
so it can work with w3m cookie files.

=head1 NOTE

save() is don't work.

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::Cookies>.

=cut

