
package IMDB::Local::DB::BaseObject;

use 5.006;
use strict;
use warnings;
use Carp;

=head1 NAME

IMDB::Local::DB::BaseObject - handy wrapper for objects from the database

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 new

=cut

use         IMDB::Local::DB::BaseObjectAccessor;
use base qw(IMDB::Local::DB::BaseObjectAccessor);

use Class::MethodMaker
    [ scalar=> [qw/imdbdb db_table db_key db_key2 db_key3/],
      ];

sub initHandle
{
    my ($self, $table, @keys)=@_;

    #print STDERR "init $self, $table, $keys[0]\n";
    # if no imdbdb handle was given in new() call, then use last handle created
    if ( !defined($self->imdbdb) ) {
	carp "imdbdb handle missing";
    }

    if ( !defined($self->imdbdb->column_info($table)) ) {
	die "unable to locate table $table";
    }

    $self->db_table($table);
    $self->db_key($keys[0]);

    if ( scalar(@keys) > 1 ) {
	$self->db_key2($keys[1]);
	if ( scalar(@keys) > 2 ) {
	    $self->db_key3($keys[2]);
	}
    }

    if ( !$self->db_columns_count() ) {
	$self->db_columns_reset();
	for my $t (@{$self->imdbdb->column_info($table)}) {
	    if ( $self->can('db_ignoredColumns') ) {
		my $ignore=0;
		for my $k ($self->db_ignoredColumns) {
		    if ( $k eq $t->{COLUMN_NAME} ) {
			$ignore=1;
			last;
		    }
		}
		next if ( $ignore );
	    }
	    $self->db_columns_push($t->{COLUMN_NAME});
	}
    }
    $self->add_accessors($self->db_columns);
    return;
}

sub _add_accessors
{
    my $self=shift;
    for (@_) {
	carp("added $_");
    }
    $self->SUPER::add_accessors(@_);
}

sub populate($$)
{
    my ($self, $hash)=@_;

    for my $k (keys %$hash) {
	#print "setting $k:".$hash->{$k}."\n";
	$self->set($k, $hash->{$k});
    }
    return(1);
}

sub populateUsingKeys
{
    my ($self, @keys)=@_;

    if ( !defined($self->db_key) ) {
	die "invalid usage, missing db_key for $self";
    }

    if ( !@keys ) {
	die "no key(s)";
    }

    if ( defined($self->db_key2) ) {
	if ( scalar(@keys) < 2 ) {
	    carp "new called without ".$self->db_key2()." value given";
	}
	if ( defined($self->db_key3) ) {
	    if ( scalar(@keys) < 3 ) {
		carp "new called without ".$self->db_key3()." value given";
	    }
	    $self->populateFromColumns(sprintf("%s='%s' AND %s='%s'", $self->db_key, $keys[0], $self->db_key2, $keys[1], $self->db_key3, $keys[2]));
	}
	else {
	    $self->populateFromColumns(sprintf("%s='%s' AND %s='%s'", $self->db_key, $keys[0], $self->db_key2, $keys[1]));
	}
    }
    else {
	$self->populateFromColumns(sprintf("%s='%s'", $self->db_key, $keys[0]));
    }
}

sub populateUsingKey($$)
{
    my ($self, $key)=@_;
    return $self->populateUsingKeys($key);
}

sub populateFromColumns($$)
{
    my ($self, $where)=@_;

    if ( !defined($self->db_table) ) {
	die "invalid usage, missing db_table for $self";
    }

    my $query="SELECT ".join(',', $self->db_columns)." from ".$self->db_table;
    if ( defined($where) ) {
	$query.=' WHERE '.$where;
    }
    #print STDERR "populating: $query\n";

    my $dbh=$self->imdbdb->dbh();
    my $ref=$dbh->selectrow_hashref($query);
    if ( !$ref ) {
	print STDERR "populating failed on: $query\n";
	return(undef);
    }

#    if ( $self->can('db_ignoredColumns') ) {
#	#print STDERR "ignoring columns\n";
#	for my $k ($self->db_ignoredColumns) {
#	    if ( $ref->{$k} ) {
#		#print STDERR "ignoring column $k\n";
#		delete($ref->{$k});
#	    }
#	}
#    }
    #$self->add_accessors(keys %$ref);
    $self->populate($ref);
}

sub _className($)
{
    my ($self)=@_;

    $self=~m/(IMDB::Local::[^=]+)/o;
    return($1);
}

