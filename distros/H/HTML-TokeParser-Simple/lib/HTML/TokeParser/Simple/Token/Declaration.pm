package HTML::TokeParser::Simple::Token::Declaration;

use strict;

our $VERSION  = '3.15';
use base 'HTML::TokeParser::Simple::Token';

sub is_declaration { 1 }

1;

__END__

=head1 NAME

HTML::TokeParser::Simple::Token::Declaration - Token.pm declaration class.

=head1 SYNOPSIS

 use HTML::TokeParser::Simple;
 my $p = HTML::TokeParser::Simple->new( $somefile );

 while ( my $token = $p->get_token ) {
     # This prints all text in an HTML doc (i.e., it strips the HTML)
     next unless $token->is_text;
     print $token->as_is;
 }

=head1 DESCRIPTION

This is the declaration class for tokens. 

=head1 OVERRIDDEN METHODS

=head2 is_declaration

C<is_declaration()> will return true if the token is the DTD at the top of the
HTML.

=cut
