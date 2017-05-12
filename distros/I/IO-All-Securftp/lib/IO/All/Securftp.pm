package IO::All::Securftp;

use warnings;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use IO::All::Securftp::iowrap qw();
use IO::All 0.30 '-base';

const type => "securftp";

=head1 NAME

IO::All::Securftp - Securftp handler for IO::All

=cut

$VERSION   = '0.001';

=head1 SYNOPSIS

  use IO::All;

  $content < io('securftp://remote@server/path/to/file.ext');
  io('Securftp://user@host/path/to/file.ext') > io("$tmpdir/file.ext");
  
  io('Securftp://user@host/path/to/file.ext')->print("Hello world: $msg\n");
  my $content = io($self->{uri} . "/$filename")->open("<", { get_content => { conversion => 'unix2dos' } })->slurp();

=head1 DESCRIPTION

This module extends IO::All for dealing with secure ftp remotes.

=head1 METHODS

=head2 SecureFTP_init

Called by uri handler of IO::All. The capability of user specified parameters
are limited.

=cut

sub SecureFTP_init
{
    my $self = shift;
    bless $self, shift;
    @_ and $self->name(shift);
    $self->_init;
}

=head2 securftp

Called by uri handler of IO::All. The capability of user specified parameters
are limited.

=cut

sub securftp { my $self=shift; $self->SecureFTP_init(__PACKAGE__, @_) }

=head2 open

Called whenever a handle shall be opened for reading or writing. Can be
triggered manually or automatically.

  $io->open($mode, \%options?)

As C<$mode> values are "<", ">" and ">>" supported.

The C<%options> hash is passed to L<IO::All::Securftp::iowrap>.

=cut

sub open
{
    my $self = shift;
    $self->is_open(1);
    my $mode = @_ ? shift : $self->mode ? $self->mode : '<';
    $self->mode($mode);
    my $opts = @_ ? shift : {};
    my $sftph = IO::All::Securftp::iowrap->new($self->name, $opts);
    if ($mode eq '<') {
	$sftph->_fetch();
    }
    elsif ($mode eq '>') {
	$sftph->_preput();
    }
    elsif ($mode eq '>>') {
	$sftph->_preappend();
    }
    $self->io_handle($sftph);
    $self;
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-IO-All-Securftp at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-All-Securftp>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::All::Securftp

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-All-Securftp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-All-Securftp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO-All-Securftp>

=item * Search CPAN

L<http://search.cpan.org/dist/IO-All-Securftp/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

=cut

1;    # End of IO::All::Securftp
