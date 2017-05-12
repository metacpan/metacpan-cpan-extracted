# $Id: /local/perl/HTML-TagClouder/trunk/lib/HTML/TagClouder.pm 11417 2007-05-24T00:51:44.727126Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package HTML::TagClouder;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Class::C3;
use Class::Inspector;
use UNIVERSAL::isa;
use UNIVERSAL::require;
use overload 
    '""' => \&render,
    fallback => 1
;
INIT { Class::C3::initialize() }
use HTML::TagClouder::Tag;

our $VERSION = 0.02;

__PACKAGE__->mk_accessors($_) for 
    qw(renderer collection processor is_processed)
;

sub new
{
    my $class = shift;
    my $self  = bless {}, $class;
    $self->setup(@_);

    return $self;
}

sub setup
{
    my $self = shift;
    my %args = @_;
    $self->is_processed(0);

    my $render_class = $self->_load_module( $args{render_class} || 'HTML::TagClouder::Render::TT');
    $self->renderer( $render_class->new(%{ $args{render_class_args} || {} }, cloud => $self) );

    my $collection_class = $self->_load_module( $args{collection_class} || 'HTML::TagClouder::Collection::Simple' );
    $self->collection( $collection_class->new(%{ $args{collection_class_args} || {} }, cloud => $self) );

    my $processor_class = $self->_load_module( $args{processor_class} || 'HTML::TagClouder::Processor::Simple' );
    $self->processor( $processor_class->new(%{ $args{processor_class} || {} }) );

}

sub _load_module
{
    my $self = shift;
    my $class = shift;
    if (! Class::Inspector->loaded( $class )) {
        $class->require or die "Could not require $class: $@";
    }
    return $class;
}

sub process
{
    my $self = shift;
    $self->processor->process( $self );
    $self->is_processed(1);
}

sub render
{
    my $self = shift;

    if (! $self->is_processed) {
        $self->process;
    }

    $self->renderer()->render($self);
}

sub add
{
    my $self = shift;
    my $tag;
    if (ref $_[0] && $_[0]->isa('HTML::TagClouder::Tag')) {
        $tag = shift;
    } else {
        my ($label, $uri, $count, $timestamp) = @_;
        $tag = HTML::TagClouder::Tag->new(
            label => $label,
            count => $count,
            uri   => $uri,
            timestamp => $timestamp || now()
        );
    }
    $self->collection->add($tag);
}

1;

__END__

=head1 NAME

HTML::TagClouder - Configurable Tag Cloud Generator

=head1 SYNOPSIS

  use HTML::TagClouder;

  # All arguments are optional!
  my $cloud = HTML::TagClouder->new(
    collection_class      => 'HTML::TagClouder::Collection::Simple',
    collection_class_args => { ... },
    processor_class       => 'HTML::TagClouder::Collection::Processor::Simple',
    processor_class_args  => { ... }, 
    render_class          => 'HTML::TagClouder::Render::TT',
    render_class_args     => {
      tt_args => {
        INCLUDE_PATH => '/path/to/templates'
      }
    }
  );
  $cloud->add(HTML::TagClouder::Tag->new($label, $uri, $count, $timestamp));
  $cloud->add($label, $uri, $count, $timestamp);

  $cloud->render;

  # or in your template
  [% cloud %]

=head1 DESCRIPTION

*WARNING* Alpha software! I mean it!

HTML::TagClouder is another take on generating Tagclouds.

It was build because a coleague complained that he wanted to customize the
HTML that gets generated for tag clouds. Other modules generated their
own HTML and it was hardcoded, hence HTML::TagClouder was born.

Currently it does just the bare minimum to generate a cloud (see CAVEATS),
but the entire process is completely configurable by allowing you to pass
in class names to do the particular job in each phase of generating the
tag cloud.

HTML::TagClouder goes through 3 phases before generating a tag cloud:

=over 4

=item 1. Data Collection

Build up your tag list via $cloud->add($tag). The tag collection is built
using HTML::TagClouder::Collection.

=item 2. Process The Tags

The processor specified in processor_class (HTML::TagClouder::Processor::Simple
by default) will iterator through the collection that was built, and will
do any required calculation.

=item 3. Render The Tags

The tags will be rendered as appropriate. By default we use Template Toolkit
for this via HTML::TagClouder::Render::TT.

=back

The main difference between the other tag cloud generators is that each
phase of the cloud generation is completely configurable. For example, by
default it uses a very naive algorithm to calculate the font sizes for
the tags, but you can easily change the logic by simple changing the
'processor' class to something you built:

  my $cloud = HTML::TagClouder->new(
    processor_class => 'MyProcessor'
  );

Or, should you decide to use a different rendering engine than the default
Template Toolkit based renderer, you can do:

  my $cloud = HTML::TagClouder->new(
    render_class => 'MyRenderClass'
  );

=head1 STRINGIFICATION

HTML::TagClouder objects automatically stringify as HTML, so you can simply
place it in your favorite template's variable stash. For example, in 
Catalyst with Template Toolkit:

  # in your controller
  sub cloud : Local {
     my ($self, $c) = @_;
     my $cloud = HTML::TagClouder->new(...);
     # add tags to cloud

     $c->stash->{cloud} = $cloud;
  }

  # in your template
  [% cloud %]

The above will simply insert the HTML generated by HTML::TagClouder.
No methods! Of course, you can achieve the equivalent by doing:

  [% cloud.render %]

=head1 TODO

=over 4

=item Incorporate "hot" tags. 

=item Set maximum for tag list

=back

Patches welcome!

=head1 CAVEATS

The interface allows a timestamp argument, but it does nothing at this moment.
I don't plan on using it for a while, so if you want it, patches welcome.

The above also means that currently there's no way to change the color of the
tags. Of course, you can always create your own subclasses that does so.

=head1 METHODS

=head2 new %args

new() constructs a new HTML::TagClouder instance, and may take the following 
parameters. If a parameter is omitted, some sane default will be provided.

=over 4

=item collection_class

The HTML::TagClouder::Collection class name that will hold the tags while
the cloud is being built

=item collection_class_args

A hashref of arguments to be passed to the collection class' constructor.

=item processor_class

The HTML::TagClouder::Processor class name that will be used to normalize
the tags. This is responsible for calculating various attributes that will
be used when rendering the tag cloud

=item processor_class_args

A hashref of arguments to be passed to the processor class' constructor.

=item render_class

The HTML::TagClouder::Render class name that will be used to render the
tag cloud for presentation

=item render_class_args

A hashref of arguments to be passed to the render class' constructor.

=back

=head2 setup

Sets up the object.

=head2 add $tag

=head2 add $label, $uri, $count, $timestamp

Adds a new tag. Accepts either the parameters passed to HTML::TagClouder::Tag
constructor, or a HTML::TagClouder::Tag instance

=head2 process

Processes the tags. This method will be automatically called from render()

=head2 render

Renders the tag cloud and returns the html.

=head1 SEE ALSO

L<HTML::TagCloud::Extended|HTML::TagCloud::Extended>, L<HTML::TagCloud>

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut