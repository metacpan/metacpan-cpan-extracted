package Firefox::Marionette::Capabilities;

use strict;
use warnings;

our $VERSION = '0.75';

sub new {
    my ( $class, %parameters ) = @_;
    my $element = bless {%parameters}, $class;
    return $element;
}

sub enumerate {
    my ($self) = @_;
    my @enum = sort { $a cmp $b } grep { defined $self->{$_} } keys %{$self};
    return @enum;
}

sub moz_use_non_spec_compliant_pointer_origin {
    my ($self) = @_;
    return $self->{moz_use_non_spec_compliant_pointer_origin};
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

sub moz_build_id {
    my ($self) = @_;
    return $self->{moz_build_id};
}

sub proxy {
    my ($self) = @_;
    return $self->{proxy};
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Firefox::Marionette::Capabilities - Represents Firefox Capabilities retrieved using the Marionette protocol

=head1 VERSION

Version 0.75

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

=item * page_load_strategy - defines the page load strategy to use for the duration of the session. Setting a page load strategy will cause navigation to be "eager", waiting for the interactive document ready state; "normal" (the default), waiting for the complete ready state; or "none", which will return immediately after starting navigation. 

=item * proxy - describes the L<proxy|Firefox::Marionette::Proxy> setup for the upcoming browser session.

=item * timeouts - describes the L<timeouts|Firefox::Marionette::Timeouts> imposed on certain session operations.

=item * moz_webdriver_click - a boolean value to indicate which kind of interactability checks to run when performing a L<click|Firefox::Marionette#click> or L<sending keys|Firefox::Marionette#type> to an elements. For Firefoxen prior to version 58.0 some legacy code as imported from an older version of FirefoxDriver was in use.

With Firefox 58 the interactability checks as required by the WebDriver specification are enabled by default. This means geckodriver will additionally check if an element is obscured by another when clicking, and if an element is focusable for sending keys.

Because of this change in behaviour, we are aware that some extra errors could be returned. In most cases the test in question might have to be updated so it's conform with the new checks. But if the problem is located in geckodriver, then please raise an issue in the issue tracker.

To temporarily disable the WebDriver conformant checks use 0 as value for this capability.

Please note that this capability exists only temporarily, and that it will be removed once the interactability checks have been stabilized.

=item * moz_accessibility_checks - run a11y checks when clicking elements. Allowed values are 1 or 0.  Default is 0.

=item * moz_headless - the browser should be started with the -headless option.  moz_headless is only supported in Firefox 56+

=item * moz_use_non_spec_compliant_pointer_origin - a boolean value to indicate how the pointer origin for an action command will be calculated.

With Firefox 59 the calculation will be based on the requirements by the WebDriver specification. This means that the pointer origin is no longer computed based on the top and left position of the referenced element, but on the in-view center point.

To temporarily disable the WebDriver conformant behavior use 0 as value for this capability.

Please note that this capability exists only temporarily, and that it will be removed once all Selenium bindings can handle the new behavior.


=back

This method returns a new L<capabilities|Firefox::Marionette::Capabilities> object.
 
=head2 enumerate

This method returns a list of strings describing the capabilities that this version of Firefox supports.

=head2 accept_insecure_certs

indicates whether untrusted and self-signed TLS certificates are implicitly trusted on navigation for the duration of the session.

=head2 page_load_strategy 

returns the page load strategy to use for the duration of the session. Setting a page load strategy will cause navigation to be "eager", waiting for the interactive document ready state; "normal" (the default), waiting for the complete ready state; or "none", which will return immediately after starting navigation. 

=head2 timeouts

returns the current L<timeouts|Firefox::Marionette::Timeouts> object

=head2 proxy

returns the current L<proxy|Firefox::Marionette::Proxy> object

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

=head2 moz_build_id

returns the L<Firefox BuildId|https://developer.mozilla.org/en-US/docs/Web/API/Navigator/buildID>

=head2 moz_webdriver_click

returns a boolean value to indicate which kind of interactability checks to run when performing a L<click|Firefox::Marionette#click> or L<sending keys|Firefox::Marionette#type> to an elements. For Firefoxen prior to version 58.0 some legacy code as imported from an older version of FirefoxDriver was in use.

With Firefox 58 the interactability checks as required by the WebDriver specification are enabled by default. This means geckodriver will additionally check if an element is obscured by another when clicking, and if an element is focusable for sending keys.

Because of this change in behaviour, we are aware that some extra errors could be returned. In most cases the test in question might have to be updated so it's conform with the new checks. But if the problem is located in geckodriver, then please raise an issue in the issue tracker.

To temporarily disable the WebDriver conformant checks use 0 as value for this capability.

Please note that this capability exists only temporarily, and that it will be removed once the interactability checks have been stabilized.

=head2 moz_process_id 

returns the process id belonging to the browser

=head2 browser_name

returns the browsers name.  For example 'firefox'

=head2 moz_headless

returns whether the browser is running in headless mode

=head2 moz_accessibility_checks 

returns the current accessibility (a11y) value

=head2 moz_use_non_spec_compliant_pointer_origin

returns a boolean value to indicate how the pointer origin for an action command will be calculated.

With Firefox 59 the calculation will be based on the requirements by the WebDriver specification. This means that the pointer origin is no longer computed based on the top and left position of the referenced element, but on the in-view center point.

To temporarily disable the WebDriver conformant behavior use 0 as value for this capability.

Please note that this capability exists only temporarily, and that it will be removed once all Selenium bindings can handle the new behavior.

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
