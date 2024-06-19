package ExtUtils::Builder::MultiLingual;
$ExtUtils::Builder::MultiLingual::VERSION = '0.007';
use strict;
use warnings;

use Carp ();

sub _init {
	my ($self, %args) = @_;
	$self->{language} = $args{language} or Carp::croak('language missing');
	return;
}

sub language {
	my $self = shift;
	return $self->{language};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::MultiLingual

=head1 VERSION

version 0.007

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
