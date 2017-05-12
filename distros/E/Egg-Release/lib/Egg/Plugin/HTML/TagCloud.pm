package Egg::Plugin::HTML::TagCloud;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: TagCloud.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use HTML::TagCloud;

our $VERSION= '3.00';

sub tagcloud {
	my $e= shift;
	$_[1] ? HTML::TagCloud->new( levels => (shift || 10) )
	      : HTML::TagCloud->new(@_);
}

1;

__END__

=head1 NAME

Egg::Plugin::HTML::TagCloud - Plugin to use HTML::TagCloud.

=head1 SYNOPSIS

  package MyApp;
  use Egg qw/ HTML::TagCloud /;
  
  my $array= $e->get_tagging_data;
  
  my $cloud= $e->tagcloud(10);
  
  $cloud->add($_->{tag_name}, "/tags/$_->{tag_id}", $_->{count}) for @$array;
  
  $e->stash->{tagcloud_content}= $cloud->html_and_css;

=head1 DESCRIPTION

It is a plugin to use L<HTML::TagCloud>.

=head1 METHODS

=head2 tagcloud ([ARGS])

The object of L<HTML::TagCloud> is returned.

Especially, the object is not maintained. However, it only returns it.

ARGS is an option to pass to L<HTML::TagCloud>.

  my $cloud= $e->tagcloud( levels => 20 );

It is acceptable only to pass the figure.

  my $cloud= $e->tagcloud(20);
  
When ARGS is omitted ' levels => 10 ' becomes defaults.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::HTML::TagCloud>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

*COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

