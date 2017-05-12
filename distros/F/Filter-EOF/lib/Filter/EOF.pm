package Filter::EOF;

=head1 NAME

Filter::EOF - Run a callback after a file has been compiled

=cut

use warnings;
use strict;

=head1 VERSION

0.04

=cut

our $VERSION = 0.04;

=head1 SYNOPSIS

  package MyPackage;
  use warnings;
  use strict;

  use Filter::EOF;

  sub import {
      my ($class, @args) = @_;
      my $caller = scalar caller;

      # set the COMPILE_TIME package var to a false value
      # when the file was compiled
      Filter::EOF->on_eof_call(sub {
          no strict 'refs';
          ${ $caller . '::COMPILE_TIME' } = 0;
      });

      # set the COMPILE_TIME package var to a true value when
      # we start compiling it.
      {   no strict 'refs';
          ${ $caller . '::COMPILE_TIME' } = 1;
      }
  }

  1;
  ...

  package MyUsingPackage;
  use warnings;
  use strict;

  our $COMPILE_TIME;
  use MyPackage;

  # prints 'yes'
  BEGIN { print +( $COMPILE_TIME ? 'yes' : 'no' ), "\n" }

  # prints 'no'
  print +( $COMPILE_TIME ? 'yes' : 'no' ), "\n";

  1;

=head1 DESCRIPTION

This module utilises Perl's source filters to provide you with a
mechanism to run some code after a file using your module has been
processed.

=cut

use Carp;
use Filter::Util::Call;

=head1 METHODS

=head2 C<import( @functions )>

Currently, only a function equivalent of the C<on_eof_call> method
is provided for export.

  use Filter::EOF qw( on_eof_call );

  sub import {
      my ($class) = @_;
      ...
      on_eof_call { ... };
  }
  ...

=cut

my %Export = (
    on_eof_call => sub { my $class = shift; sub (&) { $class->on_eof_call(@_) } },
);

sub import {
    my ($class, @names) = @_;
    for my $name (@names) {
        Carp::croak "Unknown function '$name'" unless exists $Export{ $name };
        no strict 'refs';
        *{ scalar(caller) . '::' . $name } = $Export{ $name }->($class);
    }
    return 1;
}

=head2 C<on_eof_call( $code_ref )>

Call this method in your own C<import> method to register a code 
reference that should be called when the file C<use>ing yours was
compiled.

The code reference will get a scalar reference as first argument
to an empty string. if you change this string to something else,
it will be appended at the end of the source.

  # call C<some_function()> after runtime.
  Filter->on_eof_call(sub { 
      my $append = shift;
      $$append .= '; some_function(); 1;';
  });

=cut

sub on_eof_call {
    my ($class, $code) = @_;

    my $past_eof;
    filter_add( sub {
        my $status = filter_read;
        return $status if $past_eof;
        if ($status == 0) {
            $code->(\$_);
            $status   = 1;
            $past_eof = 1;
        }
        return $status;
    });
}

=head1 EXPORTS

=head2 on_eof_call

You can optionally import the C<on_eof_call> function into your namespace.

=head1 EXAMPLES

You can find the example mentioned in L</SYNOPSIS> in the distribution
directory C<examples/synopsis/>.

=head1 SEE ALSO

L<Filter::Call::Util>,
L<Exporter/Exporting without using Exporter's import method>

=head1 AUTHOR AND COPYRIGHT

Robert 'phaylon' Sedlacek - C<E<lt>rs@474.atE<gt>>. Many thanks to
Matt S Trout for the idea and inspirations on this module.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