sub toText($)
{
    my ($self)=@_;
    
    my $text='';

    $text.="class: ".$self->_className()."\n";
    if ( 1 ) {
	for my $field (sort $self->get_accessors()) {
	    my $v=$self->$field();
	    $v='undef' if (!defined($v));
	    $text.="\t$field: $v\n";
	}
    }
    else {
	require Data::Dumper;
	
	my $D=new Data::Dumper([$self]);
	$D->Indent(1);
	my $d=$D->Dump();
	$d=~s/\n\s*\'__FIELDS__\' => \[[^\]]+\]//ogs;
	#$d=~s/\'([^\']+)\' => \'([^\']+)\'/$1:$2/ogs;
	#while ($d=~s/\n                 /\n /) {};
	$text.="$d\n";
    }
    return($text);
}

sub _updateInDB
{
    my $self=shift;
    my $args={@_};

    my $stmt="UPDATE ".$self->db_table." SET ";
    for my $key (keys %{$args}) {
	my $value=$args->{$key};
	if ( !defined($value) ) {
	    $stmt.="$key=NULL, ";
	}
	else {
	    $stmt.="$key='$value', ";
	}
    }
    $stmt=~s/, $//;

    if ( defined($self->db_key2) ) {
	if ( defined($self->db_key3) ) {
	    $stmt.=sprintf("WHERE %s='%s' AND %s='%s' AND %s='%s'", $self->db_key, $self->get($self->db_key),
			   $self->db_key2, $self->get($self->db_key2),
			   $self->db_key3, $self->get($self->db_key3));
	}
	else {
	    $stmt.=sprintf("WHERE %s='%s' AND %s='%s'", $self->db_key, $self->get($self->db_key),
			   $self->db_key2, $self->get($self->db_key2));
	}
    }
    else {
	$stmt.=sprintf("WHERE %s='%s'", $self->db_key, $self->get($self->db_key));
    }

    my $dbh=$self->imdbdb->dbh();
    #print STDERR "invoking: args=".$args."\n";
    #print STDERR "invoking: args=".%{$args}."\n";
    #print STDERR "invoking: ".$stmt."\n";

    $dbh->do($stmt);
    if ( $dbh->err() ) {
	return(0);
    }

    # update our fields so they match
    for my $key (keys %{$args}) {
	my $value=$args->{$key};
	$self->$key($value);
    }
    return(1);
}

sub update($@)
{
    my $self=shift;
    my $args={@_};
    my %updates;
    
    for my $key (keys %{$args}) {
	my $value=$args->{$key};
	my $cur=$self->get($key);
	
	if ( defined($cur) != defined($value) ) {
	    $updates{$key}=$value;
	}
	# either both undefined or both defined
	elsif ( defined($value) && $cur ne $value ) {
	    $updates{$key}=$value;
	}
    }
    if ( %updates ) {
	return $self->_updateInDB(%updates);
    }
    return(0);
}

sub newFromDB($)
{
    my ($self)=@_;

    my $class=$self->_className();

    if ( defined($self->db_key2) ) {
	if ( defined($self->db_key3) ) {
	    return new $class(imdbdb=>$self->imdbdb(),
			      $self->db_key()=>$self->get($self->db_key()),
			      $self->db_key2()=>$self->get($self->db_key2()),
			      $self->db_key3()=>$self->get($self->db_key3()));
	}
	else {
	    return new $class(imdbdb=>$self->imdbdb(),
			      $self->db_key()=>$self->get($self->db_key()),
			      $self->db_key2()=>$self->get($self->db_key2()));
	}
    }
    else {
	return new $class(imdbdb=>$self->imdbdb(),
			  $self->db_key()=>$self->get($self->db_key()));
    }
}

sub delete($)
{
    my ($self)=@_;

    if ( defined($self->db_key2) ) {
	if ( defined($self->db_key3) ) {
	    $self->imdbdb->execute("DELETE from ".$self->db_table()." WHERE ".
				   $self->db_key()."='".$self->get($self->db_key())."' AND ".
				   $self->db_key2()."='".$self->get($self->db_key2())."' AND ".
				   $self->db_key3()."='".$self->get($self->db_key3())."'");
	}
	else {
	    $self->imdbdb->execute("DELETE from ".$self->db_table()." WHERE ".
				   $self->db_key()."='".$self->get($self->db_key())."' AND ".
				   $self->db_key2()."='".$self->get($self->db_key2())."'");
	}
    }
    else {
	$self->imdbdb->execute("DELETE from ".$self->db_table()." WHERE ".
			       $self->db_key()."='".$self->get($self->db_key())."'");
    }
}

sub saveChanges($)
{
    my ($self)=@_;
    
    my $clon=$self->newFromDB();
    my %updates;

    for my $field ($self->get_accessors()) {
	if ( defined($self->get($field)) != defined($clon->get($field)) ) {
	    $updates{$field}=$self->get($field);
	}
	# either both undefined or both defined
	elsif ( defined($self->get($field)) && $self->get($field) ne $clon->get($field) ) {
	    $updates{$field}=$self->get($field);
	}
    }
    if ( %updates ) {
	return $self->_updateInDB(%updates);
    }
    return(0);
}

1;
