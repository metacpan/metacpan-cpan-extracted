package FFI::Platypus::ShareConfig;

use strict;
use warnings;
use File::ShareDir qw( dist_dir );
use File::Spec;
use JSON::PP qw( decode_json );

our $VERSION = '0.48'; # VERSION

sub get
{
  my(undef, $name) = @_;
  my $config;
  
  unless($config)
  {
    my $fn = File::Spec->catfile(dist_dir('FFI-Platypus'), 'config.json');
    my $fh;
    open $fh, '<', $fn;
    my $raw = do { local $/; <$fh> };
    close $fh;
    $config = decode_json $raw;
  }
  
  $config->{$name};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Platypus::ShareConfig

=head1 VERSION

version 0.48

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Bakkiaraj Murugesan (bakkiaraj)

Dylan Cali (calid)

pipcet

Zaki Mughal (zmughal)

Fitz Elliott (felliott)

Vickenty Fesunov (vyf)

Gregor Herrmann (gregoa)

Shlomi Fish (shlomif)

Damyan Ivanov

Ilya Pavlov (Ilya33)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
