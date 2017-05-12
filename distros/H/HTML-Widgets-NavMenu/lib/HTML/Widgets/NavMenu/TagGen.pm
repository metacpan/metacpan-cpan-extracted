package HTML::Widgets::NavMenu::TagGen;

use strict;
use warnings;

use base 'HTML::Widgets::NavMenu::Object';

use HTML::Widgets::NavMenu::EscapeHtml;

__PACKAGE__->mk_acc_ref([
    qw(name attributes)]
);

=head1 NAME

HTML::Widgets::NavMenu::TagGen - class to generate tags.

=head1 SYNOPSIS

For internal use only.

=head1 METHODS

=head2 name

For internal use.

=head2 attributes

For internal use.

=cut

sub _init
{
    my ($self, $args) = @_;

    $self->name($args->{'name'});
    $self->attributes($args->{'attributes'});

    return 0;
}

=head2 $self->gen($attribute_values, $is_standalone)

Generate the tag.

=cut

sub gen
{
    my $self = shift;

    my $attr_values = shift;

    my $is_standalone = shift || 0;

    my @tag_list = keys(%$attr_values);

    @tag_list = (grep { defined($attr_values->{$_}) } @tag_list);

    @tag_list = (sort { $a cmp $b } @tag_list);

    my $attr_spec = $self->attributes();

    return "<" . $self->name() .
        join("", map { " $_=\"" .
            ($attr_spec->{$_}->{'escape'} ?
                escape_html($attr_values->{$_})
                : $attr_values->{$_}
            ) . "\""
            } @tag_list) .
        ($is_standalone ? " /" : "") . ">";
}

1;

