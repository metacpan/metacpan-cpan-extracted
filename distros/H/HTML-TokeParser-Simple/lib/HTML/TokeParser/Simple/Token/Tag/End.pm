package HTML::TokeParser::Simple::Token::Tag::End;

use strict;

our $VERSION  = '3.16';
use base 'HTML::TokeParser::Simple::Token::Tag';

my %TOKEN = (
    tag   => 1,
    text  => 2
);

# in order to maintain the 'drop-in replacement' ability with HTML::TokeParser,
# we cannot alter the array refs.  Thus we must store instance data here.  Ugh.

my %INSTANCE;

sub _init {
    my $self = shift;
    if ('E' eq $self->[0]) {
        $INSTANCE{$self}{offset} = 0;
        $INSTANCE{$self}{tag}    = $self->[1];
    }
    else {
        $INSTANCE{$self}{offset} = -1;
        my $tag = $self->[0];
        $tag =~ s/^\///;
        $INSTANCE{$self}{tag}    = $tag;
    }
    return $self;
}

sub _get_offset { return $INSTANCE{+shift}{offset} }
sub _get_text   { return shift->[-1] }

sub _get_tag {
    my $self  = shift;
    return $INSTANCE{$self}{tag};
}

sub DESTROY     { delete $INSTANCE{+shift} }

sub rewrite_tag {
    my $self    = shift;
    # capture the final slash if the tag is self-closing
    my ($self_closing) = $self->_get_text =~ m{(\s?/)>$};
    $self_closing ||= '';
    
    my $first = $self->is_end_tag ? '/' : '';
    my $tag = sprintf '<%s%s%s>', $first, $self->get_tag, $self_closing;
    $self->_set_text($tag);
    return $self;
}

sub return_text {
    require Carp;
    Carp::carp('return_text() is deprecated.  Use as_is() instead');
    goto &as_is;
}

sub as_is {
    return shift->_get_text;
}

sub get_tag {
    return shift->_get_tag;
}

# is_foo methods

sub is_tag {
    my $self = shift;
    return $self->is_end_tag( @_ );
}

sub is_end_tag {
    my ($self, $tag) = @_;
    return $tag ? $self->_match_tag($tag) : 1;
}

sub _match_tag {
    my ($self, $tag) = @_;
    if ('Regexp' eq ref $tag) {
        return $self->_get_tag =~ $tag;
    }
    else {
        $tag = lc $tag;
        $tag =~ s/^\///;
        return $self->_get_tag eq $tag;
    }
}

1;

__END__

=head1 NAME

HTML::TokeParser::Simple::Token::Tag::End - Token.pm "end tag" class.

=head1 SYNOPSIS

 use HTML::TokeParser::Simple;
 my $p = HTML::TokeParser::Simple->new( $somefile );

 while ( my $token = $p->get_token ) {
     # This prints all text in an HTML doc (i.e., it strips the HTML)
     next unless $token->is_text;
     print $token->as_is;
 }

=head1 DESCRIPTION

This class does most of the heavy lifting for C<HTML::TokeParser::Simple>.  See
the C<HTML::TokeParser::Simple> docs for details.

=head1 OVERRIDDEN METHODS

=over 4

=item * as_is

=item * get_tag

=item * is_end_tag

=item * is_tag

=item * return_text

=item * rewrite_tag

=back

=cut
