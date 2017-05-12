package IO::All::FTP;
use strict;
use warnings;
our $VERSION = '0.14';
use IO::All::LWP '-base';

const type => 'ftp';

sub ftp { my $self=shift; $self->lwp_init(__PACKAGE__, @_) }

1;

__END__

=head1 NAME

IO::All::FTP - Extends IO::All to FTP URLs

=head1 SYNOPSIS

    use IO::All;

    "hello world\n" > io('ftp://localhost/test/x');  # save to FTP
    io('ftp//example.org/pub/xyz') > io('xyz');      # GET to file

    # two ways of getting a file with a password:
    $content < io('ftp://me:secret@example.org/xyz');
    $content < io('ftp://example.org/xyz')->user('me')->password('secret');

=head1 DESCRIPTION

This module extends IO::All for dealing with FTP URLs.
Note that you don't need to use it explicitly, as it is autoloaded by
L<IO::All> whenever it sees something that looks like an FTP URL.

=head1 METHODS

This is a subclass of L<IO::All::LWP>. The only new method is C<ftp>, which
can be used to create a blank L<IO::All::FTP> object; or it can also take an
FTP URL as a parameter. Note that in most cases it is simpler just to call
io('ftp//example.com'), which calls the C<ftp> method automatically.

=head1 OPERATOR OVERLOADING

The same operators from IO::All may be used. < GETs an FTP URL; > PUTs to
an FTP URL.

=head1 SEE ALSO

L<IO::All::LWP>, L<IO::All>, L<LWP>.

=head1 AUTHORS

Ivan Tubert-Brohman <itub@cpan.org> and 
Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007. Ivan Tubert-Brohman and Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

