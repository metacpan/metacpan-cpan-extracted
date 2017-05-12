package JiftyX::Fixtures::Script::Help;
our $VERSION = '0.07';

# ABSTRACT: help subcommands

use warnings;
use strict;

use base qw(
  App::CLI::Command::Help
);

sub run {
  my $self = shift;

  if ($self->{config}->{fixtures}) {
    $self->SUPER(@_);
  } else {
    print $self->{config}->{app_root} . " is not existed. Please run `jiftyx-fixtures init`\n";
  }

}



1;

__END__
=head1 NAME

JiftyX::Fixtures::Script::Help - help subcommands

=head1 VERSION

version 0.07

=head1 AUTHOR

  shelling <shelling@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by <shelling@cpan.org>.

This is free software, licensed under:

  The MIT (X11) License

