package BookDB;

use strict;
use Catalyst ('-Debug',
	          'Form::Processor',
			  'FillInForm',
			  'Static::Simple',
              'StackTrace',
		  );

our $VERSION = '0.02';

BookDB->config( name => 'BookDB' );

BookDB->config->{form} = {
	pre_load_forms    => 1,
	form_name_space   => 'BookDB::Form',
	debug             => 1,
};

BookDB->setup;

=head1 NAME

BookDB - Catalyst based application

=head1 SYNOPSIS

    script/bookdb_server.pl

=head1 DESCRIPTION

Catalyst based application.

=head1 METHODS

=over 4

=item default

=cut



=back

=head1 AUTHOR

Gerda Shank

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
