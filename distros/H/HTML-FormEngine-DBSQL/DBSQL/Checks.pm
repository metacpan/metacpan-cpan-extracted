=head1 NAME

HTML::FormEngine::DBSQL::Checks - collection of FormEngine::DBSQL check routines

=cut

######################################################################

package HTML::FormEngine::DBSQL::Checks;

use Locale::gettext;

######################################################################

=head1 METHODS

=head2 dbsql_unique

This method proves whether the committed field value is unique in the
tables records for this field.

When primary key values are provided, the method checks all records
except the record which belongs to the corresponding pkey. So it'll
also work when executing updates.

=cut

######################################################################

sub _dbsql_check_unique {
  my ($value,$self,$caller,$namevar) = @_;
  return '' unless($value ne '');
  my ($table,$where, $i);
  my $field = $self->_get_var($namevar||'NAME');
  if($field =~ m/^(.+)\..+$/) {
    $table = $1;
  }
  else {
    $table = $self->{dbsql_tables}->[0];
  }
  #$i = $self->_get_var('ROWNUM',1);
  foreach $_ (keys(%{$self->{dbsql_pkey}->{$table}})) {
    $val = $self->_get_input($_);
    if(ref($val) eq 'ARRAY') {
      $val = $val->[$self->{values}->{$field} || 0];# if($i);
      $val = $val->[$self->{_handle_error}->{$field}-1] if(ref($val) eq 'ARRAY');
    }
    if(!$val) {
      undef($where);
      last;
    }
    $where .= ' AND ' . $_ . ' != ' . $self->{dbsql}->quote($val);
  }
  $where = '' unless(defined($where));
  my $sql = "SELECT 1 FROM \"$table\" WHERE $field='$value'" . $where;
  my $sth = $self->{dbsql}->prepare($sql);
  unless($sth->execute) {
    $self->_dbsql_sql_error($sql);
    return 0;
  }
  if($sth->fetchrow_array()) {
    return gettext('already exists') . '!';
  }
}

1;

__END__
