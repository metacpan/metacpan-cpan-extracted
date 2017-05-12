# HTML::Macro::Loop; Loop.pm
# Copyright (c) 2001,2002 Michael Sokolov and Interactive Factory. All rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package HTML::Macro::Loop;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '1.06';


# Preloaded methods go here.

sub new ($$$)
{
    my ($class, $page) = @_;
    my $self = {
        'vars' => [],
        'rows' => [],
        '@parent' => $page,
        };
    bless $self, $class;
    return $self;
}

sub declare ($@)
# use this to indicate which vars are expected in each iteration.
# Fills the vars array.
{
    my ($self, @vars) = @_;
    @ {$$self {'vars'}} = @vars;
}

sub push_array ($@)
# values must be pushed in the same order as they were declared, and all
# must be present
{
    my ($self, @vals) = @_;
    die "HTML::Macro::Loop::push_array: number of vals pushed(" . (@vals+0) . ") does not match number declared: " . (@ {$$self{'vars'}} + 0)
        if (@vals + 0 != @ {$$self{'vars'}});
    my $row = &new_row;
    my $i = 0;
    foreach my $var (@ {$$self{'vars'}})
    {
        $row->set ($var, $vals[$i++]);
    }
    push @ {$$self{'rows'}}, $row;
}

sub new_row
{
    my ($self) = @_;
    my $row = new HTML::Macro;
    $row->set ('@parent', $self);
    $row->{'@attr'} = $self->{'@parent'}->{'@attr'};
    $row->{'@incpath'} = $self->{'@parent'}->{'@incpath'};
    return $row;
}

sub pushall_arrays ($@)
# values must be pushed in the same order as they were declared, and all
# must be present.  Arg is an array filled with refs to arrays for each row
{
    my ($self, @rows) = @_;
    foreach my $row (@rows) {
        $self->push_array (@$row);
    }
}

sub push_hash ($$)
# values passed with var labels so they may come in any order and some may be 
# absent (in which case zero is subtituted).  However, any values passed whose
# vars were not declared are -silently- ignored unless there has been no 
# declaration, in which case the keys of the hash are accepted as an implicit 
# declaration.
{
    my ($self, $pvals) = @_;
    my @ordered_vals;
    my $row = &new_row;
    $self->declare (keys %$pvals) if (!@ {$$self{'vars'}}) ;
    my $i = 0;
    foreach my $var (@ {$$self{'vars'}})
    {
        $row->set ($var, defined($$pvals{$var}) ? $$pvals{$var} : '');
    }
    push @ {$$self{'rows'}}, $row;;
}

sub set ($@ )
# set more values in the most recent row, or add a row if none exists
{
    my $self = shift;
    if (! $$self{'rows'} )
    {
        $self->push_hash (\@_);
    } else {
        my $rows = $$self{'rows'};
        my $row = $$rows[$#$rows];
        $row->set (@_);
    }
}

sub set_hash ($$ )
# set more values in the most recent row, or add a row if none exists
{
    my $self = shift;
    if (! $$self{'rows'} )
    {
        $self->push_hash (@_);
    } else {
        my $rows = $$self{'rows'};
        my $row = $$rows[$#$rows];
        $row->set_hash (@_);
    }
}

sub get ()
# get values from the most recent row
{
    my ($self, $var) = @_;
    my $rows = $$self{'rows'};
    if ($rows) {
        my $row = $$rows[$#$rows];
        return $row->get($var);
    }
    return undef;
}

sub doloop ($$$$ )
# perform repeated processing a-la HTML::Macro on the loop body $body,
# concatenate the results and return that.
{
    my ($self, $body, $separator, $separator_final, $collapse) = @_;
    my $buf = '';
    my $markup_seen;
    my @row_output;
    foreach my $row (@ {$$self{'rows'}})
    {
        $row->{'@cwd'} = $self->{'@parent'}->{'@cwd'};
        $row->{'@dynamic'} = $self->{'@dynamic'};
        my $row_markup = $row->process_buf ($body);
        next if ($collapse && !$row_markup);
        push @row_output, $row_markup;
    }
    my $n = scalar @row_output;
    foreach my $row_markup (@row_output)
    {
        -- $n;
        next if ($collapse && !$row_markup);
        if ($markup_seen) {
            # show a separator (we skip if collapse and the row generated no content)
            if ($separator_final && $n == 0) {
                $buf .= $separator_final;
            } elsif ($separator) {
                $buf .= $separator;
            }
        }
        $buf .= $row_markup;
        $markup_seen = 1;
    }
    return $buf;
}


sub new_loop ()
{
    my ($self, $name, @loop_vars) = @_;

    my $rows = $$self{'rows'};
    die "HTML::Loop::new_loop: no rows in loop - call a push method" if !@$rows;
    my $new_loop = new HTML::Macro::Loop ($$rows [$#$rows]);

    if ($name) {
        $self->set ($name, $new_loop);
    }
    if (@loop_vars) {
        $new_loop->declare (@loop_vars);
    }
    return $new_loop;
}

sub is_empty ()
{
    my ($self) = @_;
    return ! ($self->{'rows'} && (@ {$self->{'rows'}} > 0));
}

sub keys ()
{
    my ($self) = @_;
    return () if $self->is_empty();
    my $rows = $$self{'rows'};
    return ($$rows [$#$rows])->keys();
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

HTML::Macro::Loop - looping construct for repeated HTML blocks

=head1 SYNOPSIS

  use HTML::Macro;
  use HTML::Macro::Loop;
  $htm = HTML::Macro->new();
  $loop = $htm->new_loop('loop-body', 'id', 'name', 'phone');
  $loop->push_array (1, 'mike', '222-2389');
  $loop->push_hash ({ 'id' => 2, 'name' => 'lou', 'phone' => '111-2389'});
  $htm->print ('test.html');

=head1 DESCRIPTION

  HTML::Macro::Loop processes tags like 

<loop id="loop-tag"> loop body </loop>

    Each loop body is treated as a nested HTML::Macro within which variable
substitutions, conditions and nested loops are processed as described under
HTML::Macro. For complete documentation see HTML::Macro.
=head1 AUTHOR

Michael Sokolov, sokolov@ifactory.com

=head1 SEE ALSO HTML::Macro

perl(1).

=cut

