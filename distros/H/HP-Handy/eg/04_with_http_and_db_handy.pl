######################################################################
#
# 04_with_http_and_db_handy.pl - HP::Handy + HTTP::Handy + DB::Handy
#                                three-layer web CRUD application
#
# Run: perl eg/04_with_http_and_db_handy.pl [port]
# Then open http://localhost:8080/
#
# Demonstrates:
#   render_string, render_file (HP::Handy -- view layer)
#   HTTP::Handy PSGI server    (HTTP::Handy -- server layer)
#   DB::Handy CRUD             (DB::Handy   -- model layer)
#   Routes: GET /           -- item list
#           GET /add        -- add form
#           POST /add       -- insert new item
#           GET /edit?id=N  -- edit form
#           POST /edit      -- update item
#           POST /delete    -- delete item
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use File::Spec;

use lib 'lib';
use HP::Handy;
use HTTP::Handy;
use DB::Handy;

my $port = $ARGV[0] || 8080;

######################################################################
# Model: DB::Handy setup
######################################################################
my $dbdir = File::Spec->catfile(File::Spec->tmpdir(), "hp_http_db_$$");
mkdir($dbdir, 0700) or die "Cannot mkdir $dbdir: $!";

END {
    if (defined $dbdir && -d $dbdir) {
        opendir(DBDIR, $dbdir) or last;
        my @f = grep { $_ ne '.' && $_ ne '..' } readdir(DBDIR);
        closedir(DBDIR);
        for my $f (@f) {
            my $fp = File::Spec->catfile($dbdir, $f);
            if (-d $fp) {
                opendir(SUB, $fp) or next;
                my @sf = grep { $_ ne '.' && $_ ne '..' } readdir(SUB);
                closedir(SUB);
                unlink File::Spec->catfile($fp, $_) for @sf;
                rmdir $fp;
            }
            else {
                unlink $fp;
            }
        }
        rmdir $dbdir;
    }
}

my $DB = DB::Handy->new(data_dir => $dbdir);
{
    my $dbh = $DB->connect("dbi:Handy:dbname=app", '', '');
    $dbh->do(<<'SQL');
CREATE TABLE items (
    id       INTEGER,
    name     VARCHAR(60),
    category VARCHAR(30),
    price    INTEGER,
    note     VARCHAR(200)
)
SQL
    my $ins = $dbh->prepare(
        "INSERT INTO items (id,name,category,price,note) VALUES (?,?,?,?,?)"
    );
    $ins->execute(1, 'Perl Cookbook 2nd Ed', 'Book',   3500, 'Classic reference');
    $ins->execute(2, 'USB 4-port Hub',       'Gadget',  980, 'Bus-powered');
    $ins->execute(3, 'Learning Perl 7th Ed', 'Book',   2800, 'Best beginner book');
    $ins->execute(4, 'Mechanical Keyboard',  'Gadget', 8900, 'Tactile switches');
    $ins->execute(5, 'Wireless Mouse',       'Gadget', 2400, '');
    $ins->finish;
    $dbh->disconnect;
}

######################################################################
# Model helpers
######################################################################
sub db_all {
    my $dbh  = $DB->connect("dbi:Handy:dbname=app", '', '');
    my $sth  = $dbh->prepare("SELECT * FROM items ORDER BY id");
    $sth->execute();
    my @rows;
    while (my $r = $sth->fetchrow_hashref()) { push @rows, { %$r } }
    $sth->finish;
    $dbh->disconnect;
    return \@rows;
}

sub db_get {
    my ($id) = @_;
    my $dbh = $DB->connect("dbi:Handy:dbname=app", '', '');
    my $sth = $dbh->prepare("SELECT * FROM items WHERE id = ?");
    $sth->execute($id);
    my $row = $sth->fetchrow_hashref();
    my %copy = $row ? %$row : ();
    $sth->finish;
    $dbh->disconnect;
    return \%copy;
}

