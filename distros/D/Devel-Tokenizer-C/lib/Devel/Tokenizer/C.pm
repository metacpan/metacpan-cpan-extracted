################################################################################
#
# MODULE: Devel::Tokenizer::C
#
################################################################################
#
# DESCRIPTION: Generate C source for fast keyword tokenizer
#
################################################################################
#
# $Project: /Devel-Tokenizer-C $
# $Author: mhx $
# $Date: 2008/12/13 16:03:38 +0100 $
# $Revision: 16 $
# $Source: /lib/Devel/Tokenizer/C.pm $
#
################################################################################
# 
# Copyright (c) 2002-2008 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
# 
################################################################################

package Devel::Tokenizer::C;

use 5.005_03;
use strict;
use Carp;
use vars '$VERSION';

$VERSION = do { my @r = '$Snapshot: /Devel-Tokenizer-C/0.08 $' =~ /(\d+\.\d+(?:_\d+)?)/; @r ? $r[0] : '9.99' };

my %DEF = (
  CaseSensitive => 1,
  Comments      => 1,
  Indent        => '  ',
  MergeSwitches => 0,
  Strategy      => 'ordered',   #  wide, narrow, ordered
  StringLength  => '',
  TokenEnd      => "'\\0'",
  TokenFunc     => sub { "return $_[0];\n" },
  # TokenSort     => sub { $_[0] cmp $_[1] },             # TODO?
  TokenString   => 'tokstr',
  UnknownLabel  => 'unknown',
  UnknownCode   => undef,
);

sub new
{
  my $class = shift;
  my %opt = @_;
  for (keys %opt) { exists $DEF{$_} or croak "Invalid option '$_'" }
  if (exists $opt{TokenFunc}) {
    ref $opt{TokenFunc} eq 'CODE'
        or croak "Option TokenFunc needs a code reference";
  }
  my %self = (
    %DEF, @_,
    __tcheck__ => {},
    __tokens__ => {},
    __backup__ => [],
    __maxlen__ => 0,
  );
  if ($self{StringLength} eq '' and $self{Strategy} ne 'ordered') {
    croak "Cannot use Strategy '$self{Strategy}' without StringLength";
  }
  bless \%self, $class;
}

sub add_tokens
{
  my $self = shift;
  my($tokens, $pre) = ref $_[0] eq 'ARRAY' ? @_ : \@_;
  for (@$tokens) {
    my $tok = $self->{CaseSensitive} ? $_ : lc;
    exists $self->{__tcheck__}{$tok}
        and carp $self->{__tcheck__}{$tok} eq ($pre || '')
                 ? "Multiple definition of token '$_'"
                 : "Redefinition of token '$_'";
    $self->{__tcheck__}{$tok} = $self->{__tokens__}{$_} = $pre || '';
    my $len = length __quotecomment__($_);
    $self->{__maxlen__} = $len if $len > $self->{__maxlen__};
  }
  $self;
}

