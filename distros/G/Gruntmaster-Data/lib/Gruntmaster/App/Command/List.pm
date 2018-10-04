package Gruntmaster::App::Command::List;

use 5.014000;
use warnings;

our $VERSION = '6000.001';

use Gruntmaster::App '-command';
use Gruntmaster::Data;

sub usage_desc { '%c [-cjpu] list' }

sub validate_args {
	my ($self, $opt, $args) = @_;
	my @args = @$args;
	$self->usage_error('No table selected') unless $self->app->table;
}

sub execute {
	my ($self, $opt, $args) = @_;
	say join "\n", db->select($self->app->table, 'id', {}, 'id')->flat
}

1;
__END__

=encoding utf-8

=head1 NAME

Gruntmaster::App::Command::List - list all objects of a type

=head1 SYNOPSIS

  gm -c list
  # test_contest
  # some_other_contest

  gm -j list # This is pretty pointless
  # 1
  # 2
  # 3

  gm -p list
  # aplusb
  # aminusb

  gm -u list
  # MGV
  # nobody

=head1 DESCRIPTION

The list command lists the IDs of all objects of a type, one per line.
The list is sorted.

=head1 SEE ALSO

L<gm>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
