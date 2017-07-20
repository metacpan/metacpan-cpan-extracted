package Evo::Class::Syntax;
use Evo '-Export *; Carp croak; Scalar::Util reftype';

use constant SYNTAX_STATE => {};

export qw(SYNTAX_STATE);

my sub _check_settled($key) {
  croak qq#syntax error: "$key" already settled# if SYNTAX_STATE()->{$key};
}

sub inject($dep) : prototype($) : Export {
  _check_settled('inject');
  SYNTAX_STATE->{inject} = $dep;
  SYNTAX_STATE;
}

sub check($fn) : prototype($) : Export {
  _check_settled('check');
  SYNTAX_STATE->{check} = $fn;
  SYNTAX_STATE;
}

sub lazy : prototype() : Export {
  _check_settled('lazy');
  SYNTAX_STATE->{lazy}++;
  SYNTAX_STATE;
}

sub no_method() : prototype() : Export {
  _check_settled('no_method');
  SYNTAX_STATE()->{no_method}++;
  SYNTAX_STATE;
}

sub ro() : prototype() : Export {
  _check_settled('ro');
  SYNTAX_STATE()->{ro}++;
  SYNTAX_STATE;
}

sub rw() : prototype() : Export {
  Carp::carp "rw is deprecated, all attributes are rw by default";
  SYNTAX_STATE;
}

sub optional() : prototype() : Export {
  _check_settled('optional');
  SYNTAX_STATE->{optional}++;
  SYNTAX_STATE;
}

sub syntax_reset() : prototype() : Export {
  my %state = SYNTAX_STATE->%*;
  SYNTAX_STATE->%* = ();
  %state;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Class::Syntax

=head1 VERSION

version 0.0405

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
