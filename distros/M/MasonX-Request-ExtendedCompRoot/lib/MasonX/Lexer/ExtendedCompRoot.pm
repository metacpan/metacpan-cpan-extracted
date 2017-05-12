# This software is copyright (c) 2004 Alex Robinson.
# It is free software and can be used under the same terms as perl,
# i.e. either the GNU Public Licence or the Artistic License.

package MasonX::Lexer::ExtendedCompRoot;

use strict;

our $VERSION = '0.04';

use base qw(HTML::Mason::Lexer);


sub match_comp_content_call_end
{
    my $self = shift;

    if ( $self->{current}{comp_source} =~ m,\G</&(.*?)>,gcs )
    {
        my $call = $1 || '';
        $self->{current}{compiler}->component_content_call_end;
        $self->{current}{lines} += $call =~ tr/\n//;

        return 1;
    }
}




1;


__END__

=head1 NAME

MasonX::Resolver::Lexer - Extend syntax of C<HTML::Mason::Lexer>

=head1 SYNOPSIS

In your F<httpd.conf> file:

  PerlSetVar   MasonLexerClass   MasonX::Lexer::ExtendedCompRoot



=head1 DESCRIPTION

This subclass of L<HTML::Mason::Lexer>, enables the closing tag for  component calls with content to have meaningful text within them rather than cryptic </&>s. (Nor, now that official Mason supports extended closing tags, are you tied to matching the exact component name)

Eg. altough the following is still fine

  <&| /foo &>bar</&>

we can also use something like

  <&! /foo &>bar</& foo>

=head1 USAGE

To use this module you need to tell Mason to use this class for its lexer:

  PerlSetVar  MasonLexerClass    MasonX::Lexer::ExtendedCompRoot

If you are using a F<handler.pl> file, simply add this parameter to the parameters given to the ApacheHandler constructor:

  lexer_class  => 'MasonX::Lexer::ExtendedCompRoot'

=head1 PREREQUISITES

HTML::Mason

=head1 BUGS

No known bugs.

=head1 VERSION

0.04

=head1 SEE ALSO

L<HTML::Mason::Resolver::File>, L<MasonX::Request::ExtendedCompRoot>, L<MasonX::Request::ExtendedCompRoot::WithApacheSession>

=head1 AUTHOR

Alex Robinson, <cpan[@]alex.cloudband.com>

=head1 LICENSE

MasonX::Lexer::ExtendedCompRoot is free software and can be used under the same terms as Perl, i.e. either the GNU Public Licence or the Artistic License.

=cut
