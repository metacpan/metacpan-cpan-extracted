package JavaScript;

use 5.008;

use strict;
use warnings;

use Carp;

use constant JS_PROP_PRIVATE      => 0x1;
use constant JS_PROP_READONLY     => 0x2;
use constant JS_PROP_ACCESSOR     => 0x4;
use constant JS_CLASS_NO_INSTANCE => 0x1;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT = qw(JS_PROP_PRIVATE JS_PROP_READONLY JS_PROP_ACCESSOR JS_CLASS_NO_INSTANCE);

our @EXPORT_OK = (@EXPORT);

our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

our $VERSION = "1.16";

our $MAXBYTES = 1024 ** 2;

require JavaScript::Boxed;
require JavaScript::Context;
require JavaScript::Error;
require JavaScript::Function;
require JavaScript::Runtime;
require JavaScript::Script;
require JavaScript::Generator;

sub get_engine_version {
    my $version_str = js_get_engine_version();
    
    if (wantarray) {
        my ($engine, $version, $build_date) = split/\s+/, $version_str, 3;
        return ($engine, $version, $build_date);
    }
    
    return $version_str;
}

sub does_support_utf8 {
    return js_does_support_utf8();
    
}
# Alias to not break backwards compability
*does_handle_utf8 = \&does_support_utf8;

sub does_support_e4x {
    return js_does_support_e4x();
}

sub does_support_threading {
    return js_does_support_threading();
}

sub supports {
    my $pkg = shift;
    
    for (@_) {
        my $does = JavaScript->can("does_support_" . lc($_));
        croak "I don't know about '$_'" if !defined $does;
        return 0 if !$does->();
    }
        
    return 1;
}

sub create_runtime {
    my $pkg = shift;
    return JavaScript::Runtime->new(@_);
}

sub _compile_string_re {
    my $s_re = shift;
    return qr/$s_re/;
}

bootstrap JavaScript $VERSION;

1;
__END__

=head1 NAME

JavaScript - Perl extension for executing embedded JavaScript

=head1 SYNOPSIS

  use JavaScript;

  my $rt = JavaScript::Runtime->new();
  my $cx = $rt->create_context();

  $cx->bind_function(write => sub { print @_; });

  $cx->eval(q/
    for (i = 99; i > 0; i--) {
        write(i + " bottle(s) of beer on the wall, " + i + " bottle(s) of beer\n");
        write("Take 1 down, pass it around, ");
        if (i > 1) {
            write((i - 1) + " bottle(s) of beer on the wall.");
        }
        else {
            write("No more bottles of beer on the wall!");
        }
    }
  /);

=head1 DESCRIPTION

Always thought JavaScript was for web-applications only? well, think again...

This modules gives you the power of embedded JavaScript in your Perl applications. You can
write your subroutines, classes and so forth in Perl and make them callable from JavaScript.
Variables such as primitive types, objects and functions are automagically converted between
the different environments. If you return a JavaScript function you can call it as a normal
code-reference from Perl.

JavaScript is a great as an embedded language because it has no I/O, no IPC and pretty much
anything else that can interfer with the system. It's also an easy yet powerfull language
that zillions of developers worldwide knows.

Note that this module is not a JavaScript compiler/interpreter written in Perl but an interface
to the SpiderMonkey engine used in the Mozilla-family of browsers.

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item create_runtime ( ... )

Shortcut for C<JavaScript::Runtime->new(...)>.

=item get_engine_version

In scalar context it returns a string describing the engine such as C<JavaScript-C 1.5 2004-09-24>.

In list context it returns the separate parts of the string - engine, version and date of build.

=item does_support_utf8

=item does_handle_utf8

Returns a true value if SpiderMonkey is compiled with support for UTF8 strings and if we're using it.
B<does_handle_utf8> is also supported for backwards compability.

=item does_support_e4x

Returns a true value if we have compiled support for E4X.

=item does_support_threading

Returns a true value if we have compiled support for threading.

=item supports ( @features )

Checks if all features given in I<@features> are present. Is case insensitive. Supported keys are 
B<e4x>, B<utf8> and B<threading>. Extensions to this module may provide additional keys by implementing 
a method that begins with C<does_support_>.

=back

=begin PRIVATE

=head1 PRIVATE INTERFACE

=over 4

=item js_get_engine_version

Returns a string with the output of C<JS_GetImplementationVersion()>.

=item js_does_support_utf8

Returns C<PL_sv_yes> if we have compiled SpiderMonkey with C<JS_C_STRINGS_ARE_UTF8>. Otherwise returns C<PL_sv_no>.

=item js_does_support_e4x

Returns C<PL_sv_yes> if we have compiled support for E4X. Otherwise returns C<PL_sv_no>.

=item js_does_support_threading

Returns C<PL_sv_yes> if we have compiled support for threading. Otherwise returns C<PL_sv_no>.

=back

=end PRIVATE

=head1 SUPPORT

There is a mailing-list available at L<http://lists.cpan.org/showlist.cgi?name=perl-javascript>.

You may subscribe to the list by sending an empty e-mail to C<perl-javascript-subscribe@perl.org>

=head1 CREDITS

See L<CREDITS>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-javascript@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Claes Jakobsson C<< <claesjac@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2001 - 2008, Claes Jakobsson C<< <claesjac@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

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

=cut
