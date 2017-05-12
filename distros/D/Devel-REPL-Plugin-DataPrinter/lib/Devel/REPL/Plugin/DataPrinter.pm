package Devel::REPL::Plugin::DataPrinter;
{
  $Devel::REPL::Plugin::DataPrinter::VERSION = '0.007';
}
# ABSTRACT: Format REPL results with Data::Printer
use strict;
use warnings;

use Devel::REPL::Plugin;
use Data::Printer colored => 1, use_prototypes => 1;

has dataprinter_config => (
    is      => 'rw',
    default => sub { {} },
);

around 'format_result' => sub {
   my $orig = shift;
   my $self = shift;
   my @to_dump = @_;
   my $out;
   my %config = (
      %{ $self->dataprinter_config },

      # we need to force this!
      return_value => 'dump',
   );
   if (@to_dump != 1 || ref $to_dump[0]) {
      if (@to_dump == 1) {
         if ( (!exists $config{stringify}{ref $to_dump[0]}
                 && overload::Method($to_dump[0], '""'))
             or $config{stringify}{ref $to_dump[0]} ) {
            $out = "@to_dump";
         }
         else {
            $out = p $to_dump[0], %config;
         }
      } else {
         $out = p @to_dump, %config;
      }
   } else {
      $out = $to_dump[0];
   }
   $self->$orig($out);
};


1;

__END__

=pod

=head1 NAME

Devel::REPL::Plugin::DataPrinter - Format REPL results with Data::Printer

=head1 VERSION

version 0.007

=head1 SYNOPSIS

In your re.pl config file (usually C<< ~/.re.pl/repl.rc >>):

    load_plugin('DataPrinter');

That's about it. Your re.pl should now give you nicer outputs :)

=head1 CUSTOMIZATION

This plugin also provides a method C<dataprinter_config>, which can
be used to configure L<Data::Printer> for use in L<Devel::REPL>.  For example,
if you don't care for colored output:

    $_REPL->dataprinter_config({
      colored => 0,
    });

Or if you ask for caller_info in your .dataprinter file, but don't want it in
the REPL:

    $_REPL->dataprinter_config({
      caller_info => 0,
    });

See L<Data::Printer/Customization> for configuration options; the values
provided to C<dataprinter_config> override your .dataprinterrc.  C<colored> is
on by default, and the only settings you may not override are
C<use_prototypes> and C<return_value>.  Note that C<dataprinter_config> only
applies to the printing that the REPL does; if you invoke C<p()> in your REPL
session yourself, these settings are B<not> applied.

=head2 Devel::REPL::Plugin::DataPrinter specific customization

=over

=item stringify

If the reference being printed has a stringification overloaded method and you
do not want to use it by default, you can configure an override by setting the
package to zero:

    $_REPL->dataprinter_config({
      stringify => {
        'DateTime' => 0,
      },
    });

=back

=head1 SEE ALSO

* L<Devel::REPL>
* L<Devel::REPL::Plugin::DDS>
* L<Data::Printer>

=head1 AUTHOR

Breno G. de Oliveira <garu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Breno G. de Oliveira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
