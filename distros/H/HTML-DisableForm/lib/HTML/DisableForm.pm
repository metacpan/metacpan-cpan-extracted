package HTML::DisableForm;
use strict;
use warnings;
use base qw/HTML::Parser/;

our $VERSION = 0.01;

my %can_disable = (
    input    => 1,
    textarea => 1,
    select   => 1,
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(api_version => 3);
    $self->handler(start => \&_handle_start, "self, tagname, attr, text");
    $self->handler(end   => \&_handle_end, "self, tagname, text");
    $self->handler(default => \&_handle_default, "self, text");
    $self->attr_encoded(1);
    bless $self, $class;
}

sub readonly_form {
    my ($self, %option) = @_;
    $self->disable_form(%option, readonly => 1);
}

sub disable_form {
    my ($self, %option) = @_;
    $self->{target}   = $option{target} if $option{target};
    $self->{readonly} = 1 if $option{readonly};
    $self->_set_options_map($_, $option{$_}) for qw/ignore_fields ignore_forms/;
    $self->_parse(%option);
    delete $self->{output};
}

sub _set_options_map {
    my ($self, $name, $value) = @_;
    return unless defined $value;
    my %options_map = map { $_ => 1 } ref $value eq 'ARRAY' ? @$value  : $value;
    $self->{$name} = \%options_map;
}

sub _parse {
    my $self = shift;
    my %option = @_;
    if (my $file = $option{file}){
        $self->parse_file($file);
    } elsif (my $scalarref = $option{scalarref}){
        $self->parse($$scalarref);
    } elsif (my $arrayref = $option{arrayref}){
        $self->parse($_) for @$arrayref;
    }
}

sub _can_disable {
    my ($self, $tagname, $attr) = @_;
    $can_disable{$tagname} or return;
    return 0 if defined $self->{target} && !$self->{current_form};
    if (my $current_form = $self->{current_form}) {
        if (defined $self->{target}) {
            $current_form eq $self->{target} ? return 1 : return 0;
        }
        return 0 if $self->{ignore_forms}->{$current_form};
    }
    if ($attr->{name}) {
        return 0 if $self->{ignore_fields}->{$attr->{name}};
    }
    return 1;
}

sub _handle_start {
    my ($self, $tagname, $attr, $text) = @_;
    $self->{current_form} = $attr->{name} || $attr->{id} || ''
        if $tagname eq 'form';

    if ($self->_can_disable($tagname, $attr)) {
        $self->{output} .= "<$tagname";
        while (my ($key, $value) = each %$attr) {
            next if $key eq '/';
            $self->{output} .= sprintf qq( %s="%s"), $key, $value;
        }
        $self->{output} .= $self->{readonly} ? ' readonly="readonly"' : ' disabled="disabled"';
        $self->{output} .= ' /' if $attr->{'/'};
        $self->{output} .= '>';
    } else {
        $self->{output} .= $text;
    }
}

sub _handle_end {
    my ($self, $tagname, $text) = @_;
    delete $self->{current_form}
        if $tagname eq 'form' and exists $self->{current_form};
    $self->{output} .= $text;
}

sub _handle_default {
    my ($self, $text) = @_;
    $self->{output} .= $text;
}

1;

__END__

=head1 NAME

HTML::DisableForm - Manipulate disabled/readonly HTML Forms

=head1 SYNOPSIS

    use HTML::DisableForm;

    my $df = new HTML::DisableForm;
    my $output = $dif->disable_form(scalarref => \$html);

=head1 DESCRIPTION

This module automatically makes form controlls disable/readonly.

=head1 METHODS

=head2 new

Creates a new HTML::DisableForm object

  $df = new HTML::DisableForm

=head2 disable_form

Returns HTML with disabled forms. This method can take some type of
argument for a HTML document.

  $output = $df->disable_form(scalarref => \$html);

  $output = $df->disable_form(file => "/path/to/document.html");

  $output = $df->disable_form(arrayref => \@html);

Specify readonly flag if you want to makes it readonly instead of disable.

  $output = $df->disable_form(arrayref => \@html);

Suppose you have multiple forms in a html and among them there is only
one form you want to disable, specify target.

   $output = $df->disable_form(
      scalarref => \$html,
      target    => 'foo',
   );

If there are some forms you want to ignore, specify their names as
ignore_forms.

   $output = $df->disable_form(
      scalarref    => \$html,
      ignore_forms => [qw/foo bar/],
   );

You can also ignore fields what you want.

   $output = $df->disable_form(
      scalarref    => \$html,
      ignore_fields => [qw/name password/],
   );

=head2 readonly_form

This method equals to C<disable_form()> with a readonly flag.

=head1 TODO

More tests.

=head1 AUTHOR

Naoya Ito  C<< <naoya@bloghackers.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Naoya Ito C<< <naoya@bloghackers.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
