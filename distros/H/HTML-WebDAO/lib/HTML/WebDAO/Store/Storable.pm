#$Id: Storable.pm 97 2007-06-17 13:18:56Z zag $

package HTML::WebDAO::Store::Storable;
use Storable qw(lock_nstore lock_retrieve);
use HTML::WebDAO::Store::MLDBM;
use strict 'vars';
use base 'HTML::WebDAO::Store::MLDBM';

sub load {
    my $self =shift;
    my $id = shift || return {};
    my $db_file = $self->_dir()."sess_$id.sdb";
    return {} unless -e $db_file;
    return lock_retrieve($db_file);
}

sub store {
    my $self =shift;
    my $id = shift || return {};
    my $ref_tree = shift;
    return unless $ref_tree && ref($ref_tree);
    my $db_file = $self->_dir()."sess_$id.sdb";
    lock_nstore($ref_tree,$db_file);
    return $id;
}
1;
