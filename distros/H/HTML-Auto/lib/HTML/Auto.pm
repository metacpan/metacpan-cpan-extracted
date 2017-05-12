package HTML::Auto;
# ABSTRACT: write HTML for common elements
$HTML::Auto::VERSION = '0.09';
use warnings;
use strict;

use Template;
use HTML::Auto::Templates;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(matrix h v);

sub matrix {
  my ($cols,$lines,$data,$options) = @_;

  if ($options->{ucfirst}) {
    foreach (@$cols, @$lines) {
      $_ = ucfirst($_);
    }
  }

  my $vals = [];
  my $attrs = [];
  my $more = [];

  foreach my $row (@$data) {
    my $vrow = [];
    my $arow = [];
    my $mrow = [];
    foreach(@$row){
      if (ref($_)){
        push @$vrow, $_->{v};
        push @$arow, $_->{a};
        push @$mrow, $_->{more_info};
      }
      else {
        push @$vrow, $_;
        push @$arow, undef;
        push @$mrow, undef;
      }
    }
    push @$vals, $vrow;
    push @$attrs, $arow;
    push @$more, $mrow;
  }

  my $vars = {
      cols  => $cols,
      lines => $lines,
      vals  => $vals,
      attrs => $attrs,
      more  => $more,
    };
  $vars->{css} = $options->{css}
    if $options->{css};
  $vars->{myformat} = $options->{format}
    if $options->{format};
  $vars->{diagonal} = $options->{diagonal}
    if $options->{diagonal};

  my $template_name = 'matrix';
  __process($template_name, $vars);
}

sub h {
  my (@list) = @_;

  my $vars = {
      list => [@list],
    };
  my $template_name = 'h';

  __process($template_name, $vars);
}

sub v {
  my (@list) = @_;

  my $vars = {
      list => [@list],
  };
  my $template_name = 'v';

  __process($template_name, $vars);
}

sub __process {
  my ($template_name,$vars) = @_;

  # build html from template
  my $template_config = {
      INCLUDE_PATH => [ 'templates' ],
    };
  my $template = Template->new({
      LOAD_TEMPLATES => [ HTML::Auto::Templates->new($template_config) ],
    });
  my $html;
  $template->process($template_name, $vars, \$html);

  return $html;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

HTML::Auto - write HTML for common elements

=head1 VERSION

version 0.09

=head1 SYNOPSIS

Simple example:

  use HTML::Auto qw/matrix h v/;

  my @cols = qw/c1 c2 c3 c4 c5/;
  my @lines = qw/l1 l2 l3 l4 l5/;
  my $data =
     [ [1,2,3,4,5],
       [6,7,8,9,0],
       [1,1,1,1,1],
       [2,2,2,2,2],
       [3,3,3,3,3] ];

  my $m = matrix(\@cols,\@lines,$data);

  print v(
          h($m,$m,$m),
          h($m,$m),
        );

Using attributes:

  use HTML::Auto qw/matrix h v/;

  my @cols = qw/c1 c2/;
  my @lines = qw/l1 l2/;
  my $data =
     [
       [
         {v => 1, a => { style => 'background: green'}},
         2
       ],
       [
         {v => 3, a => {class => 'foo'}},
         {v => 4, a => {style => 'color: red'}}
       ]
     ];

  my $m = matrix(\@cols,\@lines,$data);

  print v(
          h($m)
        );

With mouse-over span:

  use HTML::Auto qw/matrix h v/;

  my @cols = qw/c1 c2/;
  my @lines = qw/l1 l2/;
  my $data =
     [[1,2],
    [3,
    { v=> 4,
      more_info => "This is a pop-up!"
    }]
   ];


  my $m = matrix(\@cols,\@lines,$data);

  print v(
          h($m)
        );

Passing additional CSS:

  use HTML::Auto qw/matrix h v/;

  my @cols = qw/c1 c2/;
  my @lines = qw/l1 l2/;
  my $data =
     [
       [
         {v => 1, a => { class => 'warn'}},
         2
       ],
       [3,4]
     ];

  my $options = { css => '.warn { background-color: yellow !important; }' };

  my $m = matrix(\@cols,\@lines,$data,$options);

  print v(
          h($m)
        );

=head1 FUNCTIONS

=head2 matrix

Build a matrix. Some options are available to pass to the matrix function:

=over 6

=item C<diagonal>

Highlight the diagonal of the matrix.

  my $m = matrix(\@cols,\@lines,$data, {diagonal => 1});

=item C<format>

Pass a string to be used by the C<format> filter in the TT2 template.

  my $m = matrix(\@cols,\@lines,$data, {format => '%.6f'});

=item C<ucfirst>

Option to uppercase first letter in columns and lines labels.

  my $m = matrix(\@cols,\@lines,$data, {ucfirst => 1});

=back

=head2 h

A function to allow horizontal composition.

=head2 v

A function to allow vertical composition.

=head1 AUTHORS

=over 4

=item *

Nuno Carvalho <smash@cpan.org>

=item *

André Santos <andrefs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2016 by Project Natura <natura@natura.di.uminho.pt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
