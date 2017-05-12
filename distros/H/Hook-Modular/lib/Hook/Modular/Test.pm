use 5.008;
use strict;
use warnings;

package Hook::Modular::Test;
BEGIN {
  $Hook::Modular::Test::VERSION = '1.101050';
}
# ABSTRACT: utility functions for testing Hook::Modular
use File::Temp 'tempfile';
use YAML qw/Load DumpFile/;
use Exporter qw(import);
our %EXPORT_TAGS = (util => [qw(write_config_file)],);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };

sub write_config_file {
    my $yaml     = shift;
    my $filename = (tempfile())[1];
    DumpFile($filename, Load($yaml));
    $filename;
}
1;


__END__
=pod

=head1 NAME

Hook::Modular::Test - utility functions for testing Hook::Modular

=head1 VERSION

version 1.101050

=head1 SYNOPSIS

  # t/45blah.t

  use Hook::Modular::Test ':all';

  my $config_filename = write_config_file(do { local $/; <DATA> });

  sub run {
      # ...
  }

  __DATA__
  global:
    log:
      level: error
  ...

=head1 DESCRIPTION

This module exports utility functions to aid in testing Hook::Modular. None of
the functions are exported automatically, but you can request them by name, or
get all of them if you use the C<:all> tag.

=head1 FUNCTIONS

=head2 write_config_file

  my $temp_file_name = write_config_file($yaml_string);

Takes the YAML, loads it (partly to make sure it is valid), dumps it out to a
temporary file and returns the file name.

=for test_synopsis 1;
__END__

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Hook-Modular>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Hook-Modular/>.

The development version lives at
L<http://github.com/hanekomu/Hook-Modular/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

  Marcel Gruenauer <marcel@cpan.org>
  Tatsuhiko Miyagawa <miyagawa@bulknews.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

