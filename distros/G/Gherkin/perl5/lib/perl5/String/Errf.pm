use strict;
use warnings;
package String::Errf; # I really wanted to call it String::Fister.
$String::Errf::VERSION = '0.008';
use String::Formatter 0.102081 ();
use parent 'String::Formatter';
# ABSTRACT: a simple sprintf-like dialect

use Scalar::Util ();

#pod =head1 SYNOPSIS
#pod
#pod   use String::Errf qw(errf);
#pod
#pod   print errf "This process was started at %{start}t with %{args;argument}n.\n",
#pod     { start => $^T, args => 0 + @ARGV };
#pod
#pod ...might print something like:
#pod
#pod   This process was started at 2010-10-17 14:05:29 with 0 arguments.
#pod
#pod =head1 DESCRIPTION
#pod
#pod String::Errf provides C<errf>, a simple string formatter that works something
#pod like C<L<sprintf|perlfunc/sprintf>>.  It is implemented using
#pod L<String::Formatter> and L<Sub::Exporter>.  Their documentation may be useful
#pod in understanding or extending String::Errf.  The C<errf> subroutine is only
#pod available when imported.  Calling L<String::Errf::errf> will not do what you
#pod want.
#pod
#pod =head1 DIFFERENCES FROM SPRINTF
#pod
#pod The data passed to C<errf> should be organized in a single hashref, not a list.
#pod
#pod Formatting codes require named parameters, and the available codes are
#pod different.  See L</FORMATTING CODES> below.
#pod
#pod As with most String::Formatter formatters, C<%> is not a format code.  If you
#pod want a literal C<%>, do not put anything between the two percent signs, just
#pod write C<%%>.
#pod
#pod =head2 UNDEF HANDLING
#pod
#pod By default, formatting codes tend to treat C<undef> like Perl does: coercing it
#pod to an empty string or zero.  This was a bad initial decision and will probably
#pod change.  A C<on_undef> handler can be provided when importing C<errf> to setup
#pod a callback for how undefs should be handled.  These two possibilities seem
#pod useful:
#pod
#pod   # Very lax; undefs always turn into the same string:
#pod   use String::Errf errf => { on_undef => sub { '(undef)' } };
#pod
#pod   # Strict; undefs are never valid:
#pod   use String::Errf errf => { on_undef => sub {
#pod     Carp::croak("undef passed to $_[1]{literal}") } };
#pod   } };
#pod
#pod =head2 FORMATTING CODES
#pod
#pod C<errf> formatting codes I<require> a set of arguments between the C<%> and the
#pod formatting code letter.  These arguments are placed in curly braces and
#pod separated by semicolons.  The first argument is the name of the data to look
#pod for in the format data.  For example, this is a valid use of C<errf>:
#pod
#pod   errf "The current time in %{tz}s is %{now;local}t.", {
#pod     tz  => $ENV{TZ},
#pod     now => time,
#pod   };
#pod
#pod The second argument, if present, may be a compact form for multiple named
#pod arguments.  The rest of the arguments will be named values in the form
#pod C<name=value>.  The examples below should help clarify how arguments are
#pod passed.  When an argument appears in both a compact and named form, the named
#pod form trumps the compact form.
#pod
#pod The specific codes and their arguments are:
#pod
#pod =head3 s for string
#pod
#pod The C<s> format code is for any string, and takes no arguments.  It just
#pod includes the named item from the input data.
#pod
#pod   errf "%{name}s", { name => 'John Smith' }; # returns "John Smith"
#pod
#pod Remember, C<errf> does I<not> have any of the left- or right-padding formatting
#pod that C<sprintf> provides.  It is not meant for building tables, only strings.
#pod
#pod =head3 i for integer
#pod
#pod The C<i> format code is used for integers.  It takes one optional argument,
#pod C<prefix>, which defaults to the empty string.  C<prefix> may be given as the
#pod compact argument, standing alone.  C<prefix> is used to prefix non-negative
#pod integers.  It may only be a plus sign.
#pod
#pod   errf "%{x}i",    { x => 10 }; # returns "10"
#pod   errf "%{x;+}i",  { x => 10 }; # returns "+10"
#pod
#pod   errf "%{x;prefix=+}i",  { x => 10 }; # returns "+10"
#pod
#pod The rounding behavior for non-integer values I<is not currently specified>.
#pod
#pod =head3 f for float (or fractional)
#pod
#pod The C<f> format code is for numbers with sub-integer precision.  It works just
#pod like C<i>, but adds a C<precision> argument which specifies how many decimal
#pod places of precision to display.  The compact argument may be just the prefix or
#pod the prefix followed by a period followed by the precision.
#pod
#pod   errf "%{x}f",     { x => 10.1234 }; # returns "10";
#pod   errf "%{x;+}f",   { x => 10.1234 }; # returns "+10";
#pod
#pod   errf "%{x;.2}f",  { x => 10.1234 }; # returns  "10.12";
#pod   errf "%{x;+.2}f", { x => 10.1234 }; # returns "+10.12";
#pod
#pod   errf "%{x;precision=.2}f",          { x => 10.1234 }; # returns  "10.12";
#pod   errf "%{x;prefix=+;precision=.2}f", { x => 10.1234 }; # returns "+10.12";
#pod
#pod =head3 t for time
#pod
#pod The C<t> format code is used to format timestamps provided in epoch seconds.
#pod It can be given two arguments: C<type> and C<tz>.
#pod
#pod C<type> can be either date, time, or datetime, and indicates what part of the
#pod timestamp should be displayed.  The default is datetime.  C<tz> requests that
#pod the timestamp be displayed in either UTC or the local time zone.  The default
#pod is local.
#pod
#pod The compact form is just C<type> alone.
#pod
#pod   # Assuming our local time zone is America/New_York...
#pod
#pod   errf "%{x}t",               { x => 1280530906 }; # "2010-07-30 19:01:46"
#pod   errf "%{x;type=date}t",     { x => 1280530906 }; # "2010-07-30"
#pod   errf "%{x;type=time}t",     { x => 1280530906 }; # "19:01:46"
#pod   errf "%{x;type=datetime}t", { x => 1280530906 }; # "2010-07-30 19:01:46"
#pod
#pod   errf "%{x;tz=UTC}t",               { x => 1280530906 }; # "2010-07-30 23:01:46 UTC"
#pod   errf "%{x;tz=UTC;type=date}t",     { x => 1280530906 }; # "2010-07-30 UTC"
#pod   errf "%{x;tz=UTC;type=time}t",     { x => 1280530906 }; # "23:01:46 UTC"
#pod   errf "%{x;tz=UTC;type=datetime}t", { x => 1280530906 }; # "2010-07-30 23:01:46 UTC"
#pod
#pod =head3 n and N for numbered
#pod
#pod The C<n> and C<N> format codes are for picking words based on number.  It takes
#pod two of its own arguments, C<singular> and C<plural>, as well as C<prefix> and
#pod C<precision> which may be used for formatting the number itself.
#pod
#pod If the value being formatted is 1, the singular word is used.  Otherwise, the
#pod plural form is used.
#pod
#pod   errf "%{x;singular=dog;plural=dogs}n", { x => 0 }; # 0 dogs
#pod   errf "%{x;singular=dog;plural=dogs}n", { x => 1 }; # 1 dog
#pod   errf "%{x;singular=dog;plural=dogs}n", { x => 2 }; # 2 dogs
#pod
#pod   errf "%{x;singular=dog;plural=dogs}n", { x => 1.4 }; # 1.4 dogs
#pod   errf "%{x;singular=dog;plural=dogs;precision=1}n", { x => 1.4 }; # 1.4 dogs
#pod   errf "%{x;singular=dog;plural=dogs;precision=0}n", { x => 1.4 }; # 1 dog
#pod
#pod If C<N> is used instead of C<n>, the number will not be included, only the
#pod chosen word.
#pod
#pod   errf "%{x;singular=is;plural=are}N", { x => 0 }; # are
#pod   errf "%{x;singular=is;plural=are}N", { x => 1 }; # is
#pod   errf "%{x;singular=is;plural=are}N", { x => 2 }; # are
#pod
#pod   errf "%{x;singular=is;plural=are}N", { x => 1.4 }; # 1.4 are
#pod   errf "%{x;singular=is;plural=are;precision=1}N", { x => 1.4 }; # 1.4 are
#pod   errf "%{x;singular=is;plural=are;precision=0}N", { x => 1.4 }; # 1 is
#pod
#pod The compact form may take any of the following forms:
#pod
#pod   word          - equivalent to singular=word
#pod
#pod   word+suffix   - equivalent to singular=word;plural=wordsuffix
#pod
#pod   word1/word2   - equivalent to singular=word;plural=word2
#pod
#pod If no singular form is given, an exception is thrown.  If no plural form is
#pod given, one will be generated according to some basic rules of English
#pod noun orthography.
#pod
#pod =head3
#pod
#pod =cut

