#!/usr/bin/env perl
use strict;
use warnings;
use CGI;
use FormValidator::Lite;

FormValidator::Lite->load_constraints(qw/Moose/);

my $validator = FormValidator::Lite->new( CGI->new("flg=1") );
$validator->check( flg => ['Bool'] );

__END__
