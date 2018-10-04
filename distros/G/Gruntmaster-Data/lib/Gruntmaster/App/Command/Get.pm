package Gruntmaster::App::Command::Get;

use 5.014000;
use warnings;

our $VERSION = '6000.001';

use Gruntmaster::App '-command';
use Gruntmaster::Data;

sub usage_desc { '%c [-cjpu] get id column' }

sub validate_args {
	my ($self, $opt, $args) = @_;
	my @args = @$args;
	$self->usage_error('No table selected') unless $self->app->table;
	$self->usage_error('Wrong number of arguments') if @args != 2;
}

sub execute {
	my ($self, $opt, $args) = @_;
	my ($obj, $col) = @$args;
	say db->select($self->app->table, $col, {id => $obj})->flat
}

1;
__END__

=encoding utf-8

=head1 NAME

Gruntmaster::App::Command::Get - get a property of an object

=head1 SYNOPSIS

  gm -u get MGV name
  # Marius Gavrilescu

  gm -p get aplusb level
  # beginner

  gm -c get test_ct description
  # This is a <b>test</b> contest.<br>
  # Nothing to see here.

  gm -j get 100 result_text
  # Accepted

=head1 DESCRIPTION

The get command takes two arguments: an object id and a property name,
and returns the value of that property.

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
