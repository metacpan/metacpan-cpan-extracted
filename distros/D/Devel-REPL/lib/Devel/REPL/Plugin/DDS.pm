use strict;
use warnings;
package Devel::REPL::Plugin::DDS;
# ABSTRACT: Format results with Data::Dump::Streamer

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use Data::Dump::Streamer ();
use namespace::autoclean;

around 'format_result' => sub {
   my $orig = shift;
   my $self = shift;
   my @to_dump = @_;
   my $out;
   if (@to_dump > 1 || ref $to_dump[0]) {
      if (@to_dump == 1 && overload::Method($to_dump[0], '""')) {
         $out = "@to_dump";
      } else {
         my $dds = Data::Dump::Streamer->new;
         $dds->Freezer(sub { "$_[0]"; });
         $dds->Data(@to_dump);
         $out = $dds->Out;
      }
   } else {
      $out = $to_dump[0];
   }
   $self->$orig($out);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::DDS - Format results with Data::Dump::Streamer

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
 $ARRAY1 = [
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
