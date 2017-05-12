package Games::Nonogram::Shell;

use strict;
use warnings;
use Games::Nonogram::Grid;

my @has_aliases = qw( auto load row col quit exit );

sub bootstrap {
  my $class = shift;
  my $self  = bless {}, $class;

  # set aliases
  my %alias;
  foreach my $cmd ( @has_aliases ) {
    $alias{ substr( $cmd, 0, 1 ) } = $cmd;
  }

  while ( print '> ' ) {
    my $input = <STDIN>;
    $input = '' unless defined $input;
    chomp $input;

    my ($cmd, $args) = split /\s+/, $input, 2;

    $cmd = '_next' unless defined $cmd;

    $cmd = $alias{$cmd} if exists $alias{$cmd};

    last if $cmd eq 'quit' || $cmd eq 'exit';
    next if $cmd eq 'bootstrap';

    $self->$cmd( $args ) if $self->can( $cmd );
  }
  $self;
}

sub load {
  my ($self, $file) = @_;

  return unless $file && -f $file;

  my $grid = Games::Nonogram::Grid->new_from( file => $file );
     $grid->as_string;
     $grid->clear_stash;

  $self->{grid} = $grid;
}

sub logfile {
  my ($self, $file) = @_;

  my $grid = $self->{grid} or return;

  $grid->set_logfile( $file );
}

sub _next {
  my $self = shift;

  my $grid = $self->{grid} or return;

  if ( $grid->has_answers ) {
    print "\nAnswers\n", join "\n", $grid->answers, "\nOK\n";
  }
  elsif ( $grid->is_done ) {
    $grid->as_string;
    print "\nOK\n";
  }
  else {
    $grid->update;
    $grid->as_string;

    print "\nOK\n" if $grid->is_done;
  }
}

sub auto {
  my $self = shift;

  my $grid = $self->{grid} or return;

  while ( $grid->is_dirty ) {
    $grid->update;
    print $grid->as_string, "\n" if $grid->debug;
  }

  if ( $grid->is_done or $grid->has_answers ) {
    print "\nAnswers\n", join "\n", $grid->answers, "\nOK\n";
  }
  else {
    print $grid->as_string,"\n";
    print "\nAborted\n";
  }
}

sub row {
  my ($self, $row) = @_;

  return unless $row && $row =~ /^\d+$/;

  my $grid = $self->{grid} or return;

  $grid->row( $row )->dump_blocks;
}

sub col {
  my ($self, $col) = @_;

  return unless $col && $col =~ /^\d+$/;

  my $grid = $self->{grid} or return;

  $grid->col( $col )->dump_blocks;
}

sub on    { shift->_value(  1, @_ ) }
sub off   { shift->_value(  0, @_ ) }
sub clear { shift->_value( -1, @_ ) }

sub _value {
  my ($self, $value, $args) = @_;

  my ($row, $col) = split /,\s*/, $args;

  return unless $row && $row =~ /^\d+$/;
  return unless $col && $col =~ /^\d+$/;

  my $grid = $self->{grid} or return;

  eval {
    $grid->row( $row )->value( $col => $value );
    $grid->update;
    $grid->as_string;
  };
  if ( $@ ) {
    print "That would break the puzzle.";
  }
}

sub debug {
  my ($self, $value) = @_;

  my $grid = $self->{grid} or return;

  $value = 1 unless defined $value;

  $grid->debug( $value );
}

1;

__END__

=head1 NAME

Games::Nonogram::Shell

=head1 SYNOPSIS

  use Games::Nonogram::Shell;
  Games::Nonogram::Shell->bootstrap;

=head1 DESCRIPTION

This is used internally to handle pseudo-shell interface. Following commands are available in the shell. If you want to solve a loaded puzzle step by step, just hit enter/return key (without commands).

=head1 METHOD/COMMANDS

=head2 load (shortcut: l)

loads data from the given file.

=head2 logfile

defines a log file.

=head2 auto (shortcut: a)

starts solving to the end.

=head2 row (shortcut: r)

dumps a stringified form of the given row.

=head2 col (shortcut: c)

dumps a stringified form of the given column.

=head2 on

turns on the given cell (row, col).

=head2 off

turns off the given cell (row, col).

=head2 clear

clears (undefines) the given cell (row, col).

=head2 debug

sets a debug flag.

=head2 exit/quit (shortcut: e/q)

leaves shell mode.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Kenichi Ishigaki

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
