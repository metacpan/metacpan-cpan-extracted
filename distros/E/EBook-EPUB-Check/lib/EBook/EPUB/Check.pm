package EBook::EPUB::Check;

use 5.008_001;
use strict;
use warnings;
use Carp ();
use Exporter qw/import/;
use File::ShareDir ();
use IPC::Run3 ();
use EBook::EPUB::Check::Result ();

our $VERSION   = "0.05";
our @EXPORT    = qw(epubcheck);
our @EXPORT_OK = qw();

our $JAR       = File::ShareDir::dist_file('EBook-EPUB-Check', 'epubcheck-3.0.1/epubcheck-3.0.1.jar');
$JAR           = Cygwin::posix_to_win_path($JAR) if $^O eq 'cygwin';

sub epubcheck
{
    my ($epub, $jar) = @_;

    $jar = $JAR unless defined $jar;

    Carp::croak('jar file not found') unless -f $jar;

    if ( ! defined $epub || ! -f $epub )
    {
        Carp::carp('epub file not found');
        return EBook::EPUB::Check::Result->new(\'');
    }

    my $out;
    IPC::Run3::run3(['java', '-jar', $jar, $epub], undef, \$out, \$out);

    return EBook::EPUB::Check::Result->new(\$out);
}

1;

__END__

=encoding utf-8

=for stopwords epubcheck

=head1 NAME

EBook::EPUB::Check - Perl wrapper for EpubCheck

=head1 SYNOPSIS

  use EBook::EPUB::Check; # exports epubcheck()

  my $result = epubcheck('epub/invalid.epub'); # => isa 'EBook::EPUB::Check::Result'

  unless ($result->is_valid)
  {
      print $result->report;
  }

  epubcheck('epub/valid.epub')->is_valid; # => success

=for test_synopsis_expectation_no_test

Command Line Interface:

  epubcheck ebook.epub
  epubcheck -out output.xml ebook.epub # Extracting information from an EPUB file


=head1 DESCRIPTION

EBook::EPUB::Check checks whether your EPUB files are valid.

For more Information about EpubCheck, see L<https://github.com/IDPF/epubcheck/wiki>.

=head1 PREREQUISITES

Java must be installed and set in your PATH.

=head1 FUNCTIONS

=head2 epubcheck( $epub [, $jar] )

Returns an L<EBook::EPUB::Check::Result> instance.

=head1 LICENSE

=over 2

=item of the Module

Copyright (C) pawa.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=item of EpubCheck

New BSD License

=back

=head1 SEE ALSO

L<https://github.com/IDPF/epubcheck/wiki>

L<EBook::EPUB>

=head1 AUTHOR

pawa E<lt>pawa@pawafuru.comE<gt>

=cut
