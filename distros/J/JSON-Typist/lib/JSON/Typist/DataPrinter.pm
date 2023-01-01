use strict;
use warnings;
package JSON::Typist::DataPrinter 0.008;

# ABSTRACT: a helper for Data::Printer-ing JSON::Typist data

use Data::Printer use_prototypes => 0;
use Term::ANSIColor qw(colored);

our $STRING_COLOR = 'ansi46';
our $NUMBER_COLOR = 'bright_magenta';
our $BOOL_COLOR   = 'ansi214';

use Sub::Exporter -setup => [ qw( jdump ) ];

#pod =head1 SYNOPSIS
#pod
#pod   use JSON::Typist::DataPrinter qw( jdump );
#pod
#pod   my $data = get_typed_data_from_your_code();
#pod
#pod   say "I got data and here it is!";
#pod
#pod   say jdump($data); # ...and you get beautifully printed data
#pod
#pod =head1 OVERVIEW
#pod
#pod This library exists for one reason: to provide C<jdump>.  It might change at
#pod any time, but one thing is for sure:  it takes an argument to dump and it
#pod returns a printable string describing it.
#pod
#pod =func jdump
#pod
#pod   my $string = jdump($struct);
#pod
#pod This uses Data::Printer to produce a pretty printing of the structure, color
#pod coding typed data and ensuring that it's presented clearly.  The format may
#pod change over time, so don't rely on it!  It's meant for humans, not computers,
#pod to read.
#pod
#pod =cut

sub jdump {
  my ($value) = @_;

  return p(
    $value,
    (
      return_value  => 'dump',
      colored       => 1,
      show_readonly => 0,
      filters       => [
        {
          'Test::Deep::JType::jstr' => sub { colored([$STRING_COLOR], qq{"$_[0]"}) },
          'Test::Deep::JType::jnum' => sub { colored([$NUMBER_COLOR], 0 + $_[0]) },
          'JSON::PP::Boolean'       => sub { colored([$BOOL_COLOR], $_[0] ? 'true' : 'false') },
        }
      ],
    )
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Typist::DataPrinter - a helper for Data::Printer-ing JSON::Typist data

=head1 VERSION

version 0.008

=head1 SYNOPSIS

  use JSON::Typist::DataPrinter qw( jdump );

  my $data = get_typed_data_from_your_code();

  say "I got data and here it is!";

  say jdump($data); # ...and you get beautifully printed data

=head1 OVERVIEW

This library exists for one reason: to provide C<jdump>.  It might change at
any time, but one thing is for sure:  it takes an argument to dump and it
returns a printable string describing it.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 FUNCTIONS

=head2 jdump

  my $string = jdump($struct);

This uses Data::Printer to produce a pretty printing of the structure, color
coding typed data and ensuring that it's presented clearly.  The format may
change over time, so don't rely on it!  It's meant for humans, not computers,
to read.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
