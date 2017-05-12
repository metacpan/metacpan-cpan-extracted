package Kwiki::Emoticon;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';

our $VERSION = 0.03;

const class_id => 'emoticon_plugin';
const config_file => 'emoticon.yaml';

sub register {
    my $reg = shift;
    $reg->add(preload => 'emoticon_plugin');
    $reg->add(hook => 'formatter:formatter_classes', post => 'reformat');
    $reg->add(hook => 'formatter:all_phrases', post => 'addphrase');
}

sub reformat {
    my $hook = pop;
    my @classes = $hook->returned;
    push @classes, "Emoticon";
    return @classes;
}

sub addphrase {
    my $hook = pop;
    my $phrases = $hook->returned;
    push @$phrases, "emoticon";
    return $phrases
}

package Kwiki::Formatter::Emoticon;
use Spoon::Formatter;
use base 'Spoon::Formatter::Phrase';
use Text::Emoticon 0.03;

const formatter_id => 'emoticon';
field emoticon => {};

sub new {
    $self = super;
    my $class = $self->hub->config->emoticon_driver || 'MSN';
    my $emoticon = Text::Emoticon->new($class);
    $self->emoticon($emoticon);
    $self;
}

sub pattern_start {
    $self->emoticon->pattern;
}

sub html {
    my $matched = $self->matched;
    "<span>" . $self->emoticon->filter_one($self->matched) . "<!-- wiki: $matched --></span>"
}

package Kwiki::Emoticon;

1;
__DATA__

=head1 NAME

Kwiki::Emoticon - Emoticon phrase for Kwiki

=head1 SYNOPSIS

  > echo Kwiki::Emoticon >> plugins

  # optionally, you can change the Emoticon class (MSN by default)
  > $EDITOR config.yaml
  emoticon_driver: Yahoo

Now you can use emoticon like C<:-)> in your Kwiki text.

=head1 AUTHORS

Kang-min Liu E<lt>gugod@gugod.orgE<gt>

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__config/emoticon.yaml__
emoticon_driver: MSN
