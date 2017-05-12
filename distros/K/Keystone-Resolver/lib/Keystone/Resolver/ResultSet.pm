# $Id: ResultSet.pm,v 1.4 2008-04-30 16:37:05 mike Exp $

package Keystone::Resolver::ResultSet;
use strict;
use warnings;
use Encode;


sub new {
    my $class = shift();
    my($site, $findclass, %query) = @_;
    $findclass = "Keystone::Resolver::DB::$findclass" if $findclass !~ /::/;

    my $sort = delete $query{_sort};
    $sort = join(", ", $findclass->sort_fields()) if !$sort;

    # Discard empty elements and those whose names begin with "_"
    %query = map { ($_, $query{$_} ) }
	grep { !/^_/ && defined $query{$_} && $query{$_} ne "" } keys %query;

    # Replace all "'" with "''"; whole terms may still need quoting
    foreach my $key (keys %query) {
	$query{$key} =~ s/['']/''/g;
    }

    # Rather than building a condition by hand here, we should call
    # directly into a Database method that accepts %query whole;
    # unfortunately, that method doesn't exist yet.
    #
    # At the moment, we don't narrow on $site->id() since resolver
    # objects like Services and Providers do not have any concept of
    # ownership -- but that will change.
    my $db = $site->db();
    my $cond = (join(" and ", # "site_id = " . $site->id(),
		     map { $db->quote($_) . " = '" . $query{$_} . "'" } sort keys %query));
    $cond = undef if $cond eq "";
    $site->log(Keystone::Resolver::LogLevel::SQL, 
	       (defined $cond ? "SQL cond: $cond" : "no condition"));

    my($sth, $count, $errmsg) =
	$db->_findcond($findclass, $cond, $sort);
    return (undef, $errmsg) if !defined $sth;
    return bless {
	site => $site,
	class => $findclass,
	db => $db,
	query => \%query,
	sth => $sth,
	count => $count,
	hwm => 0,		# 1-based index of last record read
	objects => [],		# cache of objects made from records read
    }, $class;
}


sub class { shift()->{class} }
sub query { shift()->{query} }
sub count { shift()->{count} }


# Fetches the $i'th object in the RS, where $i is a 1-based index
sub fetch {
    my $this = shift();
    my($i) = @_;

    die "fetch($this) called with non-positive index $i"
	if $i < 1;
    die "fetch($this) called with out-of-range index $i (max=" .
	$this->count() . ")"
	if $i > $this->count();

    my $class = $this->class();
    while ($this->{hwm} < $i) {
	my $ref = $this->{sth}->fetchrow_arrayref();
	if (!defined $ref) {
	    my $errmsg = $this->{sth}->errstr();
	    return (undef, $errmsg)
		if defined $errmsg;
	    die "unexpected end of result-set after " . $this->{hwm} .
		" of " . $this->count() . " records";
	}
	my $object = $class->new($this->{db}, map { decode_utf8($_) } @$ref);
	$this->{objects}->[$this->{hwm}++] = $object;
    }

    return $this->{objects}->[$i-1];
}


1;
