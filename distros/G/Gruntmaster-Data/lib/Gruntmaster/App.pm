package Gruntmaster::App;

use 5.014000;
use warnings;

our $VERSION = '6000.001';

use App::Cmd::Setup '-app';
use Gruntmaster::Data;

sub allow_any_unambiguous_abbrev () { 1 }
sub default_command { 'commands' } # Show usage when called without arguments

sub global_opt_spec {
	(['table'   => 'hidden', {one_of => [
		['contests|ct|c' => 'Act on contests'],
		['jobs|j'        => 'Act on jobs'],
		['problems|pb|p' => 'Act on problems'],
		['users|us|u'    => 'Act on users']]}])
}

sub table { shift->global_options->{table} }

sub run {
	dbinit $ENV{GRUNTMASTER_DSN} // 'dbi:Pg:';
	shift->SUPER::run(@_);
}

1;
__END__

=encoding utf-8

=head1 NAME

Gruntmaster::App - command-line interface to the Gruntmaster 6000 database

=head1 SYNOPSIS

  use Gruntmaster::App;
  Gruntmaster::App->run;

=head1 DESCRIPTION

Gruntmaster::App is a command-line interface to the Gruntmaster 6000
database. It is the backend of the B<gm> script.

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
