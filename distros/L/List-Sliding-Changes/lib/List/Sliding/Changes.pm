package List::Sliding::Changes;
use strict;

use Exporter;
use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Carp qw(croak);

$VERSION     = 0.03;
@ISA         = qw (Exporter);

@EXPORT_OK   = qw ( &find_new_indices &find_new_elements );

=head1 NAME

List::Sliding::Changes - Extract new elements from a sliding window

=head1 SYNOPSIS

=for example begin

  use strict;
  use Tie::File;
  use List::Sliding::Changes qw(find_new_elements);

  my $filename = 'log.txt';
  my @log;
  tie @log, 'Tie::File', $filename
    or die "Couldn't tie to $filename : $!\n";

  # See what has happened since we last polled
  my @status = get_last_20_status_messages();

  # Find out what we did not already communicate
  my (@new) = find_new_elements(\@log,\@status);
  print "New log messages : $_\n"
    for (@new);

  # And update our log with what we have seen
  push @log, @new;

=for example end

=head1 DESCRIPTION

This module allows you to easily find elements that were appended
to one of two lists. It is intended to faciliate processing wherever
you don't have a log but only a sliding window for events, such as
a status window which only displays the 20 most recent events,
without timestamp.

The module assumes that the update frequency is high and will always
respect the longest overlap between the two sequences. To be a bit
faster with long lists, it searches the first list from the end,
assuming that the first list will be much longer than the second list.

=head1 PUBLIC METHODS

find_new_indices( \@OLDLIST, \@NEWLIST [, EQUALITY] )

Returns the list of indices that were added since the last time @OLDLIST
was updated. This is convenient if you want to modify @NEWLIST afterwards.
The function accepts an optional third parameter, which should be a
reference to a function that takes two list elements and compares them
for equality.

find_new_elements( \@OLDLIST, \@NEWLIST [, EQUALITY] )

Returns the list of the elements that were added since the last time @OLDLIST
was updated.

=cut

sub find_new_indices {
  my ($old,$new,$equal) = @_;
  croak "First parameter to find_new_elements() must be a reference, not $old" unless ref $old;
  croak "Second parameter to find_new_elements() must be a reference, not $new" unless ref $new;
  $equal ||= sub { $_[0] eq $_[1] };

  my ($new_offset,$old_offset) = (0,scalar @$old - scalar @$new);
  $old_offset = 0 if $old_offset < 0;

  while ($old_offset < scalar @$old) {
    $new_offset = 0;
    while (($old_offset+$new_offset < scalar @$old)
       and ($new_offset < scalar @$new)
       and ($equal->($old->[$old_offset+$new_offset],$new->[$new_offset]))) {
      $new_offset++;
    };
    last if ($old_offset+$new_offset == scalar @$old);
    $old_offset++;
  };

  ($new_offset .. $#$new)
};

sub find_new_elements {
  my ($old,$new,$equal) = @_;
  croak "First parameter to find_new_elements() must be a reference, not $old" unless ref $old;
  croak "Second parameter to find_new_elements() must be a reference, not $new" unless ref $new;

  (@{$new}[ find_new_indices($old,$new,$equal) ])
};

1;
__END__

=head1 BUGS

More tests are always welcome !

=head1 AUTHOR

  Max Maischein <corion@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003-2008 Max Maischein. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1),
L<File::Tail> for a solution working only with files,
L<Text::Diff> and L<Algorithm::Diff> for a more holistic approach.
