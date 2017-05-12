package Mac::Choose;
use base qw(Exporter);

use strict;
use warnings;

use IPC::Open2 qw(open2);
use File::ShareDir qw(dist_file);

# use the executable that shipped with this module
our $executable_path = dist_file("Mac-Choose","choose");

our $VERSION = 2;
our @EXPORT_OK;

sub choose(@) {
   my @choices = @_
   	 or return undef;

    my ($chld_out, $chld_in);
    my $pid = open2($chld_out, $chld_in, $executable_path);

    # send each of the options
    foreach (@choices) {
    	next unless defined && length;
    	print $chld_in $_, "\n";
    }
    close $chld_in;

    my $result = <$chld_out>;
    return $result;
}
push @EXPORT_OK, "choose";

1;

__END__

=head1 NAME

Mac::Choose - make a choice with the choose command line util

=head1 SYNOPSIS

   use Mac::Choose qw(choose);
   my $color = choose qw(
   	  red
   	  orange
   	  yellow
   	  green
   	  blue
   	  indigo
   	  violet
   ) or die "User canceled selection";

=head1 DESCRIPTION

C<choose> is a commercial commandline utility for OS X from
Tiny Robot Software that shows a simple fuzzy-matching GUI for
selecting from one of several options.

   http://tinyrobotsoftware.com/choose/

This module is a really really thin wrapper around it that
handles installing the command line utility and provides
a function to do the shelling out to C<choose> via IPC::Open2.

While installing this module installs a copy of choose, if
you continue to use this code beyond the time unlimited trial
you should purchase a license from Tiny Robot Software

  https://sites.fastspring.com/tinyrobotsoftware/instant/choose

=head2 Function

This module exports one function on request, or you can call
it fully qualified.

=over

=item choose @possibilities

Shows the GUI allowing the user to pick from the possibilities.
Returns the selected option, or undef if the user canceled
the selection (by hitting ESC / clicking outside the dialog.)

=back

=head2 Configuring

This module uses the copy of C<choose> distributed with the
module distribution by default.  If you've
installed C<choose> somewhere else and you want to use that,
you can use the L<$Mac::Choose:
:executable_path> to
override the path to the executable.

   local $Mac::Choose::executable_path = "/stuff/bin/choose";
   my $char = choose "Buffy","Willow","Xander","Tara","Oz";

=head1 BUGS

Bugs (and requests for new features) can be reported though the CPAN
RT system: L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mac-Choose>

Alternatively, you can simply fork this project on github and
send me pull requests.  Please see L<http://github.com/2shortplanks/Mac-Choose>

=head1 AUTHOR

Written by Mark Fowler <mark@twoshortplanks.com>

=head1 COPYRIGHT

Copyright Mark Fowler 2014.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

The choose command line utility itself is copyright Tiny Robot Software.
Neither Mark Fowler nor this Perl library is associated with the choose
command line utility or Tiny Robot Software (though Tiny Robot Software
did give permission for choose to be distributed with this module
when asked.)

=head1 SEE ALSO

L<http://tinyrobotsoftware.com/choose/>


