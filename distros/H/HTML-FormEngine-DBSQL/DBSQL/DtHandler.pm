=head1 NAME

HTML::FormEngine::DBSQL::DtHandler - DBMS datatype handlers

=head1 GENERAL INFORMATION ABOUT DATATYPE HANDLERS

To every handler is given:

=over

=item

the object reference

=item

a reference to the fields form configuration hash

=item

a reference to a hash which contains information about the column, the
information is extracted with the help of DBIs C<column_info> method,
read the documentation of DBI for more information.

=back

The handler then modifies the fields configuration hash and can use
information out of the column information hash (which he mustn't
modify!).

Which handler is called for which datatype is configured by the
skin. The default skin is HTML::FormEngine::DBSQL::SkinClassic.


=cut

######################################################################

package HTML::FormEngine::DBSQL::DtHandler;

# Copyright (c) 2003, Moritz Sinn. This module is free software;
# you can redistribute it and/or modify it under the terms of the
# GNU GENERAL PUBLIC LICENSE, see COPYING for more information

######################################################################

use Locale::gettext;

######################################################################

=head1 DATATYPE HANDLERS

=head2 _dbsql_dthandle_string

Sets C<templ> to I<text> and tries to determine the maximal length
which is then assigned to C<MAXLEN>. When C<MAXLEN> is lower
than the default size, C<SIZE> is set to C<MAXLEN>.

=cut

######################################################################

sub _dbsql_dthandle_string {
  my ($self,$res,$info) = @_;
  $res->{templ} = 'text';
  #if($info->{dtypmod} =~ m/^[0-9]+$/ && $info->{dtypmod} > 4) {
  if($info->{COLUMN_SIZE} =~ m/^[0-9]+$/) {
    #$res->{MAXLEN} = $info->{dtypmod} -4;
    $res->{MAXLEN} = $info->{COLUMN_SIZE};
    if(! defined($self->{skin_obj}->get_default('_text', 'SIZE')) || ($res->{MAXLEN} < $self->{skin_obj}->get_default('_text','SIZE'))) {
      $res->{SIZE} = $res->{MAXLEN};
    }
  }
}

######################################################################

=head2 _dbsql_dthandle_bool

C<templ> is set to I<select>, I<Yes> or I<No> is given as options
which is internally represented as 1 and 0.

=cut

######################################################################

sub _dbsql_dthandle_bool {
  my ($self,$res) = @_;
  $res->{templ} = 'select';
  $res->{OPTION} = [[[gettext('Yes'),gettext('No')]]];
  $res->{OPT_VAL} = [[['1','0']]];
}

######################################################################

=head2 _dbsql_dthandle_date

C<templ> is set to I<text>, C<SIZE> and C<MAXLEN> to 10 because a
valid date value won't need more.

=cut

######################################################################

sub _dbsql_dthandle_date {
  my($self,$res) = @_;
  $res->{templ} = 'text';
  $res->{MAXLEN} = 10;
  $res->{SIZE} = 10;
  $res->{ERROR} = 'date';
}

######################################################################

=head2 _dbsql_dthandle_text

C<templ> is set to I<textarea>.

=cut

######################################################################

sub _dbsql_dthandle_text {
  my($self,$res) = @_;
  $res->{templ} = 'textarea';
}

######################################################################

=head2 _dbsql_dthandle_integer

C<ERROR> is set to C<digitonly>.

=cut

######################################################################

sub _dbsql_dthandle_integer {
  my ($self,$res) = @_;
  $res->{templ} = 'text';
  $res->{ERROR} = 'digitonly';
}

######################################################################

1;

__END__
