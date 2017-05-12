package HTML::TokeParser::Simple::Token::Comment;

use strict;

our $VERSION  = '3.16';
use base 'HTML::TokeParser::Simple::Token';

sub is_comment { 1 }

1;

__END__

=head1 NAME

HTML::TokeParser::Simple::Token::Comment - Token.pm comment class.

=head1 SYNOPSIS

 use HTML::TokeParser::Simple;
 my $p = HTML::TokeParser::Simple->new( $somefile );

 while ( my $token = $p->get_token ) {
     # This prints all text in an HTML doc (i.e., it strips the HTML)
     next unless $token->is_text;
     print $token->as_is;
 }

=head1 DESCRIPTION

This is the class for comment tokens.

See L<HTML::Parser> for detailed information about comments.

=head1 OVERRIDDEN METHODS

=head2 is_comment

C<is_comment()> will return true if the token is the DTD at the top of the
HTML.

=cut
