package JavaScript::Console;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

JavaScript::Console

=head1 DESCRIPTION

JavaScript window.console mapping for Perl.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use JavaScript::Console;

    my $console = JavaScript::Console->new();

    $console->group('g');
    $console->log($v);
    $console->group_end();

    print $console->output;

=head1 AUTHOR

Akzhan Abdulin, C<< <akzhan.abdulin at gmail.com> >>

=cut

use JSON::XS ();

use constant DEFAULT_CHARSET => 'utf-8';

my $json = undef;

sub _default_formatter {
    my $value = shift;
    $json ||= JSON::XS->new->allow_nonref->allow_blessed;
    return $json->encode( $value );
}

=head1 METHODS

=over

=item B<new>( $class, %config )

Instantiates new JavaScript::Console object with given configuration.

Available configuration options:

    * formatter - \&formatter( $value ), returns JavaScript representation for the value.
                                        JSON::XS-based by default.

    * charset   - Charset, utf-8 by default.

=cut

sub new {
    my ( $class, %config ) = @_;
    $class = ref $class  if ref $class;
    $config{formatter} ||= \&_default_formatter;
    $config{charset} ||= DEFAULT_CHARSET;
    $config{output} = [];
    return bless {
        %config
    }, $class;
}

sub _console_raw {
    my ( $self, $name, @args ) = @_;
    push @{ $self->{output} }, "console.$name(". join( ',', @args ). ");";
    return $self;
}

sub _jarg {
    my ( $self, $value ) = @_;
    return $self->{formatter}->( $value );
}

sub _console {
    my ( $self, $name, @args ) = @_;
    return $self->_console_raw( $name, map { $self->_jarg($_) } @args );
}

=item B<charset>( $self, $charset )

Gets or sets charset. See L</new> for details.

=cut

sub charset {
    my ( $self, $charset ) = @_;
    return $self->{charset}  unless defined( $charset );
    $self->{charset} = $charset;
    return $self;
}

=item B<output>( $self )

Gets resulting HTML (with script tag if not empty).

=cut

sub output {
    my $self = shift;

    return ''  if scalar( $self->{output} ) eq 0;

    return ''
        . "<script charset=\"$self->{charset}\" defer>(function(console) {"
        . "if (! console) { return; }"
        . join( '', @{ $self->{output} } )
        . "})(window.console);</script>"
        ;
}

=item B<log>( $self, @args )

Prints log message with given @args to JavaScript console.

=cut

sub log {
    my $self = shift;
    return $self->_console( 'log', @_ );
}

=item B<debug>( $self, @args )

Alias for L</log>( @args ).

=cut

sub debug {
    my $self = shift;
    return $self->log( @_ );
}

=item B<info>( $self, @args )

Prints info message with given @args to JavaScript console.

=cut

sub info {
    my $self = shift;
    return $self->_console( 'info', @_ );
}

=item B<warn>( $self, @args )

Prints warn message with given @args to JavaScript console.

=cut

sub warn {
    my $self = shift;
    return $self->_console( 'warn', @_ );
}

=item B<error>( $self, @args )

Prints error message with given @args to JavaScript console.

=cut

sub error {
    my $self = shift;
    return $self->_console( 'error', @_ );
}

=item B<group>( $self, @args )

Groups next messages in JavaScript console until L</group_end>.

See also L</group_collapsed>.

=cut

sub group {
    my $self = shift;
    return $self->_console('group', @_);
}

=item B<group_collapsed>( $self, @args )

Groups and collapses by default next messages in JavaScript console until L</group_end>.

See also L</group>.

=cut

sub group_collapsed {
    my $self = shift;
    return $self->_console('groupCollapsed', @_);
}

=item B<group_end>( $self, @args )

Closes previously opened group of messages in JavaScript console.

See also L</group> and L</group_collapsed>.

=cut

sub group_end {
    my $self = shift;
    return $self->_console('groupEnd', @_);
}

=item B<dir>( $self, @args )

Low level method to inspect the HTML element.

=cut

sub dir {
    my $self = shift;
    return $self->_console_raw( 'dir', @_ );
}

=item B<dir_by_id>( $self, $id )

Inspect the HTML element with specified ID.

=cut

sub dir_by_id {
    my ( $self, $id ) = @_;
    return $self->dir( "document.getElementById(". _default_formatter($id). ")" );
}

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-javascript-console at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JavaScript-Console>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JavaScript::Console

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JavaScript-Console>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JavaScript-Console>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JavaScript-Console>

=item * Search CPAN

L<http://search.cpan.org/dist/JavaScript-Console/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Akzhan Abdulin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of JavaScript::Console