sub db_insert {
    my ($name, $category, $price, $note) = @_;
    my $dbh = $DB->connect("dbi:Handy:dbname=app", '', '');
    my $sth = $dbh->prepare(
        "INSERT INTO items (id,name,category,price,note) VALUES (?,?,?,?,?)"
    );
    # Determine next id
    my $sth2 = $dbh->prepare("SELECT id FROM items ORDER BY id");
    $sth2->execute();
    my $max = 0;
    while (my $r = $sth2->fetchrow_hashref()) {
        $max = $r->{id} if $r->{id} > $max;
    }
    $sth2->finish;
    $sth->execute($max + 1, $name, $category, $price, $note);
    $sth->finish;
    $dbh->disconnect;
}

sub db_update {
    my ($id, $name, $category, $price, $note) = @_;
    my $dbh = $DB->connect("dbi:Handy:dbname=app", '', '');
    $dbh->do(
        "UPDATE items SET name=?, category=?, price=?, note=? WHERE id=?",
        undef, $name, $category, $price, $note, $id
    );
    $dbh->disconnect;
}

sub db_delete {
    my ($id) = @_;
    my $dbh = $DB->connect("dbi:Handy:dbname=app", '', '');
    $dbh->do("DELETE FROM items WHERE id = ?", undef, $id);
    $dbh->disconnect;
}

