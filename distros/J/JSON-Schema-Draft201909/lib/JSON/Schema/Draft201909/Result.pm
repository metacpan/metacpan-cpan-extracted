use strict;
use warnings;
package JSON::Schema::Draft201909::Result;
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Contains the result of a JSON Schema evaluation

our $VERSION = '0.005';

no if "$]" >= 5.031009, feature => 'indirect';
use Moo;
use MooX::TypeTiny;
use Types::Standard qw(ArrayRef InstanceOf Enum);
use MooX::HandlesVia;
use JSON::Schema::Draft201909::Error;
use JSON::PP ();
use constant { true => JSON::PP::true, false => JSON::PP::false };
use namespace::clean;

use overload
  'bool'  => sub { $_[0]->result },
  '0+'    => sub { $_[0]->count },
  fallback => 1;

has result => (
  is => 'ro',
  isa => InstanceOf['JSON::PP::Boolean'],
  coerce => sub { $_[0] ? true : false },
);

has errors => (
  is => 'bare',
  isa => ArrayRef[InstanceOf['JSON::Schema::Draft201909::Error']],
  lazy => 1,
  default => sub { [] },
  handles_via => 'Array',
  handles => {
    errors => 'elements',
    error_count => 'count',
  },
);

has output_format => (
  is => 'ro',
  isa => Enum[qw(flag basic detailed verbose)],
  default => 'basic',
);

sub BUILD {
  my $self = shift;
  warn 'result is false but there are no errors' if not $self->result and not $self->error_count;
}

sub format {
  my ($self, $style) = @_;
  if ($style eq 'flag') {
    return +{ valid => $self->result };
  }
  if ($style eq 'basic') {
    return +{
      valid => $self->result,
      $self->result
        ? ()
        : ( errors => [ map $_->TO_JSON, $self->errors ] ),
    };
  }

  die 'unsupported output format';
}

sub count { $_[0]->result ? 0 : $_[0]->error_count }

sub TO_JSON {
  my $self = shift;
  $self->format($self->output_format);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::Draft201909::Result - Contains the result of a JSON Schema evaluation

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use JSON::Schema::Draft201909;
  my $js = JSON::Schema::Draft201909->new;
  my $result = $js->evaluate($data, $schema);
  my @errors = $result->errors;

  my $result_data_encoded = encode_json($result); # calls TO_JSON

  # use in numeric and boolean context
  say sprintf('got %d %ss', $result, ($result ? 'annotation' : 'error'));

  # use in string context
  say 'full results: ', $result;

=head1 DESCRIPTION

This object holds the complete results of evaluating a data payload against a JSON Schema using
L<JSON::Schema::Draft201909>.

=head1 OVERLOADS

The object contains a boolean overload, which evaluates to the value of L</result>, so you can
use the result of L<JSON::Schema::Draft201909/evaluate> in boolean context.

=head1 ATTRIBUTES

=head2 result

A boolean. Indicates whether validation was successful or failed.

=head2 errors

Returns an array of L<JSON::Schema::Draft201909::Error> objects.

=head2 output_format

One of: C<flag>, C<basic>, C<detailed>, C<verbose>. Defaults to C<basic>.

=head1 METHODS

=for Pod::Coverage BUILD

=head2 format

Returns a data structure suitable for serialization; requires one argument specifying the output
format to use, which corresponds to the formats documented in
L<https://json-schema.org/draft/2019-09/json-schema-core.html#rfc.section.10.4>. The only supported
formats at this time are C<flag> and C<basic>.

=head2 TO_JSON

Calls L</format> with the style configured in L</output_format>.

=head2 count

Returns the number of errors, when the result is false, or zero otherwise.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/karenetheridge/JSON-Schema-Draft201909/issues>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.freenode.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
