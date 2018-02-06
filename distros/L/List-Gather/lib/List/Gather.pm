package List::Gather; # git description: 0.13-9-g4c4e5d3
# ABSTRACT: Construct lists procedurally without temporary variables

use strict;
use warnings;

our $VERSION = '0.14';

use Devel::CallParser;
use Devel::CallChecker;

use XSLoader;

XSLoader::load(
    __PACKAGE__,
    $VERSION,
);

require B::Hooks::EndOfScope
    unless _QPARSE_DIRECTLY();

my @keywords;
BEGIN { @keywords = qw(gather take gathered) }

use Sub::Exporter -setup => {
    exports => [@keywords],
    groups  => { default => [@keywords] },
};

#pod =head1 SYNOPSIS
#pod
#pod   use List::Gather;
#pod
#pod   my @list = gather {
#pod       while (<$fh>) {
#pod           next if /^\s*$/;
#pod           next if /^\s*#/;
#pod           last if /^(?:__END__|__DATA__)$/;
#pod           take $_ if some_predicate($_);
#pod       }
#pod
#pod       take @defaults unless gathered;
#pod   };
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module provides a C<gather> keyword that allows lists to be constructed
#pod procedurally, without the need for a temporary variable.
#pod
#pod Within the block controlled by a C<gather> any call to C<take> pushes that
#pod call's argument list to an implicitly created array.
#pod
#pod C<gather> returns the list of values taken during its block's execution.
#pod
#pod =head1 EXAMPLES
#pod
#pod   my @interesting_child_nodes = gather for my $n (@nodes) {
#pod       take $n->all_children
#pod           if $n->is_interesting;
#pod   };
#pod
#pod   my @last_10_events = gather {
#pod       while ($log->has_event) {
#pod           take $log->next_event;
#pod       }
#pod
#pod       shift gathered while gathered > 10;
#pod   };
#pod
#pod   my @search_results = gather {
#pod       $user_interface->register_status_callback(sub {
#pod           sprintf "Searching... Found %d matches so far", scalar gathered;
#pod       });
#pod
#pod       wait_for_search_results(sub {
#pod           my ($result) = @_;
#pod           take $result;
#pod       }, @search_terms);
#pod
#pod       $user_interface->register_status_callback(sub {
#pod           sprintf "Found a total of %d", scalar gathered;
#pod       });
#pod   };
#pod
#pod   my @leaf_nodes = gather {
#pod       $graph->visit_all_nodes_recursively(sub {
#pod           my ($node) = @_;
#pod           take $node if $node->is_leaf;
#pod       });
#pod   };
#pod
#pod =func gather
#pod
#pod   gather { ... }
#pod   gather({ ... })
#pod   gather STMT
#pod
#pod Executes the block it has been provided with, collecting all arguments passed to
#pod C<take> calls within it. After execution, the list of values collected is
#pod returned.
#pod
#pod Note that block C<gather> executes is equivalent to a C<do BLOCK>. It is neither
#pod a code nor a loop. Loop control keywords, such as C<next> and C<last>, as well
#pod as C<return> will behave accordingly.
#pod
#pod Parens around the C<gather> block are optional.
#pod
#pod =func take
#pod
#pod   take LIST
#pod
#pod Collects a C<LIST> of values within the C<gather> block it has been compiled in.
#pod
#pod C<take> returns all its arguments.
#pod
#pod C<take> calls outside of the lexical scope of a C<gather> block are compile time
#pod errors. Calling C<take> is only legal within the dynamic scope its associated
#pod C<gather> block.
#pod
#pod =func gathered
#pod
#pod   gathered
#pod
#pod Returns the list of items collected so far during the execution of a C<gather>
#pod block.
#pod
#pod C<gathered> calls outside of the lexical scope of a C<gather> block are compile
#pod time errors. Calling C<gathered> outside of the dynamic scope of its associated
#pod C<gather> block is legal.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod = L<Syntax::Keyword::Gather>
#pod A non-lexical gather/take implementation that's otherwise very similar to this one
#pod = L<Perl6::GatherTake>
#pod An experimental implementation of a lazily evaluating gather/take
#pod = L<Perl6::Take>
#pod A very simple gather/take implementation without lexical scoping
#pod = L<Perl6::Gather>
#pod Like L<Syntax::Keyword::Gather>, but reliant on L<Perl6::Export>
#pod = L<List::Gen>
#pod A comprehensive suit list generation functions featuring a non-lexical gather/take
#pod
#pod =head1 ACKNOWLEDGEMENTS
#pod
#pod =for :list
#pod * Andrew Main (Zefram) E<lt>zefram@fysh.orgE<gt>
#pod for providing his input in both the design and implementation of this module,
#pod and writing much of the infrastructure that made this module possible in the
#pod first place
#pod * Arthur Axel "fREW" Schmidt E<lt>frioux+cpan@gmail.comE<gt>
#pod for his input on various aspects of this module as well as the many tests of his
#pod L<Syntax::Keyword::Gather> module that this module shamelessly stole
#pod * Dave (autarch) Rolsky <autarch@urth.org> and Jesse (doy) Luehrs E<lt>doy@tozt.netE<gt>
#pod for helping to improve both documentation and test coverage
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

