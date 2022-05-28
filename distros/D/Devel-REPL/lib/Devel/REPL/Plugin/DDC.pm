use strict;
use warnings;
package Devel::REPL::Plugin::DDC;
# ABSTRACT: Format results with Data::Dumper::Concise

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use Data::Dumper::Concise ();
use namespace::autoclean;

around 'format_result' => sub {
  my $orig = shift;
  my $self = shift;
  my $to_dump = (@_ > 1) ? [@_] : $_[0];
  my $out;
  if (ref $to_dump) {
    if (overload::Method($to_dump, '""')) {
      $out = "$to_dump";
    } else {
      $out = Data::Dumper::Concise::Dumper($to_dump);
    }
  } else {
    $out = $to_dump;
  }
  $self->$orig($out);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::DDC - Format results with Data::Dumper::Concise

=head1 VERSION

version 1.003029

=head1 SYNOPSIS

 # in your re.pl file:
 use Devel::REPL;
 my $repl = Devel::REPL->new;
 $repl->load_plugin('DDS');
 $repl->run;

 # after you run re.pl:
 $ map $_*2, ( 1,2,3 )
[
  2,
  4,
  6
];

 $

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-REPL>
(or L<bug-Devel-REPL@rt.cpan.org|mailto:bug-Devel-REPL@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#devel> on C<irc.perl.org>|irc://irc.perl.org/#devel-repl>.

=head1 AUTHOR

Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>)

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
