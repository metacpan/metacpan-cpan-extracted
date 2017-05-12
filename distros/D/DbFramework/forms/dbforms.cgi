#!/usr/local/bin/perl -I../..

=pod

=head1 NAME

dbforms.cgi - Forms interface to DbFramework databases

=head1 SYNOPSIS

  http://foo/cgi_bin/dbforms.cgi?db=foo&db_dsn=mysql:database=foo&c_dsn=mysql:database=dbframework_catalog

=head1 DESCRIPTION

B<dbforms.cgi> presents a simple HTML forms interface to any database
configured to work with B<DbFramework>.  The database B<must> have the
appropriate catalog entries in the catalog database before it will
work with this script (see L<DbFramework::Catalog/"The Catalog">.)

=head2 Query string arguments

The following arguments are supported in the query string.  Mandatory
arguments are shown in B<bold>.

=over 4

=item B<db>

The name of the database.

=item B<db_dsn>

The portion of the DBI DSN after 'DBI:' to be used to connect to the
database e.g. 'mysql:database=foo'.

=item B<c_dsn>

The portion of the DBI DSN after 'DBI:' to be used to connect to the
catalog database e.g. 'mysql:database=dbframework_catalog'.

=item B<host>

The host on which the database is located (default = 'localhost'.)

=back

=head1 SEE ALSO

L<DbFramework::Catalog>.

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1999 Paul Sharpe. England.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use lib '../..';
use DbFramework::Util;
use DbFramework::Persistent;
use DbFramework::DataModel;
use DbFramework::Template;
use DbFramework::Catalog;
use CGI qw/:standard/;
use URI::Escape;

$cgi    = new CGI;
$db     = $cgi->param('db')      || die "No database specified";
$db_dsn = $cgi->param('db_dsn')  || die "No database DBI string specified";
$c_dsn  = $cgi->param('c_dsn')   || die "No catalog DBI string specified";
$host   = $cgi->param('host')    || undef;
$form   = $cgi->param('form')    || 'input';
$action = $cgi->param('action')  || 'select';
$dsn    = "DBI:$db_dsn";
$dsn    = "$dsn;host=$host" if $host;
$dm     = new DbFramework::DataModel($db,$dsn);
$dm->dbh->{PrintError} = 0;  # ePerl chokes on STDERR
$dbh = $dm->dbh; $dbh->{PrintError} = 0;
$dm->init_db_metadata("DBI:$c_dsn");

@tables = @{$dm->collects_table_l};
$class  = $table = $cgi->param('table') || $tables[0]->name;
$template = new DbFramework::Template(undef,\@tables);
$template->default($table);

$code = DbFramework::Persistent->make_class($class);
eval $code;

package main;
($t)     = $dm->collects_table_h_byname($table);
$catalog = new DbFramework::Catalog("DBI:$c_dsn");
$thing   = new $class($t,$dbh,$catalog);
cgi_set_attributes($thing);

#  unless ( $form eq 'input' ) {
#    $thing->init_pk;
#    $thing->table->read_form($form);
#  }

# unpack composite column name parameters
for my $param ( $cgi->param ) {
  if ( $param =~ /,/ ) {
    my @columns = split /,/,$param;
    my @values  = split /,/,$cgi->param($param);
    for ( my $i = 0; $i <= $#columns; $i++ ) {
      $cgi->param($columns[$i],$values[$i]);
    }
  }
}

sub cgi_set_attributes {
  my $thing = shift;
  my %attributes;
  for ( $thing->table->attribute_names ) {
    $attributes{$_} = $cgi->param($_) ne '' ? $cgi->param($_) : undef;
  }
  $thing->attributes_h([%attributes]);
}

sub error {
  my $message = shift;
  print  "<font color=#ff0000><strong>ERROR!</strong><p>$message</font>\n";
}

print $cgi->header;
print <<EOF;
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>
  <head>
    <title>$db: $table</title>
  </head>

  <body>
  <table border=1>
    <tr>
      <td valign=top>
      <table>
        <tr>
          <td valign=top>
          <h1>db: $db</h1>
          </td>
        </tr>
        <tr>
          <td>
            <h4>Tables</h4>
            <ul>
