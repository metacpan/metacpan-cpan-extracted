package IO::All::HTTPS;
use strict;
use warnings;
our $VERSION = '0.14';
use IO::All::HTTP '-base';

const type => 'https';

sub https { my $self=shift;$self->lwp_init(__PACKAGE__, @_) }

1;

__END__

=head1 NAME

IO::All::HTTPS - Extends IO::All for HTTPS URLs

=head1 SYNOPSIS

    use IO::All;

    $content < io('https://example.org');   # GET webpage

    # two ways of getting a page with a password:
    $content < io('https://me:secret@example.org');
    $content < io('https://example.org')->user('me')->password('secret');


=head1 DESCRIPTION

This module extends L<IO::All> for dealing with HTTPS URLs. 
Note that you don't need to use it explicitly, as it is autoloaded by
L<IO::All> whenever it sees something that looks like an HTTPS URL.

The SYNOPSIS shows some simple typical examples, but there are many other
interesting combinations with other IO::All features! For example, you can get
an HTTPS URL and write the content to a socket, or to an FTP URL, of to a DBM
file.

=head1 METHODS

This is a subclass of L<IO::All::LWP>. The only new method is C<https>, which
can be used to create a blank L<IO::All::HTTPS> object; or it can also take an
HTTPS URL as a parameter. Note that in most cases it is simpler just to call
io('https://example.com'), which calls the C<https> method automatically.

=head1 OPERATOR OVERLOADING

The same operators from IO::All may be used. < GETs an HTTPS URL; > PUTs to
an HTTPS URL.

=head1 SEE ALSO

L<IO::All>, L<IO::All::LWP>, L<LWP>.

=head1 AUTHORS

Ivan Tubert-Brohman <itub@cpan.org> and 
Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007. Ivan Tubert-Brohman and Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

