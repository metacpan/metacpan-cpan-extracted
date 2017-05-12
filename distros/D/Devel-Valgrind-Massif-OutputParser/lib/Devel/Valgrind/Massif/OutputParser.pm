use strict;
use warnings;
package Devel::Valgrind::Massif::OutputParser;
{
  $Devel::Valgrind::Massif::OutputParser::VERSION = '0.005';
}
{
  $Devel::Valgrind::Massif::OutputParser::DIST = 'Devel-Valgrind-Massif-OutputParser';
}

# ABSTRACT: Parse the output from massif just like msparser.py

use autodie;


sub new { return bless {}, shift }


sub parse_file {
  my ($self, $file) = @_;
  open my $fh, '<', $file;
  return $self->parse($fh);
}


sub parse {
  my ($self, $fh) = @_;
  return $self->_do_parse($fh);
}

sub _do_parse {
  my ($self, $fh) = @_;

  my %mdata;
  my $cur_snapshot;
  my $heap_tree_depth;

  while (defined(my $line = readline $fh)) {

    next if $line =~ /^\s*#/; # comment line

    if ($line =~ /^snapshot\s*=\s*(.*)/ ) {
      $cur_snapshot = $1;
      $mdata{snapshots}[$cur_snapshot]{heap_tree} = undef;
      next;
    }

    if ($line =~ /^(\w+)\s*=\s*(.*)/ ) {
      unless ( defined $cur_snapshot) {
        $mdata{$1} = $2;
        next;
      }

      if ($1 eq "heap_tree") {
        if (lc($2) eq "detailed") {
          push @{ $mdata{detailed_snapshots_index} ||= [] }, $cur_snapshot;
        }

        if (lc($2) eq "peak") {
          $mdata{peak_snapshot_index} = $cur_snapshot;
        }
        next;
      }

      $mdata{snapshots}[$cur_snapshot]{$1} = $2;
      next;
    }

    if ($line =~ /^\s*(\w+)\s*:\s*(.*)/ ) {
      unless ( defined $cur_snapshot) {
        $mdata{$1} = $2;
        next;
      }

      # we have a heap-tree entry... time to parse that monstrosity
      $mdata{snapshots}[$cur_snapshot]{heap_tree} =
        _build_heap_tree($fh, _make_heap_node($line), 0);
      next;
    }
  }

  return \%mdata;
}



sub _make_heap_node {
  my ($line) = @_;

  chomp $line;

  my ($num_children, $bytes, $details) =
    ($line =~ /^\s* n(\d+): \s*(\d+) \s+(.*)/x);

  # if the regex didn't match...
  return unless defined $num_children;

  my ($addr, $func, $file, $line_num) =
    ($details =~ /(0x[0-9A-F]+): ([^\s]+) \((?:in)? (.*?)(?:\:(\d+))?\)/);

  # save the info
  return {
    num_children => $num_children,
    children     => [],
    nbytes       => $bytes,
    raw_details  => $details,
    details      => (!$addr ? undef : {
      address  => $addr,
      function => $func,
      file     => $file,
      line     => $line_num,
    }),
  };
}

sub _build_heap_tree {
  my ($fh, $parent) = @_;

  my @siblings;
  for my $sib_num ( 0 .. $parent->{num_children} - 1 ) {

    defined(my $line = readline $fh) or return;
    my $sib = _make_heap_node($line);
    return unless $sib;
    push @{ $parent->{children} }, $sib;

    if ( $sib->{num_children} ) {
      _build_heap_tree($fh, $sib);
      next;
    }
  }
  return $parent;
}

1;


=pod

=head1 NAME

Devel::Valgrind::Massif::OutputParser - Parse the output from massif just like msparser.py

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Devel::Valgrind::Massif::OutputParser;
  my $data;

  # so, you could do this:
  my $data0 = Devel::Valgrind::Massif::OutputParser->parse_file($some_file);
  my $data1 = Devel::Valgrind::Massif::OutputParser->parse($some_fh);

  # or you could do this:
  my $mp = Devel::Valgrind::Massif::OutputParser->new();
  my $data2 = $mp->parse_file($some_file);
  my $data3 = $mp->parse($some_fh);

=head1 METHODS

=head2 new()

While you can call the other methods as class methods, this is here to make OO
folk happier, and to somewhat appease the "dammit these package names are too 
damned long" people, (like me) too.

  my $mp = Devel::Valgrind::Massif::OutputParser->new();

=head2 parse_file($file_name)

A convenience method, provided because msparser.py has it, too.

$file_name is a string that is the path to an output file created by running massif.

The output is the same data structure that would be returned from ->parse().

=head2 parse($fh)

$fh is a readable file handle, or something that can behave like one.

The main method for this package, it reads the output data from massif through
the given file handle and returns a perl data structure that mirrors the one
output by msparser.py in python.

=head1 AUTHOR

Stephen R. Scaffidi <sscaffidi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Stephen R. Scaffidi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Devel::Valgrind::Massif::OutputParser

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Devel-Valgrind-Massif-OutputParser>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Devel-Valgrind-Massif-OutputParser>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-Valgrind-Massif-OutputParser>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Devel-Valgrind-Massif-OutputParser>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Devel-Valgrind-Massif-OutputParser>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Devel-Valgrind-Massif-OutputParser>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Devel-Valgrind-Massif-OutputParser>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Devel-Valgrind-Massif-OutputParser>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Devel-Valgrind-Massif-OutputParser>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Devel::Valgrind::Massif::OutputParser>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-devel-valgrind-massif-outputparser at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-Valgrind-Massif-OutputParser>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Hercynium/Devel-Valgrind-Massif-OutputParser>

  git clone https://github.com/Hercynium/Devel-Valgrind-Massif-OutputParser.git

=head1 BUGS

Please report any bugs or feature requests to bug-devel-valgrind-massif-outputparser@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Valgrind-Massif-OutputParser

=cut


__END__

