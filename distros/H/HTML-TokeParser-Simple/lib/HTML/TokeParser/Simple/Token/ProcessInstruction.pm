package HTML::TokeParser::Simple::Token::ProcessInstruction;

use strict;

our $VERSION  = '3.16';
use base 'HTML::TokeParser::Simple::Token';

sub return_token0 { goto &get_token0 } # deprecated

sub get_token0 {
    return shift->[1];
}

sub is_pi { 1 }

sub is_process_instruction { 1 }

1;

__END__

=head1 NAME

HTML::TokeParser::Simple::Token::ProcessInstruction - Token.pm process instruction class.

=head1 SYNOPSIS

 use HTML::TokeParser::Simple;
 my $p = HTML::TokeParser::Simple->new( $somefile );

 while ( my $token = $p->get_token ) {
     # This prints all text in an HTML doc (i.e., it strips the HTML)
     next unless $token->is_text;
     print $token->as_is;
 }

=head1 DESCRIPTION

Process Instructions are from XML.  This is very handy if you need to parse out
PHP and similar things with a parser.

Currently, there appear to be some problems with process instructions.  You can
override this class if you need finer grained handling of process instructions.

C<is_pi()> and C<is_process_instruction()> both return true.

=head1 OVERRIDDEN METHODS

=over 4

=item * get_token0

=item * is_pi

=item * is_process_instruction

=item * return_token0

=back

=cut
