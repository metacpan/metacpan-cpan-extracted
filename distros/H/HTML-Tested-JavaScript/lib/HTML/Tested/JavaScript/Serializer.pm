=head1 NAME

HTML::Tested::JavaScript::Serializer - Serialize HTML::Tested to/from JavaScript.

=head1 SYNOPSIS

  package MyClass;
  use base 'HTML::Tested';
  use HTML::Tested::JavaScript::Serializer;
  use HTML::Tested::JavaScript::Serializer::Value;
  
  use constant HTJS => "HTML::Tested::JavaScript::Serializer";

  # add JS Value named "val".
  __PACKAGE__->ht_add_widget(HTJS . "::Value", "val");

  # add serializer "ser" and bind "val" to it.
  __PACKAGE__->ht_add_widget(HTJS, "ser", "val");

  # now MyClass->ht_render produces ser javascript variable

  # in your HTML file serialize back
  ht_serializer_submit(ser, url, callback);

=head1 DESCRIPTION

This module serializes data to/from JavaScript data structures.
It also produces script tags to include necessary JavaScript files.

=head1 AUTHOR

	Boris Sukholitko
	boriss@gmail.com
	

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.
=head1 SEE ALSO

HTML::Tested, HTML::Tested::JavaScript::Serializer::Value,
HTML::Tested::JavaScript::Serializer::List.

Tests for HTML::Tested::JavaScript.

=cut 

use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript::Serializer;
use base 'HTML::Tested::Value';
use HTML::Tested::JavaScript;
use Carp;

sub new {
	my ($class, $parent, $name, @jses) = @_;
	my $self = bless({ name => $name, _jses => \@jses
			, _options => {} }, $class);
	my @unknowns = grep { !$parent->ht_find_widget($_) } @jses;
	confess "$class: Unable to find js controls: " . join(', ', @unknowns)
			 if @unknowns;
	return $self;
}

sub Wrap {
	my ($n, $v) = @_;
	$v =~ s#/#\\/#gs; # is needed for </script>
	return "<script>//<![CDATA[\nvar $n = $v;//]]>\n</script>";
}

sub render {
	my ($self, $caller, $stash, $id) = @_;
	my $n = $self->name;
	my $res = $caller->ht_get_widget_option($n, "no_script") ? ""
			: HTML::Tested::JavaScript::Script_Include();
	$res .= Wrap($n, "{\n\t" . join(",\n\t", grep { $_ } map {
				my $r = $stash->{$_};
				ref($r) ? $stash->{$_ . "_js"} : $r
			} @{ $self->{_jses} })
		. "\n}");
	$stash->{ $n } = $res;
}

sub validate { return (); }

sub Extract_Text {
	my ($n, $str) = @_;
	my ($res) = ($str =~ m#<script>//<!\[CDATA\[\nvar $n = (.*)#s);
	($res =~ s#;//\]\]>\n</script>.*##s) if $res;
	return $res;
}

sub Extract_JSON {
	my ($n, $str) = @_;
	my $et = Extract_Text($n, $str) // return;
	return JSON::XS->new->allow_nonref->decode($et);
}

1;
