package BookDB::Form::Borrower;

use strict;
use warnings;
use base 'Form::Processor::Model::DBIC';


=head1 NAME

Form object for Borrower 

=head1 DESCRIPTION

Catalyst Controller.

=cut


sub object_class { 'DB::Borrower' } 


sub profile {
	return {
		fields => {
			name         => {
                type => 'Text',
                required => 1,
                order    => 1,
            },
			email        => {
                type => 'Email',
                required => 1,
                order => 4,
            },
			phone        => {
                type => 'Text',
                order => 2,
            },
			url          => {
                type => 'URL',
                order => 3,
            },
		},
      unique => {
         name => 'That name is already in our user directory'
      },
	};
}


=head1 AUTHOR

Gerda Shank

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

1;
