package Finance::BankUtils::ID::Mechanize;

our $DATE = '2017-05-16'; # DATE
our $VERSION = '0.45'; # VERSION

use 5.010;
use strict;
use warnings;
use Log::Any::IfLOG qw($log);

use parent qw(WWW::Mechanize);

use String::Indent ();

sub new {
    my ($class, %args) = @_;
    my $mech = WWW::Mechanize->new;
    $mech->{verify_https} = $args{verify_https} // 0;
    $mech->{https_ca_dir} = $args{https_ca_dir} // "/etc/ssl/certs";
    $mech->{https_host}   = $args{https_host};
    bless $mech, $class;
}

# will be set by some other code, and will be immediately consumed and emptied
# by _make_request().
our $saved_resp;

sub _make_request {
    my $self = shift;
    my $req = shift;
    local $ENV{HTTPS_CA_DIR} = $self->{verify_https} ?
        $self->{https_ca_dir} : '';
    $log->tracef("HTTPS_CA_DIR = %s", $ENV{HTTPS_CA_DIR});
    if ($self->{verify_https} && $self->{https_host}) {
        $req->header('If-SSL-Cert-Subject',
                     qr!\Q/CN=$self->{https_host}\E(/|$)!);
    }
    $log->trace("Mech request:\n" . String::Indent::indent('  ', $req->headers_as_string));
    my $resp;
    if ($saved_resp) {
        $resp = $saved_resp;
        $saved_resp = undef;
        $log->trace("Mech response (from saved):" .
                        String::Indent::indent('  ', $resp->headers_as_string));
    } else {
        $resp = $self->SUPER::_make_request($req, @_);
        $log->trace("Mech response:\n" . String::Indent::indent('  ', $resp->headers_as_string));
    }
    $resp;
}

1;
# ABSTRACT: A subclass of WWW::Mechanize

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::BankUtils::ID::Mechanize - A subclass of WWW::Mechanize

=head1 VERSION

This document describes version 0.45 of Finance::BankUtils::ID::Mechanize (from Perl distribution Finance-Bank-ID-BCA), released on 2017-05-16.

=head1 SYNOPSIS

 my $mech = Finance::BankUtils::ID::Mechanize->new(
     verify_https => 1,
     #https_ca_dir => '/etc/ssl/certs',
     https_host   => 'example.com',
 );
 # use as you would WWW::Mechanize object ...

=head1 DESCRIPTION

This is a subclass of WWW::Mechanize that can do some extra stuffs:

=over

=item * HTTPS certificate verification

=item * use saved response from a file

=item * log using Log::ny

=back

=head1 METHODS

=head2 new()

=head2 request()

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Finance-Bank-ID-BCA>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Finance-Bank-ID-BCA>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-Bank-ID-BCA>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2013, 2012, 2011, 2010 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
