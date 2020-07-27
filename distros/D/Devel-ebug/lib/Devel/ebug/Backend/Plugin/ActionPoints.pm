package Devel::ebug::Backend::Plugin::ActionPoints;

use strict;
use warnings;
use File::Spec;

our $VERSION = '0.63'; # VERSION

sub register_commands {
  return (
  break_point => { sub => \&break_point, record => 1 },
  break_points => { sub => \&break_points },
  break_points_with_condition => { sub => \&break_points_with_condition },
  all_break_points_with_condition => { sub => \&all_break_points_with_condition },
  break_point_delete => { sub => \&break_point_delete, record => 1 },
  break_point_subroutine => { sub => \&break_point_subroutine, record => 1 },
  watch_point => { sub => \&watch_point, record => 1 },
  break_on_load => { sub => \&break_on_load },
  );
}
sub break_point {
  my($req, $context) = @_;
  my $line = set_break_point($req->{filename}, $req->{line}, $req->{condition});
  return $line ? { line => $line } : {};
}

sub break_points {
  my($req, $context) = @_;
  use vars qw(@dbline %dbline);
  my $filename = $req->{filename} || $context->{filename};
  *DB::dbline = $main::{ '_<' . $filename };
  my $break_points = [
    sort { $a <=> $b }
    grep { $DB::dbline{$_} }
    keys %DB::dbline
  ];
  return { break_points => $break_points };
}

sub break_points_with_condition {
  my($req, $context) = @_;
  use vars qw(@dbline %dbline);
  my $filename = $req->{filename} || $context->{filename};
  *DB::dbline = $main::{ '_<' . $filename };
  my $break_points = [
    map  { my $c = $DB::dbline{$_};
           { filename => $filename, line => $_,
             ( $c && $c != 1 ) ? ( condition => $c ) : () } }
    sort { $a <=> $b }
    grep { $DB::dbline{$_} }
    keys %DB::dbline
  ];
  return { break_points => $break_points };
}

sub all_break_points_with_condition {
  my($req, $context) = @_;
  use vars qw(@dbline %dbline);
  my $files = Devel::ebug::Backend::Plugin::Filenames::filenames
                  ( $req, $context ); # breaks encapsulation
  my @break_points;
  foreach my $file ( sort @{$files->{filenames}} ) {
    *DB::dbline = $main::{ '_<' . $file };
    push @break_points,
      map  { my $c = $DB::dbline{$_};
             { filename => $file, line => $_,
               ( $c && $c != 1 ) ? ( condition => $c ) : () } }
       sort { $a <=> $b }
       grep { $DB::dbline{$_} }
       keys %DB::dbline;
  }
  return { break_points => \@break_points };
}

sub break_point_delete {
  my($req, $context) = @_;
  use vars qw(@dbline %dbline);
  *DB::dbline = $main::{ '_<' . $req->{filename} };
  $DB::dbline{$req->{line}} = 0;
  return {};
}

sub break_point_subroutine {
  my($req, $context) = @_;
  my($filename, $start, $end) = $DB::sub{$req->{subroutine}} =~ m/^(.+):(\d+)-(\d+)$/;
  my $line = set_break_point($filename, $start);
  return $line ? { line => $line } : {};
}

sub watch_point {
  my($req, $context) = @_;
  my $watch_point = $req->{watch_point};
  push @{$context->{watch_points}}, $watch_point;
  return {};
}


# set a break point
sub set_break_point {
  my($filename, $line, $condition) = @_;
  $condition ||= 1;
  *DB::dbline = $main::{ '_<' . $filename };

  # move forward until a line we can actually break on
  while (1) {
    return 0 if not defined $DB::dbline[$line]; # end of code
    last unless $DB::dbline[$line] == 0; # not breakable
    $line++;
  }
  $DB::dbline{$line} = $condition;
  return $line;
}

#set a break point on file loading
sub break_on_load{
  my($req, $context) = @_;
  my $filename = $req->{filename};

  $DB::break_on_load{$filename} = 1;

  if (!File::Spec->file_name_is_absolute( $filename )){
      #add the absolute path
    $filename = File::Spec->rel2abs( $filename);
    $DB::break_on_load{$filename} = 1;
  }

  return {};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::ebug::Backend::Plugin::ActionPoints

=head1 VERSION

version 0.63

=head1 AUTHOR

Original author: Leon Brocard E<lt>acme@astray.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Brock Wilcox E<lt>awwaiid@thelackthereof.orgE<gt>

Taisuke Yamada

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2020 by Leon Brocard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
