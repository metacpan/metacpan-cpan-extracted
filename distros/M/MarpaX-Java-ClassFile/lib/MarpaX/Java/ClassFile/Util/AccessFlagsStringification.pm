use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Util::AccessFlagsStringification;
use Exporter 'import'; # gives you Exporter's import() method directly
use Scalar::Util qw/blessed/;
our @EXPORT_OK = qw/accessFlagsStringificator/;

# ABSTRACT: Returns the string describing access flags

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

my %_ACCESS_FLAG = (
                    'ClassFile' =>
                    [
                     [ ACC_PUBLIC     => 0x0001 ],
                     [ ACC_FINAL      => 0x0010 ],
                     [ ACC_SUPER      => 0x0020 ],
                     [ ACC_INTERFACE  => 0x0200 ],
                     [ ACC_ABSTRACT   => 0x0400 ],
                     [ ACC_SYNTHETIC  => 0x1000 ],
                     [ ACC_ANNOTATION => 0x2000 ],
                     [ ACC_ENUM       => 0x4000 ]
                    ],
                    'FieldInfo' =>
                    [
                     [ ACC_PUBLIC     => 0x0001 ],
                     [ ACC_PRIVATE    => 0x0002 ],
                     [ ACC_PROTECTED  => 0x0004 ],
                     [ ACC_STATIC     => 0x0008 ],
                     [ ACC_FINAL      => 0x0010 ],
                     [ ACC_VOLATILE   => 0x0040 ],
                     [ ACC_TRANSIENT  => 0x0080 ],
                     [ ACC_SYNTHETIC  => 0x1000 ],
                     [ ACC_ENUM       => 0x4000 ]
                    ],
                    'MethodInfo' =>
                    [
                     [ ACC_PUBLIC       => 0x0001 ],
                     [ ACC_PRIVATE      => 0x0002 ],
                     [ ACC_PROTECTED    => 0x0004 ],
                     [ ACC_STATIC       => 0x0008 ],
                     [ ACC_FINAL        => 0x0010 ],
                     [ ACC_SYNCHRONIZED => 0x0020 ],
                     [ ACC_BRIDGE       => 0x0040 ],
                     [ ACC_VARARGS      => 0x0080 ],
                     [ ACC_NATIVE       => 0x0100 ],
                     [ ACC_ABSTRACT     => 0x0400 ],
                     [ ACC_STRICT       => 0x0800 ],
                     [ ACC_SYNTHETIC    => 0x1000 ]
                    ],
                    'Parameter' =>
                    [
                     [ ACC_FINAL        => 0x0010 ],
                     [ ACC_SYNTHETIC    => 0x1000 ],
                     [ ACC_MANDATED     => 0x8000 ]
                    ],
                    'Class' =>
                    [
                     [ ACC_PUBLIC       => 0x0001 ],
                     [ ACC_PRIVATE      => 0x0002 ],
                     [ ACC_PROTECTED    => 0x0004 ],
                     [ ACC_STATIC       => 0x0008 ],
                     [ ACC_FINAL        => 0x0010 ],
                     [ ACC_INTERFACE    => 0x0200 ],
                     [ ACC_ABSTRACT     => 0x0400 ],
                     [ ACC_SYNTHETIC    => 0x1000 ],
                     [ ACC_ANNOTATION   => 0x2000 ],
                     [ ACC_ENUM         => 0x4000 ]
                    ]
);


sub accessFlagsStringificator {
  # my ($self, $access_flags) = @_;

  my $blessed = blessed($_[0]) // '';
  $blessed =~ s/^.*:://;

  return '' unless exists($_ACCESS_FLAG{$blessed});

  my $hash = $_ACCESS_FLAG{$blessed};
  join(', ', map { $hash->[$_]->[0] } grep { ($_[1] & $hash->[$_]->[1]) == $hash->[$_]->[1] } (0..$#{$hash}))
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Util::AccessFlagsStringification - Returns the string describing access flags

=head1 VERSION

version 0.008

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
