# $Id: /local/perl/HTML-TagClouder/trunk/lib/HTML/TagClouder/Render/TT.pm 11406 2007-05-23T10:17:09.023599Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package HTML::TagClouder::Render::TT;
use strict;
use warnings;
use base qw(HTML::TagClouder::Render);
use Template;

__PACKAGE__->mk_accessors($_) for qw(template filename);

sub new
{
    my $class = shift;
    my $self  = $class->next::method(filename => 'cloud.tt', @_);

    $self->setup(@_);
    $self;
}

sub setup
{
    my $self = shift;
    my %args = @_;

    my %tt_args = %{ $args{tt_args} || {} };
    $tt_args{INCLUDE_PATH} ||= 'root';
    $self->template( Template->new( \%tt_args ) );
}

sub render
{
    my($self, $c) = @_;
    my $template = $self->template;

    my $out = '';
    $template->process($self->filename, { cloud => $c }, \$out) ||
        die $template->error();
    return $out;
}

1;

__END__

=head1 NAME

HTML::TagClouder::Render::TT - Render HTML::TagClouder With TT

=head1 DESCRIPTION

Renders HTML::TagClouder with Template Toolkit. This module expectes a
template file named cloud.tt to be in your INCLUDE_PATH, but you can 
change it by setting the filename parameter:

  HTML::TagClouder->new(
     render_class_args => {
        filename => 'mycustom_template.tt'
    }
  )

See examples/tt/cloud.tt for an example

=head1 METHODS

=head2 new

=head2 setup

=head2 render
=cut
