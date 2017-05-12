package Lingua::PT::Inflect;

use 5.006;
use strict;
use warnings;
use Lingua::PT::Hyphenate;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	sing2plural
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	sing2plural
);

our $VERSION = '0.06';

=head1 NAME

Lingua::PT::Inflect - Converts Portuguese words from singular to plural

=head1 SYNOPSIS

  use Lingua::PT::Inflect;

  $plural = sing2plural('programador')   # now holds 'programadores'

=head1 DESCRIPTION

Converts Portuguese words from singular to plural. There may be some
special cases that will fail (words ending in -„o or -s might fail, as
many special cases are yet to be prevented; anyone volunteering to
look at a huge list of words?)

=cut

my (%exceptions,@rules,%rules);

BEGIN {
  %exceptions = (
    'l·pis'	=> 'l·pis',
    'pires'	=> 'pires',

    'm„o'	=> 'm„os',
    'afeg„o'	=> 'afeg„os',

    'p„o'	=> 'p„es',
    'capit„o'	=> 'capit„es',
    'c„o'	=> 'c„es',
    'alem„o'	=> 'alem„es',
  );

  @rules = map qr/$_/, qw(·s Ís el ol al oi ul m „o (?<=[aeiou]) (?<=[rnsz]));

  %rules = (
    qr/·s/	=> 'ases',
    qr/Ís/	=> 'eses',
    qr/el/	=> 'Èis',
    qr/ol/	=> 'Ûis',
    qr/al/	=> 'ais',
    qr/oi/	=> 'ois',
    qr/ul/	=> 'uis',
    qr/m/	=> 'ns',
    qr/„o/	=> 'ıes',
    qr/(?<=[aeiou])/	=> 's',
    qr/(?<=[rnsz])/	=> 'es',
  );

}

#

=head1 METHODS

=head2 new

Creates a new Lingua::PT::Inflect object.

If you're doing this lots of time, it would probably be better for you
to use the sing2plural function directly (that is, creating a new
object for each word in a long text doesn't seem so bright if you're
not going to use it later on).

=cut

sub new {
  my ($self, $word) = @_;
  bless \$word, $self;
}

=head2 sing2plural

Converts a word in the singular gender to plural.

  $plural = sing2plural($singular);

=cut

sub sing2plural {
  defined $_[0] || return undef;

  my $word;
  if (ref($_[0]) eq 'Lingua::PT::Inflect') {
    my $self = shift;
    $word = $$self;
  }
  else {
    $word = shift;
  }

  $_ = $word;

  defined $exceptions{$_} && return $exceptions{$_};

  for my $rule (@rules) {
    if (s/$rule$/$rules{$rule}/) {return $_}
  }

  if (/il$/) {
    my @syl = hyphenate($_);

    s!il$!$syl[-2] =~ /[„‚·ÍÈÌÛıÙ˙√¡…Õ”’‘ ¬⁄]/ ? 'eis' : 'is' !e;
  }

  return $_;
}

1;
__END__

=head1 TO DO

=over 6

=item * Several words are exceptions to the rules; there is a file of
those words that need to be checked.

=back

=head1 SEE ALSO

More tools for the Portuguese language processing can be found at the Natura
project: http://natura.di.uminho.pt

=head1 AUTHOR

Jose Castro, C<< <cog@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2004 Jose Castro, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
