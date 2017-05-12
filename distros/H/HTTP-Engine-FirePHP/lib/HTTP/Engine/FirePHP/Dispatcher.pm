package HTTP::Engine::FirePHP::Dispatcher;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(FirePHP::Dispatcher);

sub send_headers {
    my $self = shift;
    $self->SUPER::send_headers(@_);
    $self->finalize;
}

sub rollback_last_message {
    my $self = shift;
    $self->SUPER::rollback_last_message(@_);
    $self->finalize;
}

sub start_group {
    my $self = shift;
    $self->SUPER::start_group(@_);
    $self->finalize;
}

sub end_group {
    my $self = shift;
    $self->SUPER::end_group(@_);
    $self->finalize;
}

1;

__DATA__

=head1 NAME

HTTP::Engine::FirePHP::Dispatcher - An extension of FirePHP::Dispatcher

=head1 SYNOPSIS

    # None - this class is used by L<HTTP::Engine::FirePHP>. You should not
    # need to use it directly.

=head1 DESCRIPTION

This class extends L<FirePHP::Dispatcher> so that after headers are
manipulated, C<finalize()> is called. That way the developer who wants to log
to FirePHP doesn't have to worry about administrativa. The performance impact
is minimal, especially since FirePHP will be used only during debugging. Also,
calling C<finalize()> several times does not alter the result - there
aren't duplicate headers or something like that.

=head1 METHODS

=over 4

=item send_headers()

=item rollback_last_message()

=item start_group()

=item end_group()

Like the superclass' methods, except they also call C<finalize()> afterwards.

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see L<http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

The development version lives at
L<http://github.com/hanekomu/http-engine-firephp/>. Instead of sending
patches, please fork this project using the standard git and github
infrastructure.

=head1 AUTHORS

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

