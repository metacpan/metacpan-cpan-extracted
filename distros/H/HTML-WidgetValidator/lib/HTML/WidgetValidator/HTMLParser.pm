package HTML::WidgetValidator::HTMLParser;
use warnings;
use strict;
use HTML::Parser;
use HTML::WidgetValidator::HTMLElement;

sub new {
    my ($class, %args) = @_;
    my $self = bless { %args }, $class;
    $self->{parser} = HTML::Parser->new(
        api_version => 3,
        handlers => {
            start   => [$self->starthandler, 'text, tagname, attr'],
            end     => [$self->endhandler, 'text, tagname'],
            text    => [$self->texthandler, 'text'],
	    comment => [$self->texthandler, 'text'],
            default => [$self->defaulthandler, 'event, text'],
        },
    );
    $self->{parser}->empty_element_tags( 1 );
    return $self;
}

sub parse {
    my ($self,$html) = @_;
    $self->{result} = [];
    $self->{parser}->parse($html);
    return $self->{result};
}

sub starthandler {
    my $self = shift;
    return sub {
        my ($text, $tag, $attr) = @_;
	$text =~ s|/>$|>|;
	push @{$self->{result}},
	    HTML::WidgetValidator::HTMLElement->new(
		type=>'start',name=>$tag,attr=>$attr,text=>$text );
    }
}

sub endhandler {
    my $self = shift;
    return sub {
        my ($text, $tag) = @_;
	push @{$self->{result}},
	    HTML::WidgetValidator::HTMLElement->new(
		type=>'end',name=>$tag, text=>"</$tag>" );
    }
}

sub texthandler {
    my $self = shift;
    return sub {
        my ($text) = @_;
	return if( $text =~ /^\s+$/s );
	push @{$self->{result}},
	    HTML::WidgetValidator::HTMLElement->new(
		type=>'text',text=>$text );
    }
}

sub defaulthandler {
    my $self = shift;
    return sub {};
}

1;
__END__

=head1 NAME

HTML::WidgetValidator::HTMLParser


=head1 DESCRIPTION

HTML Parser class for HTML::WidgetValidator.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<HTML::Parser>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENCE AND COPYRIGHT

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