sub generate
{
  my $self = shift;
  my %options = (Indent => '', @_);
  my $IND = $options{Indent};
  my $I = $self->{Indent};

  if ($self->{StringLength}) {
    my @tokens;
    for my $t (keys %{$self->{__tokens__}}) {
      $tokens[length $t]{$t} = $self->{__tokens__}{$t};
    }

    my $rv = <<EOS;
${IND}switch ($self->{StringLength})
$IND\{
EOS

    for my $len (1 .. $#tokens) {
      $tokens[$len] or next;
      my $count = keys %{$tokens[$len]};
      my $switch = $self->__makeit__($IND.$I.$I, $self->__order__($tokens[$len]), 0, 0, $tokens[$len]);
      $rv .= <<EOS;
$IND${I}case $len: /* $count tokens of length $len */
$switch
EOS
    }

    my $unk = $self->__unknown__("$IND$I$I");

    $rv .= <<EOS if $unk;
$IND${I}default:
$unk
EOS

    $rv .= "$IND}\n"
  }
  else {
    return $self->__makeit__($IND, undef, 0, 0, $self->{__tokens__});
  }
}

sub __order__
{
  my($self, $tok) = @_;
  my @hist;

  return undef if $self->{Strategy} eq 'ordered';

  for my $k (keys %$tok) {
    my @key = ($self->{CaseSensitive} ? $k : uc $k) =~ /(.)/g;
    for my $i (0 .. $#key) {
      $hist[$i]{$key[$i]}++;
    }
  }
  for my $i (0 .. $#hist) {
    $hist[$i]{ix} = $i;
  }

  if ($self->{Strategy} eq 'wide') {
    @hist = sort { keys %$b <=> keys %$a } @hist;
  }
  elsif ($self->{Strategy} eq 'narrow') {
    @hist = sort { keys %$a <=> keys %$b } @hist;
  }
  else {
    croak "Invalid Strategy '$self->{Strategy}'";
  }

  return [map $_->{ix}, @hist];
}

sub __commented__
{
  my($self, $code, $comment) = @_;
  return "$code\n" unless $self->{Comments};
  sprintf "%-50s/* %-$self->{__maxlen__}s */\n", $code, __quotecomment__($comment);
}

sub __unknown__
{
  my($self, $indent) = @_;
  my $code = defined $self->{UnknownCode} ? $self->{UnknownCode}
                                          : "goto $self->{UnknownLabel};";
  $code =~ s/\s+$//;
  $code =~ s/^/$indent/m;
  return $code;
}

sub __makeit__
{
  my($self, $IND, $order, $level, $pre_flag, $t, %tok) = @_;
  my $I = $self->{Indent};

  %$t or return '';

  if (keys(%$t) == 1) {
    my($token) = keys %$t;
    my($rvs,$code);
    my $unknown = '';

    if ($level > length $token) {
      $rvs = $self->__commented__($IND.'{', $token);
      $code = $self->{TokenFunc}->($token);
      $code =~ s/^/$IND$I/mg;
    }
    else {
      my @chars = $token =~ /(.)/g;
      my $cmp = join " &&\n$IND$I$I",
                map { $_->[1] } sort { $a->[0] <=> $b->[0] } map {
                  my $p = defined $order ? $order->[$_] : $_;
                  [$p, $self->__chr2cmp__($p, "'".__quotechar__($chars[$p])."'")];
                } $level .. $#chars;

      if (defined $self->{TokenEnd} and not $self->{StringLength}) {
        $level = @chars;
        $cmp and $cmp .= " &&\n$IND$I$I";
        $cmp .= $self->{TokenString} . "[$level] == $self->{TokenEnd}";
      }

      $unknown = "\n" . $self->__unknown__($IND) . "\n" if $cmp;

      $rvs = ($cmp ? $IND . "if ($cmp)\n" : '') .  $self->__commented__($IND.'{', $token);

      $code = $self->{TokenFunc}->($token);
      $code =~ s/^/$IND$I/mg;
    }

    return "$rvs$code$IND}\n$unknown";
  }

  for my $n (keys %$t) {
    my $c = __quotechar__(substr $n, (defined $order ? $order->[$level] : $level), 1)
            or defined $self->{TokenEnd} or next;
    $tok{$c ne '' ? ($self->{CaseSensitive} || $c !~ /^[a-zA-Z]$/ ? "'$c'" : "'\U$c\E'")
                  : $self->{TokenEnd}}{$n} = $t->{$n};
  }

  my $pos = defined $order ? $order->[$level] : $level;
  my $bke = '';
  my $rvs = '';
  my $nlflag = 0;

  if (keys %tok > 1 or !$self->{MergeSwitches}) {
    if (@{$self->{__backup__}}) {
      my $cmp = join " &&\n$IND$I$I",
                map { $_->[1] } sort { $a->[0] <=> $b->[0] }
                @{$self->{__backup__}};
      
      $rvs .= $IND."if ($cmp)\n".$IND."{\n";
      $bke = "$IND}\n";

      $IND .= $I;

      @{$self->{__backup__}} = ();
    }

    $rvs .= $IND."switch ($self->{TokenString}\[$pos])\n".$IND."{\n";
  }
  else {
    $bke = "\n" . $self->__unknown__($IND) . "\n" unless @{$self->{__backup__}};
    push @{$self->{__backup__}}, [$pos, $self->__chr2cmp__($pos, keys %tok)];
  }

  for my $c (sort keys %tok) {
    my($clear_pre_flag, %seen) = 0;
    my @pre = grep !$seen{$_}++, values %{$tok{$c}};

    $nlflag and $rvs .= "\n";

    if( $pre_flag == 0 && @pre == 1 && $pre[0] ) {
      $rvs .= "#if $pre[0]\n";
      $pre_flag = $clear_pre_flag = 1;
    }

    if (keys %tok > 1 or !$self->{MergeSwitches}) {
      $rvs .= $self->{CaseSensitive} || $c !~ /^'[a-zA-Z]'$/
            ? $IND.$I."case $c:\n"
            : $IND.$I."case \U$c\E:\n"
            . $IND.$I."case \L$c\E:\n";

      $rvs .= $self->__makeit__($IND.$I.$I, $order, $level+1, $pre_flag, $tok{$c});
    }
    else {
      $rvs .= $self->__makeit__($IND, $order, $level+1, $pre_flag, $tok{$c});
    }

    if ($clear_pre_flag) {
      my $cmt = $self->{Comments} ? " /* $pre[0] */" : '';
      $rvs .= "#endif$cmt\n";
      $pre_flag = 0;
    }

    $nlflag = 1;
  }

  if (keys %tok > 1 || !$self->{MergeSwitches}) {
    my $unk = $self->__unknown__("$IND$I$I");

    $unk = "$IND${I}default:\n$unk\n" if $unk;

    return <<EOS . $bke;
$rvs
$unk$IND}
EOS
  }
  else {
    return $rvs . $bke;
  }
}

