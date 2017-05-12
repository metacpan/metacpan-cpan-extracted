use 5.006;
use strict;
use warnings;

package Devel::Cover::Report::Json_detailed;

our $VERSION = '0.001000';

# ABSTRACT: Generate a comprehensive JSON file articulating the full contents of a coverage run.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Devel::Cover::DB;
use Path::Tiny qw( path );
use Try::Tiny qw( try catch );
use Carp qw( carp );

sub _extract_statements {
  my ( $db, $file, ) = @_;

  my $cover = $db->cover;
  my $f     = $cover->file($file);
  my @lines;

  try {
    @lines = path($file)->lines( { chomp => 1 } );
  }
  catch {
    carp $_;
  };
  return [] unless @lines;
  my @lines_info;

  my $line_no = -1;
  while (@lines) {
    $line_no++;
    my $next_line = shift @lines;
    my $entry     = {};
    $entry->{line} = $line_no;
    $entry->{code} = $next_line;

    my $error = 0;

    for my $field (qw( statement subroutine pod time )) {
      if ( $f->$field()
        and my $coverage = $f->$field()->location($line_no) )
      {
        if ( 'ARRAY' eq ref $coverage ) {
          $coverage = $coverage->[0];
        }
        $entry->{$field} = $coverage->uncoverable ? q[-] : $coverage->covered;
        $error ||= $coverage->error;
      }
    }
    for my $field (qw( branch condition )) {
      if ( $f->$field and my $coverage = $f->$field->location($line_no) ) {
        if ( 'ARRAY' eq ref $coverage ) {
          $coverage = $coverage->[0];
        }
        $entry->{$field} = $coverage->uncoverable ? q[-] : $coverage->percentage;
        $error ||= $coverage->error;
      }
    }
    if ($error) {
      $entry->{coverage_error} = 1;
    }
    push @lines_info, $entry;
  }
  return \@lines_info;
}

sub _extract_branches {
  my ( $db, $file, ) = @_;
  my $branches = $db->cover->file($file)->branch;
  return [] unless $branches;
  my @lines_info;
  for my $location ( sort { $a <=> $b } $branches->items ) {
    for my $branch ( @{ $branches->location($location) } ) {
      my $entry = {};
      $entry->{line}           = $location;
      $entry->{code}           = $branch->text;
      $entry->{coverage_error} = 1 if $branch->error;
      if ( $branch->uncoverable ) {
        $entry->{uncoverable} = 1;
        push @lines_info, $entry;
        next;
      }
      $entry->{percentage} = $branch->percentage;
      $entry->{true}       = $branch->covered;
      $entry->{false}      = $branch->total - $branch->covered;
      push @lines_info, $entry;
    }
  }
  return \@lines_info;
}

sub _extract_subroutines {
  my ( $db, $file, ) = @_;
  my $subs = $db->cover->file($file)->subroutine;
  return [] unless $subs;
  my @lines_info;
  for my $location ( sort { $a <=> $b } $subs->items ) {
    my $sub_records = $subs->location($location);
    for my $sub_record ( @{$sub_records} ) {
      my $entry = {};
      $entry->{line} = $location;
      $entry->{name} = $sub_record->name;
      if ( $sub_record->uncoverable ) {
        $entry->{uncoverable} = 1;
        push @lines_info, $entry;
        next;
      }
      $entry->{count} = $sub_record->covered;
      push @lines_info, $entry;
    }
  }
  return \@lines_info;
}

sub _extract_runs {
  my ( $db, ) = @_;
  my @out;
  for my $r ( sort { $a->{start} <=> $b->{start} } $db->runs ) {
    my $entry = {
      start        => $r->start,
      finish       => $r->finish,
      os           => $r->OS,
      perl_version => $r->perl,
      run          => $r->run,
      time         => $r->finish - $r->start,
    };
    push @out, $entry;
  }
  return \@out;
}





sub report {
  my ( undef, $db, $options ) = @_;
  my $statements = {};
  my $branches   = {};
  my $subs       = {};
  my $runs       = _extract_runs( $db, $options );
  for my $file ( @{ $options->{file} } ) {
    $statements->{$file} = _extract_statements( $db, $file, $options );
  }
  for my $file ( @{ $options->{file} } ) {
    $branches->{$file} = _extract_branches( $db, $file, $options );
  }
  for my $file ( @{ $options->{file} } ) {
    $subs->{$file} = _extract_subroutines( $db, $file, $options );
  }

  $db->calculate_summary(
    statements => 1,
    branches   => 1,
    subs       => 1,
    conditions => 1,

    #        force      => 1,
  );
  my $report = {
    report_format => '0.1.0',
    statements    => $statements,
    branches      => $branches,
    subs          => $subs,
    runs          => $runs,
    summary       => $db->{summary},
  };
  require Devel::Cover::DB::IO::JSON;
  my $io = Devel::Cover::DB::IO::JSON->new( options => 'pretty' );
  $io->write( $report, "$options->{outputdir}/cover_detailed.json" );
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Cover::Report::Json_detailed - Generate a comprehensive JSON file articulating the full contents of a coverage run.

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

This is an attempt at extracting the contents of a C<Devel::Coverage> C<DB> into
a more useful format for the web.

  cover -report json_detailed

Emits:

  cover_db/cover_detailed.json

Which has at present the following data structure:

  {
    report_format => '0.1.0',
    branches      => {
      some_file => [@list_of_branch_reports],
      some_file => [@list_of_branch_reports],
    },
    runs       => [@list_of_run_reports],
    statements => {
      some_file => [@list_of_statement_reports],
      some_file => [@list_of_statement_reports],
    },
    subs => {
      some_file => [@list_of_sub_reports],
      some_file => [@list_of_sub_reports],
    },
    summary => {'???'},
  }

  Branch Report:
  {
    line           => 1,     # The Line Number
    code           => "",    # The code in question for the branch
    coverage_error => 1,     # Wether or not this is a coverage error
    uncoverable    => 1,     # If this is true, the following will be missing
    percentage     => " 50"  # The percent of covered branches
    true           => 5,       # The Number of covered branches
    false          => 5,       # The number of uncovered branches
  }

  Statement Report:
  {
    line           => 1,        # The Line Number
    code           => "",       # The code in question for the branch
    coverage_error => 1,        # Wether or not this is a coverage error
                                #---
                                # Any of the following may be eq "-" if they're not coverable.
    statement      => 5,        # Count of statement executions
    subroutine     => 5,        # Count of sub executions
    pod            => 1,        # Count of POD Coverage
    time           => 500,      # Time spent on statement
    branch         => " 50",    # Percent of covered branches
    condition      => " 50",    # Percent of covered conditions
  }

  Subroutine Report:
  {
    line        => 1,          # The Line Number
    name        => "BEGIN",    # The name of the subroutine
    uncoverable => 1,          # If this is true, the following will be missing.
    count       => 10,         # The number of sub executions
  }

  Run Report:
  {
    start        => UNIXTIME,          # When the given test run started
    finish       => UNIXTIME,          # when the given test run stopped
    os           => "linux",           # The operating system the run ran on
    perl_version => "5.12.3",          # The version of perl the run ran on
    run          => "path/foo.t",      # The invoked script
    time         => finish - start,    # Convenience time-elapsed
  }

Though its very experimental because I'm still working out how the (Undocumented) guts of C<Devel::Cover> works.

Some of the fields feel wrongly named too but are kept because they're the same as C<Devel::Cover>'s internals and I can't think of something better in the interim.

But if I change anything significant, I'll also change the C<report_format> string.

=for Pod::Coverage report

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
