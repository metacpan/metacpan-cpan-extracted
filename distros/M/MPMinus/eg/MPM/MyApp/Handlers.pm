package MPM::MyApp::Handlers; # $Id$
use strict;

=head1 NAME

MPM::MyApp::Handlers - MPMinus Init Handler of MyApp

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    PerlInitHandler MPM::MyApp::Handlers

=head1 DESCRIPTION

MPMinus MyApp Init Handler

=head1 HISTORY

See C<Changes> file

=head1 SEE ALSO

L<MPMinus>

=head1 AUTHOR

Mr. Anonymous E<lt>root@localhostE<gt>

=head1 COPYRIGHT

Copyright (C) 2019 Mr. Anonymous. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use MPMinus;

use base qw/MPMinus::BaseHandlers/;

use vars qw($VERSION);
$VERSION = '1.00';

sub handler {
    my $r = shift;
    my $m = MPMinus->m;
    $m->conf_init($r, __PACKAGE__);
    __PACKAGE__->Init($m);

    # Handlers
    $r->handler('modperl'); # modperl, perl-script
    #$r->push_handlers(PerlHeaderParserHandler => sub { __PACKAGE__->HeaderParserHandler($m) });
    $r->push_handlers(PerlAccessHandler   => sub { __PACKAGE__->AccessHandler($m) });
    $r->push_handlers(PerlAuthenHandler   => sub { __PACKAGE__->AuthenHandler($m) });
    $r->push_handlers(PerlAuthzHandler    => sub { __PACKAGE__->AuthzHandler($m) });
    $r->push_handlers(PerlTypeHandler     => sub { __PACKAGE__->TypeHandler($m) });
    $r->push_handlers(PerlFixupHandler    => sub { __PACKAGE__->FixupHandler($m) });
    $r->push_handlers(PerlResponseHandler => sub { __PACKAGE__->ResponseHandler($m) });
    $r->push_handlers(PerlLogHandler      => sub { __PACKAGE__->LogHandler($m) });
    $r->push_handlers(PerlCleanupHandler  => sub { __PACKAGE__->CleanupHandler($m) });

    return __PACKAGE__->InitHandler($m);
}
sub InitHandler {
    my $pkg = shift;
    my $m = shift;

    # ... Setting general mpminus nodes ...
    # $m->set( nodename => ' ... value ... ' ) unless $m->nodename;

    return __PACKAGE__->SUPER::InitHandler($m);
}

1;

