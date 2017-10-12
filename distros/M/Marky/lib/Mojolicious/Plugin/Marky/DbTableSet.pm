package Mojolicious::Plugin::Marky::DbTableSet;
$Mojolicious::Plugin::Marky::DbTableSet::VERSION = '0.035';
#ABSTRACT: Mojolicious::Plugin::Marky::DbTableSet - querying one database table

use Mojo::Base 'Mojolicious::Plugin';
use Marky::DbTable;
use Marky::Bookmarker;
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


sub register {
    my ( $self, $app, $conf ) = @_;

    $self->_init($app,$conf);

    $app->helper( 'marky_do_query' => sub {
        my $c        = shift;
        my %args = @_;

        return $self->_do_query($c);
    } );

    $app->helper( 'marky_table_list' => sub {
        my $c        = shift;
        my %args = @_;

        return $self->_make_table_list($c);
    } );

    $app->helper( 'marky_table_array' => sub {
        my $c        = shift;
        my %args = @_;

        my @tables = sort keys %{$self->{dbtables}};
        return \@tables;
    } );
    $app->helper( 'marky_total_records' => sub {
        my $c        = shift;
        my %args = @_;

        return $self->_total_records($c,%args);
    } );

    $app->helper( 'marky_db_related_list' => sub {
        my $c        = shift;
        my %args = @_;

        return $self->_make_db_related_list($c,%args);
    } );

    $app->helper( 'marky_taglist' => sub {
        my $c        = shift;
        my %args = @_;

        return $self->_taglist($c,%args);
    } );

    $app->helper( 'marky_tagcloud' => sub {
        my $c        = shift;
        my %args = @_;

        return $self->_tagcloud($c,%args);
    } );

    $app->helper( 'marky_set_options' => sub {
        my $c        = shift;
        my %args = @_;

        return $self->_set_options($c,%args);
    } );
    $app->helper( 'marky_settings' => sub {
        my $c        = shift;
        my %args = @_;

        return $self->_settings($c,%args);
    } );
    $app->helper( 'marky_add_bookmark_form' => sub {
        my $c        = shift;
        my %args = @_;

        return $self->_add_bookmark_form($c,%args);
    } );
    $app->helper( 'marky_add_bookmark_bookmarklet' => sub {
        my $c        = shift;
        my %args = @_;

        return $self->_add_bookmark_bookmarklet($c,%args);
    } );
    $app->helper( 'marky_save_new_bookmark' => sub {
        my $c        = shift;
        my %args = @_;

        return $self->_save_new_bookmark($c,%args);
    } );
}


sub _init {
    my $self = shift;
    my $app = shift;
    my $conf = shift;

    $self->{route_prefix} = $app->config->{route_prefix};
    $self->{dbtables} = {};
    $self->{edit_tables} = {};
    foreach my $t (sort keys %{$app->config->{tables}})
    {
        $self->{dbtables}->{$t} = Marky::DbTable->new(%{$app->config->{tables}->{$t}});
        if (exists $app->config->{tables}->{$t}->{editing}
                and ref $app->config->{tables}->{$t}->{editing} eq 'HASH')
        {
            $self->{edit_tables}->{$t} = Marky::Bookmarker->new(%{$app->config->{tables}->{$t}->{editing}});
        }
    }
    return $self;
} # _init


sub _do_query {
    my $self = shift;
    my $c = shift;
    my $app = $c->app;

    my $db = $c->param('db');
    if (!exists $self->{dbtables}->{$db})
    {
        $c->render(template => 'apperror',
            errormsg=>"<p>No such db: $db</p>");
        return undef;
    }

    my $tags = $c->param('tags');
    my $q = $c->param('q');
    my $p = $c->param('p');
    my $where = $c->param('where');

    my $n = $c->session('n');
    my $sort_by = $c->session("${db}_sort_by");
    my $sort_by2 = $c->session("${db}_sort_by2");
    my $sort_by3 = $c->session("${db}_sort_by3");

    my $delterm = $c->param('delterm');
    if ($delterm && $q)
    {
        $q =~ s/\b[ +]?$delterm\b//;
        $q =~ s/[ +]$//;
        $q =~ s/^[ +]//;
        $c->param('q'=>$q);
        $c->param(delterm=>undef);
    }
    my $deltag = $c->param('deltag');
    if ($deltag && $tags)
    {
        $tags =~ s/\b[ +]?$deltag\b//;
        $tags =~ s/[ +]$//;
        $tags =~ s/^[ +]//;
        $c->param('tags'=>$tags);
        $c->param(deltag=>undef);
    }
    my $opt_url = $c->url_for("/db/$db/opt");
    my $location = $c->url_for("/db/$db");
    my $res = $self->{dbtables}->{$db}->query(location=>$location,
        opt_url=>$opt_url,
        db=>$db,
        q=>$q,
        tags=>$tags,
        where=>$where,
        n=>$n,
        p=>$p,
        sort_by=>$sort_by,
        sort_by2=>$sort_by2,
        sort_by3=>$sort_by3,
        show_sql=>$app->config->{tables}->{$db}->{show_sql},
    );
    if (!defined $res)
    {
        $c->render(template => 'apperror',
            errormsg=>$self->{dbtables}->{$db}->what_error());
        return undef;
    }

    $c->content('footer',$res->{pagination});
    $c->content_for('footer',$res->{searchform});
    $c->stash('query_taglist', $res->{query_tags});

    $c->stash('results' => $res->{results});
    $c->render(template => 'results');
} # _do_query


