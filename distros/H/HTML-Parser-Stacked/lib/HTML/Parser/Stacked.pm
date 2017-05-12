# $Id: /mirror/perl/HTML-Parser-Stacked/trunk/lib/HTML/Parser/Stacked.pm 8903 2007-11-10T17:37:37.203788Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package HTML::Parser::Stacked;
use strict;
use warnings;
use base qw(HTML::Parser);
our $VERSION = '0.00001';

sub new
{
    my $class = shift;
    my %args  = @_;
    my (%handlers, %pargs);
    while (my($name, $spec) = each %args) {
        $handlers{ ($name =~ /^(.+)_h$/)[0] } = $spec;
        $pargs{ $name } = [ \&_dispatch, "self,event,$spec->[1]" ];
    }
    my $self = $class->SUPER::new(%pargs);
    $self->{stacked_parser}{handlers} = \%handlers;
    return $self;
}

sub _dispatch
{
    my ($self, $event, @args) = @_;
    my $cb_list = $self->{stacked_parser}{handlers}{$event}->[0];
    $_->(@args) for @$cb_list;
}

1;

__END__

=head1 NAME

HTML::Parser::Stacked - HTML::Parser With Stacked Handlers

=head1 SYNOPSIS

  use HTML::Parser::Stacked;

  HTML::Parser::Stacked->new(
    start_h => [
      [ \&start_handler1, \&start_handler2, \&start_handler3 ],
      "self,tag,attr"
    ],
    text_h => [
      [ \&text_handler1, \&text_handler2, \&text_handler3 ],
      "self,dtext"
    ]
  );

=head1 DESCRIPTION

I often find myself using multiple modules to analyze the contents of an
HTML document. By using this module, you can make one pass at the document
while employing multiple logics.

=head1 METHODS

=head2 new

Takes the same arguments as HTML::Parser, except that the handler spec
is an array reference of code references

If you had previously

  HTML::Parser->new(
    start_h => [ \&foo, " ... spec ... " ]
  );

You should write it as

  HTML::Parser::Stacked->new(
    start_h => [ [\&foo], " ... spec ... " ]
  );

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut