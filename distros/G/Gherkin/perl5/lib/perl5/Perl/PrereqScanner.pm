use 5.008;
use strict;
use warnings;

package Perl::PrereqScanner;
# ABSTRACT: a tool to scan your Perl code for its prerequisites
$Perl::PrereqScanner::VERSION = '1.023';
use Moose;

use List::Util qw(max);
use Params::Util qw(_CLASS);
use Perl::PrereqScanner::Scanner;
use PPI 1.215; # module_version, bug fixes
use String::RewritePrefix 0.005 rewrite => {
  -as => '__rewrite_scanner',
  prefixes => { '' => 'Perl::PrereqScanner::Scanner::', '=' => '' },
};

use CPAN::Meta::Requirements 2.124; # normalized v-strings

use namespace::autoclean;

has scanners => (
  is  => 'ro',
  isa => 'ArrayRef[Perl::PrereqScanner::Scanner]',
  init_arg => undef,
  writer   => '_set_scanners',
);

sub __scanner_from_str {
  my $class = __rewrite_scanner($_[0]);
  confess "illegal class name: $class" unless _CLASS($class);
  eval "require $class; 1" or die $@;
  return $class->new;
}

sub __prepare_scanners {
  my ($self, $specs) = @_;
  my @scanners = map {; ref $_ ? $_ : __scanner_from_str($_) } @$specs;

  return \@scanners;
}

sub BUILD {
  my ($self, $arg) = @_;

  my @scanners = @{ $arg->{scanners} || [ qw(Perl5 Superclass TestMore Moose Aliased POE) ] };
  my @extra_scanners = @{ $arg->{extra_scanners} || [] };

  my $scanners = $self->__prepare_scanners([ @scanners, @extra_scanners ]);

  $self->_set_scanners($scanners);
}

#pod =method scan_string
#pod
#pod   my $prereqs = $scanner->scan_string( $perl_code );
#pod
#pod Given a string containing Perl source code, this method returns a
#pod CPAN::Meta::Requirements object describing the modules it requires.
#pod
#pod This method will throw an exception if PPI fails to parse the code.
#pod
#pod B<Warning!>  It isn't entirely clear whether PPI prefers to receive
#pod strings as octet strings or character strings.  For now, my advice
#pod is to pass octet strings.
#pod
#pod =cut

sub scan_string {
  my ($self, $str) = @_;
  my $ppi = PPI::Document->new( \$str );
  confess "PPI parse failed: " . PPI::Document->errstr unless defined $ppi;

  return $self->scan_ppi_document( $ppi );
}

#pod =method scan_file
#pod
#pod   my $prereqs = $scanner->scan_file( $path );
#pod
#pod Given a file path to a Perl document, this method returns a
#pod CPAN::Meta::Requirements object describing the modules it requires.
#pod
#pod This method will throw an exception if PPI fails to parse the code.
#pod
#pod =cut

sub scan_file {
  my ($self, $path) = @_;
  my $ppi = PPI::Document->new( $path );
  confess "PPI failed to parse '$path': " . PPI::Document->errstr
      unless defined $ppi;

  return $self->scan_ppi_document( $ppi );
}

#pod =method scan_ppi_document
#pod
#pod   my $prereqs = $scanner->scan_ppi_document( $ppi_doc );
#pod
#pod Given a L<PPI::Document>, this method returns a CPAN::Meta::Requirements object
#pod describing the modules it requires.
#pod
#pod =cut

sub scan_ppi_document {
  my ($self, $ppi_doc) = @_;

  my $req = CPAN::Meta::Requirements->new;

  for my $scanner (@{ $self->{scanners} }) {
    $scanner->scan_for_prereqs($ppi_doc, $req);
  }

  return $req;
}

#pod =method scan_module
#pod
#pod   my $prereqs = $scanner->scan_module( $module_name );
#pod
#pod Given the name of a module, eg C<'PPI::Document'>,
#pod this method returns a CPAN::Meta::Requirements object
#pod describing the modules it requires.
#pod
#pod =cut

sub scan_module {
  my ($self, $module_name) = @_;

  # consider rewriting to use Module::Which -- rjbs, 2013-11-03
  require Module::Path;
  if (defined(my $path = Module::Path::module_path($module_name))) {
    return $self->scan_file($path);
  }

  confess "Failed to find file for module '$module_name'";
}

1;

=pod

=encoding UTF-8

=head1 NAME

Perl::PrereqScanner - a tool to scan your Perl code for its prerequisites

=head1 VERSION

version 1.023

=head1 SYNOPSIS

  use Perl::PrereqScanner;
  my $scanner = Perl::PrereqScanner->new;
  my $prereqs = $scanner->scan_ppi_document( $ppi_doc );
  my $prereqs = $scanner->scan_file( $file_path );
  my $prereqs = $scanner->scan_string( $perl_code );
  my $prereqs = $scanner->scan_module( $module_name );

=head1 DESCRIPTION

The scanner will extract loosely your distribution prerequisites from your
files.

The extraction may not be perfect but tries to do its best. It will currently
find the following prereqs:

=over 4

=item *

plain lines beginning with C<use> or C<require> in your perl modules and scripts, including minimum perl version

=item *

regular inheritance declared with the C<base> and C<parent> pragmata

=item *

L<Moose> inheritance declared with the C<extends> keyword

=item *

L<Moose> roles included with the C<with> keyword

=item *

OO namespace aliasing using the C<aliased> module

=back

=head2 Scanner Plugins

Perl::PrereqScanner works by running a series of scanners over a PPI::Document
representing the code to scan.  By default the "Perl5", "Moose", "TestMore",
"POE", and "Aliased" scanners are run.  You can supply your own scanners when
constructing your PrereqScanner:

  # Us only the Perl5 scanner:
  my $scanner = Perl::PrereqScanner->new({ scanners => [ qw(Perl5) ] });

  # Use any stock scanners, plus Example:
  my $scanner = Perl::PrereqScanner->new({ extra_scanners => [ qw(Example) ] });

=head1 METHODS

=head2 scan_string

  my $prereqs = $scanner->scan_string( $perl_code );

Given a string containing Perl source code, this method returns a
CPAN::Meta::Requirements object describing the modules it requires.

This method will throw an exception if PPI fails to parse the code.

B<Warning!>  It isn't entirely clear whether PPI prefers to receive
strings as octet strings or character strings.  For now, my advice
is to pass octet strings.

=head2 scan_file

  my $prereqs = $scanner->scan_file( $path );

Given a file path to a Perl document, this method returns a
CPAN::Meta::Requirements object describing the modules it requires.

This method will throw an exception if PPI fails to parse the code.

=head2 scan_ppi_document

  my $prereqs = $scanner->scan_ppi_document( $ppi_doc );

Given a L<PPI::Document>, this method returns a CPAN::Meta::Requirements object
describing the modules it requires.

=head2 scan_module

  my $prereqs = $scanner->scan_module( $module_name );

Given the name of a module, eg C<'PPI::Document'>,
this method returns a CPAN::Meta::Requirements object
describing the modules it requires.

=for Pod::Coverage::TrustPod new

=head1 SEE ALSO

L<scan-perl-prereqs>, in this distribution, is a command-line interface to the scanner

=head1 AUTHORS

=over 4

=item *

Jerome Quelin

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords bowtie celogeek Christopher J. Madsen David Golden Steinbrunner Ed J Florian Ragwitz Jakob Voss Jerome Quelin Jérôme John SJ Anderson Karen Etheridge Mark Gardner Neil Bowers Randy Stauner Tina Mueller Vyacheslav Matjukhin

=over 4

=item *

bowtie <bowtie@cpan.org>

=item *

celogeek <me@celogeek.com>

=item *

Christopher J. Madsen <perl@cjmweb.net>

=item *

David Golden <dagolden@cpan.org>

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

Ed J <mohawk2@users.noreply.github.com>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Jakob Voss <voss@gbv.de>

=item *

Jerome Quelin <jquelin@gmail.com>

=item *

Jérôme Quelin <jquelin@gmail.com>

=item *

John SJ Anderson <genehack@genehack.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Mark Gardner <gardnerm@gsicommerce.com>

=item *

Neil Bowers <neil@bowers.com>

=item *

Randy Stauner <rwstauner@cpan.org>

=item *

Tina Mueller <tinita@cpan.org>

=item *

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#pod =for Pod::Coverage::TrustPod
#pod   new
#pod
#pod =head1 SYNOPSIS
#pod
#pod   use Perl::PrereqScanner;
#pod   my $scanner = Perl::PrereqScanner->new;
#pod   my $prereqs = $scanner->scan_ppi_document( $ppi_doc );
#pod   my $prereqs = $scanner->scan_file( $file_path );
#pod   my $prereqs = $scanner->scan_string( $perl_code );
#pod   my $prereqs = $scanner->scan_module( $module_name );
#pod
#pod =head1 DESCRIPTION
#pod
#pod The scanner will extract loosely your distribution prerequisites from your
#pod files.
#pod
#pod The extraction may not be perfect but tries to do its best. It will currently
#pod find the following prereqs:
#pod
#pod =begin :list
#pod
#pod * plain lines beginning with C<use> or C<require> in your perl modules and scripts, including minimum perl version
#pod
#pod * regular inheritance declared with the C<base> and C<parent> pragmata
#pod
#pod * L<Moose> inheritance declared with the C<extends> keyword
#pod
#pod * L<Moose> roles included with the C<with> keyword
#pod
#pod * OO namespace aliasing using the C<aliased> module
#pod
#pod =end :list
#pod
#pod =head2 Scanner Plugins
#pod
#pod Perl::PrereqScanner works by running a series of scanners over a PPI::Document
#pod representing the code to scan.  By default the "Perl5", "Moose", "TestMore",
#pod "POE", and "Aliased" scanners are run.  You can supply your own scanners when
#pod constructing your PrereqScanner:
#pod
#pod   # Us only the Perl5 scanner:
#pod   my $scanner = Perl::PrereqScanner->new({ scanners => [ qw(Perl5) ] });
#pod
#pod   # Use any stock scanners, plus Example:
#pod   my $scanner = Perl::PrereqScanner->new({ extra_scanners => [ qw(Example) ] });
#pod
#pod =head1 SEE ALSO
#pod
#pod L<scan-perl-prereqs>, in this distribution, is a command-line interface to the scanner
#pod
#pod =cut
