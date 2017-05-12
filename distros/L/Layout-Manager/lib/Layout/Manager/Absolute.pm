package Layout::Manager::Absolute;
use Moose;

extends 'Layout::Manager';

__PACKAGE__->meta->make_immutable;

no Moose;

1;
__END__
=head1 NAME

Layout::Manager::Absolute - No frills layout manager

=head1 DESCRIPTION

Does nothing.  Expects that all components will be positioned already.

=head1 SYNOPSIS

  $cont->add_component($comp1);
  $cont->add_component($comp2);

  my $lm = Layout::Manager::Absolute->new;
  $lm->do_layout($cont);

=head1 METHODS

=head2 do_layout

Size and position the components in this layout.

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 by Cory G Watson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.