sub __quotechar__
{
  my $str = shift;
  $str =~ s/(['\\])/\\$1/g;
  return __quotecomment__($str);
}

sub __quotecomment__
{
  my $str = shift;
  for my $c (qw( a b f n r t )) {
    my $e = eval qq("\\$c");
    $str =~ s/$e/\\$c/g;
  }
  $str =~ s/([\x01-\x1F])/sprintf "\\%o", ord($1)/eg;
  return $str;
}

sub __chr2cmp__
{
  my($self, $p, $c) = @_;
  $self->{CaseSensitive} || $c !~ /^'[a-zA-Z]'$/
  ? $self->{TokenString}."[$p] == $c"
  : '(' . $self->{TokenString} . "[$p] == \U$c\E || "
        . $self->{TokenString} . "[$p] == \L$c\E)";
}

1;

__END__

=head1 NAME

Devel::Tokenizer::C - Generate C source for fast keyword tokenizer

=head1 SYNOPSIS

  use Devel::Tokenizer::C;
  
  $t = Devel::Tokenizer::C->new(TokenFunc => sub { "return \U$_[0];\n" });
  
  $t->add_tokens(qw( bar baz ))->add_tokens(['for']);
  $t->add_tokens([qw( foo )], 'defined DIRECTIVE');
  
  print $t->generate;

=head1 DESCRIPTION

The Devel::Tokenizer::C module provides a small class for creating
the essential ANSI C source code for a fast keyword tokenizer.

The generated code is optimized for speed. On the ANSI-C keyword
set, it's 2-3 times faster than equivalent code generated with
the C<gprof> utility.

The above example would print the following C source code:

  switch (tokstr[0])
  {
    case 'b':
      switch (tokstr[1])
      {
        case 'a':
          switch (tokstr[2])
          {
            case 'r':
              if (tokstr[3] == '\0')
              {                                     /* bar */
                return BAR;
              }
  
              goto unknown;
  
            case 'z':
              if (tokstr[3] == '\0')
              {                                     /* baz */
                return BAZ;
              }
  
              goto unknown;
  
            default:
              goto unknown;
          }
  
        default:
          goto unknown;
      }
  
    case 'f':
      switch (tokstr[1])
      {
        case 'o':
          switch (tokstr[2])
          {
  #if defined DIRECTIVE
            case 'o':
              if (tokstr[3] == '\0')
              {                                     /* foo */
                return FOO;
              }
  
              goto unknown;
  #endif /* defined DIRECTIVE */
  
            case 'r':
              if (tokstr[3] == '\0')
              {                                     /* for */
                return FOR;
              }
  
              goto unknown;
  
            default:
              goto unknown;
          }
  
        default:
          goto unknown;
      }
  
    default:
      goto unknown;
  }

So the generated code only includes the main C<switch> statement for
the tokenizer. You can configure most of the generated code to fit
for your application.

=head1 METHODS

=head2 new

The following configuration options can be passed to the constructor.

=head3 CaseSensitive =E<gt> 0 | 1

Boolean defining whether the generated tokenizer should be case
sensitive or not. This will only affect the letters A-Z. The
default is 1, so the generated tokenizer is case sensitive.

=head3 Comments =E<gt> 0 | 1

Boolean defining whether the generated code should contain comments
or not. The default is 1, so comments will be generated.

=head3 Indent =E<gt> STRING

String to be used for one level of indentation. The default is
two space characters.

=head3 MergeSwitches =E<gt> 0 | 1

Boolean defining whether nested C<switch> statements containing
only a single C<case> should be merged into a single C<if> statement.
This is usually only done at the end of a branch.
With C<MergeSwitches>, merging will also be done in the middle of
a branch. E.g. the code

  $t = Devel::Tokenizer::C->new(
         TokenFunc     => sub { "return \U$_[0];\n" },
         MergeSwitches => 1,
       );
  
  $t->add_tokens(qw( carport carpet muppet ));
  
  print $t->generate;

would output this C<switch> statement:

  switch (tokstr[0])
  {
    case 'c':
      if (tokstr[1] == 'a' &&
          tokstr[2] == 'r' &&
          tokstr[3] == 'p')
      {
        switch (tokstr[4])
        {
          case 'e':
            if (tokstr[5] == 't' &&
                tokstr[6] == '\0')
            {                                       /* carpet  */
              return CARPET;
            }
  
            goto unknown;
  
          case 'o':
            if (tokstr[5] == 'r' &&
                tokstr[6] == 't' &&
                tokstr[7] == '\0')
            {                                       /* carport */
              return CARPORT;
            }
  
            goto unknown;
  
          default:
            goto unknown;
        }
      }
  
      goto unknown;
  
    case 'm':
      if (tokstr[1] == 'u' &&
          tokstr[2] == 'p' &&
          tokstr[3] == 'p' &&
          tokstr[4] == 'e' &&
          tokstr[5] == 't' &&
          tokstr[6] == '\0')
      {                                             /* muppet  */
        return MUPPET;
      }
  
      goto unknown;
  
    default:
      goto unknown;
  }

=head3 Strategy =E<gt> 'ordered' | 'narrow' | 'wide'

The strategy to be used for sorting character positions.
C<ordered> will leave the characters in their normal order.
C<narrow> will sort the characters positions so that the
positions with least character variation are checked first.
C<wide> will do exactly the opposite. (If you're confused
now, just try it. ;-)

The default is C<ordered>. You can only use C<narrow> and
C<wide> together with C<StringLength>.

The code

  $t = Devel::Tokenizer::C->new(
         TokenFunc     => sub { "return \U$_[0];\n" },
         StringLength  => 'len',
         Strategy      => 'ordered',
       );
  
  $t->add_tokens(qw( mhj xho mhx ));
  
  print $t->generate;

would output this C<switch> statement:

  switch (len)
  {
    case 3: /* 3 tokens of length 3 */
      switch (tokstr[0])
      {
        case 'm':
          switch (tokstr[1])
          {
            case 'h':
              switch (tokstr[2])
              {
                case 'j':
                  {                                 /* mhj */
                    return MHJ;
                  }
  
                case 'x':
                  {                                 /* mhx */
                    return MHX;
                  }
  
                default:
                  goto unknown;
              }
  
            default:
              goto unknown;
          }
  
        case 'x':
          if (tokstr[1] == 'h' &&
              tokstr[2] == 'o')
          {                                         /* xho */
            return XHO;
          }
  
          goto unknown;
  
        default:
          goto unknown;
      }
  
    default:
      goto unknown;
  }

Using the C<narrow> strategy, the C<switch> statement would be:

  switch (len)
  {
    case 3: /* 3 tokens of length 3 */
      switch (tokstr[1])
      {
        case 'h':
          switch (tokstr[0])
          {
            case 'm':
              switch (tokstr[2])
              {
                case 'j':
                  {                                 /* mhj */
                    return MHJ;
                  }
  
                case 'x':
                  {                                 /* mhx */
                    return MHX;
                  }
  
                default:
                  goto unknown;
              }
  
            case 'x':
              if (tokstr[2] == 'o')
              {                                     /* xho */
                return XHO;
              }
  
              goto unknown;
  
            default:
              goto unknown;
          }
  
        default:
          goto unknown;
      }
  
    default:
      goto unknown;
  }

Using the C<wide> strategy, the C<switch> statement would be:

  switch (len)
  {
    case 3: /* 3 tokens of length 3 */
      switch (tokstr[2])
      {
        case 'j':
          if (tokstr[0] == 'm' &&
              tokstr[1] == 'h')
          {                                         /* mhj */
            return MHJ;
          }
  
          goto unknown;
  
        case 'o':
          if (tokstr[0] == 'x' &&
              tokstr[1] == 'h')
          {                                         /* xho */
            return XHO;
          }
  
          goto unknown;
  
        case 'x':
          if (tokstr[0] == 'm' &&
              tokstr[1] == 'h')
          {                                         /* mhx */
            return MHX;
          }
  
          goto unknown;
  
        default:
          goto unknown;
      }
  
    default:
      goto unknown;
  }

=head3 StringLength =E<gt> STRING

Identifier of the C variable that contains the length of the
string, when available. If the string length is know, switching
can be done more effectively. That doesn't mean that it is more
effective to compute the string length first. If you don't know
the string length, just don't use this option. This is also the
default.

=head3 TokenEnd =E<gt> STRING

Character that defines the end of each token. The default is the
null character C<'\0'>. Can also be C<undef> if tokens don't end
with a special character.

=head3 TokenFunc =E<gt> SUBROUTINE

A reference to the subroutine that returns the code for each token
match. The only parameter to the subroutine is the token string.

This is the default subroutine:

  TokenFunc => sub { "return $_[0];\n" }

It is the responsibility of the supplier of this routine to make
the code exit out of the generated code once a token is matched,
otherwise the behaviour of the generated code is undefined.

=head3 TokenString =E<gt> STRING

Identifier of the C character array that contains the token string.
The default is C<tokstr>.

=head3 UnknownLabel =E<gt> STRING

Label that should be jumped to via C<goto> if there's no keyword
matching the token. The default is C<unknown>.

=head3 UnknownCode =E<gt> STRING

Code that should be executed if there's no keyword matching the token.
This is an alternative to C<UnknownLabel>. If C<UnknownCode> is present,
it will override C<UnknownLabel>.

=head2 add_tokens

You can add tokens using the C<add_tokens> method.

The method either takes a list of token strings or a reference
to an array of token strings which can optionally be followed
by a preprocessor directive string.

Calls to C<add_tokens> can be chained together, as the method
returns a reference to its calling object.

=head2 generate

The C<generate> method will return a string with the tokenizer
C<switch> statement. If no tokens were added, it will return an
empty string.

You can optionally pass an C<Indent> option to the C<generate>
method to specify a string used for indenting the whole
C<switch> statement, e.g.:

  print $t->generate(Indent => "\t");

This is completely independent from the C<Indent> option passed
to the constructor.

=head1 AUTHOR

Marcus Holland-Moritz E<lt>mhx@cpan.orgE<gt>

=head1 BUGS

I hope none, since the code is pretty short.
Perhaps lack of functionality ;-)

=head1 COPYRIGHT

Copyright (c) 2002-2008, Marcus Holland-Moritz. All rights reserved.
This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

