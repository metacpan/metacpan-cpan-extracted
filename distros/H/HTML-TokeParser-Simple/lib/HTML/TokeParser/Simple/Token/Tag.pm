package HTML::TokeParser::Simple::Token::Tag;

use strict;

our $VERSION  = '3.16';
use base 'HTML::TokeParser::Simple::Token';

my %INSTANCE;

sub new {
    my ($class, $object) = @_;
    $class->_croak("This is a base class that should not be instantiated") 
        if __PACKAGE__ eq $class;
    my $self = bless $object, $class;
    $self->_init;
}

sub _get_attrseq { return [] }

sub _get_attr { return {} }

sub _set_text   { 
    my $self = shift; 
    $self->[-1] = shift;
    return $self;
}

# attribute munging methods
# get_foo methods

sub return_text {
    carp('return_text() is deprecated.  Use as_is() instead');
    goto &as_is;
}

sub as_is {
    return shift->_get_text;
}

sub get_tag {
    return shift->_get_tag;
}

1;

__END__

=head1 NAME

HTML::TokeParser::Simple::Token::Tag - Token.pm tag class.

=head1 SYNOPSIS

 use HTML::TokeParser::Simple;
 my $p = HTML::TokeParser::Simple->new( $somefile );

 while ( my $token = $p->get_token ) {
     # This prints all text in an HTML doc (i.e., it strips the HTML)
     next unless $token->is_text;
     print $token->as_is;
 }

=head1 DESCRIPTION

This is the base class for start and end tokens.  It should not be
instantiated.  See C<HTML::TokeParser::Simple::Token::Tag::Start> and
C<HTML::TokeParser::Simple::Token::Tag::End> for details.

=head1 OVERRIDDEN METHODS

The following list of methods are provided by this class.  See
L<HTML::TokeParser::Simple> for descriptions of these methods.

=over 4

=item * as_is

=item * get_tag

=item * return_text

=back