use Carp ();
use Time::Piece ();
use Params::Util ();

use Sub::Exporter -setup => {
  exports => {
    errf => sub {
      my ($class, $name, $arg) = @_;
      my $fmt = $class->new($arg);
      return sub { $fmt->format(@_) };
    },
  }
};

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);
  my $arg   = shift;
  $self->{'String::Errf'} = {};
  if ($arg && $arg->{on_undef}) {
    $self->{'String::Errf'}{on_undef} = $arg->{on_undef};
  }

  return $self;
}

sub default_codes {
  return {
    i => '_format_int',
    f => '_format_float',
    t => '_format_timestamp',
    s => '_format_string',
    n => '_format_numbered',
    N => '_format_numbered',
  };
}

sub default_input_processor { 'require_named_input' }
sub default_format_hunker   { '__hunk_errf' }
sub default_string_replacer { '__replace_errf' }
sub default_hunk_formatter  { '__format_errf' }

my $regex = qr/
 (%                      # leading '%'
  (?:{                   # {
    ([^;]*?)             #   mandatory argument name
    (?: ; ([^\}]*?) )?   #   optional extras after semicolon
  })                     # }
  ($|.)                  # potential conversion character
 )
/xi;

sub __hunk_errf {
  my ($self, $string) = @_;

  my @to_fmt;
  my $pos = 0;

  while ($string =~ m{\G(.*?)$regex}gs) {
    push @to_fmt, $1, {
      literal     => $2,
      argument    => $3,
      extra       => $4,
      conversion  => $5,
    };

    $pos = pos $string;
  }

  push @to_fmt, substr $string, $pos if $pos < length $string;

  return \@to_fmt;
}

