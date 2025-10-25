package Devel::StatProfiler::SectionGuard;
use 5.12.0;
use warnings;

sub new {
  my $class = shift;
  my $self = bless({@_} => $class);
  Devel::StatProfiler::start_section($self->{section_name});
  return $self;
}

sub section_name { $_[0]->{section_name} }

sub DESTROY {
  my $self = shift;
  Devel::StatProfiler::end_section($self->{section_name});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::StatProfiler::SectionGuard

=head1 VERSION

version 0.56

=head1 AUTHORS

=over 4

=item *

Mattia Barbon <mattia@barbon.org>

=item *

Steffen Mueller <smueller@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Mattia Barbon, Steffen Mueller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
