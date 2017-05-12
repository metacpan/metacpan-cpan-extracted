package GOBO::AmiGO::Indexes::AmiGOWrapper;
use Moose::Role;
use GOBO::DBIC::GODBModel::Query;

#has schema => (is=>'rw', isa=>'AmiGO::Model::Schema');
has query => (is=>'rw', isa=>'GOBO::DBIC::GODBModel::Query');


1;


=head1 NAME

GOBO::AmiGO::Indexes::AmigoWrapper

=head1 SYNOPSIS

do not use this method directly

=head1 DESCRIPTION

Role of providing direct DB connectivity to the AmiGO/GO Database

=cut