sub __replace_errf {
  my ($self, $hunks, $input) = @_;

  my $heap = {};
  my $code = $self->codes;

  for my $i (grep { ref $hunks->[$_] } 0 .. $#$hunks) {
    my $hunk = $hunks->[ $i ];
    my $conv = $code->{ $hunk->{conversion} };

    Carp::croak("Unknown conversion in stringf: $hunk->{conversion}")
      unless defined $conv;

    $hunk->{replacement} = $input->{ $hunk->{argument} };
    $hunk->{args}        = [ $hunk->{extra} ? split /;/, $hunk->{extra} : () ];
  }
}

sub __format_errf {
  my ($self, $hunk) = @_;

  my $conv = $self->codes->{ $hunk->{conversion} };

  Carp::croak("Unknown conversion in stringf: $hunk->{conversion}")
    unless defined $conv;

  if (
    ! defined $hunk->{replacement}
    && (my $on_undef = $self->{'String::Errf'}{on_undef})
  ) {
    return $self->$on_undef($hunk);
  }

  return $self->$conv($hunk->{replacement}, $hunk->{args}, $hunk);
}

sub _proc_args {
  my ($self, $input, $parse_compact) = @_;

  return $input if ref $input eq 'HASH';

  $parse_compact ||= sub {
    Carp::croak("no compact format allowed, but compact format found");
  };

  my @args = @$input;

  my $first = (defined $args[0] and length $args[0] and $args[0] !~ /=/)
            ? shift @args
            : undef;

  my %param = (
    ($first ? %{ $parse_compact->($first) } : ()),
    (map {; split /=/, $_, 2 } @args),
  );

  return \%param;
}

