package HTML::WidgetValidator;
use warnings;
use strict;
use HTML::WidgetValidator::HTMLParser;
use HTML::WidgetValidator::WidgetContainer;

our $VERSION = '0.0.3';

sub new {
    my ($class, %args) = @_;
    my $self = bless {
	parser    => HTML::WidgetValidator::HTMLParser->new,
	container => HTML::WidgetValidator::WidgetContainer->new(%args),
    }, $class;
    return $self;
}

sub add {
    my $self = shift;
    $self->{container}->add(@_);
}

sub validate {
    my ($self, $html) = @_;
    my $result;
    my $elements = $self->{parser}->parse($html);
    return $self->{container}->match($elements, $html);
}

sub widgets {
    my $self = shift;
    return $self->{container}->widgets;
}

1;
__END__

=head1 NAME

HTML::WidgetValidator - Perl framework for validating various widget HTML snipets


=head1 VERSION

This document describes HTML::WidgetValidator version 0.0.3


=head1 SYNOPSIS

    use HTML::WidgetValidator;
    my $validator = HTML::WidgetValidator->new;
    my $result  = $validator->validate($html);
    my $code = $result->code;
    my $name = $result->name;


=head1 DESCRIPTION

When HTML code is passed to HTML::WidgetValidator, it will analyze the code to see what kind
of Widget it is for. It is possible to pre-specify the type of Widget that will be detected
(if nothing is specified all included Widget types will be considered).

If the HTML Tag representing the Widget is too long, it is necessary to divide the HTML
code up by elements. For example the Yahoo! Weather Information code below is comprised of
two scripts, it is necessary to pass along each script separately.

    <script>var CFLwidth = "150";var CFLheight = "322";
    var CFLswfuri = "http://i.yimg.jp/images/weather/blogparts/yj_weather.swf?mapc=4";
    </script>
    <script type="text/javascript" charset="euc-jp"
                src="http://weather.yahoo.co.jp/weather/promo/js/weather.js"></script>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENCE AND COPYRIGHT

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
