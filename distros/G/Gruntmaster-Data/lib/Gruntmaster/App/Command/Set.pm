package Gruntmaster::App::Command::Set;

use 5.014000;
use warnings;

our $VERSION = '6000.001';

use Gruntmaster::App '-command';
use Gruntmaster::Data;

use File::Slurp qw/read_file/;

use constant PAGES => {
	contests => '/ct/',
	jobs     => '/log/',
	problems => '/pb/',
	users    => '/us/',
};

sub opt_spec {
	['file!', 'Use the contents of a file as value']
}

sub usage_desc { "%c [-cjpu] set id column value [column value ...]\n%c [-cjpu] set --file id column filename [column filename ...]" }

sub validate_args {
	my ($self, $opt, $args) = @_;
	my @args = @$args;
	$self->usage_error('No table selected') unless $self->app->table;
	$self->usage_error('Not enough arguments provided') if @args < 3;
	$self->usage_error('The number of arguments must be odd') unless @args % 2;
}

sub execute {
	my ($self, $opt, $args) = @_;
	my ($id, %values) = @$args;
	%values = map { $_ => scalar read_file $values{$_} } keys %values if $opt->{file};
	db->update($self->app->table, \%values, {id => $id});
	purge PAGES->{$self->app->table}.$_ for '', $id;
}

1;
__END__

=encoding utf-8

=head1 NAME

Gruntmaster::App::Command::Set - set a property of an object

=head1 SYNOPSIS

  gm -u set MGV name 'Marius Gavrilescu'
  gm -p set aplusb level beginner
  gm -c set test_ct 'This is a <b>test</b> contest.<br>Nothing to see here'
  gm -j set 100 result_text Accepted

=head1 DESCRIPTION

The set command takes three arguments: an object id, a property name,
and a value. It sets the given property of the given object to the
given value.

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