# Likely integer formatting options are:
#   prefix (+ for positive numbers)
#
# Other options like (minwidth, precision, fillchar) are not out of the
# question, but if this system is to be used for formatting simple
# user-oriented error messages, they seem really unlikely to be used.  Put off
# supplying them! -- rjbs, 2010-07-30
sub _format_int {
  my ($self, $value, $rest) = @_;

  my $arg = $self->_proc_args($rest, sub {
    return { prefix => $_[0] eq '+' ? '+' : '', }
  });

  my $int_value = int $value;
  $value = sprintf '%.0f', $value unless $int_value == $value;

  return $value if $value < 0;

  $arg->{prefix} = '' unless defined $arg->{prefix};

  return "$arg->{prefix}$value";
}


# Likely float formatting options are:
#   prefix (+ for positive numbers)
#   precision
#
# My remarks above for "int" go for floats, too. -- rjbs, 2010-07-30
sub _format_float {
  my ($self, $value, $rest) = @_;

  my $arg = $self->_proc_args($rest, sub {
    my ($prefix_str, $prec) = $_[0] =~ /\A(\+?)(?:\.(\d+))?\z/;
    return { prefix => $prefix_str, precision => $prec };
  });

  undef $arg->{precision}
    unless defined $arg->{precision} and length $arg->{precision};

  $arg->{prefix} = '' unless defined $arg->{prefix};

  $value = defined $arg->{precision}
         ? sprintf("%0.$arg->{precision}f", $value)
         : $value;

  return $value < 0 ? $value : "$arg->{prefix}$value";
}

sub _format_timestamp {
  my ($self, $value, $rest) = @_;

  my $arg = $self->_proc_args($rest, sub {
    return { type => $_[0] };
  });

  my $type = $arg->{type} || 'datetime';
  my $zone = $arg->{tz}   || 'local';

  my $format = $type eq 'datetime' ? '%Y-%m-%d %H:%M:%S'
             : $type eq 'date'     ? '%Y-%m-%d'
             : $type eq 'time'     ? '%H:%M:%S'
             : Carp::croak("unknown format type for %t: $type");

  # Supplying a time zone is *strictly informational*. -- rjbs, 2010-10-15
  Carp::croak("illegal time zone for %t: $zone")
    unless $zone eq 'local' or $zone eq 'UTC';

  my $method = $zone eq 'UTC' ? 'gmtime' : 'localtime';
  my $piece  = Time::Piece->$method($value);

  my $str = $piece->strftime($format);

  return $zone eq 'UTC' ? "$str UTC" : $str;
}

sub _format_string {
  my ($self, $value, $rest) = @_;
  return $value;
}

sub _pluralize {
  my ($singular) = @_;

  return $singular  =~ /(?:[xzs]|sh|ch)\z/ ? "${singular}es"
       : $singular  =~ s/y\z/ies/          ? $singular
       :                                     "${singular}s";
}