EOF

for ( @{$dm->collects_table_l} ) {
  my $table = $_->name;
  print "<li><a href=",$cgi->url,"?db=$db&driver=$driver&db_dsn=$db_dsn&c_dsn=$c_dsn&host=$host&table=$table>$table</a>\n";
}

print <<EOF;
            </ul>
          </td>
        </tr>
      </table>
      </td>
      <td valign=top>
        <table border=0>
        <tr>
          <td colspan=2 align=middle>
            <h1>$table</h1>
          </td>
        </tr>
        <tr>
          <td>
EOF

if ( $form eq 'input' ) {
  my $self_url = $cgi->self_url;
  print "<form method=post action=$self_url>\n";
  for ( qw(host driver db db_dsn c_dsn table form) ) {
    print "<input type=hidden name=$_ value=",$$_,">\n";
  }
  my $values_hashref = $thing->table_qualified_attribute_hashref;
  print $thing->table->as_html_heading,"\n<tr>\n";
  print $template->fill($values_hashref);
  for ( 'select','insert' ) {
    print "<td><input type=radio name=action value=$_";
    print ' checked' if /^$action$/;
    print "> $_</td>\n";
  }
print <<EOF;
  <td><input type=submit value="Submit"></td>
  </form>
EOF
}
print <<EOF;
  </tr>
  </td>
  </tr>
EOF

my $action = $cgi->param('action') || '';

SWITCH: {
  $action eq 'select' &&
    do { 
      my @names = $thing->table->attribute_names;
      my $conditions;
      for ( @names ) {
	if ( $cgi->param($_) ) {
	  $conditions .= " AND " if $conditions;
	  if ( $thing->table->in_foreign_key($thing->table->contains_h_byname($_)) ) {
	    $conditions .= "$_ = " . $cgi->param($_);
	  } else {
	    $conditions .= "$_ " . $cgi->param($_);
	  }
	}
      }
      my @things = eval { $thing->select($conditions) };
      if ( $@ ) {
	error($@);
      } else {
	if ( @things ) {
	  for my $thing ( @things ) {
	    my %attributes = %{$thing->attributes_h};
	    my $url = $cgi->url . "?db=$db&db_dsn=$db_dsn&c_dsn=$c_dsn&host=$host&table=$table&form=$form&action=update";
	    for ( keys(%attributes) ) {
	      $url .= uri_escape("&$_=$attributes{$_}");
	    }
	    # fill template
	    my $values_hashref = $thing->attributes_h;
	    print "<form method=post action=",$cgi->self_url,">\n";
	    for ( qw(host driver db db_dsn c_dsn table form) ) {
	      print "<input type=hidden name=$_ value=",$$_,">\n";
	    }
	    print $thing->table->is_identified_by->as_hidden_html($values_hashref);
	    print "<TR>",$template->fill($thing->table_qualified_attribute_hashref),"\n";
	    print "<td><input type=radio name=action value=update",($action eq 'select') ? ' checked>' : '',"update</td>\n";
	    print "<td><input type=radio name=action value=delete>",($action eq 'delete') ? ' checked' : '',"delete</td>\n";
	    print "<td><input type=submit value='Submit'></td></tr></form>\n";
	  }
	} else {
	  print "<TR><TD><strong>No rows matched your query</strong></TD></TR>\n";
	}
      }
      last SWITCH;
    };
  $action =~ /^(insert|update|delete)$/ &&
    do {
      my %attributes;
      if ( $action =~ /update/ ) {
	# make update condition from current pk
	for my $param ( $cgi->param ) {
	  if ( my($pk_column) = $param =~ /^pk_(\w+)$/ ) {
	    $attributes{$pk_column} = $cgi->param($param);
	  }
	}
      }
      cgi_set_attributes($thing);
      eval { $thing->$action(\%attributes); };
      error($@) if $@;
    }
}
$dm->dbh->disconnect;
$dbh->disconnect;

print <<EOF;
     </table>
    </td>
  </tr>
</table>
</body>
</html>
EOF
