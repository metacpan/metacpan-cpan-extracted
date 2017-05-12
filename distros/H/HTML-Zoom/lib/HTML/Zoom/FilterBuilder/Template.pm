package HTML::Zoom::FilterBuilder;

use strictures 1;
use Template::Tiny;

sub _template_object {
  shift->{_template_object} ||= Template::Tiny->new;
}

sub template_text {
  my ($self, $vars) = @_;
  my $parser = $self->_zconfig->parser;
  my $tt = $self->_template_object;
  $self->collect({
    filter => sub {
      $_->map(sub {
        return $_ unless $_->{type} eq 'TEXT';
        my $unescape = $parser->html_unescape($_->{raw});
        $tt->process(\$unescape, $vars, \my $out);
        return { %$_, raw => $parser->html_escape($out) }
      })
    },
    passthrough => 1,
  })
}

sub template_text_raw {
  my ($self, $vars) = @_;
  my $tt = $self->_template_object;
  my $parser = $self->_zconfig->parser;
  $self->collect({
    filter => sub {
      $_->map(sub {
        return $_ unless $_->{type} eq 'TEXT';
        $tt->process(\($_->{raw}), $vars, \my $out);
        return { %$_, raw => $out }
      })
    },
    passthrough => 1,
  })
}

1;