sub _total_records {
    my $self  = shift;
    my $c  = shift;

    my $db = $c->param('db');

    my $total = $self->{dbtables}->{$db}->total_records();
    if (!defined $total)
    {
        $c->render(template => 'apperror',
            errormsg=>$self->{dbtables}->{$db}->what_error());
        return undef;
    }
    return $total;
} # _total_records


sub _make_db_related_list {
    my $self  = shift;
    my $c  = shift;

    my $db = $c->param('db');
    my $db_url = $c->url_for("/db/$db");
    my @out = ();
    push @out, "<div class='dblist'><ul>";
    push @out, "<li><a href='${db_url}'>$db</a></li>";
    foreach my $t (qw(taglist tagcloud))
    {
        push @out, "<li><a href='${db_url}/$t'>$db $t</a></li>";
    }
    push @out, "</ul></div>";
    my $out = join("\n", @out);
    return $out;
} # _make_db_related_list


sub _make_table_list {
    my $self  = shift;
    my $c  = shift;

    my @out = ();
    push @out, "<div class='dblist'><ul>";
    foreach my $t (sort keys %{$self->{dbtables}})
    {
        my $url = $c->url_for("/db/$t");
        push @out, "<li><a href='$url'>$t</a></li>";
    }
    push @out, "</ul></div>";
    my $out = join("\n", @out);
    return $out;
} # _make_table_list


sub _taglist {
    my $self  = shift;
    my $c  = shift;

    my $db = $c->param('db');
    my $opt_url = $c->url_for("/db/$db/opt");
    my $location = $c->url_for("/db/$db");
    my $res = $self->{dbtables}->{$db}->taglist(location=>$location,
        opt_url=>$opt_url,
        db=>$db,
        n=>0,
    );
    if (!defined $res)
    {
        $c->render(template => 'apperror',
            errormsg=>$self->{dbtables}->{$db}->what_error());
        return undef;
    }
    return $res->{results};
} # _taglist


sub _tagcloud {
    my $self  = shift;
    my $c  = shift;

    my $db = $c->param('db');
    my $opt_url = $c->url_for("/db/$db/opt");
    my $location = $c->url_for("/db/$db");
    my $res = $self->{dbtables}->{$db}->tagcloud(location=>$location,
        opt_url=>$opt_url,
        db=>$db,
        n=>0,
    );
    if (!defined $res)
    {
        $c->render(template => 'apperror',
            errormsg=>$self->{dbtables}->{$db}->what_error());
        return undef;
    }
    return $res->{results};
} # _tagcloud


sub _set_options {
    my $self  = shift;
    my $c  = shift;
    my %args = @_;

    # Set options for things like n
    my @db = (sort keys %{$self->{dbtables}});

    my @fields = (qw(n));
    foreach my $db (@db)
    {
        push @fields, "${db}_sort_by";
        push @fields, "${db}_sort_by2";
        push @fields, "${db}_sort_by3";
    }
    my %fields_set = ();
    foreach my $field (@fields)
    {
        my $val = $c->param($field);
        if ($val)
        {
            $c->session->{$field} = $val;
            $fields_set{$field} = 1;
        }
        else
        {
            if ($field =~ /(\w+)_sort_by./)
            {
                # We want to delete later sort-by values
                # if they are blank and the first one was set,
                # because we want to be able to sort by just
                # one or two fields if we want.
                my $db = $1;
                if ($fields_set{"${db}_sort_by"})
                {
                    delete $c->session->{$field};
                }
            }
        }
    }
    my $referrer = $c->req->headers->referrer;
} # _set_options


