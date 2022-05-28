use strict;
use warnings;
package Devel::REPL::Plugin::CompletionDriver::INC;
# ABSTRACT: Complete module names in use and require

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use Devel::REPL::Plugin::Completion;    # die early if cannot load
use File::Next;
use File::Spec;
use namespace::autoclean;

sub BEFORE_PLUGIN {
    my $self = shift;
    $self->load_plugin('Completion');
}

around complete => sub {
  my $orig = shift;
  my ($self, $text, $document) = @_;

  my $last = $self->last_ppi_element($document, 'PPI::Statement::Include');

  return $orig->(@_)
    unless $last->isa('PPI::Statement::Include');

  my @elements = $last->children;
  shift @elements; # use or require

  # too late for us to care, they're completing on something like
  #     use List::Util qw(m
  # OR they just have "use " and are tab completing. we'll spare them the flood
  return $orig->(@_)
    if @elements != 1;

  my $package = shift @elements;
  my $outsep  = '::';
  my $insep   = "::";
  my $keep_extension = 0;
  my $prefix  = '';

  # require "Foo/Bar.pm" -- not supported yet, ->string doesn't work for
  # partially completed elements
  #if ($package->isa('PPI::Token::Quote'))
  #{
  #  # we need to strip off the leading quote and stash it
  #  $package = $package->string;
  #  my $start = index($package->quote, $package);
  #  $prefix = substr($package->quote, 0, $start);

  #  # we're completing something like: require "Foo/Bar.pm"
  #  $outsep = $insep = '/';
  #  $keep_extension = 1;
  #}
  if ($package =~ /'/)
  {
    # the goofball is using the ancient ' package sep, we'll humor him
    $outsep = "'";
    $insep = "'|::";
  }

  my @directories = split $insep, $package;

  # split drops trailing fields
  push @directories, '' if $package =~ /(?:$insep)$/;
  my $final = pop @directories;
  my $final_re = qr/^\Q$final/;

  my @found;

  # most VCSes don't litter every single fucking directory with garbage. if you
  # know of any other, just stick them in here. No one wants to complete
  # Devel::REPL::Plugin::.svn
  my %ignored =
  (
      '.'    => 1,
      '..'   => 1,
      '.svn' => 1,
  );

  # this will take a directory and add to @found all of the possible matches
  my $add_recursively;
  $add_recursively = sub {
    my ($path, $iteration, @more) = @_;
    opendir((my $dirhandle), $path) || return;
    for (grep { !$ignored{$_} } readdir $dirhandle)
    {
      my $match = $_;

      # if this is the first time around, we need respect whatever the user had
      # at the very end when he pressed tab
      next if $iteration == 0 && $match !~ $final_re;

      my $fullmatch = File::Spec->rel2abs($match, $path);
      if (-d $fullmatch)
      {
        $add_recursively->($fullmatch, $iteration + 1, @more, $match);
      }
      else
      {
        $match =~ s/\..*// unless $keep_extension;
        push @found, join '', $prefix,
                              join $outsep, @directories, @more, $match;
      }
    }
  };

  # look through all of
  INC: for (@INC)
  {
    my $path = $_;

    # match all of the fragments they have, so "use Moose::Meta::At<tab>"
    # will only begin looking in ../Moose/Meta/
    for my $subdir (@directories)
    {
      $path = File::Spec->catdir($path, $subdir);
      -d $path or next INC;
    }

    $add_recursively->($path, 0);
  }

  return $orig->(@_), @found;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::CompletionDriver::INC - Complete module names in use and require

=head1 VERSION

version 1.003029

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-REPL>
(or L<bug-Devel-REPL@rt.cpan.org|mailto:bug-Devel-REPL@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#devel> on C<irc.perl.org>|irc://irc.perl.org/#devel-repl>.

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail dot com> >>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
