package HTML::TokeParser::Simple::Token::Tag::Start;

use strict;

our $VERSION  = '3.16';
use base 'HTML::TokeParser::Simple::Token::Tag';

use HTML::Entities qw/encode_entities/;

my %TOKEN = (
    tag     => 1,
    attr    => 2,
    attrseq => 3,
    text    => 4
);

my %INSTANCE;

sub _init {
    my $self = shift;
    if ('S' eq $self->[0]) {
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

sub _get_attrseq {
    my $self  = shift;
    my $index = $TOKEN{attrseq} + $self->_get_offset;
    return $self->[$index];
}

sub _get_attr {
    my $self  = shift;
    my $index = $TOKEN{attr} + $self->_get_offset;
    return $self->[$index];
}

sub DESTROY     { delete $INSTANCE{+shift} }

sub return_attr    { goto &get_attr }
sub return_attrseq { goto &get_attrseq }
sub return_tag     { goto &get_tag }

# attribute munging methods

sub set_attr {
    my ($self, $name, $value) = @_;
    return 'HASH' eq ref $name
        ? $self->_set_attr_from_hashref($name)
        : $self->_set_attr_from_string($name, $value);
}

sub _set_attr_from_string {
    my ($self, $name, $value) = @_;
    $name = lc $name;
    my $attr    = $self->get_attr;
    my $attrseq = $self->get_attrseq;
    unless (exists $attr->{$name}) {
        push @$attrseq => $name;
    }
    $attr->{$name} = $value;
    $self->rewrite_tag;
}

sub _set_attr_from_hashref {
    my ($self, $attr_hash) = @_;
    while (my ($attr, $value) = each %$attr_hash) {
        $self->set_attr($attr, $value);
    }
    return $self;
}

sub rewrite_tag {
    my $self    = shift;
    my $attr    = $self->get_attr;
    my $attrseq = $self->get_attrseq;

    # capture the final slash if the tag is self-closing
    my ($self_closing) = $self->_get_text =~ m{(\s?/)>$};
    $self_closing ||= '';
    
    my $tag = '';
    foreach ( @$attrseq ) {
        next if $_ eq '/'; # is this a bug in HTML::TokeParser?
        $tag .= sprintf qq{ %s="%s"} => $_, encode_entities($attr->{$_});
    }
    my $first = $self->is_end_tag ? '/' : '';
    $tag = sprintf '<%s%s%s%s>', $first, $self->get_tag, $tag, $self_closing;
    $self->_set_text($tag);
    return $self;
}

sub delete_attr {
    my ($self,$name) = @_;
    $name = lc $name;
    my $attr = $self->get_attr;
    return unless exists $attr->{$name};
    delete $attr->{$name};
    my $attrseq = $self->get_attrseq;
    @$attrseq = grep { $_ ne $name } @$attrseq;
    $self->rewrite_tag;
}

# get_foo methods

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

sub get_token0 {
    return '';
}

sub get_attr {
    my $self = shift;
    my $attributes = $self->_get_attr;
    return @_ ? $attributes->{lc shift} : $attributes;
}

sub get_attrseq {
    my $self = shift;
    $self->_get_attrseq;
}

# is_foo methods

sub is_tag {
    my $self = shift;
    return $self->is_start_tag( @_ );
}

sub is_start_tag {
    my ($self, $tag) = @_;
    return $tag ? $self->_match_tag($tag) : 1;
}

sub _match_tag {
    my ($self, $tag) = @_;
    return 'Regexp' eq ref $tag
        ? $self->_get_tag =~ $tag
        : $self->_get_tag eq lc $tag;
}

1;

__END__

=head1 NAME

HTML::TokeParser::Simple::Token::Tag::Start - Token.pm "start tag" class.

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

=item * delete_attr

=item * get_attr

=item * get_attrseq

=item * get_tag

=item * get_token0

=item * is_start_tag

=item * is_tag

=item * return_attr

=item * return_attrseq

=item * return_tag

=item * return_text

=item * rewrite_tag

=item * set_attr

=back

=cut

