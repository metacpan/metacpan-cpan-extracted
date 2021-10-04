use strict;
use warnings;
use 5.022;

package Alien::Build::Wizard::Questions 0.04 {

  use Exporter qw( import );
  use constant QUESTION_URL          => 'Enter the full URL to the latest tarball (or zip, etc.) of the project you want to alienize.';
  use constant QUESTION_CLASS_NAME   => 'What is the class name for your Alien?';
  use constant QUESTION_HUMAN_NAME   => 'What is the human project name of the alienized package?';
  use constant QUESTION_PKG_NAMES    => 'Which pkg-config names (if any) should be used to detect system install?  You may space separate multiple names.';
  use constant QUESTION_BUILD_SYSTEM => 'Choose build system.';
  use constant QUESTION_ALIEN_TYPE   => "What use cases will this Alien provide?  You may choose more than one:\n" .
                                        " - tool: command line tool, often used in building other Aliens\n" .
                                        " - xs:   library that can be used to build XS bindings\n" .
                                        " - ffi:  library that can be used to build FFI bindings\n";
  use constant QUESTION_LATEST       => "Do you want to install the specific version from the URL above, or the latest version?\n" .
                                        " - specific: best used when the alienized package may change a lot from version to version.  You can still later change to a " .
                                        "newer version, but you will have to make a new release of the Alien to do so.\n" .
                                        " - latest: typically the best option.  If the alienized package provides a relatively stable API new versions will be used " .
                                        "when available without having to cut a new release of the Alein.";

  # ABSTRACT: List of questions

  our @EXPORT_OK   = sort grep /^QUESTION_/, keys %Alien::Build::Wizard::Questions::;
  our %EXPORT_TAGS = ( all => \@EXPORT_OK );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Wizard::Questions - List of questions

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 % perldoc Dist::Zilla::MintingProfile::AlienBuild

=head1 DESCRIPTION

This class is private.

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla::MintingProfile::AlienBuild>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
