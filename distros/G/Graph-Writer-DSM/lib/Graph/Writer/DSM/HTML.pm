package Graph::Writer::DSM::HTML;
$Graph::Writer::DSM::HTML::VERSION = '0.008';
use Modern::Perl;
use base qw( Graph::Writer );
use Mojo::Template;

local $/ = undef;
our $TEMPLATE = <DATA>;

=head1 NAME

Graph::Writer::DSM::HTML - draw graph as a DSM matrix in HTML format

=head1 VERSION

version 0.008

=head1 DESCRIPTION

See L<Graph::Writer::DSM>.

=head1 SYNOPSIS

See L<Graph::Writer::DSM>.

=head1 METHODS

=head1 new()

Like L<Graph::Writer::DSM>, this module provide some extra parameters
to new() method.

Supported parameters are:

=over 4

=item title

The title of HTML page. Default: 'Design Structure Matrix'.

=back

=cut

sub _init {
  my ($self, %param) = @_;
  $self->SUPER::_init();
  $self->{title} = $param{title} // 'Design Structure Matrix';
}

=head1 write_graph()

See L<Graph::Writer::DSM>.

=cut

sub _write_graph {
  my ($self, $graph, $FILE) = @_;
  my $template = Mojo::Template->new;
  my $output = $template->render($TEMPLATE, $graph, $self->{title});
  print $FILE $output;
}

1;

=head1 SEE ALSO

L<Graph>, L<Graph::Writer>, L<Chart::Gnuplot>.

=head1 CREDITS

Antonio Terceiro <terceiro AT softwarelivre.org>

=head1 COPYRIGHT

Copyright (c) 2013, Joenio Costa

=cut

__DATA__
% my ($graph, $title) = @_;
% my @modules = sort($graph->vertices);
<!DOCTYPE html>
<html>
  <body>
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=utf8"/>
      <title><%= $title %></title>
      <style type="text/css">
        table {
          border-collapse: collapse;
        }
        th {
          background: #eeeeec;
        }
        td, th {
          border: 1px solid #d3d7cf;
          min-width: 20px;
          text-align: center;
          vertical-align: center;
        }
        th:first-child {
          text-align: right;
          padding: 0px 5px;
        }
        td.empty {
          border: none;
        }
      </style>
    </head>
    <h1><%= $title %></h1>
    <table>
      <tr>
        <td class='empty'></td>
        % foreach my $m (@modules) {
        <th title='<%= $m %>'>&nbsp;</th>
        % }
      </tr>
      % foreach my $m1 (@modules) {
      <tr>
        <th><%= $m1 %></th>
        % foreach my $m2 (@modules) {
          % if ($m1 eq $m2) {
            <th title='<%= $m1 %>'>&nbsp;</th>
          % }
          % elsif ($graph->has_edge($m1, $m2)) {
            <td class='dependency' title='<%= $m1 %> &rarr; <%= $m2 %>'>&#9679;</td>
          % } else {
            <td>&nbsp;</td>
          % }
        % }
      </tr>
      % }
    </table>
  </body>
</html>
