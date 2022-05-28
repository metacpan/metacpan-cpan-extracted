# First cut at using the readline history directly rather than reimplementing
# it. It does save history but it's a little crappy; still playing with it ;)
#
# epitaph, 22nd April 2007

use strict;
use warnings;
package Devel::REPL::Plugin::ReadLineHistory;
# ABSTRACT: Integrate history with the facilities provided by L<Term::ReadLine>

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use File::Spec;
use namespace::autoclean;

my $hist_file = $ENV{PERLREPL_HISTFILE} ||
    File::Spec->catfile(($^O eq 'MSWin32' && "$]" < 5.016 ? $ENV{HOME} || $ENV{USERPROFILE} : (<~>)[0]), '.perlreplhist');

# HISTLEN should probably be in a config file to stop people accidentally
# truncating their history if they start the program and forget to set
# PERLREPL_HISTLEN
my $hist_len=$ENV{PERLREPL_HISTLEN} || 100;

around 'run' => sub {
   my $orig=shift;
   my ($self, @args)=@_;
   if ($self->term->ReadLine eq 'Term::ReadLine::Gnu') {
      $self->term->stifle_history($hist_len);
   }
   if ($self->term->ReadLine eq 'Term::ReadLine::Perl') {
      $self->term->Attribs->{MaxHistorySize} = $hist_len;
   }
   if (-f($hist_file)) {
      if ($self->term->ReadLine eq 'Term::ReadLine::Gnu') {
         $self->term->ReadHistory($hist_file);
      }
      if ($self->term->ReadLine eq 'Term::ReadLine::Perl') {
         open HIST, $hist_file or die "ReadLineHistory: could not open $hist_file: $!\n";
         while (my $line = <HIST>) {
            chomp $line;
            $self->term->addhistory($line);
         }
         close HIST;
      }
   }

   $self->term->Attribs->{do_expand}=1;  # for Term::ReadLine::Gnu
   $self->term->MinLine(2);              # don't save one letter commands

   # let History plugin know we have Term::ReadLine support
   $self->have_readline_history(1) if $self->can('have_readline_history');


   $self->$orig(@args);

   if ($self->term->ReadLine eq 'Term::ReadLine::Gnu') {
      $self->term->WriteHistory($hist_file) ||
      $self->print("warning: failed to write history file $hist_file");
   }
   if ($self->term->ReadLine eq 'Term::ReadLine::Perl') {
      my @lines = $self->term->GetHistory() if $self->term->can('GetHistory');
      if( open HIST, ">$hist_file" ) {
         print HIST join("\n",@lines);
         close HIST;
      } else {
         $self->print("warning: unable to WriteHistory to $hist_file");
      }
   }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::ReadLineHistory - Integrate history with the facilities provided by L<Term::ReadLine>

=head1 VERSION

version 1.003029

=head1 DESCRIPTION

This plugin enables loading and saving command line history from
a file as well has history expansion of previous commands using
the !-syntax a la bash.

By default, history expansion is enabled with this plugin when
using L<Term::ReadLine::Gnu|Term::ReadLine::Gnu>. That means that
"loose" '!' characters will be treated as history events which
may not be what you wish.

To avoid this, you need to quote the '!' with '\':

  my $var = "foo\!";

or place the arguments in single quotes---but enable the
C<Term::ReadLine> attribute C<history_quotes_inhibit_expansion>:

  $_REPL->term->Attribs->{history_quotes_inhibit_expansion} = 1;
  my $var = 'foo!';

and to disable history expansion from GNU readline/history do

  $_REPL->term->Attribs->{do_expand} = 0;

=head1 CONFLICTS

Note that L<Term::ReadLine::Perl> does not support a history
expansion method.  In that case, you may wish to use the
L<Devel::REPL History plugin|Devel::REPL::Plugin::History> which provides similar functions.
Work is underway to make use of either L<History|Devel::REPL::Plugin::History> or
L<ReadLineHistory|Devel::REPL::Plugin::ReadHistory>> consistent for expansion with either the
L<Term::ReadLine::Gnu> support or L<Term::ReadLine::Perl>.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-REPL>
(or L<bug-Devel-REPL@rt.cpan.org|mailto:bug-Devel-REPL@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#devel> on C<irc.perl.org>|irc://irc.perl.org/#devel-repl>.

=head1 AUTHOR

Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>)

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
