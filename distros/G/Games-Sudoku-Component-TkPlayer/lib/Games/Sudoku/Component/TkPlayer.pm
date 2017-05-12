package Games::Sudoku::Component::TkPlayer;

use strict;
use warnings;

our $VERSION = '0.02';

use Tk;
use Games::Sudoku::Component::TkPlayer::View;
use Games::Sudoku::Component::TkPlayer::Controller;
use Games::Sudoku::Component::Controller;

sub bootstrap {
  my $self = shift;

  my $view = Games::Sudoku::Component::TkPlayer::View->new(
    mw  => MainWindow->new,
    sdk => Games::Sudoku::Component::Controller->new,
    cmd => Games::Sudoku::Component::TkPlayer::Controller->new,
    ver => $VERSION,
  );

  $view->create;

  MainLoop;

  print "Thank you for playing!\n";
}

1;

__END__

=head1 NAME

Games::Sudoku::Component::TkPlayer - Let's play Sudoku

=head1 SYNOPSIS

    use Games::Sudoku::Component::TkPlayer;
    Games::Sudoku::Component::TkPlayer->bootstrap;

=head1 DESCRIPTION

This is a sample application for Games::Sudoku::Component I presented at
YAPC::Asia 2006. You usually don't have to bother with internals. Just
run "tksudoku.pl" and enjoy!

=head1 METHOD

=over 4

=item bootstrap

prepares widgets and runs main loop.

=back

=head1 SEE ALSO

L<Tk>, L<Games::Sudoku::Component>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
