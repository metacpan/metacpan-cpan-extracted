package Lexical::Alias;

require Exporter;
require DynaLoader;

@ISA = qw( Exporter DynaLoader );
@EXPORT = qw( alias );
@EXPORT_OK = qw( alias_r alias_s alias_a alias_h );
$VERSION = '0.04';
$SWAP = 0;

bootstrap Lexical::Alias $VERSION;

sub alias_s(\$\$) { goto &alias_r }
sub alias_a(\@\@) { goto &alias_r }
sub alias_h(\%\%) { goto &alias_r }

if ($] < 5.008) {
  # compain about "use Lexical::Alias;" prior to perl v5.8:
  @EXPORT_FAIL = qw( alias );
} else {
  eval 'sub alias (\[$@%]\[$@%]) { goto &alias_r }; 1' or die $@;
}

1;

__END__

=head1 NAME

Lexical::Alias - makes a lexical an alias for another variable

=head1 SYNOPSIS

  use 5.008;
  use Lexical::Alias;

  my ($src, $dst);
  alias $src, $dst;

  my (@src, @dst);
  alias @src, @dst;

  my (%src, %dst);
  alias %src, %dst;

  # modifying $src/@src/%src
  # modifies $dst/@dst/%dst,
  # and vice-versa

  # or, if supporting Perls prior to v5.8:

  use Lexical::Alias qw( alias_r alias_s alias_a alias_h );

  my ($src, $dst);
  alias_s $src, $dst;

  my (@src, @dst);
  alias_a @src, @dst;

  my (%src, %dst);
  alias_h %src, %dst;

  alias_r \$src, \$dst;
  alias_r \@src, \@dst;
  alias_r \%src, \%dst;

  # if you prefer the alias come first...
  $Lexical::Alias::SWAP = 1;
  alias $dst, $src;  # $dst is an alias for $src

=head1 DESCRIPTION

This module allows you to alias a lexical (declared with C<my>) variable to
another variable (package or lexical).  You will receive a fatal error if you
try aliasing a scalar to something that is not a scalar (etc.).

=head2 Parameter Swaping (new!)

Version 0.04 introduced the C<$Lexical::Alias::SWAP> variable.  When it is
true, the arguments to the aliasing functions are expected in reverse order;
that is, the alias comes I<first>, and the source variable second.

(Thanks to Jenda from F<perlmonks.org> for requesting this.)

=head2 Exported Functions

=over 4

=item * C<alias(src, dst)>

Makes I<dst> (which must be lexical) an alias to I<src> (which can be either
lexical or a package variable).  I<src> and I<dst> must be the same data type
(scalar and scalar, array and array, hash and hash).

This is only available in Perl v5.8 and later, where it is exported
automatically.

=item * C<alias_s($src, $dst)>

Makes I<dst> (which must be lexical) an alias to I<src> (which can be either
lexical or a package variable).  This is not exported by default.

=item * C<alias_a(@src, @dst)>

Makes I<dst> (which must be lexical) an alias to I<src> (which can be either
lexical or a package variable).  This is not exported by default.

=item * C<alias_h(%src, %dst)>

Makes I<dst> (which must be lexical) an alias to I<src> (which can be either
lexical or a package variable).  This is not exported by default.

=item * C<alias_r(\src, \dst)>

Makes I<dst> (which must be lexical) an alias to I<src> (which can be either
lexical or a package variable).  I<src> and I<dst> must be the same data type
(scalar and scalar, array and array, hash and hash).  This is not exported by
default.

=back

=head2 Caveats

If you alias one lexical to another lexical, then making another alias to
either lexical makes I<all three lexicals> point to the same data.

  use Lexical::Alias;

  my ($x, $y, $z);
  alias $x => $y;  # $y is an alias for $x
  alias $z => $y;  # $y (and thus $x) is an alias for $z
  $z = 10;
  print $x;        # 10

This is not a bug.

However, there I<does> appear to be a bug in Perl 5.8.0 (which has been
fixed in the development version 5.9.0); when these functions are used in a
subroutine, they appear to not work fully:

  my $orig = 1;
  my $alias = 99;
  alias $orig => $alias;
  print "$orig = $alias\n";

  sub foo {
    my $orig = 1;
    my $alias = 99;
    alias $orig => $alias;
    print "foo(): $orig = $alias\n";
  }

  foo();

The expected output is "1 = 1" and "foo(): 1 = 1".  It is not so.  The
second output is "foo(): 1 = 99".  Jenda pointed this out to me, and I do not
know where in the source the bug is, but it will be fixed for the next
release of Perl (5.8.1).

=head1 AUTHOR

Jeff C<japhy> Pinyan, F<japhy@pobox.com>

Thanks to Tye McQueen for a bug fix -- this module should work from 5.005 on.

F<http://www.pobox.com/~japhy/>

=head1 SEE ALSO

F<Devel::LexAlias>, by Richard Clamp, from which I got (and modified) the
code necessary for this module.  I've wanted this feature for some time, and
Richard opened the door with this module.

F<Variable::Alias>, by Brent Dax, which is a tie() interface to aliasing
all sorts of variables.
