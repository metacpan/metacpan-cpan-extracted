package Firefox::Marionette::Capabilities;

use strict;
use warnings;

our $VERSION = '0.16';

sub new {
    my ( $class, %parameters ) = @_;
    my $element = bless {%parameters}, $class;
    return $element;
}

sub accept_insecure_certs {
    my ($self) = @_;
    return $self->{accept_insecure_certs};
}

sub page_load_strategy {
    my ($self) = @_;
    return $self->{page_load_strategy};
}

sub timeouts {
    my ($self) = @_;
    return $self->{timeouts};
}

sub browser_version {
    my ($self) = @_;
    return $self->{browser_version};
}

sub rotatable {
    my ($self) = @_;
    return $self->{rotatable};
}

sub platform_version {
    my ($self) = @_;
    return $self->{platform_version};
}

sub platform_name {
    my ($self) = @_;
    return $self->{platform_name};
}

sub moz_profile {
    my ($self) = @_;
    return $self->{moz_profile};
}

sub moz_webdriver_click {
    my ($self) = @_;
    return $self->{moz_webdriver_click};
}

sub moz_process_id {
    my ($self) = @_;
    return $self->{moz_process_id};
}

sub browser_name {
    my ($self) = @_;
    return $self->{browser_name};
}

sub moz_headless {
    my ($self) = @_;
    return $self->{moz_headless};
}

sub moz_accessibility_checks {
    my ($self) = @_;
    return $self->{moz_accessibility_checks};
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Firefox::Marionette::Capabilities - Represents Firefox Capabilities retrieved using the Marionette protocol

=head1 VERSION

Version 0.16

=head1 SYNOPSIS

    use Firefox::Marionette();
    use v5.10;

    my $firefox = Firefox::Marionette->new( capabilities => Firefox::Marionette::Capabilities->new( accept_insecure_certs => 0 ) );
    if ($firefox->capabilities->accept_insecure_certs() {
        say "Browser will now ignore certificate failures";
    }

=head1 DESCRIPTION

This module handles the implementation of Firefox Capabilities using the Marionette protocol

=head1 SUBROUTINES/METHODS

=head2 new
 
accepts a hash as a parameter.  Allowed keys are below;

=over 4

=item * accept_insecure_certs - Indicates whether untrusted and self-signed TLS certificates are implicitly trusted on navigation for the duration of the session. Allowed values are 1 or 0.  Default is 0.

=item * page_load_strategy - The page load strategy to use for the current session.  Must be one of 'none', 'eager', or 'normal'.

=item * timeouts - describes the L<timeouts|Firefox::Marionette::Timeouts> imposed on certian session operations.

=item * moz_webdriver_click - use a WebDriver conforming L<click|Firefox::Marionette#click>.  Allowed values are 1 or 0.  Default is 0.

=item * moz_accessibility_checks - run a11 checks when clicking elements. Allowed values are 1 or 0.  Default is 0.

=item * moz_headless - the browser should be started with the -headless option

=back

This method returns a new L<capabilities|Firefox::Marionette::Capabilities> object.
 
=head2 accept_insecure_certs

indicates whether untrusted and self-signed TLS certificates are implicitly trusted on navigation for the duration of the session.

=head2 page_load_strategy 

returns the page load strategy being used for the current session.  It will be one of 'none', 'eager', or 'normal'.

=head2 timeouts

returns the current L<timeouts|Firefox::Marionette::Timeouts> object

=head2 browser_version 

returns the version of L<firefox|https://firefox.com/>

=head2 platform_name 

returns the operating system name. For example 'linux', 'darwin' or 'windows_nt'.

=head2 rotatable

does this version of L<firefox|https://firefox.com> have a rotatable screen such as Android Fennec.

=head2 platform_version

returns the operation system version. For example '4.14.11-300.fc27.x86_64', '17.3.0' or '10.0'

=head2 moz_profile

returns the directory that contains the browsers profile

=head2 moz_webdriver_click

is the browser using a WebDriver conforming L<click|Firefox::Marionette#click>

=head2 moz_process_id 

returns the process id belonging to the browser

=head2 browser_name

returns the browsers name.  For example 'firefox'

=head2 moz_headless

returns whether the browser is running in headless mode

=head2 moz_accessibility_checks 

returns the current accessibility (a11y) value

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Firefox::Marionette::Capabilities requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-firefox-marionette@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

David Dick  C<< <ddick@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018, David Dick C<< <ddick@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic/perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
