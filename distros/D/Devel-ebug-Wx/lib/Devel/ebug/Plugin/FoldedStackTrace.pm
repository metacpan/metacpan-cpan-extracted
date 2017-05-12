package Devel::ebug::Plugin::FoldedStackTrace;

use strict;
use base qw(Exporter);

our @EXPORT = qw(folded_stack_trace);

=head1 NAME

Devel::ebug::Plugin::FoldedStackTrace - programmer-friendly stack traces

=head1 SYNOPSIS

  my @folded_frames = $ebug->folded_stack_trace;
  foreach my $frame ( @folded_frames ) {
      # use all Devel::StackTraceFrame accessor, plus
      # caller_package caller_subroutine caller_filename caller_line
      # current_package current_subroutine current_filename current_line
  }
  # main's current_subroutine is 'MAIN::'
  print $folded_frame[-1]->current_subroutine;

=head1 DESCRIPTION

Each C<Devel::StackTraceFrame> object in a stack trace includes some
information about the caller and some information about the current
frame, and remembering which information lies where is hard.  Plus,
some information about the topmost (main or similar) stack frame is
missing.

This plugin provides an easier-to use C<Devel::StackTraceFrame> subclass.

=cut

use Devel::StackTrace;

# folds current/caller frame in every item, includes main and
# current frame
sub folded_stack_trace {
    my( $self ) = @_;
    my @frames = $self->stack_trace;
    my @folded = Devel::ebug::Plugin::Wx::StackTraceFrame
                   ->fold_frame_list( $self, @frames );

    return @folded;
}

package Devel::ebug::Plugin::Wx::StackTraceFrame;

use strict;
use base qw(Devel::StackTraceFrame Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors
  ( qw(caller_package current_package caller_subroutine current_subroutine
       caller_filename current_filename caller_line current_line) );

sub new {
    my( $class, $args ) = @_;
    my $self = bless { %$args }, $class;

    return $self;
}

sub new_from_frame {
    my( $class, $frame ) = @_;
    my $self = bless { %$frame }, $class;

    $self->{current_subroutine} = $self->{subroutine};
    $self->{caller_package} = $self->{package};
    $self->{caller_filename} = $self->{filename};
    $self->{caller_line} = $self->{line};

    return $self;
}

sub fold_frame_list {
    my( $class, $ebug, @frames ) = @_;
    my @folded = map $class->new_from_frame( $_ ), @frames;

    # main
    push @folded, $class->new
      ( { current_package    => @frames ? $frames[-1]->package  : undef,
          current_filename   => @frames ? $frames[-1]->filename : undef,
          current_line       => @frames ? $frames[-1]->line     : undef,
          current_subroutine => 'MAIN::',
          args               => [],
          } );
    # current
    $folded[0]->{current_package} = $ebug->package;
    $folded[0]->{current_filename} = $ebug->filename;
    $folded[0]->{current_line} = $ebug->line;

    # propagate current_* down the call chain
    for( my $i = 1; $i < @folded; ++$i ) {
        $folded[$i]->{current_package} = $folded[$i-1]->caller_package;
        $folded[$i]->{current_filename} = $folded[$i-1]->caller_filename;
        $folded[$i]->{current_line} = $folded[$i-1]->caller_line;
    }

    # propagate caller_subroutine up the call chain
    for( my $i = @folded - 1; $i > 0; --$i ) {
        $folded[$i-1]->{caller_subroutine} = $folded[$i]->current_subroutine;
    }

    return @folded;
}

1;
