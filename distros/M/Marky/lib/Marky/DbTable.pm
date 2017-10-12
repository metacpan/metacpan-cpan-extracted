package Marky::DbTable;
$Marky::DbTable::VERSION = '0.035';
#ABSTRACT: Marky::DbTable - querying one database table

use common::sense;
use DBI;
use Path::Tiny;
use Search::Query;
use Sort::Naturally;
use Text::NeatTemplate;
use YAML::Any;
use POSIX qw(ceil);
use HTML::TagCloud;
use Mojo::URL;


sub new {
    my $class = shift;
    my %parameters = (@_);
    my $self = bless ({%parameters}, ref ($class) || $class);

    $self->_set_defaults();

    return ($self);
} # new


sub query_raw {
    my $self = shift;
    my %args = @_;

    if (!$self->_connect())
    {
        return undef;
    }

    my $data = $self->_search(%args);
    return $data;
} # query_raw


sub query {
    my $self = shift;
    my %args = @_;

    if (!$self->_connect())
    {
        return undef;
    }

    return $self->_process_request(%args);
} # query


sub taglist {
    my $self = shift;
    my %args = @_;

    if (!$self->_connect())
    {
        return undef;
    }

    return $self->_process_taglist(%args);
} # taglist


sub tagcloud {
    my $self = shift;
    my %args = @_;

    if (!$self->_connect())
    {
        return undef;
    }

    return $self->_process_tagcloud(%args);
} # tagcloud


sub total_records {
    my $self = shift;
    my %args = @_;

    if (!$self->_connect())
    {
        return undef;
    }

    return $self->_total_records(%args);
} # total_records


sub what_error {
    my $self = shift;
    my %args = @_;

    return $self->{error};
} # what_error


sub _set_defaults {
    my $self = shift;

    $self->{route_prefix} = '' if !defined $self->{route_prefix};

    $self->{user} = '' if !defined $self->{user};
    $self->{password} = '' if !defined $self->{password};

    if (!defined $self->{database})
    {
        die "No database given";
    }
    if (!defined $self->{table})
    {
        die "No table given";
    }
    if (!defined $self->{columns})
    {
        die "No columns given";
    }
    if (!defined $self->{sort_columns})
    {
        $self->{sort_columns} = $self->{columns};
    }
    $self->{tagfield} = 'tags' if !defined $self->{tagfield};
    $self->{default_limit} = 100 if !defined $self->{default_limit};

    if (!defined $self->{row_template})
    {
        $self->{row_template} =<<'EOT';
<li>
<div class="linkcontainer">
<span class="linktitle">{$title}</span>
<div class="linkdescription">
{?description [$description:html]}
</div>
{?all_tags <div class="linktaglist">[$all_tags]</div>}
</div>
</li>
EOT
    }

    if (!defined $self->{tags_template})
    {
        $self->{tags_template} =<<'EOT';
<a href="{$url}/{?tags_query [$tags_query]}{?qquery ?[$qquery]}" class="tag {?not_in_list button}">{?not_in_list <span class="fa fa-tag"></span>} {$tag_label}{?num_tags  ([$num_tags])}</a>
EOT
    }
    if (!defined $self->{tag_query_template})
    {
        $self->{tag_query_template} =<<'EOT';
<a title="Remove tag" href="{$url}/{?tags_query [$tags_query]}?deltag={$tag}{?q &q=[$q]}{?p &p=[$p]}{?where &where=[$where]}" class="tag button"><span class="fa fa-tag"></span> {$tag} <span class="remove fa fa-remove"></span></a>
EOT
    }
    if (!defined $self->{q_query_template})
    {
        $self->{q_query_template} =<<'EOT';
<a title="Remove term" href="{$url}/{?tags_query tags/[$tags_query]}?delterm={$qterm}{?q &q=[$q]}{?p &p=[$p]}{?where &where=[$where]}" class="tag button"><span class="fa fa-question"></span> {$qterm} <span class="remove fa fa-close"></span></a>
EOT
    }
    if (!defined $self->{results_template})
    {
        $self->{results_template} =<<'EOT';
{?searchform [$searchform]}
{?pagination [$pagination]}
{?total <p>[$total] records found. Page [$p] of [$num_pages].</p>}
{?query <div class="query">[$query]</div>}
{?sql <p class="sql">[$sql]</p>}
{?result <div class="results fancy">[$result]</div>}
EOT
    }
    if (!defined $self->{pagination_template})
    {
        $self->{pagination_template} =<<'EOT';
<div class="pagination">
<span class="prev">{?prev_page <a title="Prev" class="prevnext" href="[$location]/[$tq]?p=[$prev_page]&q=[$q]&where=[$where]">}<span class="fa fa-chevron-left"></span> Prev{?prev_page </a>}</span>
<span class="next">{?next_page <a title="Next" href="[$location]/[$tq]?p=[$next_page]&q=[$q]&where=[$where]">}Next <span class="fa fa-chevron-right"></span>{?next_page </a>}</span>
</div>
EOT
    }
    if (!defined $self->{searchform})
    {
        $self->{searchform} =<<'EOT';
<div class="searchform">
<form class="searcher" action="{$action}">
<span class="textin"><label class="fa fa-question">Any:</label> <input type="text" name="q" value="{$q}"/></span>
<span class="textin"><label class="fa fa-tags">Tags:</label> <input type="text" name="tags" value="{$tags}"></span>
<span class="selector"><label>Pg:</label> {$selectP}</span>
<input type="submit" value="Search">
</form>
<form class="setter" action="{$opt_url}">
<span class="selector"><label>N:</label> {$selectN}</span>
<span class="selector"><label>Sort:</label> {$sorting}</span>
<input type="submit" value="Set">
</form></div>
EOT
        if ($self->{use_where})
        {
            my $whereness =<<'EOW';
<div class="where"><label>Where:</label><textarea name="where" rows="3" cols="80">{$where}</textarea></div>
EOW
            $self->{searchform} =~ s/(<input type="submit" value="Search">)/${whereness}$1/;
        }
    }
    return $self;

} # _set_defaults


sub _connect {
    my $self = shift;

    my $old_dbh = $self->{dbh};
    if ($old_dbh)
    {
        return 1;
    }

    # The database is either a DSN (data source name)
    # or a file name. If it's a file name, assume it's SQLite
    my $database = $self->{database};
    if ($database)
    {
        my $dsn = $database;
        my $user = $self->{user};
        my $pw = $self->{password};
        if (-f $database)
        {
            $dsn = "dbi:SQLite:dbname=$database";
        }
        my $dbh = DBI->connect($dsn, $user, $pw);
        if (!$dbh)
        {
            $self->{error} = "Can't connect to $database $DBI::errstr";
            return 0;
        }
        $self->{dbh} = $dbh;
    }
    else
    {
	$self->{error} = "No Database given." . Dump($self);
        return 0;
    }

    return 1;
} # _connect


sub _search {
    my $self = shift;
    my %args = @_;

    my $dbh = $self->{dbh};

    # first find the total
    my $q = $self->_query_to_sql(%args,get_total=>1);
    my $sth = $dbh->prepare($q);
    if (!$sth)
    {
        $self->{error} = "FAILED to prepare '$q' $DBI::errstr";
        return undef;
    }
    my $ret = $sth->execute();
    if (!$ret)
    {
        $self->{error} = "FAILED to execute '$q' $DBI::errstr";
        return undef;
    }
    my @ret_rows=();
    my $total = 0;
    my @row;
    while (@row = $sth->fetchrow_array)
    {
        $total = $row[0];
    }
    my $num_pages = 1;
    if ($args{n})
    {
        $num_pages = ceil($total / $args{n});
        $num_pages = 1 if $num_pages < 1;
    }

    if ($total > 0)
    {
        $q = $self->_query_to_sql(%args,total=>$total);
        $sth = $dbh->prepare($q);
        if (!$sth)
        {
            $self->{error} = "FAILED to prepare '$q' $DBI::errstr";
            return undef;
        }
        $ret = $sth->execute();
        if (!$ret)
        {
            $self->{error} = "FAILED to execute '$q' $DBI::errstr";
            return undef;
        }

        while (my $hashref = $sth->fetchrow_hashref)
        {
            push @ret_rows, $hashref;
        }
    }
    return {rows=>\@ret_rows,
        total=>$total,
        num_pages=>$num_pages,
        sql=>$q};
} # _search


sub _process_request {
    my $self = shift;
    my %args = @_;

    my $dbh = $self->{dbh};
    my $location = $args{location};
    $args{n} = 20 if !defined $args{n};
    my $tobj = Text::NeatTemplate->new();

    my $data = $self->_search(
        %args
    );
    if (!defined $data)
    {
        return undef;
    }

    my $searchform = $self->_format_searchform(
        %args,
        data=>$data,
    );
    my $pagination = $self->_format_pagination(
        %args,
        data=>$data,
    );
    my $result = $self->_format_rows(
        %args,
        rows=>$data->{rows},
        total=>$data->{total},
        tags_query=>$args{tags},
        tags_action=>"$location/tags",
    );
    my %all_tags = $self->_create_taglist(
        rows=>$data->{rows},
        total=>$data->{total},
    );
    my $query_tags = $self->_format_taglist(
        %args,
        all_tags=>\%all_tags,
        tags_query=>$args{tags},
        tags_action=>"$location/tags",
    );
    my $tquery_str = $self->_format_tag_query(
        %args,
        tags_query=>$args{tags},
        tags_action=>"$location/tags");
    my $qquery_str = $self->_format_q_query(
        %args,
        tags_query=>$args{tags},
        action=>$location);
    my $query_str = join(' ', $tquery_str, $qquery_str);
    my $html = $tobj->fill_in(
        data_hash=>{
            %args,
            p=>($args{p} ? $args{p} : 1),
            sql=>($args{show_sql} ? $data->{sql} : ''),
            query=>$query_str,
            result=>$result,
            total=>$data->{total},
            num_pages=>$data->{num_pages},
            searchform=>$searchform,
            pagination=>$pagination,
        },
        template=>$self->{results_template},
    );

    return { results=>$html,
        query_tags=>$query_tags,
        searchform=>$searchform,
        pagination=>$pagination,
        total=>$data->{total},
        num_pages=>$data->{num_pages},
    };
} # _process_request


sub _process_taglist {
    my $self = shift;
    my %args = @_;

    my $dbh = $self->{dbh};
    my $location = $args{location};
    $args{n} = 20 if !defined $args{n};
    my $tobj = Text::NeatTemplate->new();

    my $data = $self->_search(
        %args
    );

    my %all_tags = $self->_create_taglist(
        rows=>$data->{rows},
        total=>$data->{total},
    );
    my $count = keys %all_tags;
    my $query_tags = $self->_format_taglist(
        %args,
        all_tags=>\%all_tags,
        total_tags=>$count,
        tags_query=>$args{tags},
        tags_action=>"$location/tags",
    );

    return { results=>$query_tags,
        query_tags=>$query_tags,
        total=>$data->{total},
        total_tags=>$count,
        num_pages=>$data->{num_pages},
    };
} # _process_taglist


sub _process_tagcloud {
    my $self = shift;
    my %args = @_;

    my $dbh = $self->{dbh};
    my $location = $args{location};
    $args{n} = 20 if !defined $args{n};
    my $tobj = Text::NeatTemplate->new();

    my $data = $self->_search(
        %args
    );

    my %all_tags = $self->_create_taglist(
        rows=>$data->{rows},
        total=>$data->{total},
    );
    my $count = keys %all_tags;
    my $query_tags = $self->_format_taglist(
        %args,
        all_tags=>\%all_tags,
        tags_query=>$args{tags},
        tags_action=>"$location/tags",
    );
    my $tagcloud = $self->_format_tagcloud(
        %args,
        all_tags=>\%all_tags,
        tags_query=>$args{tags},
        tags_action=>"$location/tags",
    );

    return { results=>$tagcloud,
        query_tags=>$query_tags,
        total=>$data->{total},
        total_tags=>$count,
        num_pages=>$data->{num_pages},
    };
} # _process_tagcloud


sub _total_records {
    my $self = shift;

    my $dbh = $self->{dbh};

    my $q = $self->_query_to_sql(get_total=>1);

    my $sth = $dbh->prepare($q);
    if (!$sth)
    {
        $self->{error} = "FAILED to prepare '$q' $DBI::errstr";
        return undef;
    }
    my $ret = $sth->execute();
    if (!$ret)
    {
        $self->{error} = "FAILED to execute '$q' $DBI::errstr";
        return undef;
    }
    my $total = 0;
    my @row;
    while (@row = $sth->fetchrow_array)
    {
        $total = $row[0];
    }
    return $total;
} # _total_records


sub _build_where {
    my $self = shift;
    my %args = @_;
    my $field = $args{field};
    my $query_string = $args{q};
    
    # no query, no WHERE
    if (!$query_string)
    {
        return '';
    }

    my $sql_where = '';

    # If there is no field, it is a simple query string;
    # the simple query string will search all columns in OR fashion
    # that is (col1 GLOB term OR col2 GLOB term...) etc
    # only allow for '-' prefix, not the complex Search::Query stuff
    # Note that if this is a NOT term, the query clause needs to be
    # (col1 NOT GLOB term AND col2 NOT GLOB term)
    # and checking for NULL too
    if (!$field)
    {
        my @and_clauses = ();
        my @terms = split(/[ +]/, $query_string);
        for (my $i=0; $i < @terms; $i++)
        {
            my $term = $terms[$i];
            my $not = 0;
            if ($term =~ /^-(.*)/)
            {
                $term = $1;
                $not = 1;
            }
            if ($not) # negative term, match NOT AND
            {
                my @and_not_clauses = ();
                foreach my $col (@{$self->{columns}})
                {
                    my $clause = sprintf('(%s IS NULL OR %s NOT GLOB "*%s*")', $col, $col, $term);
                    push @and_not_clauses, $clause;
                }
                push @and_clauses, "(" . join(" AND ", @and_not_clauses) . ")";
            }
            else # positive term, match OR
            {
                my @or_clauses = ();
                foreach my $col (@{$self->{columns}})
                {
                    my $clause = sprintf('%s GLOB "*%s*"', $col, $term);
                    push @or_clauses, $clause;
                }
                push @and_clauses, "(" . join(" OR ", @or_clauses) . ")";
            }
        }
        $sql_where = join(" AND ", @and_clauses);
    }
    elsif ($field eq 'tags'
            or $field eq $self->{tagfield})
    {
        my $tagfield = $self->{tagfield};
        my @and_clauses = ();
        my @terms = split(/[ +]/, $query_string);
        for (my $i=0; $i < @terms; $i++)
        {
            my $term = $terms[$i];
            my $not = 0;
            my $equals = 1; # make tags match exactly by default
            if ($term =~ /^-(.*)/)
            {
                $term = $1;
                $not = 1;
            }
            # use * for a glob marker
            if ($term =~ /^\*(.*)/)
            {
                $term = $1;
                $equals = 0;
            }
            if ($not and !$equals)
            {
                my $clause = sprintf('(%s IS NULL OR %s NOT GLOB "*%s*")', $tagfield, $tagfield, $term);
                push @and_clauses, $clause;
            }
            elsif ($not and $equals) # negative term, match NOT AND
            {
                my $clause = sprintf('(%s IS NULL OR (%s != "%s" AND %s NOT GLOB "%s|*" AND %s NOT GLOB "*|%s|*" AND %s NOT GLOB "*|%s"))',
                    $tagfield,
                    $tagfield, $term,
                    $tagfield, $term,
                    $tagfield, $term,
                    $tagfield, $term,
                );
                push @and_clauses, $clause;
            }
            elsif ($equals) # positive term, match OR
            {
                my $clause = sprintf('(%s = "%s" OR %s GLOB "%s|*" OR %s GLOB "*|%s|*" OR %s GLOB "*|%s")',
                    $tagfield, $term,
                    $tagfield, $term,
                    $tagfield, $term,
                    $tagfield, $term,
                );
                push @and_clauses, $clause;
            }
            else 
            {
                my $clause = sprintf('%s GLOB "*%s*"', $tagfield, $term);
                push @and_clauses, $clause;
            }
        }
        $sql_where = join(" AND ", @and_clauses);
    }
    else # other columns
    {
        my $parser = Search::Query->parser(
            query_class => 'SQL',
            query_class_opts => {
                like => 'GLOB',
                wildcard => '*',
                fuzzify2 => 1,
            },
            null_term => 'NULL',
            default_field => $field,
            default_op => '~',
            fields => [$field],
            );
        my $query  = $parser->parse($args{q});
        $sql_where = $query->stringify;
    }

    return ($sql_where ? "(${sql_where})" : '');
} # _build_where


sub _query_to_sql {
    my $self = shift;
    my %args = @_;

    my $p = $args{p};
    my $items_per_page = $args{n};
    my $total = ($args{total} ? $args{total} : 0);
    my $order_by = '';
    if ($args{sort_by} and $args{sort_by2} and $args{sort_by3})
    {
        $order_by = join(', ', $args{sort_by}, $args{sort_by2}, $args{sort_by3});
    }
    elsif ($args{sort_by} and $args{sort_by2})
    {
        $order_by = join(', ', $args{sort_by}, $args{sort_by2});
    }
    elsif ($args{sort_by})
    {
        $order_by = $args{sort_by};
    }
    else
    {
        $order_by = join(', ', @{$self->{default_sort}});
    }

    my $offset = 0;
    if ($p and $items_per_page)
    {
        $offset = ($p - 1) * $items_per_page;
        if ($total > 0 and $offset >= $total)
        {
            $offset = $total - 1;
        }
        elsif ($offset <= 0)
        {
            $offset = 0;
        }
    }

    my @and_clauses = ();
    foreach my $col (@{$self->{columns}})
    {
        if ($args{$col})
        {
            my $clause = $self->_build_where(field=>$col, q=>$args{$col});
            push @and_clauses, $clause;
        }
    }
    if ($args{'tags'} and $self->{tagfield} ne 'tags')
    {
        my $clause = $self->_build_where(field=>'tags', q=>$args{'tags'});
        push @and_clauses, $clause;
    }

    if ($args{q})
    {
        my $clause = $self->_build_where(field=>'', q=>$args{q});
        push @and_clauses, $clause;
    }
    # a freeform where condition
    if ($args{where})
    {
        push @and_clauses, $args{where};
    }
    # if there's an extra condition in the configuration, add it here
    if ($self->{extra_cond})
    {
        if (@and_clauses)
        {
            push @and_clauses, "(" . $self->{extra_cond} . ")";
        }
        else
        {
            push @and_clauses, $self->{extra_cond};
        }
    }
    my $sql_where = join(" AND ", @and_clauses);

    my $q = '';
    if ($args{get_total})
    {
        $q = "SELECT COUNT(*) FROM " . $self->{table};
        $q .= " WHERE $sql_where" if $sql_where;
    }
    else
    {
        $q = "SELECT * FROM " . $self->{table};
        $q .= " WHERE $sql_where" if $sql_where;
        $q .= " ORDER BY $order_by" if $order_by;
        $q .= " LIMIT $items_per_page" if $items_per_page;
        $q .= " OFFSET $offset" if $offset;
    }

    return $q;
} # _query_to_sql


sub _format_searchform {
    my $self = shift;
    my %args = @_;

    my $data = $args{data};
    my $location = $args{location};
    my $tobj = Text::NeatTemplate->new();

    my $selectN = '';
    my @os = ();
    push @os, '<select name="n">';
    foreach my $limit (qw(10 20 50 100))
    {
        if ($limit == $args{n})
        {
            push @os, "<option value='$limit' selected>$limit</option>";
        }
        else
        {
            push @os, "<option value='$limit'>$limit</option>";
        }
    }
    push @os, '</select>';
    $selectN = join("\n", @os);

    my $total = $data->{total};
    my $num_pages = $data->{num_pages};
    if ($args{p} > $num_pages)
    {
        $args{p} = 1;
    }

    my $selectP = '';
    @os = ();
    push @os, '<select name="p">';
    for (my $p = 1; $p <= $num_pages; $p++)
    {
        if ($p == $args{p})
        {
            push @os, "<option value='$p' selected>$p</option>";
        }
        else
        {
            push @os, "<option value='$p'>$p</option>";
        }
    }
    push @os, '</select>';
    $selectP = join("\n", @os);

    my $db = $args{db};
    my $sorting = '';
    @os = ();
    foreach my $sf (qw(sort_by sort_by2 sort_by3))
    {
        push @os, "<select name='${db}_$sf'>";
        push @os, "<option value=''> </option>";
        foreach my $s (sort @{$self->{sort_columns}})
        {
            if ($s eq $args{$sf})
            {
                push @os, "<option value='$s' selected>$s</option>";
            }
            else
            {
                push @os, "<option value='$s'>$s</option>";
            }
            my $s_desc = "${s} DESC";
            if ($s_desc eq $args{$sf})
            {
                push @os, "<option value='$s_desc' selected>$s_desc</option>";
            }
            else
            {
                push @os, "<option value='$s_desc'>$s_desc</option>";
            }
        }
        push @os, '</select>';
    }
    $sorting = join("\n", @os);

    my $searchform = $tobj->fill_in(
        data_hash=>{
            %args,
            action=>$location,
            selectN=>$selectN,
            selectP=>$selectP,
            sorting=>$sorting,
        },
        template=>$self->{searchform},
    );

    return $searchform;
} # _format_searchform


sub _format_pagination {
    my $self = shift;
    my %args = @_;

    my $data = $args{data};
    my $location = $args{location};
    my $tobj = Text::NeatTemplate->new();

    my $total = $data->{total};
    my $num_pages = $data->{num_pages};
    if ($args{p} > $num_pages)
    {
        $args{p} = $num_pages;
    }
    if ($args{p} < 1)
    {
        $args{p} = 1;
    }
    my $prev_page = $args{p} - 1;
    if ($prev_page < 1)
    {
        $prev_page = 0;
    }
    my $next_page = $args{p} + 1;
    if ($next_page > $num_pages)
    {
        $next_page = 0;
    }
    my $tq = '';
    if ($args{tags})
    {
        $tq = 'tags/' . $args{tags};
    }

    my $pagination = $tobj->fill_in(
        data_hash=>{
            %args,
            tq=>$tq,
            prev_page=>$prev_page,
            next_page=>$next_page,
        },
        template=>$self->{pagination_template},
    );

    return $pagination;
} # _format_pagination


sub _format_rows {
    my $self = shift;
    my %args = @_;

    my @rows = @{$args{rows}};
    my $total = $args{total};

    my @out = ();
    push @out, '<ul>';
    my $tobj = Text::NeatTemplate->new();
    foreach my $row_hash (@rows)
    {
        # format the tags, then format the row
        # may need to remove trailing empty tags
        my $proper_tags = $row_hash->{$self->{tagfield}};
        $proper_tags =~ s/^[|]//;
        $proper_tags =~ s/[|]$//;
        my @tags = split(/\|/, $proper_tags);
        my $tags_str = $self->_format_tag_collection(
            %args,
            in_list=>0,
            tags_array=>\@tags);
        $row_hash->{all_tags} = $tags_str;
        $row_hash->{route_prefix} = $self->{route_prefix};
        my $text = $tobj->fill_in(data_hash=>$row_hash,
                                  template=>$self->{row_template});
        push @out, $text;
    }
    push @out, "</ul>\n";

    my $results = join("\n", @out);

    return $results;
} # _format_rows


sub _create_taglist {
    my $self = shift;
    my %args = @_;

    my @rows = @{$args{rows}};

    my %all_tags = ();
    foreach my $row_hash (@rows)
    {
        # iterate over the tags
        my @tags = split(/\|/, $row_hash->{$self->{tagfield}});
        foreach my $tag (@tags)
        {
            if ($tag)
            {
                $all_tags{$tag}++;
            }
        }
    }
    return %all_tags;
} # _create_taglist


sub _format_tagcloud {
    my $self = shift;
    my %args = @_;

    my $cloud = HTML::TagCloud->new(levels=>30);
    my @out = ();
    push @out, '<div id="tagcloud">';
    foreach my $tag (nsort keys %{$args{all_tags}})
    {
        my $tq = '';
        if (!$args{tags_query})
        {
            $tq = $tag;
        }
        elsif ($args{tags_query} =~ /\Q$tag\E/)
        {
            # this tag is already in the query
            $tq = $args{tags_query};
        }
        else
        {
            $tq = "$args{tags_query}+${tag}";
        }
        my $tag_url = "$args{location}/tags/$tq";
        $cloud->add($tag, $tag_url, $args{all_tags}->{$tag});
    }
    my $tc = $cloud->html_and_css();
    push @out, $tc;
    push @out, "</div>\n";

    my $taglist = join("\n", @out);

    return $taglist;
} # _format_tagcloud


sub _format_taglist {
    my $self = shift;
    my %args = @_;

    my @out = ();
    push @out, '<div id="alltags">';
    if (exists $args{total_tags}
            and defined $args{total_tags}
            and $args{total_tags})
    {
        push @out, "<p>Tag-count: $args{total_tags}</p>";
    }
    push @out, "<ul id='listtag'>\n";
    my $tl = $self->_format_tag_collection(
        %args,
        in_list=>1,
    );
    push @out, $tl;
    push @out, "</ul>\n";
    push @out, "</div>\n";

    my $taglist = join("\n", @out);

    return $taglist;
} # _format_taglist


sub _format_tag_collection {
    my $self = shift;
    my %args = @_;

    my $tags_query = $args{tags_query};
    my $tags_action = $args{tags_action};
    my @tags = ($args{all_tags} ? nsort keys %{$args{all_tags}} : nsort @{$args{tags_array}});
    my $qquery = '';
    my @qq = ();
    push @qq, "q=$args{q}" if $args{q};
    push @qq, "p=$args{p}" if $args{p};
    my $qquery = join('&', @qq);

    my $tobj = Text::NeatTemplate->new();
    my @out = ();
    foreach my $tag (@tags)
    {
        my $tag_label = $tag;
        $tag_label =~ s/-/ /g; # remove dashes
        my $tq = '';
        if (!$tags_query)
        {
            $tq = $tag;
        }
        elsif ($tags_query =~ /\Q$tag\E/)
        {
            # this tag is already in the query
            $tq = $tags_query;
        }
        else
        {
            $tq = "${tags_query}+${tag}";
        }
        push @out, "<li>" if $args{in_list};
        push @out, $tobj->fill_in(data_hash=>{tag=>$tag,
            tag_label=>$tag_label,
            num_tags=>(defined $args{all_tags} ? $args{all_tags}->{$tag} : undef),
            in_list=>$args{in_list},
            not_in_list=>!$args{in_list},
            tags_query=>$tq,
            qquery=>$qquery,
            url=>$tags_action},
            template=>$self->{tags_template});
        push @out, "</li>\n" if $args{in_list};
    }

    my $taglist = join("\n", @out);

    return $taglist;
} # _format_tag_collection


sub _format_tag_query {
    my $self = shift;
    my %args = @_;

    my $tags_query = $args{tags_query};
    my $tags_action = $args{tags_action};
    my @terms = split(/[ +]/, $tags_query);

    my $tobj = Text::NeatTemplate->new();
    my @out = ();
    foreach my $tag (@terms)
    {
        my $tq = '';
        if (!$tags_query)
        {
            $tq = $tag;
        }
        elsif ($tags_query =~ /\Q$tag\E/)
        {
            # this tag is already in the query
            $tq = $tags_query;
        }
        else
        {
            $tq = "${tags_query}+${tag}";
        }
        push @out, $tobj->fill_in(data_hash=>{
                %args,
                tag=>$tag,
                tags_query=>$tq,
                url=>$tags_action},
            template=>$self->{tag_query_template});
    }

    my $taglist = join("\n", @out);

    return $taglist;
} # _format_tag_query


sub _format_q_query {
    my $self = shift;
    my %args = @_;

    if (!$args{q})
    {
        return '';
    }
    my @terms = split(/[ +]/, $args{q});

    my $tobj = Text::NeatTemplate->new();
    my @out = ();
    foreach my $term (@terms)
    {
        push @out, $tobj->fill_in(data_hash=>{
                %args,
                qterm=>$term,
                tags_query=>$args{tags_query},
                qquery=>$args{q},
                url=>$args{action}},
            template=>$self->{q_query_template});
    }

    my $qlist = join("\n", @out);

    return $qlist;
} # _format_q_query

1; # End of Marky::DbTable

__END__

=pod

=encoding UTF-8

=head1 NAME

Marky::DbTable - Marky::DbTable - querying one database table

=head1 VERSION

version 0.035

=head1 SYNOPSIS

    use Marky::DbTable;;

=head1 DESCRIPTION

Bookmarking and Tutorial Library application.
Querying one database table, returning result.

=head1 NAME

Marky::DbTable - querying one database table

=head1 VERSION

version 0.035

=head1 METHODS

=head2 new

Create a new object, setting global values for the object.

    my $obj = Marky::DbTable->new(
        database=>$database);

=head2 query_raw

Query the database, return an array of results.

$results = $dbtable->query_raw($sql);

=head2 query

Query the database, return results and query-tags.

$results = $dbtable->query(
    location=>$base_url,
    %args);

=head2 taglist

Query the database, return a taglist

=head2 tagcloud

Query the database, return a tagcloud.

=head2 total_records

Query the database, return the total number of records.

=head2 what_error

There was an error, what was it?

=head1 Helper Functions

These are functions which are NOT exported by this plugin.

=head2 _set_defaults

Set the defaults for the object if they are not defined already.

=head2 _connect

Connect to the database
If we've already connected, do nothing.

=head2 _search

Search the database;
returns the total, the query, and the results for the current page.

$hashref = $dbtable->_search(
q=>$query_string,
tags=>$tags,
p=>$p,
n=>$items_per_page,
sort_by=>$order_by,
);

=head2 _process_request

Process the request, return HTML
Note that if there are no query-strings, it will return ALL the results.
It's so annoying to have a search-engine which barfs at empty searches.

$dbtable->_process_request(%args);

=head2 _process_taglist

Process the request, return HTML of all the tags.

$dbtable->_process_taglist(%args);

=head2 _process_tagcloud

Process the request, return HTML of all the tags.

$dbtable->_process_tagcloud(%args);

=head2 _total_records

Find the total records in the database.

$dbtable->_total_records();

=head2 _build_where

Build (part of) a WHERE condition

$where_cond = $dbtable->build_where(
    q=>$query_string,
    field=>$field_name,
);

=head2 _query_to_sql

Convert a query string to an SQL select statement
While this leverages on Select::Query, it does its own thing
for a generic query and for a tags query

$sql = $dbtable->_query_to_sql(
q=>$query_string,
tags=>$tags,
p=>$p,
where=>$where,
n=>$items_per_page,
sort_by=>$order_by,
sort_by2=>$order_by2,
sort_by3=>$order_by3,
);

=head2 _format_searchform

Format an array of results hashrefs into HTML

$result = $self->_format_searchform(
    total=>$total,
    tags_query=>$tags_query,
    location=>$action_url);

=head2 _format_pagination

Format the prev/next links.

$result = $self->_format_pagination(
    total=>$total,
    tags_query=>$tags_query,
    location=>$action_url);

=head2 _format_rows

Format an array of results hashrefs into HTML

$result = $self->_format_rows(
    rows=>$result_arrayref,
    total=>$total,
    tags_query=>$tags_query,
    tags_action=>$action_url);

=head2 _create_taglist

Count up all the tags in the results.

%all_tags = $self->_create_taglist(
    rows=>$result_arrayref);

=head2 _format_tagcloud

Format a hash of tags into HTML

$tagcloud = $dbtable->_format_tagcloud(
    all_tags=>\%all_tags,
    tags_query=>$tags_query,
    tags_action=>$action_url);

=head2 _format_taglist

Format a hash of tags into HTML

$taglist = $dbtable->_format_taglist(
    all_tags=>\%all_tags,
    tags_query=>$tags_query,
    tags_action=>$action_url);

=head2 _format_tag_collection

Format an array of tags into HTML

$taglist = $dbtable->_format_tag_collection(
    in_list=>0,
    all_tags=>\%all_tags,
    tags_array=>\@tags,
    tags_query=>$tags_query,
    tags_action=>$action_url);

=head2 _format_tag_query

Format a tag query into components which can be removed from the query

$tagq_str = $dbtable->_format_tag_query(
    tags_query=>$tags_query,
    tags_action=>$action_url);

=head2 _format_q_query

Format a q query into components which can be removed from the query

$tagq_str = $dbtable->_format_q_query(
    q=>$q,
    tags_query=>$tags_query,
    action=>$action_url);

=head1 AUTHOR

Kathryn Andersen <perlkat@katspace.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kathryn Andersen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
