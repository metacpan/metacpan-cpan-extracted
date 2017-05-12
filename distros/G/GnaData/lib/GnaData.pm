=head1 NAME

GnaData - Routines for converting formats 

=head1 SYNOPSIS

This class does GnaData.

=cut

package GnaData;
use strict;
use DBI;
use IO::Handle;
use IO::File;

$GnaData::VERSION = '0.01';

sub dump_rdb {
    my ($connect, $table, $fh) = @_;
    my ($field);
    my ($i);
    my ($dbh) = DBI->connect($connect);
    my ($sth) = $dbh->prepare("select * from " . $table);
    my (@date_fields) = ();
    $sth->execute();

    my ($line) = join("\t",  @{$sth->{'NAME_lc'}}) ."\n";
    $fh->print($line);
    $line =~ s/[a-z0-9\_\-]/\-/gi;
    $fh->print($line);

    my($i) = 0;
    foreach $field (@{$sth->{'NAME_lc'}}) {
	if (&is_date_field($field)) {
	    push(@date_fields, $i);
	}
	$i++;
    }

    my (@array);

    while (@array = $sth->fetchrow_array) {
	foreach $i (@date_fields) {
	    $array[$i] =~ s/0000\-00\-00//gi;
	    $array[$i] =~ s/^([0-9]{4})\-([0-9]{2})\-([0-9]{2})$/$1$2$3/gi; 
	}   
	$line = join("\t", @array) . "\n";
	$fh->print($line);
    }
    $sth->finish(); 
    $dbh->disconnect;
}

sub load_rdb {
    my ($connect, $table, $inh) = @_;
    my($outh) = IO::File->new("/tmp/gnadata.load.$$", "w");
    my($attributes) = {};
    
    if (defined $outh) {
	my($dbh) = DBI->connect($connect);
	my($sth) = $dbh->prepare("listfields $table");
	$sth->execute();
	my($translate_fields) = $sth->{'NAME_lc'};
	my($field);
	my($i) = 0;
	foreach $field (@{$translate_fields}) {
	    $attributes->{$field} = {};
	    $attributes->{$field}->{'is_date'} = 
		&is_date_field($field);
	    $attributes->{$field}->{'NULLABLE'} =
		$sth->{'NULLABLE'}->[$i];
	    $i++;
	}

	$sth->finish();
	&rdb_to_sqlload($inh, $outh, $translate_fields,
			$attributes);
	$outh->close();
	if (-e "/tmp/gnadata.load.$$") {

	    $dbh->do("delete from $table");
	    $dbh->do('load data local infile ' . "\"/tmp/gnadata.load.$$\"" 
		     . ' into table ' . $table);

	}
	$dbh->disconnect;
	unlink "/tmp/gnadata.load.$$";
    }
}

sub rdb_to_sqlload {
    my ($inh, $outh, 
	$translate_fields, $attr) = @_;
    my ($line);
    my ($first_line) = 1;
    my ($second_line) = 1;
    my ($field);
    my (@infields);
    my (@outfields);
    my (%f);
    my ($i);

    while ($line = $inh->getline()) {
	if ($first_line) {
	    chop $line;

	    @infields = split(/\t/, $line);
	    if ($translate_fields eq undef) {
		@outfields = @infields;
	    } else {
		@outfields = @{$translate_fields};
	    }

	    $first_line = 0;
	    $second_line = 1;
	} elsif ($second_line) {
	    $first_line = 0;
	    $second_line = 0;
	} else {
	    chop $line;
	    %f = ();
	    @f{@infields} = split(/\t/, $line);

	    foreach $field (@outfields) {
		if ($attr->{$field}->{'is_date'} == 1) {
		    $f{$field} =~
			s/^([0-9]{4})([0-9]{2})([0-9]{2})$/$1-$2-$3/;    
		} elsif ($attr->{$field}->{'NULLABLE'} == 1) {
		    $f{$field} = '\N';
		}
	    }
	    $outh->print(join("\t", @f{@outfields}), "\n");
	}
    }
}

sub is_date_field {
    my($field) = @_;
    return ($field =~ /^date/i || $field =~ /date$/i);
}

1;