sub _settings {
    my $self  = shift;
    my $c  = shift;
    my %args = @_;

    my $db = $c->param('db');

    my @fields = (qw(n));
    push @fields, "${db}_sort_by";
    push @fields, "${db}_sort_by2";
    push @fields, "${db}_sort_by3";
    
    my @out = ();
    foreach my $field (@fields)
    {
        my $val = $c->session->{$field};
        push @out, "<p><b>$field:</b> $val</p>";
    }
    my $referrer = $c->req->headers->referrer;
    print STDERR "_settings referrer=$referrer\n";
    push @out, "<p>Back: <a href='$referrer'>$referrer</a></p>";

    return join("\n", @out);
} # _settings


sub _add_bookmark_form {
    my $self  = shift;
    my $c  = shift;
    my %args = @_;

    my $db = $c->param('db');
    if (!exists $self->{edit_tables}->{$db})
    {
        $c->render(template => 'apperror',
            errormsg=>"<p>No such editable db: $db</p>");
        return;
    }

    my %data = ();
    my @fields = $self->{edit_tables}->{$db}->fields();
    foreach my $fn (@fields)
    {
        my $val = $c->param($fn);
        if (defined $val)
        {
            $data{$fn} = $val;
        }
    }
    my $add_url = $c->url_for("/db/$db/add");
    return $self->{edit_tables}->{$db}->bookmark_form(
        action=>$add_url,
        %data,
    );
} # _add_bookmark_form


sub _add_bookmark_bookmarklet {
    my $self  = shift;
    my $c  = shift;
    my %args = @_;

    my $db = $c->param('db');
    if (!exists $self->{edit_tables}->{$db})
    {
        $c->render(template => 'apperror',
            errormsg=>"<p>No such editable db: $db</p>");
        return;
    }

    my $add_url = $c->url_for("/db/$db/add")->to_abs;
    return $self->{edit_tables}->{$db}->bookmarklet(
        %args,
        action=>$add_url,
    );
} # _add_bookmark_bookmarklet


sub _save_new_bookmark {
    my $self  = shift;
    my $c  = shift;
    my %args = @_;

    my $db = $c->param('db');
    if (!exists $self->{edit_tables}->{$db})
    {
        $c->render(template => 'apperror',
            errormsg=>"<p>No such editable db: $db</p>");
        return;
    }
    my @status = ();
    push @status, "<div class='status'>";
    my %data = ();
    my @fields = $self->{edit_tables}->{$db}->fields();
    foreach my $fn (@fields)
    {
        my $val = $c->param($fn);
        if (defined $val)
        {
            $data{$fn} = $val;
            push @status, "<p><span class='field'>$fn</span>: $val</p>";
        }
    }
    push @status, "</div>";
    $c->content('results', join("\n", @status));
    if (!$self->{edit_tables}->{$db}->save_new_bookmark(data=>\%data))
    {
        $c->content_for('results',"<p class='error'>Bookmark-save failed.</p>");
    }
    else
    {
        $c->content_for('results',"<p>Bookmark saved.</p>");
    }
} # _save_new_bookmark

1; # End of Mojolicious::Plugin::Marky::DbTableSet

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Marky::DbTableSet - Mojolicious::Plugin::Marky::DbTableSet - querying one database table

=head1 VERSION

version 0.035

=head1 SYNOPSIS

    use Mojolicious::Plugin::Marky::DbTableSet;;

=head1 DESCRIPTION

Bookmarking and Tutorial Library application.
Querying one database table, returning result.

=head1 NAME

Mojolicious::Plugin::Marky::DbTableSet - querying one database table

=head1 VERSION

version 0.035

=head1 REGISTER

=head1 Helper Functions

These are functions which are NOT exported by this plugin.

=head2 _init

Initialize.

=head2 _do_query

Do a query, looking at the params and session.

=head2 _total_records

Return the total number of records in this db

=head2 _make_db_related_list

Make a taglist/tagcloud list for this db

=head2 _make_table_list

Make a list of all the dbtables.

=head2 _taglist

Make a taglist for a db

=head2 _tagcloud

Make a tagcloud for a db

=head2 _set_options

Set options in the session

=head2 _settings

Show the current settings

=head2 _add_bookmark_form

Create a bookmark form; if the values have been passed in via GET,
then use them to pre-fill the form.

=head2 _add_bookmark_bookmarklet

Create a Javascript bookmarklet

=head2 _save_new_bookmark

Save the bookmark info which we got in the (post) parameters

=head1 AUTHOR

Kathryn Andersen <perlkat@katspace.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kathryn Andersen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
