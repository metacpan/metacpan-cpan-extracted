package HTML::Filter::Callbacks::Tag;

use strict;
use warnings;
use HTML::Entities;

sub new {
  my ($class, %args) = @_;

  bless {}, $class;
}

sub set {
  my ($self, $tokens, $org, $skipped_text) = @_;

  my ($name, @attrs) = @$tokens;
  if (@attrs >= 2 and $attrs[-1] eq '/' and $attrs[-2] eq '/') {
    splice @attrs, -2, 2;
  }

  %$self = (
    name       => $name,
    attrs      => \@attrs,
    org        => $org,
    skipped    => $skipped_text,
    prepend    => '',
    append     => '',
    is_dirty   => 0,
    is_removed => 0,
    is_end     => (substr($org, 0, 2) eq '</' ? 1 : 0),
    is_empty   => (substr($org, -2, 2) eq '/>' ? 1 : 0),
  );
}

sub name { shift->{name} }

sub as_string {
  my $self = shift;

  return unless $self->{name};

  my $out = '';
  if (defined $self->{skipped} and length $self->{skipped}) {
    $out .= $self->{skipped};
  }
  if (defined $self->{prepend} and length $self->{prepend}) {
    $out .= $self->{prepend};
  }
  unless ($self->{is_dirty}) {
    $out .= $self->{org};
  }
  else {
    unless ($self->{is_removed}) {
      $out .= '<';
      $out .= '/' if $self->{is_end};
      $out .= $self->{name};
      my @attrs = @{ $self->{attrs} };
      while (my ($key, $value) = splice @attrs, 0, 2) {
        $out .= " $key=$value" unless $key eq '/';
      }
      $out .= ' /' if $self->{is_empty} && substr($self->{name}, -1, 1) ne '/';
      $out .= '>';
    }
  }
  if (defined $self->{append} and length $self->{append}) {
    $out .= $self->{append};
  }
  return $out;
}

sub remove_tag {
  my $self = shift;

  $self->{is_removed} = 1;
  $self->{is_dirty} = 1;
}

sub remove_text_and_tag {
  my $self = shift;

  $self->{is_removed} = 1;
  $self->{skipped} = '';
  $self->{is_dirty} = 1;
}

sub remove_text {
  my $self = shift;

  $self->{skipped} = '';
}

sub remove_attr {
  my ($self, $cond) = @_;

  return unless $self->{attrs};
  return unless defined $cond and length $cond;

  $cond = qr/^$cond$/i unless ref $cond;

  my $offset = scalar @{ $self->{attrs} };
  while ($offset > 0) {
    if ($self->{attrs}->[$offset - 2] =~ /$cond/) {
      splice @{ $self->{attrs} }, $offset - 2, 2;
    }
    $offset -= 2;
  }
  $self->{is_dirty} = 1;
}

sub replace_attr {
  my ($self, $cond, $code_or_value) = @_;

  return unless $self->{attrs};
  return unless defined $cond and length $cond;

  $cond = qr/^$cond$/i unless ref $cond;

  my $offset = scalar @{ $self->{attrs} };
  while ($offset > 0) {
    if ($self->{attrs}->[$offset - 2] =~ /$cond/) {
      my ($value, $quote) = $self->_remove_quote($self->{attrs}->[$offset - 1]);

      if (ref $code_or_value eq 'CODE') {
        local $_ = $value;
        $value = $code_or_value->($_);
      }
      else {
        $value = $code_or_value;
      }
      $value = '' unless defined $value;
      $value = encode_entities($value, q/<>&'"/);
      if ($quote) {
        $value = "$quote$value$quote";
      }
      $self->{attrs}->[$offset - 1] = $value;
    }
    $offset -= 2;
  }
  $self->{is_dirty} = 1;
}

sub replace_tag {
    my ($self, $new_name) = @_;

    $self->{name}     = $new_name;
    $self->{is_dirty} = 1;
}

sub _remove_quote {
  my ($self, $value) = @_;
  my $open  = substr($value,  0, 1);
  my $close = substr($value, -1, 1);
  my $quote;
  if ($open eq $close and ($open eq q/'/ or $open eq q/"/)) {
    $quote = $open;
    $value = substr($value, 1, length($value) - 2);
  }
  $value = decode_entities($value);
  return wantarray ? ($value, $quote) : $value;
}

sub add_attr {
  my ($self, $name, $value) = @_;
  $value = $self->_remove_quote($value);
  $value = encode_entities($value, q/<>&"'/);
  my $offset = scalar @{ $self->{attrs} ||= [] };
  my $replaced;
  while ($offset > 0) {
    if ($self->{attrs}->[$offset - 2] eq $name) {
      $self->{attrs}->[$offset - 1] = qq/"$value"/;
      $replaced = 1;
      last;
    }
    $offset -= 2;
  }
  push @{ $self->{attrs} ||= [] }, $name, qq/"$value"/ unless $replaced;
  $self->{is_dirty} = 1;
}

sub attr {
  my ($self, $name) = @_;

  return unless $self->{attrs};

  $name = lc $name;
  my $offset = scalar @{ $self->{attrs} };
  while ($offset > 0) {
    if (lc $self->{attrs}->[$offset - 2] eq $name) {
      my $value = $self->_remove_quote($self->{attrs}->[$offset - 1]);
      return decode_entities($value);
    }
    $offset -= 2;
  }
  return;
}

sub prepend {
  my ($self, $html) = @_;

  $self->{prepend} = $html;
}

sub append {
  my ($self, $html) = @_;

  $self->{append} = $html;
}

sub text {
  my $self = shift;
  if (@_) {
    $self->{skipped} = shift;
  }
  $self->{skipped};
}

1;

__END__

=head1 NAME

HTML::Filter::Callbacks::Tag

=head1 DESCRIPTION

This will be passed to the callbacks you add to the L<HTML::Filter::Callbacks> object. See the SYNOPSIS of L<HTML::Filter::Callbacks> for usage.

=head1 METHODS

=head2 new

creates an object.

=head2 set

used internally to initialize the object.

=head2 name

returns the tag name.

=head2 attr

takes an attribute name and returns the attribute value or undef if there's no attribute of the name.

=head2 text

returns any text (everything other than tags) C<before> the tag. This typically returns white spaces between the tags for an open (start) tag, and the content of the tag for a close (end) tag, but don't count on that as HTMLs are not always well-structured.

You can replace the text by passing an extra argument.

=head2 add_attr

takes an attribute name and its value to add to the tag. If there's an attribute of the name, the value will be replaced.

=head2 remove_attr

takes an attribute name to remove. You can also pass a regular expression if you remove arbitrary attributes.

=head2 replace_attr

takes an attribute name and its value to replace. You can also pass a regular expression if you replace arbitrary attributes.

=head2 replace_tag

takes an tag name and its value to replace.

=head2 remove_tag

removes the tag entirely. Note that this only removes a start or end tag, not the pair. So you usually need to add another callback to remove the counterpart.

=head2 remove_text

removes the text before the tag.

=head2 remove_text_and_tag

removes both the text and the tag.

=head2 append

takes an HTML to insert after the tag. As of this writing, you need to escape the HTML by yourself if necessary.

=head2 prepend

takes an HTML to insert just before the tag, namely between the skipped text and the tag. As of this writing, you need to escape the HTML by yourself if necessary.

=head2 as_string

returns an HTML expression of the tag (with the skipped and inserted texts).

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

Yuji Shimada E<lt>xaicron@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
