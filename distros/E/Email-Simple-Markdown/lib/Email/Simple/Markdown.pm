package Email::Simple::Markdown;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: simple email creation with auto text and html multipart body
$Email::Simple::Markdown::VERSION = '0.7.3';
use strict;
use warnings;

use Carp;

use Email::Abstract;
use Email::MIME;
use Email::Simple;

use List::Util 1.29 qw/ first pairmap /;
use Module::Runtime qw/ use_module /;

use Moo;
extends 'Email::Simple';

sub BUILDARGS {
    return {};
}

around create => sub {
    my ( $orig, $self, %arg ) = @_;

    my @local_args = qw/ css markdown_engine pre_markdown_filter charset /;
    my %md_arg;
    @md_arg{@local_args} = delete @arg{@local_args};

    my $email = $orig->( $self, %arg );

    $email->markdown_engine_set(
        $md_arg{markdown_engine}||'auto'
    );

    $email->charset_set( $md_arg{charset} ) if $md_arg{charset};
    $email->css_set($md_arg{css}) if $md_arg{css};
    $email->pre_markdown_filter_set($md_arg{pre_markdown_filter}) 
        if $md_arg{pre_markdown_filter};

    return $email;
};

our @SUPPORTED_ENGINES = qw/ Text::MultiMarkdown Text::Markdown /;

has markdown_engine => (
    is              => 'rw',
    lazy            => 1,
    default         => sub { $_[0]->find_markdown_engine },
    clearer         => 1,
    coerce          => sub {
        my( $value ) = @_;
        
        return $value eq 'auto'
            ? __PACKAGE__->find_markdown_engine 
            : $value;
    },
    trigger => sub{
        my( $self, $engine ) = @_;
        
        die "engine '$engine' not implementing a 'markdown' method\n"
            unless use_module($engine)->can('markdown');

        $self->clear_markdown_object;
    },
    writer => 'markdown_engine_set',
);

has markdown_object => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    default => sub { $_[0]->{markdown_engine}->new },
    handles => {
        _markdown => 'markdown',
    }
);

sub find_markdown_engine {
    first { eval { use_module($_) } } @SUPPORTED_ENGINES
        or die "No supported markdown engine found" 
}

has markdown_css => (
    is => 'rw',
    reader => 'css',
    writer => 'css_set',
    coerce => sub {
        my $css = shift;

        if ( ref $css eq 'ARRAY' ) {
            my @css = @$css;

            croak "number of argument is not even" if @css % 2;

            $css = join "\n", pairmap { "$a { $b }" } @css;
        }

        $css;
    },
);

has markdown_filter => (
    is => 'rw',
    writer => 'pre_markdown_filter_set',
);

has markdown_charset => (
    is => 'rw',
    writer => 'charset_set',
);

sub with_markdown {
    my $self = shift;

    my $body = $self->body;
    
    my $mail = Email::Abstract->new($self->SUPER::as_string)
                ->cast('Email::MIME');

    $mail->content_type_set('multipart/alternative');

    $mail->parts_set([
        Email::MIME->create(
            attributes => { 
                content_type => 'text/plain',
                charset      => $self->markdown_charset
            },
            body => $body,
        ),
        Email::MIME->create(
            attributes => {
                content_type => 'text/html',
                charset      => $self->markdown_charset,
                encoding     => 'quoted-printable',
            },
            body => $self->markdown_part,
        )
    ]);

    return Email::Abstract->new($mail);
}

sub markdown_part {
    my $self = shift;

    my $markdown = $self->body;

    if( my $filter =  $self->markdown_filter ) {
        local $_ = $markdown;
        $filter->();
        $markdown = $_;
    }
    
    $markdown = $self->_markdown($markdown);
    $markdown = '<style type="text/css">'
              . $self->css
              . '</style>'
              . $markdown 
        if $self->css;

    return $markdown;
}

sub as_string { $_[0]->with_markdown->as_string }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::Simple::Markdown - simple email creation with auto text and html multipart body

=head1 VERSION

version 0.7.3

=head1 SYNOPSIS

    use Email::Simple::Markdown;

    my $email = Email::Simple::Markdown->create(
        header => [
            From    => 'me@here.com',
            To      => 'you@there.com',
            Subject => q{Here's a multipart email},
        ],
        body => '[this](http://metacpan.org/search?q=Email::Simple::Markdown) is *amazing*',
    );

    print $email->as_string;

=head1 DESCRIPTION

I<Email::Simple::Markdown> behaves almost exactly like L<Email::Simple>,
excepts for one detail: when its method C<as_string()> is invoked, the
returned string representation of the email has multipart body with a 
I<text/plain> element (the original body), and a I<text/html> element,
the markdown rendering of the text body.

The markdown convertion is done using L<Text::MultiMarkdown>.

=head1 METHODS

I<Email::Simple::Markdown> inherits all the methods if L<Email::Simple>. 
In addition, it provides one more method: I<with_markdown>.

=head2 create( ... ) 

Behaves like L<Email::Simple>'s C<create()>, but accepts the following
additional arguments:

=over

=item markdown_engine => $module

See C<markdown_engine_set>. If not given, defaults to C<auto>.

=item css => $stylesheet

If provided, the html part of the email will be prepended with the given
stylesheet, wrapped by a I<css> tag.

=item pre_markdown_filter => sub { ... }

See C<pre_markdown_filter_set>.

=item charset => $charset

The character set supplied to C<Email::MIME::create()>. By default, no character set 
is passed.

=back

=head2 markdown_engine

Returns the markdown engine used by the object.

=head2 markdown_engine_set( $module )

Sets the markdown engine to be used by the object. 
Accepts C<auto>, L<Text::MultiMarkdown>, L<Text::Markdown>, or any module
implementing a C<markdown> method.

If not specified or set to C<auto>, the object will use the first markdown module it finds
between L<Text::MultiMarkdown> and L<Text::Markdown>.

=head2 css

Returns the cascading stylesheet that is applied to the html part of the
email.

=head2 css_set( $stylesheet )

Sets the cascading stylesheet for the html part of the email to be
I<$stylesheet>.  

    $email->css_set( <<'END_CSS' );
        p   { color: red; }
        pre { border-style: dotted; }
    END_CSS

The I<$stylesheet> can also be an array ref, holding key/value pairs where
the key is the css selector and the value the attached style. For example, 
the equivalent call to the one given above would be:

    $email->css_set([
        p   => 'color: red;',
        pre => 'border-style: dotted;',
    ]);

=head2 pre_markdown_filter_set( sub{ ... } );

Sets a filter to be run on the body before the markdown transformation is
done. The body will be passed as C<$_> and should be modified in-place.

E.g., to add a header to the email:

    $mail->pre_markdown_filter_set(sub {
        s#^#<div id="header">My Corp <img src='..' /></div>#;
    });

=head2 charset_set( $charset )

Sets the charset to be used by the email.

=head2 with_markdown()

Returns an L<Email::Abstract> representation of the email, with 
its multipart body.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2017, 2014, 2013, 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
