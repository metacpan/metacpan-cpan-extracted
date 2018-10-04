package Gruntmaster::App::Command::Edit;

use 5.014000;
use warnings;

our $VERSION = '6000.001';

use File::Temp qw/tempfile/;
use File::Slurp qw/read_file write_file/;
use Gruntmaster::App '-command';
use Gruntmaster::Data;

use Gruntmaster::App::Command::Set;
BEGIN { *PAGES = *Gruntmaster::App::Command::Set::PAGES }

sub usage_desc { '%c [-cjpu] edit id column' }

sub validate_args {
	my ($self, $opt, $args) = @_;
	my @args = @$args;
	$self->usage_error('No table selected') unless $self->app->table;
	$self->usage_error('Wrong number of arguments') if @args != 2;
}

sub execute {
	my ($self, $opt, $args) = @_;
	my ($obj, $col) = @$args;
	my ($fh, $file) = tempfile 'gruntmaster-problem-editXXXX', TMPDIR => 1, UNLINK => 1;
	write_file $fh, db->select($self->app->table, $col, {id => $obj})->flat;
	close $fh;
	my $editor = $ENV{EDITOR} // 'editor';
	system $editor, $file;
	db->update($self->app->table, {$col => scalar read_file $file}, {id => $obj});
	purge PAGES->{$self->app->table}.$_ for '', $obj;
}

1;
__END__

=encoding utf-8

=head1 NAME

Gruntmaster::App::Command::Edit - edit a property of an object

=head1 SYNOPSIS

  gm -u edit MGV name
  gm -p edit aplusb level
  gm -c edit test_ct description
  gm -j edit 100 result_text

=head1 DESCRIPTION

The get command takes two arguments: an object id and a property name,
and opens an editor with the value of that property. Upon exiting the
editor, the property is set to the contents of the file.

=head1 ENVIRONMENT

The editor is taken from the EDITOR environment variable. If this
variable is unset, the program F<editor> is executed instead.

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
