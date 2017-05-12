package List::Objects::WithUtils::Array::Junction;
$List::Objects::WithUtils::Array::Junction::VERSION = '2.028003';
## no critic

{ package 
    List::Objects::WithUtils::Array::Junction::Base;
  use strictures 2;
  use parent 'List::Objects::WithUtils::Array';
  use overload
    '=='   => 'num_eq',
    '!='   => 'num_ne',
    '>='   => 'num_ge',
    '>'    => 'num_gt',
    '<='   => 'num_le',
    '<'    => 'num_lt',
    'eq'   => 'str_eq',
    'ne'   => 'str_ne',
    'ge'   => 'str_ge',
    'gt'   => 'str_gt',
    'le'   => 'str_le',
    'lt'   => 'str_lt',
    'bool' => 'bool',
    '""'   => sub { shift },
  ;
}
{ package 
    List::Objects::WithUtils::Array::Junction::All;
  use strict; use warnings;
  our @ISA = 'List::Objects::WithUtils::Array::Junction::Base';

  sub num_eq {
    return regex_eq(@_) if ref $_[1] eq 'Regexp';
    for (@{ $_[0] })
      { return unless $_ == $_[1] }
    1
  }

  sub num_ne {
    return regex_ne(@_) if ref $_[1] eq 'Regexp';
    for (@{ $_[0] })
      { return unless $_ != $_[1] }
    1
  }

  sub num_ge {
    return num_le( @_[0, 1] ) if $_[2];
    for (@{ $_[0] })
      { return unless $_ >= $_[1] }
    1
  }

  sub num_gt {
    return num_lt( @_[0, 1] ) if $_[2];
    for (@{ $_[0] })
      { return unless $_ > $_[1] }
    1
  }

  sub num_le {
    return num_ge( @_[0, 1] ) if $_[2];
    for (@{ $_[0] })
      { return unless $_ <= $_[1] }
    1
  }

  sub num_lt {
    return num_gt( @_[0, 1] ) if $_[2];
    for (@{ $_[0] })
      { return unless $_ < $_[1] }
    1
  }

  sub str_eq {
    for (@{ $_[0] })
      { return unless $_ eq $_[1] }
    1
  }

  sub str_ne {
    for (@{ $_[0] })
      { return unless $_ ne $_[1] }
    1
  }

  sub str_ge {
    return str_le( @_[0, 1] ) if $_[2];
    for (@{ $_[0] })
      { return unless $_ ge $_[1] }
    1
  }

  sub str_gt {
    return str_lt( @_[0, 1] ) if $_[2];
    for (@{ $_[0] })
      { return unless $_ gt $_[1] }
    1
  }

  sub str_le {
    return str_ge( @_[0, 1] ) if $_[2];
    for (@{ $_[0] })
      { return unless $_ le $_[1] }
    1
  }

  sub str_lt {
    return str_gt( @_[0, 1] ) if $_[2];
    for (@{ $_[0] })
      { return unless $_ lt $_[1] }
    1
  }

  sub regex_eq {
    for (@{ $_[0] })
      { return unless $_ =~ $_[1] }
    1
  }

  sub regex_ne {
    for (@{ $_[0] })
      { return unless $_ !~ $_[1] }
    1
  }

  sub bool {
    for (@{ $_[0] })
      { return unless $_ }
    1
  }

}

{ package 
    List::Objects::WithUtils::Array::Junction::Any;
  use strict; use warnings;
  our @ISA = 'List::Objects::WithUtils::Array::Junction::Base';

  sub num_eq {
    return regex_eq(@_) if ref $_[1] eq 'Regexp';
    for (@{ $_[0] }) 
      { return 1 if $_ == $_[1] }
    ()
  }

  sub num_ne {
    return regex_eq(@_) if ref $_[1] eq 'Regexp';
    for (@{ $_[0] })
      { return 1 if $_ != $_[1] }
    ()
  }

  sub num_ge {
    return num_le( @_[0, 1] ) if $_[2];
    for (@{ $_[0] })
      { return 1 if $_ >= $_[1] }
    ()
  }

  sub num_gt {
    return num_lt( @_[0, 1] ) if $_[2];
    for (@{ $_[0] })
      { return 1 if $_ > $_[1] }
    ()
  }

  sub num_le {
    return num_ge( @_[0, 1] ) if $_[2];
    for (@{ $_[0] })
      { return 1 if $_ <= $_[1] }
    ()
  }

  sub num_lt {
    return num_gt( @_[0, 1] ) if $_[2];
    for (@{ $_[0] })
      { return 1 if $_ < $_[1] }
    ()
  }

  sub str_eq {
    for (@{ $_[0] })
      { return 1 if $_ eq $_[1] }
    ()
  }

  sub str_ne {
    for (@{ $_[0] })
      { return 1 if $_ ne $_[1] }
    ()
  }

  sub str_ge {
    return str_le( @_[0, 1] ) if $_[2];
    for (@{ $_[0] })
      { return 1 if $_ ge $_[1] }
    ()
  }

  sub str_gt {
    return str_lt( @_[0, 1] ) if $_[2];
    for (@{ $_[0] })
      { return 1 if $_ gt $_[1] }
    ()
  }

  sub str_le {
    return str_ge( @_[0, 1] ) if $_[2];
    for (@{ $_[0] })
      { return 1 if $_ le $_[1] }
    ()
  }

  sub str_lt {
    return str_gt( @_[0, 1] ) if $_[2];
    for (@{ $_[0] })
      { return 1 if $_ lt $_[1] }
    ()
  }

  sub regex_eq {
    for (@{ $_[0] })
      { return 1 if $_ =~ $_[1] }
    ()
  }

  sub regex_ne {
    for (@{ $_[0] })
      { return 1 if $_ !~ $_[1] }
    ()
  }

  sub bool {
    for (@{ $_[0] })
      { return 1 if $_ }
    ()
  }
}

1;

=pod

=for Pod::Coverage new

=head1 NAME

List::Objects::WithUtils::Array::Junction - Lightweight junction classes

=head1 SYNOPSIS

  # See List::Objects::WithUtils::Role::Array::WithJunctions

=head1 DESCRIPTION

These are light-weight junction objects covering most of the functionality
provided by L<Syntax::Keyword::Junction>. They provide the objects created by
the C<all_items> and C<any_items> methods defined by
L<List::Objects::WithUtils::Role::Array::WithJunctions>.

Only the junction types used by L<List::Objects::WithUtils> ('any' and 'all')
are implemented; nothing is exported. The C<~~> smart-match operator is not
supported. See L<Syntax::Keyword::Junction> if you were looking for a
stand-alone implementation with more features.

The junction objects produced are subclasses of
L<List::Objects::WithUtils::Array>.

See L<List::Objects::WithUtils::Role::Array::WithJunctions> for usage details.

=head2 Motivation

My original goal was to get L<Sub::Exporter> out of the
L<List::Objects::WithUtils> dependency tree; that one came along with
L<Syntax::Keyword::Junction>.

L<Perl6::Junction> would have done that for me. Unfortunately, that comes with
some unresolved RT bugs right now that are reasonably annoying (especially
warnings under perl-5.18.x).

=head1 AUTHOR

This code is originally derived from L<Perl6::Junction> by way of
L<Syntax::Keyword::Junction>; the original author is Carl Franks, based on the
Perl6 design documentation.

Adapted to L<List::Objects::WithUtils> by Jon Portnoy <avenj@cobaltirc.org>

=cut
