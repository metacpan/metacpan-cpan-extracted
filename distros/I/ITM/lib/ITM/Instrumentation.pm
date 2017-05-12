package ITM::Instrumentation;
our $AUTHORITY = 'cpan:GETTY';
$ITM::Instrumentation::VERSION = '0.002';
use Moo;
use ITM;

with qw( ITM::Role );

sub type { ITM_INSTRUMENTATION() }

has source => (
  is => 'ro',
  required => 1,
);

1;

__END__

=pod

=head1 NAME

ITM::Instrumentation

=head1 VERSION

version 0.002

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUPPORT

IRC

  Join #hardware on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-itm
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-itm/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
