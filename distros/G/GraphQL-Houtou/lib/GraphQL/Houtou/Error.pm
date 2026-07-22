package GraphQL::Houtou::Error;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.02';

use overload
  '""' => 'to_string',
  fallback => 1;

sub new {
  my ($class, %args) = @_;
  die "GraphQL::Houtou::Error requires a 'message'\n"
    if !defined $args{message};
  return bless { %args }, $class;
}

sub message        { return $_[0]->{message} }
sub locations      { return $_[0]->{locations} }
sub path           { return $_[0]->{path} }
sub nodes          { return $_[0]->{nodes} }
sub extensions     { return $_[0]->{extensions} }
sub original_error { return $_[0]->{original_error} }

sub to_string {
  my ($self) = @_;
  return $self->{message};
}

sub to_json {
  my ($self) = @_;
  my %json;
  for my $key (qw(message locations path extensions)) {
    $json{$key} = $self->{$key} if exists $self->{$key};
  }
  return \%json;
}

1;
__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou::Error - lightweight GraphQL error object

=head1 SYNOPSIS

  use GraphQL::Houtou::Error;
  die GraphQL::Houtou::Error->new(message => 'Something is not right...');

=head1 DESCRIPTION

Minimal error object used by GraphQL::Houtou for parse-time and
completion-time failures. Stringifies to its message so it can be matched
with plain regexes when caught as an exception.

=head1 ATTRIBUTES

C<message> (required), C<locations>, C<path>, C<nodes>, C<extensions>,
C<original_error>.

=head1 METHODS

=head2 to_string

Returns the message. Also used for C<""> overload.

=head2 to_json

Returns a hashref with the response-facing keys (C<message>, C<locations>,
C<path>, C<extensions>) that are present on the object.

=cut