sub _format_numbered {
  my ($self, $value, $rest, $hunk) = @_;

  my $arg = $self->_proc_args($rest, sub {
    my ($word) = @_;

    my ($singular, $divider, $extra) = $word =~ m{\A(.+?)(?: ([/+]) (.+) )?\z}x;

    $divider = '' unless defined $divider; # just to avoid warnings

    my $plural = $divider   eq '/'                 ? $extra
               : $divider   eq '+'                 ? "$singular$extra"
               :                                     _pluralize($singular);

    return { singular => $singular, plural => $plural };
  });

  $value = $self->_format_float($value, {
    prefix    => $arg->{prefix},
    precision => $arg->{precision},
  });

  Carp::croak("no word given to number-based formatter")
    unless defined $arg->{singular};

  $arg->{plural} = _pluralize($arg->{singular}) unless defined $arg->{plural};

  my $formed = abs($value) == 1 ? $arg->{singular} : $arg->{plural};

  return $formed if $hunk->{conversion} eq 'N';
  return "$value $formed";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Errf - a simple sprintf-like dialect

=head1 VERSION

version 0.008

=head1 SYNOPSIS

  use String::Errf qw(errf);

  print errf "This process was started at %{start}t with %{args;argument}n.\n",
    { start => $^T, args => 0 + @ARGV };

...might print something like:

  This process was started at 2010-10-17 14:05:29 with 0 arguments.

=head1 DESCRIPTION

String::Errf provides C<errf>, a simple string formatter that works something
like C<L<sprintf|perlfunc/sprintf>>.  It is implemented using
L<String::Formatter> and L<Sub::Exporter>.  Their documentation may be useful
in understanding or extending String::Errf.  The C<errf> subroutine is only
available when imported.  Calling L<String::Errf::errf> will not do what you
want.

=head1 DIFFERENCES FROM SPRINTF

The data passed to C<errf> should be organized in a single hashref, not a list.

Formatting codes require named parameters, and the available codes are
different.  See L</FORMATTING CODES> below.

As with most String::Formatter formatters, C<%> is not a format code.  If you
want a literal C<%>, do not put anything between the two percent signs, just
write C<%%>.

=head2 UNDEF HANDLING

By default, formatting codes tend to treat C<undef> like Perl does: coercing it
to an empty string or zero.  This was a bad initial decision and will probably
change.  A C<on_undef> handler can be provided when importing C<errf> to setup
a callback for how undefs should be handled.  These two possibilities seem
useful:

  # Very lax; undefs always turn into the same string:
  use String::Errf errf => { on_undef => sub { '(undef)' } };

  # Strict; undefs are never valid:
  use String::Errf errf => { on_undef => sub {
    Carp::croak("undef passed to $_[1]{literal}") } };
  } };

=head2 FORMATTING CODES

C<errf> formatting codes I<require> a set of arguments between the C<%> and the
formatting code letter.  These arguments are placed in curly braces and
separated by semicolons.  The first argument is the name of the data to look
for in the format data.  For example, this is a valid use of C<errf>:

  errf "The current time in %{tz}s is %{now;local}t.", {
    tz  => $ENV{TZ},
    now => time,
  };

The second argument, if present, may be a compact form for multiple named
arguments.  The rest of the arguments will be named values in the form
C<name=value>.  The examples below should help clarify how arguments are
passed.  When an argument appears in both a compact and named form, the named
form trumps the compact form.

The specific codes and their arguments are:

=head3 s for string

The C<s> format code is for any string, and takes no arguments.  It just
includes the named item from the input data.

  errf "%{name}s", { name => 'John Smith' }; # returns "John Smith"

Remember, C<errf> does I<not> have any of the left- or right-padding formatting
that C<sprintf> provides.  It is not meant for building tables, only strings.

=head3 i for integer

The C<i> format code is used for integers.  It takes one optional argument,
C<prefix>, which defaults to the empty string.  C<prefix> may be given as the
compact argument, standing alone.  C<prefix> is used to prefix non-negative
integers.  It may only be a plus sign.

  errf "%{x}i",    { x => 10 }; # returns "10"
  errf "%{x;+}i",  { x => 10 }; # returns "+10"

  errf "%{x;prefix=+}i",  { x => 10 }; # returns "+10"

The rounding behavior for non-integer values I<is not currently specified>.

=head3 f for float (or fractional)

