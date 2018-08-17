package Method::Signatures::PP;

use strict;
use warnings;
use Import::Into;
use Moo;

our $VERSION = '0.000005'; # v0.0.5

$VERSION = eval $VERSION;

sub import {
  Babble::Filter->import::into(1, __PACKAGE__);
}

sub extend_grammar {
  my ($self, $g) = @_;
  $g->add_rule(MethodDeclaration => 
    'method(?&PerlOWS)(?:(?&PerlIdentifier)(?&PerlOWS))?+'
    .'(?:(?&PerlParenthesesList))?+'
    .'(?&PerlOWS) (?&PerlBlock)'
  );
  $g->augment_rule(SubroutineDeclaration => '(?&PerlMethodDeclaration)');
}

sub transform_to_plain {
  my ($self, $top) = @_;
  $top->remove_use_statement('Function::Parameters');
  $top->remove_use_statement('Method::Signatures::PP');
  $top->remove_use_statement('Method::Signatures::Simple');
  $top->each_match_within(MethodDeclaration => [
      [ kw => 'method' ],
      [ name => '(?&PerlOWS)(?:(?&PerlIdentifier)(?&PerlOWS))?+' ],
      [ sig => '(?:(?&PerlParenthesesList))?+' ],
      [ rest => '(?&PerlOWS) (?&PerlBlock)' ],
    ] => sub {
      my ($m) = @_;
      my ($kw, $sig, $rest) = @{$m->submatches}{qw(kw sig rest)};
      $kw->replace_text('sub');
      my $sig_text = $sig->text;
      my $front = 'my $self = shift; '
                  .($sig_text ? "my ${sig_text} = \@_; ": '');
      $rest->transform_text(sub { s/^(\s*)\{/${1}{ ${front}/ });
      unless (($m->subtexts('name'))[0]) {
        $rest->transform_text(sub { s/$/;/ });
      }
      $sig->replace_text('');
  });
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
line to this module for fatpacking/shipping/etc. - and since this code now
uses L<Babble>, to create a .pmc you can run:

  perl -MBabble::Filter=Method::Signatures::PP -0777 -pe babble \
    lib/MyFile.pm >lib/MyFile.pmc

(or even use -pi -e on a built distdir)

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
