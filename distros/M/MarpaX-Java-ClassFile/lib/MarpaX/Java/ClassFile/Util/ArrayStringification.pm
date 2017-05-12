use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Util::ArrayStringification;
use Exporter 'import'; # gives you Exporter's import() method directly
our @EXPORT_OK = qw/arrayStringificator/;

# ABSTRACT: Unblessed array stringification helper

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

sub arrayStringificator {
  # my ($self, $arrayRef) = @_;
  #
  # If the array ref is empty, bypass the following
  #
  return '[]' if (! @{$_[1]});
  #
  # Current recursivity level in OUR stringification routines
  #
  my $currentLevel = $MarpaX::Java::ClassFile::Struct::STRINGIFICATION_LEVEL // 0;
  my $localIndent = '  ' x $currentLevel;
  #
  # To have a pretty printing of indices
  #
  my $maxIndice = $#{$_[1]};
  my $lengthMaxIndice = length($maxIndice);
  #
  # Call for stringification
  #
  my $innerIndent = '  ' . $localIndent;
  my $rc = "[\n" . join(",\n",
                        map {
                          #
                          # Say to any other overload stub that we fake a new level because we
                          # managed ourself the fact that this is a deployed array
                          #
                          local $MarpaX::Java::ClassFile::Struct::STRINGIFICATION_LEVEL = $currentLevel + 1;
                          sprintf('%s#%*d %s',
                                  $innerIndent,
                                  -$lengthMaxIndice,
                                  $_,
                                  $_[1]->[$_]
                                 )
                        }
                        grep { defined($_[1]->[$_]) }  # A cp can be undef
                        (0..$#{$_[1]})) . "\n$localIndent]";
  $rc
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Util::ArrayStringification - Unblessed array stringification helper

=head1 VERSION

version 0.008

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
