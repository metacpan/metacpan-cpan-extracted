use strict;
use warnings;
package Devel::REPL::Plugin::Completion;
# ABSTRACT: Extensible tab completion

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use Scalar::Util 'weaken';
use PPI;
use namespace::autoclean;

has current_matches => (
   is => 'rw',
   isa => 'ArrayRef',
   lazy => 1,
   default => sub { [] },
);

has match_index => (
   is => 'rw',
   isa => 'Int',
   lazy => 1,
   default => sub { 0 },
);

has no_term_class_warning => (
   isa => "Bool",
   is  => "rw",
   default => 0,
);

has do_readline_filename_completion => (  # so default is no if Completion loaded
   isa => "Bool",
   is  => "rw",
   lazy => 1,
   default => sub { 0 },
);

before 'read' => sub {
   my ($self) = @_;

   if ((!$self->term->isa("Term::ReadLine::Gnu") and !$self->term->isa("Term::ReadLine::Perl"))
         and !$self->no_term_class_warning) {
      warn "Term::ReadLine::Gnu or Term::ReadLine::Perl is required for the Completion plugin to work";
      $self->no_term_class_warning(1);
   }

   my $weakself = $self;
   weaken($weakself);

   if ($self->term->isa("Term::ReadLine::Gnu")) {
      $self->term->Attribs->{attempted_completion_function} = sub {
         $weakself->_completion(@_);
      };
   }

   if ($self->term->isa("Term::ReadLine::Perl")) {
      $self->term->Attribs->{completion_function} = sub {
         $weakself->_completion(@_);
      };
   }

};

sub _completion {
   my $is_trp = scalar(@_) == 4 ? 1 : 0;
   my ($self, $text, $line, $start, $end) = @_;
   $end = $start+length($text) if $is_trp;

   # we're discarding everything after the cursor for completion purposes
   # we can't just use $text because we want all the code before the cursor to
   # matter, not just the current word
   substr($line, $end) = '';

   my $document = PPI::Document->new(\$line);
   return unless defined($document);

   $document->prune('PPI::Token::Whitespace');

   my @matches = $self->complete($text, $document);

   # iterate through the completions
   if ($is_trp) {
      if (scalar(@matches)) {
         return @matches;
      } else {
         return ($self->do_readline_filename_completion) ? readline::rl_filename_list($text) : () ;
      }
   } else {
      $self->term->Attribs->{attempted_completion_over} = 1 unless $self->do_readline_filename_completion;
      if (scalar(@matches)) {
         return $self->term->completion_matches($text, sub {
               my ($text, $state) = @_;

               if (!$state) {
                  $self->current_matches(\@matches);
                  $self->match_index(0);
               }
               else {
                  $self->match_index($self->match_index + 1);
               }

               return $self->current_matches->[$self->match_index];
            });
      } else {
         return;
      }
   }
}

sub complete {
   return ();
}

# recursively find the last element
sub last_ppi_element {
   my ($self, $document, $type) = @_;
   my $last = $document;
   while ($last->can('last_element') && defined($last->last_element)) {
      $last = $last->last_element;
      return $last if $type && $last->isa($type);
   }
   return $last;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::Completion - Extensible tab completion

=head1 VERSION

version 1.003029

=head1 NOTE

By default, the Completion plugin explicitly does I<not> use the Gnu readline
or Term::ReadLine::Perl fallback filename completion.

Set the attribute C<do_readline_filename_completion> to 1 to enable this feature.

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
