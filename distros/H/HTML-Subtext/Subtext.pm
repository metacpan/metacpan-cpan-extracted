package HTML::Subtext;

use strict;
use URI::Escape;
use vars qw($VERSION @ISA);

require HTML::Filter;
@ISA=qw(HTML::Filter);

$VERSION = '1.03';

sub new {
  my $class = shift;
  my $self = $class->SUPER::new();
  while (@_) {
    my $key = shift;
    my $val = shift;
    $self->{$key} = $val;
  }
  return $self;
}

sub output {
  my $self = shift;
  my $output = $self->{'OUTPUT'};
  if ($output) {
    my $type = ref($output);
    if    ($type eq 'ARRAY') {
      push(@{$output}, $_[0]);
    }
    elsif ($type eq 'SCALAR') {
      $$output .= $_[0];
    }
    else {
      print $output $_[0];
    }
  }
  else {
    $self->SUPER::output(@_);
  }
}

sub start {
  my $self = shift;
  my $tag = $_[0];
  if ($tag eq 'a' && $_[1]{'href'} =~ /^subtext:(.*)/) {
    ($self->{subtext} = $self->{'CONTEXT'}{uri_unescape($1)})
    || do { warn "WARNING: HTML::Subtext -- no context for " . $_[3] . "\n";
            $self->SUPER::start(@_); }
  }
  else {
    $self->SUPER::start(@_);
  }
}

sub text {
  my $self = shift;
  if ($self->{subtext}) {
    $self->output($self->{subtext});
  }
  else {
    $self->SUPER::text(@_);
  }
}

sub end {
  my $self = shift;
  my $tag = $_[0];
  if ($self->{subtext} && $tag eq 'a') {
    $self->{subtext} = 0;
  }
  else {
    $self->SUPER::end(@_);
  }
}

1;
__END__

=head1 NAME

HTML::Subtext - Perform text substitutions on an HTML template

=head1 SYNOPSIS

  use HTML::Subtext;
  %context = ( ... ); # Hash of names to substitution text
  $p = HTML::Subtext->new('CONTEXT' => \%context);
  $p->parse_file("template.html");

=head1 DESCRIPTION

C<HTML::Subtext> is a package for performing text substitutions on a
specially formatted HTML template. The template uses normal HTML markup,
but includes links of the form:

  <a href="subtext:foo/bar">This text will be replaced</a>

The URI in this link tells C<HTML::Subtext> to check in the provided
hash C<'CONTEXT'> for a key named C<'foo/bar'>. If this lookup succeeds
in producing a string value, the text in the body of the link is replaced
by that value.

=head1 EXAMPLES

This example performs substitutions into a template embedded into the
Perl code as a I<here-document>.

  use HTML::Subtext;
  
  %context = (
    'author/name' => 'Kaelin Colclasure',
    'author/email' => '<a href="mailto:kaelin@acm.org">kaelin@acm.org</a>'
  );
  
  $p = HTML::Subtext->new('CONTEXT' => \%context);
  $p->parse(<<EOT);
  <html><head><title>example</title></head><body>
  <a href=\"subtext:author/name\">Author's name here</a>
  <a href=\"subtext:author/email\">mailto: link here</a>
  </body></html>
  EOT

When run, the example produces the following output:

  <html><head><title>example</title></head><body>
  Kaelin Colclasure
  <a href="mailto:kaelin@acm.org">kaelin@acm.org</a>
  </body></html>

=head1 SEE ALSO

L<HTML::Filter>, L<HTML::Parser>

=head1 COPYRIGHT

Copyright 1999 Kaelin Colclasure.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
