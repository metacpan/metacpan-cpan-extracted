package Gruntmaster::App::Command::Rm;

use 5.014000;
use warnings;

our $VERSION = '6000.001';

use Gruntmaster::App '-command';
use Gruntmaster::Data;

sub usage_desc { '%c [-cjpu] rm id' }

sub validate_args {
	my ($self, $opt, $args) = @_;
	my @args = @$args;
	$self->usage_error('No table selected') unless $self->app->table;
	$self->usage_error('Wrong number of arguments') if @args != 1;
}

sub execute {
	my ($self, $opt, $args) = @_;
	my ($obj) = @$args;
	say 'Rows deleted: ', db->delete($self->app->table, {id => $obj})->rows
}

1;
__END__

=encoding utf-8

=head1 NAME

Gruntmaster::App::Command::Rm - remove an object

=head1 SYNOPSIS

  gm -c rm test_contest
  gm -p rm aplusb
  gm -j rm 10
  gm -u rm MGV

=head1 DESCRIPTION

The rm command takes the ID of an object and removes it.

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
