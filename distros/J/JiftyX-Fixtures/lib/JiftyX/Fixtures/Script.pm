package JiftyX::Fixtures::Script;
our $VERSION = '0.07';

# ABSTRACT: Main script package handling dispatch for subcommands

use strict;
use warnings;

use App::CLI;
use base qw(App::CLI App::CLI::Command);

sub options {
  return (
    'h|help|?'  => 'help',
    'man'     => 'man',
  );
}

sub before_run {
  my ($here, $self) = @_;

  if ($self->{help}) {
    print "jiftyx-fixtures v$JiftyX::Fixtures::VERSION\n";
    eval 'print $' . ref($self) . '::help_msg';
    exit;
  }

}

sub run {
  my ($here, $self) = @_;
}


1;

__END__
=head1 NAME

JiftyX::Fixtures::Script - Main script package handling dispatch for subcommands

=head1 VERSION

version 0.07

=head1 AUTHOR

  shelling <shelling@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by <shelling@cpan.org>.

This is free software, licensed under:

  The MIT (X11) License

