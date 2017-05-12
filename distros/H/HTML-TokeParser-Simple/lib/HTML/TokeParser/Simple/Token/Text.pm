package HTML::TokeParser::Simple::Token::Text;

use strict;

our $VERSION  = '3.16';
use base 'HTML::TokeParser::Simple::Token';

sub as_is {
    return shift->[1];
}

sub is_text { 1 }

1;

__END__

=head1 NAME

HTML::TokeParser::Simple::Token::Text - Token.pm text class.

=head1 SYNOPSIS

 use HTML::TokeParser::Simple;
 my $p = HTML::TokeParser::Simple->new( $somefile );

 while ( my $token = $p->get_token ) {
     # This prints all text in an HTML doc (i.e., it strips the HTML)
     next unless $token->is_text;
     print $token->as_is;
 }

=head1 DESCRIPTION

This class represents "text" tokens.  See the C<HTML::TokeParser::Simple>
documentation for details.

=head1 OVERRIDDEN METHODS

=over 4

=item * as_is

=item * is_text

=back

=cut
