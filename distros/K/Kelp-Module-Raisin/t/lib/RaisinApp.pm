package RaisinApp;

use strict;
use warnings;

use HTTP::Status qw(:constants);
use Raisin::API;

api_format 'json';

resource test => sub {
	summary 'test action';
	get 'ttt' => sub { 'Hello World from Raisin!' };
};

1;
