#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use File::Mosaic;
use Digest::MD5;
use IO::File;
use Log::Log4perl qw(:easy);
use Data::Dumper;

#Log::Log4perl->easy_init($DEBUG);

my $tmp_fn = "tmp.ukAw731ou";
my $tmp_dn = "${tmp_fn}.d";

my @data = qw(one two three four five);
my @tags = qw(1 2 3 4 5);


cleanup($tmp_fn, $tmp_dn);

write_test($tmp_fn, $tmp_dn, \@data, \@tags);
fetch_tags_test($tmp_fn, $tmp_dn, \@data, \@tags);
fetch_test($tmp_fn, $tmp_dn, \@data, \@tags);
insert_before_test($tmp_fn, $tmp_dn, \@data, \@tags);
insert_after_test($tmp_fn, $tmp_dn, \@data, \@tags);
replace_test($tmp_fn, $tmp_dn, \@data, \@tags);
remove_test($tmp_fn, $tmp_dn, \@data, \@tags);
reorder_tags_test($tmp_fn, $tmp_dn, \@data, \@tags);

cleanup($tmp_fn, $tmp_dn);

sub write_test {
    my ($fn, $dn, $aref, $tag_aref) = @_;

    write_mosaic($fn, $dn, $aref, $tag_aref);

    my $sum = digest_array($aref);
    my $sum_test = digest_file($fn);

    is($sum, $sum_test);
}

sub fetch_tags_test {
    my ($fn, $dn, $aref, $tag_aref) = @_;

    my $fm = File::Mosaic->new(filename => $fn, mosaic_directory => $dn);
    my @tags = $fm->fetch_tags();

    is_deeply($tag_aref, \@tags);
}

sub fetch_test {
    my ($fn, $dn, $aref, $tag_aref) = @_;
    my $fm = File::Mosaic->new(filename => $fn, mosaic_directory => $dn);
    my $sum = digest_array($aref);

    my $ctxt = Digest::MD5->new();

    for (@$tag_aref) {
        $ctxt->add($fm->fetch(tag => $_));
    }

    my $sum_test = $ctxt->hexdigest;
    is($sum, $sum_test);
}

sub insert_before_test {
    my ($fn, $dn, $aref, $tag_aref) = @_;
    my $fm = File::Mosaic->new(filename => $fn, mosaic_directory => $dn);

    unshift @$aref, 'zero';
    unshift @$tag_aref, 0;

    $fm->insert_before(tag => $tag_aref->[0], before_tag => $tag_aref->[1], mosaic => 'zero');
    $fm->close();

    my $sum = digest_array($aref);
    my $sum_test = digest_file($fn);

    is($sum, $sum_test);
}

sub insert_after_test {
    my ($fn, $dn, $aref, $tag_aref) = @_;
    my $fm = File::Mosaic->new(filename => $fn, mosaic_directory => $dn);

    push @$aref, 'six';
    push @$tag_aref, 6;

    $fm->insert_after(tag => $tag_aref->[-1], after_tag => $tag_aref->[-2], mosaic => 'six');
    $fm->close();

    my $sum = digest_array($aref);
    my $sum_test = digest_file($fn);

    is($sum, $sum_test);
}

sub append_test {
    my ($fn, $dn, $aref, $tag_aref) = @_;
    my $fm = File::Mosaic->new(filename => $fn, mosaic_directory => $dn);

    push @$aref, 'seven';
    push @$tag_aref, 7;

    $fm->append(tag => '7', mosaic => 'seven');
    $fm->close();

    my $sum = digest_array($aref);
    my $sum_test = digest_file($fn);
    
    is($sum, $sum_test);
}

sub replace_test {
    my ($fn, $dn, $aref, $tag_aref) = @_;

    my $fm = File::Mosaic->new(filename => $fn, mosaic_directory => $dn);

    $aref->[1] = 'ein';

    $fm->replace(tag => '1', mosaic => 'ein');
    $fm->close();

    my $sum = digest_array($aref);
    my $sum_test = digest_file($fn);

    is($sum, $sum_test);
}

sub remove_test {
    my ($fn, $dn, $aref, $tag_aref) = @_;

    my $fm = File::Mosaic->new(filename => $fn, mosaic_directory => $dn);

    shift @$aref;
    shift @$tag_aref;

    $fm->remove(tag => '0');
    $fm->close();

    my $sum = digest_array($aref);
    my $sum_test = digest_file($fn);

    is($sum, $sum_test);
}

sub reorder_tags_test {
    my ($fn, $dn, $aref, $tag_aref) = @_;

    my $fm = File::Mosaic->new(filename => $fn, mosaic_directory => $dn);

    my @tags = $fm->fetch_tags();
    my @data;
    push @data, $fm->fetch(tag => $_) for (@tags);
    my @rdata = reverse @data; 
 
    my @rtags = reverse @tags;
    $fm->reorder_tags(tags => \@rtags);
    my @rtags_test = $fm->fetch_tags();

    is_deeply(\@rtags, \@rtags_test);

    my @rdata_test;
    push @rdata_test, $fm->fetch(tag => $_) for (@rtags);

    is_deeply(\@rdata, \@rdata_test);

    $fm->close();

    my $sum = digest_array(\@rdata_test);
    my $sum_test = digest_file($fn);

    is($sum, $sum_test);
}

#### subs ########################################

sub digest_file {
    my $fn = shift;
    my $finh = IO::File->new($fn) or 
        die "%Error: $! '$fn'!\n";

    my $sum = Digest::MD5->new->addfile($finh)->hexdigest;

    $finh->close();
    return $sum;
}

sub digest_array {
    my $aref = shift;
    return Digest::MD5->new->add(join('', @$aref))->hexdigest;
}

sub write_mosaic {
    my ($fn, $dn, $aref, $tag_aref) = @_;
    my $fm = File::Mosaic->new(filename => $fn, mosaic_directory => $dn);

    for (my $i=0; $i<@$aref; $i++) {
        $fm->append(tag => $tag_aref->[$i], mosaic => $aref->[$i]);
    }

    $fm->close();
}


sub cleanup {
    my ($fn, $dn) = @_;

    unlink($fn) if -f $fn;
    unlink("$dn/.mosaics") if -f "$dn/.mosaics";
    for (glob("$dn/*")) {
        unlink $_;
    }
    rmdir $dn;
}

