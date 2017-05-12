package Gapp::Gtk2;
{
  $Gapp::Gtk2::VERSION = '0.60';
}

use Gtk2;
use Gapp::Gtk2::DateEntry;
use Gapp::Gtk2::TimeEntry;
use Gapp::Gtk2::Model::List;
use Gapp::Gtk2::Model::SimpleList;

1;


__END__

=pod

=head1 NAME

Gapp::Gtk2 - Gtk2 Widget Extension

=head1 SYNOPSIS

  use Gtk2 '-init';

  use Gapp::Gtk2;

  # date entry widget

  $e = Gapp::Gtk2::DateEntry->new;

  # time entry widget

  $e = Gapp::Gtk2::TimeEntry->new;

  # models that hold arbitrary data

  $list = Gapp::Gtk2::Model::SimpleList->new;

  $list->append( $anything );

   
=head1 DESCRIPTION

These additional widgets were created for use with L<Gapp>. You can use them
without the Gapp layer by using L<Gapp::Gtk2>.

=head1 SEE ALSO

=over 4

=item L<Gapp>

=back

=head1 AUTHOR

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT

    Copyright (c) 22012 Jeffrey Ray Hallock.
    
    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

