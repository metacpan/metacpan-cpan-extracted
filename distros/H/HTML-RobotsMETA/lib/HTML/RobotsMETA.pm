# $Id: /mirror/perl/HTML-RobotsMETA/trunk/lib/HTML/RobotsMETA.pm 4223 2007-10-29T06:42:26.630870Z daisuke  $
# 
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package HTML::RobotsMETA;
use strict;
use warnings;
use HTML::Parser;
use HTML::RobotsMETA::Rules;
our $VERSION = '0.00004';

sub new
{
    my $class = shift;
    my $self  = bless {}, $class;
    return $self;
}

sub parser
{
    my $self = shift;
    return $self->{parser} ||= HTML::Parser->new(
        api_version => 3,
        $self->get_parser_callbacks
    );
}

sub get_parser_callbacks
{
    my $self = shift;
    return (
        start_h => [ sub { $self->_parse_start_h(@_) }, "tagname, attr" ]
    );
}

sub parse_rules
{
    my $self = shift;

    my @rules;
    local $self->{rules} = \@rules;

    my $parser = $self->parser();
    
    $parser->parse(@_);
    $parser->eof;

    # merge rules that were found in this document
    my %directives = (map { %$_ } @rules);
    return HTML::RobotsMETA::Rules->new(%directives);
}

sub _parse_start_h
{
    my ($self, $tag, $attr) = @_;

    return unless $tag eq 'meta';

    # the "name" attribute may contain either "robots", or user-specified
    # robot name, which is specific to a particular crawler
    # XXX - Handle the specific agent part later
    return unless defined $attr->{name} && $attr->{name} =~ /^robots$/;

    my %directives;
    # Allowed values
    #   FOLLOW
    #   NOFOLLOW
    #   INDEX
    #   NOINDEX
    #   ARCHIVE
    #   NOARCHIVE
    #   SERVE
    #   NOSERVER
    #   NOIMAGEINDEX
    #   NOIMAGECLICK
    #   ALL
    #   NONE
    my $content = lc $attr->{content};
    while ($content =~ /((?:no)?(follow|index|archive|serve)|(?:noimage(?:index|click))|all|none)/g) {
        $directives{$1}++;
    }

    push @{$self->{rules}}, \%directives;
}

1;

__END__

=head1 NAME

HTML::RobotsMETA - Parse HTML For Robots Exclusion META Markup

=head1 SYNOPSIS

  use HTML::RobotsMETA;
  my $p = HTML::RobotsMETA->new;
  my $r = $p->parse_rules($html);
  if ($r->can_follow) {
    # follow links here!
  } else {
    # can't follow...
  }

=head1 DESCRIPTION

HTML::RobotsMETA is a simple HTML::Parser subclass that extracts robots
exclusion information from meta tags. There's not much more to it ;)

=head1 DIRECTIVES

Currently HTML::RobotsMETA understands the following directives:

=over 4

=item ALL

=item NONE

=item INDEX

=item NOINDEX

=item FOLLOW

=item NOFOLLOW

=item ARCHIVE

=item NOARCHIVE

=item SERVE

=item NOSERVE

=item NOIMAGEINDEX

=item NOIMAGECLICK

=back

=head1 METHODS

=head2 new

Creates a new HTML::RobotsMETA parser. Takes no arguments

=head2 parse_rules

Parses an HTML string for META tags, and returns an instance of
HTML::RobotsMETA::Rules object, which you can use in conditionals later

=head2 parser

Returns the HTML::Parser instance to use.

=head2 get_parser_callbacks

Returns callback specs to be used in HTML::Parser constructor. 

=head1 TODO

Tags that specify the crawler name (e.g. E<lt>META NAME="Googlebot"E<gt>) are
not handled yet.

There also might be more obscure directives that I'm not aware of.

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 SEE ALSO

L<HTML::RobotsMETA::Rules|HTML::RobotsMETA::Rules> L<HTML::Parser|HTML::Parser>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut