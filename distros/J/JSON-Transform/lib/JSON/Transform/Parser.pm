package JSON::Transform::Parser;

use strict;
use warnings;
use base qw(Pegex::Parser);
use Exporter 'import';
use JSON::Transform::Grammar;
use XML::Invisible::Receiver;

use constant DEBUG => $ENV{JSON_TRANSFORM_DEBUG};

our @EXPORT_OK = qw(
  parse
);

=head1 NAME

JSON::Transform::Parser - JSON::Transform Pegex parser

=head1 SYNOPSIS

  use JSON::Transform::Parser qw(parse);
  my $parsed = parse(
    $source
  );

=head1 DESCRIPTION

Provides both an outside-accessible point of entry into the JSON::Transform
parser (see above), and a subclass of L<Pegex::Parser> to parse a document
into an AST usable by JSON::Transform.

=head1 METHODS

=head2 parse

  parse($source);

B<NB> that unlike in C<Pegex::Parser> this is a function, not an instance
method. This achieves hiding of Pegex implementation details.

=cut

my $GRAMMAR = JSON::Transform::Grammar->new; # singleton
sub parse {
  my ($source) = @_;
  my $parser = __PACKAGE__->SUPER::new(
    grammar => $GRAMMAR,
    receiver => XML::Invisible::Receiver->new,
    debug => DEBUG,
  );
  my $input = Pegex::Input->new(string => $source);
  scalar $parser->SUPER::parse($input);
}

1;
