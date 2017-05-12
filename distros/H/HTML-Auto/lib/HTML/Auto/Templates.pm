package HTML::Auto::Templates;
# ABSTRACT: stores HTML::Auto templates
$HTML::Auto::Templates::VERSION = '0.09';
use base qw/Template::Provider/;

use warnings;
use strict;

use File::Basename;

my $templates = {

'matrix' => <<'EOT'
<style type="text/css">
span.vertical {
    -webkit-transform: rotate(180deg);
    -moz-transform: rotate(180deg);
    transform: rotate(180deg);
    writing-mode: tb-rl;
    filter: flipv fliph;
    display: block;
    width: 20px;
    white-space: nowrap;
}

table.auto th {
    padding-top: 24px;
    padding-bottom: 10px;
    padding-left: 5px;
    padding-right: 5px;
    width: 20px;
    background-color: #aaaaaa;
}

table.auto td {
    text-align: center;
    width: 30px;
    background-color: #eeeeee;
    padding: 6px;
}

table.auto td.fst {
    width: 80px;
    font-weight: bold;
    background-color: #aaaaaa;
    padding: 5px;
}

th.empty {
    background-color: white !important;
}

table.auto td.mid {
    background-color: #cccccc;
}

td:hover {
    background-color: #aaaaaa;
}

td.more_info { 
    position:relative;
    z-index:24;
    text-decoration:none;
    cursor: default;
    color: black;
    width: 80px;
}

td.more_info:hover{
    z-index:25;
}

td.more_info td {
    width: auto;
}

td.more_info span {
    display: none;
}

td.more_info:hover span { 
    display:block;
    position:absolute;
    border:1px solid #ccc;
    min-width:24em;
    background-color:#fff;
    color:#000;
    text-align: left;
    font-size: 80%;
    text-decoration: none;
} 

[% IF css %]
[% css %]
[% END %]
</style>

<table class="auto">
  <tr>
    <th class="empty"> </th>
      [% FOREACH i IN cols %]
        <th> <span class="vertical">[% i -%]</span></th>
      [% END %]
  </tr>
  [% i_c = 0 %]
  [% FOREACH i IN vals %]
    <tr>
      <td class="fst">[% lines.shift -%]</td>
        [% j_c = 0 %]
        [% FOREACH j IN i %]
          <td
            [% class = "" %]
            [% IF diagonal AND i_c == j_c %]
              [% class = "mid" %]
            [% END %]
            [% IF more.$i_c.$j_c %]
              [% class = "more_info " _  class %]
            [% END %]
            [% IF attrs.$i_c.$j_c.class %]
              [% class = class _ " " _ attrs.$i_c.$j_c.class %]
            [% END %]
            [% attrs.$i_c.$j_c.delete('class') %]
            [% IF class.length != 0 %] class="[% class %]" [% END %]
            [% FOREACH att IN attrs.$i_c.$j_c.keys %]
              [% att %]="[% attrs.$i_c.$j_c.$att %]" 
            [% END %]
            >[% IF myformat %][% j | format(myformat) %][% ELSE %][% j %][% END %]
              [% IF more.$i_c.$j_c %]
                <span>[% more.$i_c.$j_c %]</span> 
              [% END %]
          </td> 
	      [% j_c = j_c + 1 %]
        [% END %]
      </tr>
      [% i_c = i_c + 1 %]
  [% END %]
</table>
EOT
,
'h' => <<'EOT'
<div>
  [% FOREACH i IN list %]
    <div style="float: left;">[% i %]</div>
  [% END %]
  <span style="clear: both;"></div>
</div>
EOT
,
'v' => <<'EOT'
[% FOREACH i IN list %]
  <div>[% i %]</div>
[% END %]
EOT
};

sub _template_modified {
  my($self,$path) = @_;

  return 1;
}

sub _template_content {
  my ($self, $path) = @_;

  $path = basename($path);;
  $self->debug("get $path") if $self->{DEBUG};

  my $data = $templates->{$path};
  my $error = "error: $path not found";
  my $mod_date = 1;

  return $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Auto::Templates - stores HTML::Auto templates

=head1 VERSION

version 0.09

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
