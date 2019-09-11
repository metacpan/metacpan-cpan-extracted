package MOP4Import::Pairs;
use 5.010;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use MOP4Import::Declare -as_base, qw/Opts m4i_opts m4i_args/;
use MOP4Import::Util qw/terse_dump/;

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};

sub dispatch_pairs_as_declare {
  (my $myPack, my $pragma, my Opts $opts, my (@pairs)) = @_;

  #
  # Process leading non-pair pragmas. (ARRAY and -pragma)
  #
  while (@pairs) {
    if (ref $pairs[0] eq 'CODE') {
      (shift @pairs)->($myPack, $opts);
    } elsif ($pairs[0] =~ /^-([A-Za-z]\w*)$/) {
      shift @pairs;
      $myPack->dispatch_declare_pragma($opts, $1);
    } else {
      last;
    }
  }

  unless (@pairs % 2 == 0) {
    croak "Odd number of arguments!: ".terse_dump(\@pairs);
  }

  my $sub = $myPack->can("declare_$pragma")
    or croak "Unknown declare pragma: $pragma";

  while (my ($name, $speclist) = splice @pairs, 0, 2) {

    if (defined $name) {
      print STDERR " dispatching 'declare_$pragma' for pair("
        , terse_dump($name, $speclist)
        , $myPack->file_line_of($opts), "\n" if DEBUG;

      $sub->($myPack, $opts, $name, @$speclist);
    } else {
      print STDERR " fallback to dispatch_declare for pair of undef => "
        , terse_dump($speclist)
        , $myPack->file_line_of($opts), "\n" if DEBUG;

      $myPack->dispatch_declare($opts, @$speclist);
    }
  }
}

1;

=head1 NAME

MOP4Import::Pairs - pragma dispatcher for name => [@pragma]... style protocol

=head1 SYNOPSIS

  package YourExporter;
  use MOP4Import::Pairs -as_base, qw/Opts m4i_opts/;

  sub import {
    my $myPack = shift;

    my Opts $opts = m4i_opts([caller]);

    # Invoke declare_foobar for each $name => $pragmas pairs.
    $myPack->dispatch_pairs_as_declare(foobar => $opts, @_);
  }

  sub declare_foobar {
    (my $myPack, my Opts $opts, my ($name, @pragmas)) = m4i_args(@_);
    ...
  }

  #-----------------------------------
  # Then you can use above module in other script like following
  #-----------------------------------

  use YourExporter (
    xxx => [1..3],
    yyy => [4..6]
  );

  # Above is equivalent of following:

  BEGIN {
    YourExporter->declare_foobar(__PACKAGE__, xxx, 1..3);
    YourExporter->declare_foobar(__PACKAGE__, yyy, 4..6);
  }

=head1 DESCRIPTION

This module provides C<< name => [@pragma_list] >> style dispatcher of
L<MOP4Import::Declare> pragmas. Mainly used from L<MOP4Import::Types>.

=head2 "MetaObject Protocol for Import" in this module

This module does not provide "import" itself.
Instead, this provides a helper method C<dispatch_pairs_as_declare>
to implement "import".

=head1 METHODS

=head2 dispatch_pairs_as_declare($pragma, $opts, @name_pragmalist_pairs)
X<dispatch_pairs_as_declare>

This basically does following:

  sub dispatch_pairs_as_declare {
    (my $myPack, my $pragma, my Opts $opts, my (@pairs)) = @_;

    my $method = "declare_$pragma";

    while (my ($typename, $pragma_list) = splice @pairs, 0, 2) {
  
      $myPack->$method($opts, $typename, @$pragma_list);
  
    }
  }

=head1 AUTHOR

Kobayashi, Hiroaki E<lt>hkoba@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
