package HTML::Template::Ex::Filter;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Filter.pm 297 2007-03-25 14:34:59Z lushe $
#
use strict;
use warnings;

our $VERSION = '0.02';

sub set {
	{
	 format=> 'scalar',
	 sub=> sub {
		my $text= shift;
		$$text=~s{\[\%\s*([^\%]+)\s*\%\]} [ &__filter($1) ]sge;
	  },
	 };
}
sub __filter {
	local($_)= @_;
	return
	/^(?:var|\=)\s*(\S+)/i ? do {
		my $v= $1;
		$v=~/^(url|html)\s*\:(.+)/i
		  ? qq{<tmpl_var escape="$1" name="$2">}
		  : qq{<tmpl_var name=$v>};
	 }:
	/^ex(?:\s+(.+))?/i ? do {
		my($str, $option)= ($1, "");
		if ($str) {
			my($name, $escape)=
			  $str=~/^([^\:\"\']+)\s*\:\s*([^\s\"\']+)/ ? ($2, $1):
			  $str=~/^([^\:\"\']+)\:\s*$/ ? ("", $1):
			  $str=~/([^\s\"\']+)/ ? ($1, ""): ("", "");
			$option = qq{ escape="$escape} if $escape;
			$option.= qq{ name="$name"}    if $name;
		}
		qq{<tmpl_ex$option>};
	 }:
	/^set\s+([^\s\=]+)\s*\=\s*(.+)/i ? do {
		my($name, $value)= ($1, $2);
		$value=~s/(?:^[\"\']|[\"\']\s*$)//g;
		qq{<tmpl_set name="$name" value="$value">};
	 }:
	/^(if|unless)\s+(\S+)/i          ? do { qq{<tmpl_$1 name=$2>} }:
	/^else/i                         ? do { qq{<tmpl_else>} }:
	/^loop\s+(\S+)/i                 ? do { qq{<tmpl_loop name=$1>} }:
	/^(?:end_loop|\/\s*loop)/        ? do { qq{</tmpl_loop>} }:
	/^(?:include|\.\.\.?)\s*(\S+)/i  ? do { qq{<tmpl_include name=$1>} }:
	/^(?:end_|\/\s*)(if|unless|ex)/i ? do { qq{</tmpl_$1>} }:
	/^(?:\!|comment)/                ? do { "" }:
	do { qq{[% $_ %]} };
}

1;

__END__

=head1 NAME

HTML::Template::Ex::Filter - tmpl_tag filter for HTML::Template::Ex.

=head1 SYNOPSIS

  use HTML::Template::Ex;
  use HTML::Template::Ex::Filter;
  
  my $tmpl= HTML::Template::Ex->new(
    ...
    filter=> HTML::Template::Ex::Filter->set,
    );

  [%... include_template.tmpl %]
  
  [% ex %]
    my($self, $param)= @_;
    ...
    ..... ban, bo, bon.
    "";
  [% end_ex %]
  
  [% =param_name %]
  
  [% loop loop_param_name %]
    ...
  [% end_loop %]

=head1 DESCRIPTION

This module offers the filter to make the format of HTML::Template easy a little.

=head1 TAGS

=head2 [% ex %] ... [% end_ex %]

It corresponds to '<TMPL_EX> ... </TMPL_EX>'.

To specify the NAME attribute, as follows is done.

  [% ex param_name %] ...

In addition, delimit by the ESCAPE attribute and to the following

  [% ex html:param_name %]

NAME attribute a unspecified ESCAPE attribute must make the head and to the 
following

  [% ex html: %]

=head2 [% set PARAM_NAME="PARAM_VALUE" %]

It corresponds to '<TMPL_SET NAME="PARAM_NAME" VALUE="PARAM_VALUE">'.

=head2 [% =VAR_NAME %]

It corresponds to '<TMPL_VAR NAME="VAR_NAME">'.

The ESCAPE attribute does as follows.

  [% =html:VAR_NAME %]

=head2 [% if VAR_NAME %] ... [% else %] ... [% end_if %]

It corresponds to '<TMPL_IF NAME="VAR_NAME"> ... <TMPL_ELSE> ... </TMPL_IF>'.

=head2 [% unless VAR_NAME %] ... [% else %] ... [% end_unless %]

It corresponds to '<TMPL_UNLESS NAME="VAR_NAME"> ... <TMPL_ELSE> ... </TMPL_UNLESS>'.

=head2 [% loop ARRAY_NAME %] ... [% end_loop %]

It corresponds to '<TMPL_LOOP NAME="ARRAY_NAME"> ... </TMPL_LOOP>'.

=head2 [%... INCLUDE_TEMPLATE %]  or  [% include INCLUDE_TEMPLATE %]

It corresponds to '<TMPL_INCLUDE NAME="...">'.

=head2 [% ! COMMENT_STRING %]  or [% comment COMMENT_STRING %]

It is a comment. It is not reflected in the template.

=head1 SEE ALSO

L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