List::Gather - Construct lists procedurally without temporary variables

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  use List::Gather;

  my @list = gather {
      while (<$fh>) {
          next if /^\s*$/;
          next if /^\s*#/;
          last if /^(?:__END__|__DATA__)$/;
          take $_ if some_predicate($_);
      }

      take @defaults unless gathered;
  };

=head1 DESCRIPTION

This module provides a C<gather> keyword that allows lists to be constructed
procedurally, without the need for a temporary variable.

Within the block controlled by a C<gather> any call to C<take> pushes that
call's argument list to an implicitly created array.

C<gather> returns the list of values taken during its block's execution.

=head1 FUNCTIONS

=head2 gather

  gather { ... }
  gather({ ... })
  gather STMT

Executes the block it has been provided with, collecting all arguments passed to
C<take> calls within it. After execution, the list of values collected is
returned.

Note that block C<gather> executes is equivalent to a C<do BLOCK>. It is neither
a code nor a loop. Loop control keywords, such as C<next> and C<last>, as well
as C<return> will behave accordingly.

Parens around the C<gather> block are optional.

=head2 take

  take LIST

Collects a C<LIST> of values within the C<gather> block it has been compiled in.

C<take> returns all its arguments.

C<take> calls outside of the lexical scope of a C<gather> block are compile time
errors. Calling C<take> is only legal within the dynamic scope its associated
C<gather> block.

=head2 gathered

  gathered

Returns the list of items collected so far during the execution of a C<gather>
block.

C<gathered> calls outside of the lexical scope of a C<gather> block are compile
time errors. Calling C<gathered> outside of the dynamic scope of its associated
C<gather> block is legal.

=head1 EXAMPLES

  my @interesting_child_nodes = gather for my $n (@nodes) {
      take $n->all_children
          if $n->is_interesting;
  };

  my @last_10_events = gather {
      while ($log->has_event) {
          take $log->next_event;
      }

      shift gathered while gathered > 10;
  };

  my @search_results = gather {
      $user_interface->register_status_callback(sub {
          sprintf "Searching... Found %d matches so far", scalar gathered;
      });

      wait_for_search_results(sub {
          my ($result) = @_;
          take $result;
      }, @search_terms);

      $user_interface->register_status_callback(sub {
          sprintf "Found a total of %d", scalar gathered;
      });
  };

  my @leaf_nodes = gather {
      $graph->visit_all_nodes_recursively(sub {
          my ($node) = @_;
          take $node if $node->is_leaf;
      });
  };

=head1 SEE ALSO

=over 4

=item L<Syntax::Keyword::Gather>

A non-lexical gather/take implementation that's otherwise very similar to this one

=item L<Perl6::GatherTake>

An experimental implementation of a lazily evaluating gather/take

=item L<Perl6::Take>

A very simple gather/take implementation without lexical scoping

=item L<Perl6::Gather>

Like L<Syntax::Keyword::Gather>, but reliant on L<Perl6::Export>

=item L<List::Gen>

A comprehensive suit list generation functions featuring a non-lexical gather/take

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item *

Andrew Main (Zefram) E<lt>zefram@fysh.orgE<gt>

for providing his input in both the design and implementation of this module,
and writing much of the infrastructure that made this module possible in the
first place

=item *

Arthur Axel "fREW" Schmidt E<lt>frioux+cpan@gmail.comE<gt>

for his input on various aspects of this module as well as the many tests of his
L<Syntax::Keyword::Gather> module that this module shamelessly stole

=item *

Dave (autarch) Rolsky <autarch@urth.org> and Jesse (doy) Luehrs E<lt>doy@tozt.netE<gt>

for helping to improve both documentation and test coverage

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=List-Gather>
(or L<bug-List-Gather@rt.cpan.org|mailto:bug-List-Gather@rt.cpan.org>).

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Father Chrysostomos David Mitchell Tony Cook bay-max1

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Father Chrysostomos <sprout@cpan.org>

=item *

David Mitchell <davem@iabyn.com>

=item *

Tony Cook <tonyc@cpan.org>

=item *

bay-max1 <34803732+bay-max1@users.noreply.github.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