The C<f> format code is for numbers with sub-integer precision.  It works just
like C<i>, but adds a C<precision> argument which specifies how many decimal
places of precision to display.  The compact argument may be just the prefix or
the prefix followed by a period followed by the precision.

  errf "%{x}f",     { x => 10.1234 }; # returns "10";
  errf "%{x;+}f",   { x => 10.1234 }; # returns "+10";

  errf "%{x;.2}f",  { x => 10.1234 }; # returns  "10.12";
  errf "%{x;+.2}f", { x => 10.1234 }; # returns "+10.12";

  errf "%{x;precision=.2}f",          { x => 10.1234 }; # returns  "10.12";
  errf "%{x;prefix=+;precision=.2}f", { x => 10.1234 }; # returns "+10.12";

=head3 t for time

The C<t> format code is used to format timestamps provided in epoch seconds.
It can be given two arguments: C<type> and C<tz>.

C<type> can be either date, time, or datetime, and indicates what part of the
timestamp should be displayed.  The default is datetime.  C<tz> requests that
the timestamp be displayed in either UTC or the local time zone.  The default
is local.

The compact form is just C<type> alone.

  # Assuming our local time zone is America/New_York...

  errf "%{x}t",               { x => 1280530906 }; # "2010-07-30 19:01:46"
  errf "%{x;type=date}t",     { x => 1280530906 }; # "2010-07-30"
  errf "%{x;type=time}t",     { x => 1280530906 }; # "19:01:46"
  errf "%{x;type=datetime}t", { x => 1280530906 }; # "2010-07-30 19:01:46"

  errf "%{x;tz=UTC}t",               { x => 1280530906 }; # "2010-07-30 23:01:46 UTC"
  errf "%{x;tz=UTC;type=date}t",     { x => 1280530906 }; # "2010-07-30 UTC"
  errf "%{x;tz=UTC;type=time}t",     { x => 1280530906 }; # "23:01:46 UTC"
  errf "%{x;tz=UTC;type=datetime}t", { x => 1280530906 }; # "2010-07-30 23:01:46 UTC"

=head3 n and N for numbered

The C<n> and C<N> format codes are for picking words based on number.  It takes
two of its own arguments, C<singular> and C<plural>, as well as C<prefix> and
C<precision> which may be used for formatting the number itself.

If the value being formatted is 1, the singular word is used.  Otherwise, the
plural form is used.

  errf "%{x;singular=dog;plural=dogs}n", { x => 0 }; # 0 dogs
  errf "%{x;singular=dog;plural=dogs}n", { x => 1 }; # 1 dog
  errf "%{x;singular=dog;plural=dogs}n", { x => 2 }; # 2 dogs

  errf "%{x;singular=dog;plural=dogs}n", { x => 1.4 }; # 1.4 dogs
  errf "%{x;singular=dog;plural=dogs;precision=1}n", { x => 1.4 }; # 1.4 dogs
  errf "%{x;singular=dog;plural=dogs;precision=0}n", { x => 1.4 }; # 1 dog

If C<N> is used instead of C<n>, the number will not be included, only the
chosen word.

  errf "%{x;singular=is;plural=are}N", { x => 0 }; # are
  errf "%{x;singular=is;plural=are}N", { x => 1 }; # is
  errf "%{x;singular=is;plural=are}N", { x => 2 }; # are

  errf "%{x;singular=is;plural=are}N", { x => 1.4 }; # 1.4 are
  errf "%{x;singular=is;plural=are;precision=1}N", { x => 1.4 }; # 1.4 are
  errf "%{x;singular=is;plural=are;precision=0}N", { x => 1.4 }; # 1 is

The compact form may take any of the following forms:

  word          - equivalent to singular=word

  word+suffix   - equivalent to singular=word;plural=wordsuffix

  word1/word2   - equivalent to singular=word;plural=word2

If no singular form is given, an exception is thrown.  If no plural form is
given, one will be generated according to some basic rules of English
noun orthography.

=head3

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Pedro Melo

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Pedro Melo <melo@simplicidade.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
