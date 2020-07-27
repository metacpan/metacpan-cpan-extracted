package Devel::ebug::Plugin::Run;

use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(undo run return step next);

our $VERSION = '0.63'; # VERSION

# undo
sub undo {
  my($self, $levels) = @_;
  $levels ||= 1;
  my $response = $self->talk({ command => "commands" });
  my @commands = @{$response->{commands}};
  pop @commands foreach 1..$levels;
#  use YAML; warn Dump \@commands;
  my $proc = $self->proc;
  $proc->die;
  $self->load;
  $self->talk($_) foreach @commands;
  $self->basic;
}



# run until a breakpoint
sub run {
  my($self) = @_;
  my $response = $self->talk({ command => "run" });
  $self->basic; # get basic information for the new line
}


# return from a subroutine
sub return {
  my($self, @values) = @_;
  my $values;
  $values = \@values if @values;
  my $response = $self->talk({
    command => "return",
    values  => $values,
 });
  $self->basic; # get basic information for the new line
}



# step onto the next line (going into subroutines)
sub step {
  my($self) = @_;
  my $response = $self->talk({ command => "step" });
  $self->basic; # get basic information for the new line
}

# step onto the next line (going over subroutines)
sub next {
  my($self) = @_;
  my $response = $self->talk({ command => "next" });
  $self->basic; # get basic information for the new line
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::ebug::Plugin::Run

=head1 VERSION

version 0.63

=head1 AUTHOR

Original author: Leon Brocard E<lt>acme@astray.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Brock Wilcox E<lt>awwaiid@thelackthereof.orgE<gt>

Taisuke Yamada

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2020 by Leon Brocard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
