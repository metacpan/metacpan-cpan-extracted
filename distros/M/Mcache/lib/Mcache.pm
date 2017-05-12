package Mcache;

use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(new get add del update count id);

our $VERSION = '0.031';

###################

sub new {
    my $classname = shift;
    my $self = {};
    bless($self,$classname);
    $self->_init(@_);
    return $self;
}

sub _init {
    my $self = shift;
    if (@_) {
    }
}

sub DESTROY {
}

###################

sub add {
    my $self = shift;
    my @in = @_;
    my $key;
    if ($in[1]) {
	if ($in[2]) {
	    $key = "$in[2]";
	}
	else {
	    # generate unique KEY
	    $key = "$in[1]"."-".rand(1000000)."-".time."-".rand(3141592652);
	}
	$self->{$in[1]}->{"$key"} = "\"key\": \"$key\", ".$in[0];

	my $str = "\"list\": [";
	my $count = 0;
	my $rndid = rand(314159265);
	foreach my $d (sort keys %{$self->{$in[1]}}) {
	    if ($d eq 'CACHE') {next;}
	    if ($d eq 'STAT') {next;}
	    if ($d eq 'ID') {next;}
	    $str = $str." {".$self->{$in[1]}->{$d}."},";
	    ++$count;
	    $rndid = $rndid + rand(314159265);
	}
	chop($str);
	$str = $str."], \"count\": \"$count\"";
	$self->{$in[1]}->{'CACHE'} = $str;
	$self->{$in[1]}->{'STAT'} = $count;
	$self->{$in[1]}->{'ID'} = $rndid;
	undef $str;
	undef $rndid;
	undef @in;


	return $key;
    }
    else {
	return 0;
    }
}

sub update {
    my $self = shift;
    my @in = @_;
    my $key;
    if ($in[2]) {
        $key = "$in[2]";
	if (exists $self->{$in[1]}->{$in[2]}) {
	    $self->{$in[1]}->{$in[2]} = "\"key\": \"$key\", ".$in[0];

	    my $str = "\"list\": [";
	    my $count = 0;
	    my $rndid = rand(314159265);
	    foreach my $d (sort keys %{$self->{$in[1]}}) {
		if ($d eq 'CACHE') {next;}
		if ($d eq 'STAT') {next;}
		if ($d eq 'ID') {next;}
		$str = $str." {".$self->{$in[1]}->{$d}."},";
		++$count;
		$rndid = $rndid + rand(314159265);
	    }
	    chop($str);
	    $str = $str."], \"count\": \"$count\"";
	    $self->{$in[1]}->{'CACHE'} = $str;
	    $self->{$in[1]}->{'STAT'} = $count;
	    $self->{$in[1]}->{'ID'} = $rndid;
	    undef $str;
	    undef $rndid;
	    undef @in;
	}
	else {
#	    add(@in);
	}
    }
}

sub del {
    my $self = shift;
    my @in = @_;
    if ($in[1]) {
	if (exists $self->{$in[0]}->{$in[1]}) {
	    delete($self->{$in[0]}->{$in[1]});
#	    print "del: $in[1]\n";
	}
	else {
#	    print "no del\n";
	}


	my $str = "\"list\": [";
	my $count = 0;
	my $rndid = rand(314159265);
	foreach my $d (sort keys %{$self->{$in[0]}}) {
	    if ($d eq 'CACHE') {next;}
	    if ($d eq 'STAT') {next;}
	    if ($d eq 'ID') {next;}
	    $str = $str." {(-".$d."-)".$self->{$in[0]}->{$d}."},";
	    ++$count;
	    $rndid = $rndid + rand(314159265);
	}
	chop($str);
	$str = $str."], \"count\": \"$count\"";
	$self->{$in[0]}->{'CACHE'} = $str;
	$self->{$in[0]}->{'STAT'} = $count;
	$self->{$in[0]}->{'ID'} = $rndid;
	undef $str;
	undef $rndid;
	undef @in;

	return 1;
    }
    else {
	return 0;
    }
}

sub get {
    my $self = shift;
    my @in = @_;
    my $key;
    if ($in[1]) {
	my $r = $self->{$in[0]}->{$in[1]};
	if (!$r) {
	    $r = "\"key\": \"undef\"";
	}
	return $r;
    }
    elsif($in[0]) {
	my $r = $self->{$in[0]}->{'CACHE'};
	if (!$r) {
	    return "\"id\": \"null\"";
	}
	else {
	    return $r;
	}
    }
    else {
	return "\"id\": \"undef\"";
    }
}


sub count {
    my $self = shift;
    my @in = @_;
    if ($in[0]) {
	return 	$self->{$in[0]}->{'STAT'};
    }
}

sub id {
    my $self = shift;
    my @in = @_;
    if ($in[0]) {
	return 	$self->{$in[0]}->{'ID'};
    }
}


1;
__END__

=head1 NAME

    Mcache - program cache (DB).

=head1 SYNOPSIS

    use Mcache;

    my $cache = mcache->new();

    $cache->add("Foo Bar 1",1);
    my $key = $cache->add("Foo Bar 2",1);

    my $sel = $cache->get(1);
    print "{".$sel."}\n";

    $cache->del(1,$k);

    $sel = $cache->get(1);
    print "{".$sel."}\n";

=head1 DESCRIPTION

    Mcache - program cache (DB) for storing in the memory pages 
    with editable set of fields. Issuance result holds in the JSON 
    

=head2 EXPORT

    new();

    get(id); # return full data page (all fields) in JSON

    get(id,key); # return a single field with a key

    add(field,id); # add fields on data page id and return unique key

    add(field,id,key); # add fields on data page id with key

    del(id,key); # delete fields

    update(field,id,key); # update fields

    count(id); # count fields on data page id
    
    id(id); # current id for update


    var:
	    id - unique page number
	    key - unique field number

=head1 AUTHOR

Maxim Motylkov, E: mmv@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Maxim Motylkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
