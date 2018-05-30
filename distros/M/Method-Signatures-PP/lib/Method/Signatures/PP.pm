package Method::Signatures::PP;

use strict;
use warnings;
use re 'eval';
use Filter::Util::Call;
use PPR;

our $VERSION = '0.000004'; # v0.0.4

$VERSION = eval $VERSION;

our $Statement_Start;

our @Found;

my $grammar = qr{
  (?(DEFINE)
    (?<PerlKeyword>
      (?{ local $Statement_Start = pos() })
      method (?&PerlOWS)
      (?&PerlIdentifier) (?&PerlOWS)
      (?: (?&kw_balanced_parens) (?&PerlOWS) )?+
      (?&PerlBlock) (?&PerlOWS)
      (?{ push @Found, [ $Statement_Start, pos() - $Statement_Start ] })
    )
    (?<kw_balanced_parens>
      \( (?: [^()]++ | (?&kw_balanced_parens) )*+ \)
    )
  )
  $PPR::GRAMMAR
}x;

sub import {
  my $done = 0;
  filter_add(sub {
    return 0 if $done++;
    1 while filter_read();
    #warn "CODE >>>\n$_<<<";
    if (defined(my $mangled = mangle($_))) {
      $_ = $mangled;
    }
    return 1;
  });
}

sub mangle {
  my ($code) = @_;
  local @Found;
  unless ($code =~ /\A (?&PerlDocument) \Z $grammar/x) {
    warn "Failed to parse file; expect complication errors, sorry.\n";
    return undef;
  }
  my $offset = 0;
  foreach my $case (@Found) {
    my ($start, $len) = @$case;
    $start += $offset;
    my $stmt = substr($code, $start, $len);
    die "Whit?"
      unless my @match = $stmt =~ m{
        \A
        method ((?&PerlOWS))
        ((?&PerlIdentifier)) ((?&PerlOWS))
        (?: ((?&kw_balanced_parens)) ((?&PerlOWS)) )?+
        ((?&PerlBlock)) ((?&PerlOWS))
        $grammar
      }x;
    my ($ws0, $name, $ws1, $sig, $ws2, $block, $ws3) = @match;
    my $sigcode = $sig ? " my $sig = \@_;" : '';
    $block =~ s{^\{}{\{my \$self = shift;${sigcode}};
    my $replace = "sub${ws0}${name}${ws1}${block}${ws3}";
    substr($code, $start, $len) = $replace;
    $offset += length($replace) - $len;
  }
  #warn "FINAL >>>\n$_<<<";
  return $code;
}

1;

=head1 NAME

Method::Signatures::PP - EXPERIMENTAL pure perl method keyword

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Test::More;
    use Method::Signatures::PP;
    
    package Wat;
    
    use Moo;
    
    method foo {
      "FOO from ".ref($self);
    }
    
    method bar ($arg) {
      "WOOO $arg";
    }
    
    package main;
    
    my $wat = Wat->new;
    
    is($wat->foo, 'FOO from Wat', 'Parenless method');
    
    is($wat->bar('BAR'), 'WOOO BAR', 'Method w/argument');
    
    done_testing;

=head1 DESCRIPTION

It's ... a method keyword.

    method foo { ... }

is equivalent to

    sub foo { my $self = shift; ... }

and

    method bar ($arg) { ... }

is equivalent to

    method bar ($arg) { my $self = shift; my ($arg) = @_; ... }

In fact, it isn't just equivalent, this module literally rewrites the source
code in the way shown in the examples above. It does so by using a source
filter (boo, hiss, yes I know) to slurp the entire file, then Damian's
wonderfully insane L<PPR> module to parse the code to find the keywords, and
then rewrites the source before returning the file to perl to compile.

The wonderful part of this is that it's 100% pure perl and therefore unlike
every other method implementation is amenable to L<App::FatPacker> use. The
terrible part of this is that if the parse phase doesn't work, the code has
no idea at all what it's doing and ends up not touching the source code at
all, at which point the compilation failures from the keyword rewriting not
having happened will almost certainly hide the actual problem.

So, for the moment, you are strongly advised to not use this module while
developing code, and instead use L<Function::Parameters> if you have a not
completely ancient perl and L<Method::Signatures::Simple> if you're still
back in the stone age banging rocks together, and to then switch your 'use'
line to this module for fatpacking/shipping/etc. - I may yet come up with
a better solution to this and/or beg Damian for help doing so, but at the
time of writing I can offer no guarantees.

Note that L<PPR> requires perl 5.10 and as such so does this module. However,
if you need to support older perls, you can

    use Method::Signatures::PP::Compile;

which uses ingy's L<Module::Compile> to generate a .pmc file that should run
fine on whatever version of perl the rest of your code requires. This will
likely be rewritten to use a slightly less lunatic compilation mechanism in
later releases.

=head1 AUTHOR

 mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None yet - maybe this software is perfect! (ahahahahahahahahaha)

=head1 COPYRIGHT

Copyright (c) 2017 the Method::Signatures::PP L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