######################################################################
# View: inline templates
######################################################################
my $BASE = <<'BASE';
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>{% block title %}Item CRUD{% endblock %} - HP+HTTP+DB Demo</title>
<style>
* { box-sizing: border-box; }
body { font-family: sans-serif; max-width: 800px; margin: 32px auto; padding: 0 16px; color: #222; }
h1   { color: #336699; border-bottom: 2px solid #336699; padding-bottom: 6px; }
nav  { margin-bottom: 20px; }
nav a { margin-right: 16px; color: #336699; text-decoration: none; font-weight: bold; }
nav a:hover { text-decoration: underline; }
table { border-collapse: collapse; width: 100%; margin-bottom: 16px; }
th, td { padding: 8px 10px; border: 1px solid #ccc; text-align: left; vertical-align: top; }
th { background: #336699; color: #fff; }
tr:nth-child(even) { background: #f5f8fb; }
.btn { display: inline-block; padding: 5px 12px; border: none; border-radius: 3px;
       cursor: pointer; font-size: 13px; text-decoration: none; }
.btn-primary { background: #336699; color: #fff; }
.btn-warning { background: #e67e22; color: #fff; }
.btn-danger  { background: #c0392b; color: #fff; }
.btn:hover   { opacity: 0.85; }
form.inline { display: inline; }
label { display: block; margin-top: 10px; font-weight: bold; font-size: 13px; }
input[type=text], input[type=number], select, textarea {
    width: 100%; padding: 6px 8px; border: 1px solid #ccc; border-radius: 3px;
    font-size: 14px; margin-top: 3px; }
.form-group { max-width: 480px; }
.actions { margin-top: 16px; }
.msg { background: #d4edda; border: 1px solid #c3e6cb; padding: 8px 12px;
       border-radius: 3px; margin-bottom: 14px; color: #155724; }
.price { text-align: right; }
tfoot td { font-weight: bold; background: #eef2f7; }
</style>
</head>
<body>
<nav>
  <a href="/">&#x2302; Home</a>
  <a href="/add">&#x271A; Add Item</a>
</nav>
{% block content %}{% endblock %}
</body>
</html>
BASE

my $INDEX = <<'INDEX';
{% extends "base.html" %}
{% block title %}Item List{% endblock %}
{% block content %}
<h1>Item List</h1>
{% if msg %}<div class="msg">{{ msg }}</div>{% endif %}
{% if items %}
<table>
<thead><tr><th>ID</th><th>Name</th><th>Category</th><th class="price">Price (JPY)</th><th>Note</th><th>Actions</th></tr></thead>
<tbody>
{% for item in items %}
<tr>
  <td>{{ item.id }}</td>
  <td>{{ item.name }}</td>
  <td>{{ item.category }}</td>
  <td class="price">{{ item.price | commify }}</td>
  <td>{{ item.note }}</td>
  <td>
    <a class="btn btn-warning" href="/edit?id={{ item.id }}">Edit</a>
    <form class="inline" method="post" action="/delete"
          onsubmit="return confirm('Delete {{ item.name }}?')">
      <input type="hidden" name="id" value="{{ item.id }}">
      <button class="btn btn-danger" type="submit">Del</button>
    </form>
  </td>
</tr>
{% endfor %}
</tbody>
<tfoot>
<tr><td colspan="3">Total {{ items | count }} items</td>
    <td class="price">{{ total | commify }}</td><td colspan="2"></td></tr>
</tfoot>
</table>
{% else %}
<p>No items. <a href="/add">Add one</a>.</p>
{% endif %}
{% endblock %}
INDEX

my $ADD_FORM = <<'ADD';
{% extends "base.html" %}
{% block title %}Add Item{% endblock %}
{% block content %}
<h1>Add Item</h1>
<div class="form-group">
<form method="post" action="/add">
  <label>Name</label>
  <input type="text" name="name" value="{{ name }}" required>
  <label>Category</label>
  <select name="category">
    {% for cat in categories %}
    <option value="{{ cat }}"{% if cat == category %} selected{% endif %}>{{ cat }}</option>
    {% endfor %}
  </select>
  <label>Price (JPY)</label>
  <input type="number" name="price" value="{{ price }}" min="0" required>
  <label>Note</label>
  <textarea name="note" rows="3">{{ note }}</textarea>
  <div class="actions">
    <button class="btn btn-primary" type="submit">Save</button>
    <a class="btn" href="/" style="background:#999;color:#fff">Cancel</a>
  </div>
</form>
</div>
{% endblock %}
ADD

my $EDIT_FORM = <<'EDIT';
{% extends "base.html" %}
{% block title %}Edit Item #{{ item.id }}{% endblock %}
{% block content %}
<h1>Edit Item #{{ item.id }}</h1>
<div class="form-group">
<form method="post" action="/edit">
  <input type="hidden" name="id" value="{{ item.id }}">
  <label>Name</label>
  <input type="text" name="name" value="{{ item.name }}" required>
  <label>Category</label>
  <select name="category">
    {% for cat in categories %}
    <option value="{{ cat }}"{% if cat == item.category %} selected{% endif %}>{{ cat }}</option>
    {% endfor %}
  </select>
  <label>Price (JPY)</label>
  <input type="number" name="price" value="{{ item.price }}" min="0" required>
  <label>Note</label>
  <textarea name="note" rows="3">{{ item.note }}</textarea>
  <div class="actions">
    <button class="btn btn-primary" type="submit">Update</button>
    <a class="btn" href="/" style="background:#999;color:#fff">Cancel</a>
  </div>
</form>
</div>
{% endblock %}
EDIT

my @CATEGORIES = qw(Book Gadget Stationery Other);

######################################################################
# View helper: render page template with base layout
######################################################################
my $TMPDIR_VIEW = File::Spec->catfile(File::Spec->tmpdir(), "hp_view_$$");
mkdir($TMPDIR_VIEW, 0700) or die "Cannot mkdir $TMPDIR_VIEW: $!";
END {
    if (defined $TMPDIR_VIEW && -d $TMPDIR_VIEW) {
        opendir(VD, $TMPDIR_VIEW) or last;
        unlink File::Spec->catfile($TMPDIR_VIEW, $_)
            for grep { $_ ne '.' && $_ ne '..' } readdir(VD);
        closedir(VD);
        rmdir $TMPDIR_VIEW;
    }
}

sub render_page {
    my ($page_src, $vars) = @_;
    open(BASE_FH, '>' . File::Spec->catfile($TMPDIR_VIEW, 'base.html')) or die $!;
    print BASE_FH $BASE;
    close BASE_FH;
    my $t = HP::Handy->new(template_dir => $TMPDIR_VIEW, auto_escape => 1);
    $t->add_filter('commify', sub {
        my $n = defined $_[0] ? int($_[0]) : 0;
        $n =~ s/(\d)(?=(\d{3})+$)/$1,/g;
        return $n;
    });
    return $t->render_string($page_src, $vars);
}

######################################################################
# Controller: parse POST body
######################################################################
sub parse_body {
    my ($env) = @_;
    my $len  = $env->{CONTENT_LENGTH} || 0;
    my $body = '';
    if ($len > 0) {
        $env->{'psgi.input'}->read($body, $len);
    }
    my %params;
    for my $pair (split /&/, $body) {
        my ($k, $v) = split /=/, $pair, 2;
        next unless defined $k;
        $k =~ s/\+/ /g; $k =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
        $v = '' unless defined $v;
        $v =~ s/\+/ /g; $v =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
        $params{$k} = $v;
    }
    return \%params;
}

sub parse_query {
    my ($qs) = @_;
    $qs = '' unless defined $qs;
    my %params;
    for my $pair (split /&/, $qs) {
        my ($k, $v) = split /=/, $pair, 2;
        next unless defined $k;
        $k =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
        $v = '' unless defined $v;
        $v =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
        $params{$k} = $v;
    }
    return \%params;
}

######################################################################
# PSGI application
######################################################################
my $app = sub {
    my $env    = shift;
    my $method = $env->{REQUEST_METHOD};
    my $path   = $env->{PATH_INFO};

    # GET /  -- list
    if ($method eq 'GET' && ($path eq '/' || $path eq '')) {
        my $q    = parse_query($env->{QUERY_STRING});
        my $msg  = $q->{msg};
        my $rows = db_all();
        my $total = 0;
        $total += $_->{price} for @$rows;
        my $html = render_page($INDEX, {
            items      => $rows,
            total      => $total,
            msg        => $msg,
        });
        return HTTP::Handy->response_html($html);
    }

    # GET /add
    if ($method eq 'GET' && $path eq '/add') {
        my $html = render_page($ADD_FORM, {
            categories => \@CATEGORIES,
            name => '', category => 'Book', price => '', note => '',
        });
        return HTTP::Handy->response_html($html);
    }

    # POST /add
    if ($method eq 'POST' && $path eq '/add') {
        my $p = parse_body($env);
        my $name = $p->{name}     || '';
        my $cat  = $p->{category} || 'Other';
        my $price= $p->{price}    || 0;
        my $note = $p->{note}     || '';
        if ($name ne '') {
            db_insert($name, $cat, $price, $note);
            return HTTP::Handy->response_redirect('/?msg=Item+added');
        }
        my $html = render_page($ADD_FORM, {
            categories => \@CATEGORIES,
            name => $name, category => $cat, price => $price, note => $note,
        });
        return HTTP::Handy->response_html($html);
    }

    # GET /edit?id=N
    if ($method eq 'GET' && $path eq '/edit') {
        my $q    = parse_query($env->{QUERY_STRING});
        my $item = db_get($q->{id} || 0);
        unless ($item->{id}) {
            return [404, [ 'Content-Type', 'text/plain' ], [ 'Not found' ]];
        }
        my $html = render_page($EDIT_FORM, {
            item       => $item,
            categories => \@CATEGORIES,
        });
        return HTTP::Handy->response_html($html);
    }

    # POST /edit
    if ($method eq 'POST' && $path eq '/edit') {
        my $p     = parse_body($env);
        my $id    = $p->{id}       || 0;
        my $name  = $p->{name}     || '';
        my $cat   = $p->{category} || 'Other';
        my $price = $p->{price}    || 0;
        my $note  = $p->{note}     || '';
        if ($id && $name ne '') {
            db_update($id, $name, $cat, $price, $note);
            return HTTP::Handy->response_redirect('/?msg=Item+updated');
        }
        my $item = db_get($id);
        my $html = render_page($EDIT_FORM, {
            item       => $item,
            categories => \@CATEGORIES,
        });
        return HTTP::Handy->response_html($html);
    }

    # POST /delete
    if ($method eq 'POST' && $path eq '/delete') {
        my $p  = parse_body($env);
        my $id = $p->{id} || 0;
        db_delete($id) if $id;
        return HTTP::Handy->response_redirect('/?msg=Item+deleted');
    }

    return [404, [ 'Content-Type', 'text/plain' ], [ "Not Found: $path" ]];
};

HTTP::Handy->run(app => $app, port => $port);
