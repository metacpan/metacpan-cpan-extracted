package HTML::TokeParser::Simple::Token;

use strict;

our $VERSION  = '3.16';

sub new {
    my ($class, $token) = @_;
    $class->_croak("This class should not be instantiated") if __PACKAGE__ eq $class;
    return bless $token, $class;
}

sub _croak {
    my ($proto, $message) = @_;
    require Carp;
    Carp::croak($message);
}

sub _carp {
    my ($proto, $message) = @_;
    require Carp;
    Carp::carp($message);
}

sub is_tag         {}
sub is_start_tag   {}
sub is_end_tag     {}
sub is_text        {}
sub is_comment     {}
sub is_declaration {}
sub is_pi          {}
sub is_process_instruction {}

sub rewrite_tag    { shift }
sub delete_attr    {}
sub set_attr       {}
sub get_tag        {}
sub return_tag     {}  # deprecated
sub get_attr       {}
sub return_attr    {}  # deprecated
sub get_attrseq    {}
sub return_attrseq {}  # deprecated
sub get_token0     {}
sub return_token0  {}  # deprecated

# get_foo methods

sub return_text {
    my ($self) = @_;
    $self->_carp('return_text() is deprecated.  Use as_is() instead');
    goto &as_is;
}

sub as_is { return shift->[-1] }

1;

__END__

=head1 NAME

HTML::TokeParser::Simple::Token - Base class for C<HTML::TokeParser::Simple>
tokens.

=head1 SYNOPSIS

 use HTML::TokeParser::Simple;
 my $p = HTML::TokeParser::Simple->new( $somefile );

 while ( my $token = $p->get_token ) {
     # This prints all text in an HTML doc (i.e., it strips the HTML)
     next unless $token->is_text;
     print $token->as_is;
 }

=head1 DESCRIPTION

This is the base class for all returned tokens.  It should never be
instantiated directly.  In fact, it will C<croak()> if it is.

=head1 METHODS

The following list of methods are provided by this class.  Most of these are
stub methods which must be overridden in a subclass.  See 
L<HTML::TokeParser::Simple> for descriptions of these methods.

=over 4

=item * as_is

=item * delete_attr

=item * get_attr

=item * get_attrseq

=item * get_tag

=item * get_token0

=item * is_comment

=item * is_declaration

=item * is_end_tag

=item * is_pi

=item * is_process_instruction

=item * is_start_tag

=item * is_tag

=item * is_text

=item * return_attr

=item * return_attrseq

=item * return_tag

=item * return_text

=item * return_token0

=item * rewrite_tag

=item * set_attr

=back
