package Data::Object::Replace;

use 5.014;

use strict;
use warnings;

use overload (
  '""'     => 'detract',
  '~~'     => 'detract',
  'bool'   => 'detract',
  'qr'     => 'regexp',
  '@{}'    => 'self',
  fallback => 1
);

use parent 'Data::Object::Array';

our $VERSION = '1.87'; # VERSION

# METHODS

sub captures {
  my ($self) = @_;

  my $string = $self->initial;

  my $last_match_start = $self->last_match_start;
  my $last_match_end   = $self->last_match_end;

  my @captures;

  for (my $i = 1; $i < @$last_match_end; $i++) {
    my $start = $last_match_start->[$i] || 0;
    my $end   = $last_match_end->[$i]   || 0;

    push @captures, substr "$string", $start, $end - $start;
  }

  return $self->deduce([@captures]);
}

sub count {
  my ($self) = @_;

  return $self->deduce($self->[2]);
}

sub initial {
  my ($self) = @_;

  return $self->deduce($self->[6]);
}

sub last_match_end {
  my ($self) = @_;

  return $self->deduce($self->[4]);
}

sub last_match_start {
  my ($self) = @_;

  return $self->deduce($self->[3]);
}

sub named_captures {
  my ($self) = @_;

  return $self->deduce($self->[5]);
}

sub matched {
  my ($self) = @_;

  my $string = $self->initial;

  my $last_match_start = $self->last_match_start;
  my $last_match_end   = $self->last_match_end;

  my $start = $last_match_start->[0] || 0;
  my $end   = $last_match_end->[0]   || 0;

  return $self->deduce(substr "$string", $start, $end - $start);
}

sub prematched {
  my ($self) = @_;

  my $string = $self->initial;

  my $last_match_start = $self->last_match_start;
  my $last_match_end   = $self->last_match_end;

  my $start = $last_match_start->[0] || 0;
  my $end   = $last_match_end->[0]   || 0;

  return $self->deduce(substr "$string", 0, $start);
}

sub postmatched {
  my ($self) = @_;

  my $string = $self->initial;

  my $last_match_start = $self->last_match_start;
  my $last_match_end   = $self->last_match_end;

  my $start = $last_match_start->[0] || 0;
  my $end   = $last_match_end->[0]   || 0;

  return $self->deduce(substr "$string", $end);
}

sub regexp {
  my ($self) = @_;

  return $self->deduce($self->[0]);
}

sub string {
  my ($self) = @_;

  return $self->deduce($self->[1]);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Replace

=cut

=head1 ABSTRACT

Data-Object Replace Class

=cut

=head1 SYNOPSIS

  use Data::Object::Replace;

  my $result = Data::Object::Replace->new([
    $regexp,
    $altered_string,
    $count,
    $last_match_end,
    $last_match_start,
    $named_captures,
    $initial_string
  ]);

=cut

=head1 DESCRIPTION

This package provides routines for introspecting the results of a regexp
replace operation.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<Data::Object::Array>

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 captures

  captures() : ArrayObject

The captures method returns the capture groups from the result object which
contains information about the results of the regular expression operation.

=over 4

=item captures example

  my $captures = $result->captures();

=back

=cut

=head2 count

  count() : NumObject

The count method returns the number of match occurrences from the result object
which contains information about the results of the regular expression
operation.

=over 4

=item count example

  my $count = $result->count();

=back

=cut

=head2 initial

  initial() : StrObject

The initial method returns the unaltered string from the result object which
contains information about the results of the regular expression operation.

=over 4

=item initial example

  my $initial = $result->initial();

=back

=cut

=head2 last_match_end

  last() : Any

The last_match_end method returns an array of offset positions into the string
where the capture(s) stopped matching from the result object which contains
information about the results of the regular expression operation.

=over 4

=item last_match_end example

  my $last_match_end = $result->last_match_end();

=back

=cut

=head2 last_match_start

  last() : Any

The last_match_start method returns an array of offset positions into the
string where the capture(s) matched from the result object which contains
information about the results of the regular expression operation.

=over 4

=item last_match_start example

  my $last_match_start = $result->last_match_start();

=back

=cut

=head2 matched

  matched() : StrObject | UndefObject

The matched method returns the portion of the string that matched from the
result object which contains information about the results of the regular
expression operation.

=over 4

=item matched example

  my $matched = $result->matched();

=back

=cut

=head2 named_captures

  name() : StrObject

The named_captures method returns a hash containing the requested named regular
expressions and captured string pairs from the result object which contains
information about the results of the regular expression operation.

=over 4

=item named_captures example

  my $named_captures = $result->named_captures();

=back

=cut

=head2 postmatched

  postmatched() : StrObject | UndefObject

The postmatched method returns the portion of the string after the regular
expression matched from the result object which contains information about the
results of the regular expression operation.

=over 4

=item postmatched example

  my $postmatched = $result->postmatched();

=back

=cut

=head2 prematched

  prematched() : StrObject | UndefObject

The prematched method returns the portion of the string before the regular
expression matched from the result object which contains information about the
results of the regular expression operation.

=over 4

=item prematched example

  my $prematched = $result->prematched();

=back

=cut

=head2 regexp

  regexp() : RegexpObject

The regexp method returns the regular expression used to perform the match from
the result object which contains information about the results of the regular
expression operation.

=over 4

=item regexp example

  my $regexp = $result->regexp();

=back

=cut

=head2 string

  string() : StrObject

The string method returns the string matched against the regular expression
from the result object which contains information about the results of the
regular expression operation.

=over 4

=item string example

  my $string = $result->string();

=back

=cut

=head1 CREDITS

Al Newkirk, C<+317>

Anthony Brummett, C<+10>

Adam Hopkins, C<+2>

José Joaquín Atria, C<+1>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated here,
https://github.com/iamalnewkirk/do/blob/master/LICENSE.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/do/wiki>

L<Project|https://github.com/iamalnewkirk/do>

L<Initiatives|https://github.com/iamalnewkirk/do/projects>

L<Milestones|https://github.com/iamalnewkirk/do/milestones>

L<Contributing|https://github.com/iamalnewkirk/do/blob/master/CONTRIBUTE.mkdn>

L<Issues|https://github.com/iamalnewkirk/do/issues>

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Do>

L<Data::Object>

L<Data::Object::Class>

L<Data::Object::ClassHas>

L<Data::Object::Role>

L<Data::Object::RoleHas>

L<Data::Object::Library>

=cut