package File::Sticker::Database;
$File::Sticker::Database::VERSION = '3.0006';
=head1 NAME

File::Sticker::Database - write info to database

=head1 VERSION

version 3.0006

=head1 SYNOPSIS

    use File::Sticker::Database;

    my $db = File::Sticker::Database->new(%args);

    $db->write_meta(%args);

=head1 DESCRIPTION

This will write meta-data from files in various formats, and standardize it to a common
nomenclature.

=cut

use common::sense;
use Carp;
use DBI;
use DBD::SQLite::Constants qw(:file_open);
use Search::Query;
use Path::Tiny;
use YAML::Any;

=head1 DEBUGGING

=head2 whoami

Used for debugging info

=cut
sub whoami  { ( caller(1) )[3] }

=head1 METHODS

=head2 new

Create a new object, setting global values for the object.

    my $obj = File::Sticker::Database->new(
        dbname=>$dbname,
        wanted_fields=>\%wanted_fields,
        field_order=>\@field_order,
        primary_table=>$primary_table,
        space_sep=>$space_sep,
    );

=cut

sub new {
    my $class = shift;
    my %parameters = (@_);
    my $self = bless ({%parameters}, ref ($class) || $class);

    return ($self);
} # new

=head2 do_connect

Connect to the database if not connected already.

=cut
sub do_connect ($) {
    my $self = shift;
    say STDERR whoami() if $self->{verbose} > 2;

    if ($self->{dbh})
    {
        return $self->{dbh};
    }
    my $database = $self->{dbname};
    if ($database)
    {
        my $dbh = DBI->connect("dbi:SQLite:dbname=$database", undef, undef,
            {sqlite_open_flags => ($self->{readonly}
                    ? SQLITE_OPEN_READONLY
                    : SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE),
            });
        if (!$dbh)
        {
            die "Can't connect to $database: $DBI::errstr";
        }

        $self->{dbh} = $dbh;
        return $dbh;
    }
    else
    {
	die "No Database given.";
    }
} # do_connect

=head2 create_tables

Create the tables for the database.
Give them all prefixes so that multiple setups can use the same database.

If the database is readonly, this does not create tables,
but it does set up configuration information, so it should still be called.

=cut
sub create_tables ($) {
    my $self = shift;
    say STDERR whoami() if $self->{verbose} > 2;

    return unless $self->{dbh};

    my $dbh = $self->{dbh};

    my @fieldnames = @{$self->{field_order}};
    # need to define some fields as numeric, some as multi
    my @field_defs = ();
    my @multi_fields = ();
    foreach my $field (@fieldnames)
    {
        if (exists $self->{wanted_fields}->{$field})
        {
            my $type = $self->{wanted_fields}->{$field};
            if ($type =~ /MULTI/i)
            {
                push @field_defs, $field . ' TEXT';
                push @multi_fields, $field;
            }
            else
            {
                push @field_defs, $field . ' ' . $type;
            }
        }
        else
        {
            push @field_defs, $field;
        }
    }
    $self->{multi_fields} = \@multi_fields;

    my $primary_table = $self->{primary_table};

    # Only create tables is this is not readonly.
    if (!$self->{readonly})
    {
        my $q = "CREATE TABLE IF NOT EXISTS $primary_table (fileid INTEGER PRIMARY KEY, file TEXT NOT NULL UNIQUE, "
        . join(", ", @field_defs) .");";
        my $ret = $dbh->do($q);
        if (!$ret)
        {
            croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
        }
        foreach my $multi (@multi_fields)
        {
            my $deep_table = $self->_deep_table_name(${multi});
            $q = "CREATE TABLE IF NOT EXISTS ${deep_table} (fileid INTEGER NOT NULL, ${multi}, FOREIGN KEY(fileid) REFERENCES ${primary_table}(fileid));";
            $ret = $dbh->do($q);
            if (!$ret)
            {
                croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
            }
            $q = "CREATE UNIQUE INDEX IF NOT EXISTS ${deep_table}_index ON ${deep_table} (fileid, ${multi})";
            $ret = $dbh->do($q);
            if (!$ret)
            {
                croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
            }
        }

        # ----------------------------------------------------------
        # Create the "info" table
        # This has the same as the primary_table, plus a faceted_tags field
        # which combines the taggable information into one big collection
        # of faceted tags.
        # The taggable_fields hash contains the field names, and the prefix
        # for the field, if one is desired.
        # ----------------------------------------------------------
        my $space_sep = ($self->{space_sep} ? $self->{space_sep} : '-');
        if ($self->{taggable_fields})
        {
            $q = "CREATE VIEW IF NOT EXISTS ${primary_table}_info AS SELECT fileid, file, ";
            $q .= join(', ', @fieldnames);
            # create the faceted_tags field
            $q .= ", replace(";
            my @tagdefs = ();
            foreach my $fn (sort keys %{$self->{taggable_fields}})
            {
                my $prefix = $self->{taggable_fields}->{$fn};
                if ($self->{wanted_fields}->{$fn} =~ /multi/i)
                {
                    push @tagdefs, " ifnull('|$prefix' || replace($fn, '|', '|$prefix'), '')";
                }
                else # single-valued
                {
                    push @tagdefs, " ifnull('|$prefix' || $fn, '')";
                }
            }
            $q .= join(' || ', @tagdefs);
            $q .= sprintf(', " ", "%s") ', $space_sep);

            $q .= " AS faceted_tags ";
            $q .= " FROM $primary_table;";

            $ret = $dbh->do($q);
            if (!$ret)
            {
                croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
            }
        }
    }

    return 1;
} # create_tables

=head2 do_disconnect

Disconnect from the database

=cut
sub do_disconnect ($) {
    my $self = shift;
    say STDERR whoami() if $self->{verbose} > 2;

    if (!$self->{dbh})
    {
        return;
    }
    $self->{dbh}->disconnect();
} # do_disconnect

=head2 start_transaction

Start a transaction.

=cut
sub start_transaction ($) {
    my $self = shift;
    say STDERR whoami() if $self->{verbose} > 2;

    if (!$self->{dbh})
    {
        return;
    }
    my $ret = $self->{dbh}->do("BEGIN TRANSACTION;");
    if (!$ret)
    {
        croak __PACKAGE__ . " failed 'BEGIN TRANSACTION' : $DBI::errstr";
    }
} # start_transaction

=head2 commit

Commit a pending transaction.

    $self->commit();

=cut
sub commit ($%) {
    my $self = shift;
    my %args = @_;
    my $meta = $args{meta};

    return unless $self->{dbh};

    my $ret = $self->{dbh}->do("COMMIT;");
    if (!$ret)
    {
        croak __PACKAGE__ . " failed 'COMMIT' : $DBI::errstr";
    }
} # commit

=head2 get_file_id

Get the fileid of the given file

    my $fileid = $self->get_file_id($filename);

=cut
sub get_file_id ($$) {
    my $self = shift;
    my $filename = shift;
    say STDERR whoami() if $self->{verbose} > 2;

    my $dbh = $self->do_connect();

    my $fullname = $filename;
    if (-r $filename)
    {
        $fullname = path($filename)->realpath->stringify;
    }
    else
    {
        # Can't use realpath if the file isn't there
        # But we need to be able to do this if we're deleting removed files
        $fullname = path($filename)->absolute->stringify;
    }
    say STDERR "fullname=$fullname" if $self->{verbose} > 2;

    my $q = 'SELECT fileid FROM ' . $self->{primary_table} . ' WHERE file = ?';
    my $sth = $self->_prepare($q);
    my $ret = $sth->execute($fullname);
    if (!$ret)
    {
        die "FAILED '$q' $DBI::errstr";
    }

    my $fileid = 0;
    my @row;
    while (@row = $sth->fetchrow_array)
    {
        say STDERR "found a file: ", $row[0] if $self->{verbose} > 2;
        $fileid = $row[0];
    }

    return $fileid;
} # get_file_id

=head2 get_file_meta

Get the meta-data for a single file.

    $meta = $self->get_file_meta($file);

=cut

sub get_file_meta {
    my $self = shift;
    my $filename = shift;

    return unless $self->{dbh};
    my $dbh = $self->{dbh};
    my $table = $self->{primary_table};
    if ($self->{taggable_fields})
    {
        $table = "${table}_info";
    }
    my $file_id = $self->get_file_id($filename);

    return undef if !$file_id;

    my $q = "SELECT * FROM $table WHERE fileid = ?;";

    my $sth = $self->_prepare($q);
    if (!$sth)
    {
        croak "FAILED to prepare '$q' $DBI::errstr";
    }
    my $ret = $sth->execute($file_id);
    if (!$ret)
    {
        croak "FAILED to execute '$q' $DBI::errstr";
    }
    # return the first matching row because there should be only one row
    my $meta = $sth->fetchrow_hashref;
    if (!$meta)
    {
        return undef;
    }

    return $meta;
} # get_file_meta

=head2 get_all_files

Return a list of all the files in the database.

    my @files = @{$db->get_all_files()};

=cut
sub get_all_files {
    my $self = shift;

    $self->do_connect();
    my $table = $self->{primary_table};

    my $files = $self->_do_one_col_query("SELECT file FROM $table ORDER BY file;");
    return $files;
} # get_all_files

=head2 get_all_tags

Return a list of all the tags from the appropriate "deep*" table.

    my @tags = @{$db->get_all_tags()};

=cut
sub get_all_tags {
    my $self = shift;

    $self->do_connect();

    # Tags are in taggable_fields. They may either be plain fields or multi_fields.
    # Yes, there are multi_fields that aren't tags (such as multiple URLs).
    # If there are no multifields and no taggable fields then... um?
    if (!$self->{taggable_fields})
    {
        say STDERR Dump($self->{multi_fields});
        return;
    }

    # Process the multi_fields first,
    # since they have to be read from the deep_* tables
    my %mt_fields = ();
    my %tags_hash = ();
    my $space_sep = ($self->{space_sep} ? $self->{space_sep} : '-');
    foreach my $t (@{$self->{multi_fields}})
    {
        # Only count as a tag if it is in taggable_fields
        if (exists $self->{taggable_fields}->{$t})
        {
            my $deep_table = $self->_deep_table_name($t);
            # In a readonly database, deep tables might not exist,
            # so check for table existance before querying
            if (!$self->{readonly} or $self->_table_exists($deep_table))
            {
                $mt_fields{$t} = 1; # yes, we got a table, mark as processed
                say STDERR "MT=$t" if $self->{verbose} > 1;
                my $these_tags = $self->_do_one_col_query("SELECT DISTINCT replace($t, ' ', '${space_sep}') FROM ${deep_table} ORDER BY $t;");
                my @prefixed_tags = $self->_add_tag_prefixes($t, $these_tags);
                $tags_hash{$_}++ for (@prefixed_tags);
            }
            else # is a multi-tag, but does not have a deep table
            {
                $mt_fields{$t} = 2;
            }
        }
    }

    # Now process the taggable_fields which are not multi_fields.
    # (And the multi-fields that don't have deep tables)
    # These have to be looked up in the primary table.
    my $primary_table = $self->{primary_table};
    foreach my $t (keys %{$self->{taggable_fields}})
    {
        if (!$mt_fields{$t}) # has not been processed as a multi-field
        {
            say STDERR "TT=$t" if $self->{verbose} > 1;
            my $these_tags = $self->_do_one_col_query("SELECT DISTINCT replace($t, ' ', '${space_sep}') FROM ${primary_table};");
            my @prefixed_tags = $self->_add_tag_prefixes($t, $these_tags);
            $tags_hash{$_}++ for (@prefixed_tags);
        }
        elsif ($mt_fields{$t} == 2) # multi-field without deep table
        {
            say STDERR "MT=$t" if $self->{verbose} > 1;
            # Is a multi-tag field, but does not have a deep table to look at
            # Will have to look at the primary table AND split each result
            my $these_multi_tags = $self->_do_one_col_query("SELECT DISTINCT replace($t, ' ', '${space_sep}') FROM ${primary_table};");
            foreach my $mt (@{$these_multi_tags})
            {
                my @these_split_tags = split(/[,|]/, $mt);
                my @prefixed_tags = $self->_add_tag_prefixes($t, \@these_split_tags);
                $tags_hash{$_}++ for (@prefixed_tags);
            }
        }
    }
    say STDERR "Tags hash:", Dump(\%tags_hash) if $self->{verbose} > 1;

    my @tags = sort keys %tags_hash;
    say STDERR "Sorted tags:", Dump(@tags) if $self->{verbose} > 1;

    return \@tags;

} # get_all_tags

=head2 query_by_tags

Use +tag -tag nomenclature for searching the database for matching files.
If the *info table exists, uses that, otherwise, it uses the "tagfield" in the primary table.

=cut
sub query_by_tags ($$$) {
    my $self = shift;
    my $query_string = shift;
    printf "%s\n", whoami() if $self->{verbose} > 1;

    my $dbh = $self->do_connect();
    my $table = $self->{primary_table};
    my $using_info_table = 0;
    if ($self->{taggable_fields})
    {
        $table = $table . '_info';
        $using_info_table = 1;
    }
    my $default_field = ($using_info_table
        ? 'faceted_tags'
        : ( $self->{tagfield}
            ? $self->{tagfield}
            : 'tags'
        )
    );

    say sprintf("Q='%s'", $query_string) if $self->{verbose} > 1;
    my @pfields = qw(fileid file);
    push @pfields, @{$self->{field_order}},
    push @pfields, 'faceted_tags' if $using_info_table;
    my $parser = Search::Query->parser(
        query_class => 'SQL',
        null_term => 'NULL',
        query_class_opts => {
            like => 'GLOB',
            wildcard => '*',
        },
        default_field => $default_field,
        default_op => '~',
        fields => \@pfields,
        term_expander => sub {
                   my ($term, $field) = @_;
                   if (!$field || $field eq $default_field)
                   {
                       # search for pipe-delimited terms
                       my @newterms = ();
                       if (ref $term)
                       {
                           foreach my $tt (@{$term})
                           {
                               push @newterms, $tt; # term alone
                               push @newterms, $tt . '|*'; # at start
                               push @newterms, '*|' . $tt . '|*'; # in middle
                               push @newterms, '*|' . $tt; # at end
                           }
                       }
                       else
                       {
                           # Fix embeddeds quotes for SQL quoting
                           # Can't use the "quote" method because that
                           # also puts quotes around the whole thing, which
                           # messes things up.
                           $term =~ s/\'/''/g;
                           push @newterms, $term; # term alone
                           push @newterms, $term . '|*'; # at start
                           push @newterms, '*|' . $term . '|*'; # in middle
                           push @newterms, '*|' . $term; # at end
                       }
                       return @newterms;
                   }
                   return ($term);
               }
        );
    my $query  = $parser->parse($query_string);

    my $q = "SELECT file FROM $table WHERE " . $query->stringify;
    $q .= " ORDER BY file";
    print $q, "\n" if $self->{verbose} > 1;
    my $sth = $self->_prepare($q);
    my $ret = $sth->execute();
    if (!$ret)
    {
        die "FAILED '$q' $DBI::errstr";
    }

    my @files = ();
    my @row;
    while (@row = $sth->fetchrow_array)
    {
        push @files, $row[0];
    }

    return \@files;
} # query_by_tags

=head2 delete_file_from_db

Delete the record for one file from the database

    $db->delete_file_from_db($filename);

=cut
sub delete_file_from_db ($$) {
    my $self = shift;
    my $filename = shift;
    say STDERR whoami() if $self->{verbose} > 2;

    my $dbh = $self->do_connect();
    my $file_id = $self->get_file_id($filename);

    # If the file is in the db, DELETE
    if ($file_id)
    {
        # remove from deep* tables first
        foreach my $t (@{$self->{multi_fields}})
        {
            my $deep_table = $self->_deep_table_name($t);
            my $q = "DELETE FROM ${deep_table} WHERE fileid = ?;";
            my $sth = $self->_prepare($q);
            my $ret = $sth->execute($file_id);
            if (!$ret)
            {
                die "FAILED query '$q' $DBI::errstr";
            }
        }

        my $q = 'DELETE FROM ' . $self->{primary_table} . ' WHERE fileid = ?;';
        my $sth = $self->_prepare($q);
        my $ret = $sth->execute($file_id);
        if (!$ret)
        {
            die "FAILED query '$q' $DBI::errstr";
        }
    }

} # delete_file_from_db

=head2 add_meta_to_db

Add the given file info to the database.

    $db->add_meta_to_db($filename, %meta);

=cut
sub add_meta_to_db {
    my $self = shift;
    my $filename = shift;
    my %meta = @_;
    say STDERR whoami() if $self->{verbose} > 2;

    my $dbh = $self->do_connect();

    # ------------------------------------------------
    # Values
    # ------------------------------------------------
    my @values = ();
    foreach my $fn (@{$self->{field_order}})
    {
	my $val = $meta{$fn};
	if (!defined $val)
	{
	    push @values, undef;
	}
	elsif (ref $val)
	{
	    $val = join("|", @{$val});
	    push @values, $val;
	}
        elsif (exists $self->{wanted_fields}->{$fn}
                and defined $self->{wanted_fields}->{$fn}
                and $self->{wanted_fields}->{$fn} =~ /multi/i)
        # convert comma-separated into pipe-separated
        {
            $val =~ s/,\s*/|/g;
	    push @values, $val;
        }
	else
	{
	    push @values, $val;
	}
        say STDERR "  $fn=$val " if $self->{verbose};
    }
    my %multi_values = ();
    foreach my $field (@{$self->{multi_fields}})
    {
	my $val = $meta{$field};
	if (!defined $val)
	{
            # do nothing
	}
	elsif (ref $val)
	{
            $multi_values{$field} = $val;
	}
	else
	{
            my @values = split(/[,|]/, $val);
            $multi_values{$field} = \@values;
	}
    }

    # ------------------------------------------------
    # Primary Table
    # ------------------------------------------------

    # Check if the record exists in the table
    # and do an INSERT or UPDATE depending on whether it does.
    # This is faster than REPLACE because it doesn't need
    # to rebuild indexes.
    my $fullname = $filename;
    if (-r $filename)
    {
        $fullname = path($filename)->realpath->stringify;
    }
    else
    {
        # Can't use realpath if the file isn't there
        # But we need to be able to do this if we're deleting removed files
        $fullname = path($filename)->absolute->stringify;
    }
    my $file_id = $self->get_file_id($fullname);
    say STDERR "file_id=$file_id" if $self->{verbose} > 1;
    my $q;
    my $ret;
    if ($file_id)
    {
        $q = "UPDATE $self->{primary_table} SET ";
        for (my $i=0; $i < @values; $i++)
        {
            $q .= sprintf('%s = ?', $self->{field_order}->[$i]);
            if ($i + 1 < @values)
            {
                $q .= ", ";
            }
        }
        $q .= " WHERE fileid = '$file_id';";
        my $sth = $self->_prepare($q);
        if (!$sth)
        {
            croak __PACKAGE__ . " failed to prepare '$q' : $DBI::errstr";
        }
        $ret = $sth->execute(@values);
        if (!$ret)
        {
            croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
        }

        # However, it's simpler to just delete everything from the deeptables
        # and add the new tags below. I know, this is programmer laziness.
        foreach my $t (@{$self->{multi_fields}})
        {
            my $deep_table = $self->_deep_table_name($t);
            $q = "DELETE FROM ${deep_table} WHERE fileid = ?;";
            my $sth = $self->_prepare($q);
            $ret = $sth->execute($file_id);
            if (!$ret)
            {
                croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
            }
        }
    }
    else
    {
        my $placeholders = join ", ", ('?') x @{$self->{field_order}};
        $q = 'INSERT INTO ' . $self->{primary_table} . ' (file, '
        . join(", ", @{$self->{field_order}}) . ') VALUES (?, ' . $placeholders . ');';
        say STDERR "q=$q" if $self->{verbose} > 1;

        my $sth = $self->_prepare($q);
        if (!$sth)
        {
            croak __PACKAGE__ . " failed to prepare '$q' : $DBI::errstr";
        }
        $ret = $sth->execute($fullname, @values);
        if (!$ret)
        {
            croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
        }

        # get the file_id of the newly-inserted file
        $file_id = $self->get_file_id($fullname);
        say STDERR "new file_id=$file_id" if $self->{verbose} > 1;
    }

    # ------------------------------------------------
    # Deep tables
    # ------------------------------------------------
    foreach my $field (@{$self->{multi_fields}})
    {
        if (exists $multi_values{$field}
                and defined $multi_values{$field})
        {
            my $deep_table = $self->_deep_table_name($field);
            $q = "INSERT INTO ${deep_table} (fileid, ${field}) VALUES (?, ?);";
            my $sth = $self->_prepare($q);
            my @values = @{$multi_values{$field}};
            foreach my $val (@values)
            {
                $ret = $sth->execute($file_id,$val);
                if (!$ret)
                {
                    croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
                }
            }
        }
    }

} # add_meta_to_db

=head1 Helper Functions

Private interface.

=cut

=head2 _deep_table_name

Return the name of the given deep_* table.

=cut
sub _deep_table_name {
    my $self = shift;
    my $field = shift;

    return $self->{primary_table} . '_deep_' . $field;
} # _deep_table_name

=head2 _table_exists

Checks if a given table exists.
This can be relevant with a readonly database where
tables are not guaranteed to have been created.

=cut
sub _table_exists {
    my $self = shift;
    my $table = shift;
    say STDERR whoami(), ' ', $table if $self->{verbose} > 2;

    my $dbh = $self->{dbh};
    my $type = "'TABLE','VIEW'";
    my $sth = $dbh->table_info(undef, undef, $table, $type);

    my $table_does_exist = 0;
    my $found_table = '';
    my @row;
    while (@row = $sth->fetchrow_array)
    {
        say STDERR sprintf('found a table: %s (%s)', $row[2], $row[3])
            if $self->{verbose} > 2;
        $found_table = $row[2];
        $table_does_exist = 1;
    }
    return $table_does_exist;
} # _table_exists

=head2 _add_tag_prefixes

Add prefixes to the given array of tags.

    my @pref_tags = $self->_add_tag_prefixes($field, \@values);

=cut
sub _add_tag_prefixes {
    my $self = shift;
    my $field = shift;
    my $values = shift;

    my @prefixed_tags = ();
    if ($self->{taggable_fields}->{$field}) # has a field-specific prefix
    {
        my $pr = $self->{taggable_fields}->{$field};
        @prefixed_tags = map { "${pr}$_" } @{$values};
    }
    elsif ($self->{tagprefix}) # simple prefix for all tags
    {
        @prefixed_tags = map { "${field}-$_" } @{$values};
    }
    else # no prefix needed
    {
        @prefixed_tags = @{$values};
    }
    return @prefixed_tags;
} # _add_tag_prefixes

=head2 _do_one_col_query

Do a SELECT query, and return the first column of results.
This is a freeform query, so the caller must be careful to formulate it correctly.

my $results = $self->_do_one_col_query($query);

=cut

sub _do_one_col_query {
    my $self = shift;
    my $q = shift;

    if ($q !~ /^SELECT /)
    {
        # bad boy! Not a SELECT.
        return undef;
    }
    my $dbh = $self->{dbh};

    my $sth = $self->_prepare($q);
    if (!$sth)
    {
        croak "FAILED to prepare '$q' $DBI::errstr";
    }
    my $ret = $sth->execute();
    if (!$ret)
    {
        croak "FAILED to execute '$q' $DBI::errstr";
    }
    my @results = ();
    my @row;
    while (@row = $sth->fetchrow_array)
    {
        push @results, $row[0];
    }
    return \@results;

} # _do_one_col_query

=head2 _prepare

Prepare and cache prepared queries.

    my $sth = $self->_prepare($q);

=cut
sub _prepare {
    my $self = shift;
    my $q = shift;

    my $sth;
    if (exists $self->{_queries}->{$q}
            and defined $self->{_queries}->{$q})
    {
        $sth = $self->{_queries}->{$q};
    }
    else
    {
        $sth = $self->{dbh}->prepare($q);
        if (!$sth)
        {
            die "FAILED to prepare query '$q' $DBI::errstr";
        }
        $self->{_queries}->{$q} = $sth;
    }
    return $sth;
} # _prepare

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Database
__END__
