#!/usr/bin/perl
use strict;
use warnings;

use HTTP::MultiPartParser  qw[];
use Hash::MultiValue       qw[];
use IO::File               qw[SEEK_SET];
use File::Temp             qw[];

# extracts name and filename values from Content-Disposition header.
# returns the escaped value, due to different behaviour across browsers. 
# (see https://gist.github.com/chansen/7163968)
sub extract_form_data {
    local $_ = shift;
    # Fast exit for common form-data disposition
    if (/\A form-data; \s name="((?:[^"]|\\")*)" (?: ;\s filename="((?:[^"]|\\")*)" )? \z/x) {
        return ($1, $2);
    }

    # disposition type must be form-data
    s/\A \s* form-data \s* ; //xi
      or return;

    my (%p, $k, $v);
    while (length) {
        s/ ^ \s+   //x;
        s/   \s+ $ //x;

        # skip empty parameters and unknown tokens
        next if s/^ [^\s"=;]* \s* ; //x;

        # parameter name (token)
        s/^ ([^\s"=;]+) \s* = \s* //x
          or return;
        $k = lc $1;
        # quoted parameter value
        if (s/^ "((?:[^"]|\\")*)" \s* (?: ; | $) //x) {
            $v = $1;
        }
        # unquoted parameter value (token)
        elsif (s/^ ([^\s";]*) \s* (?: ; | $) //x) {
            $v = $1;
        }
        else {
            return;
        }
        if ($k eq 'name' || $k eq 'filename') {
            return if exists $p{$k};
            $p{$k} = $v;
        }
    }
    return exists $p{name} ? @p{qw(name filename)} : ();
}

my $params  = Hash::MultiValue->new;
my $uploads = Hash::MultiValue->new;

my $part;
my $parser = HTTP::MultiPartParser->new(
    boundary  => '----------0xKhTmLbOuNdArY',
    on_header => sub {
        my ($headers) = @_;

        my $disposition;
        foreach (@$headers) {
            if (/\A Content-Disposition: [\x09\x20]* (.*)/xi) {
                $disposition = $1;
                last;
            }
        }

        (defined $disposition)
          or die q/Content-Disposition header is missing/;

        my ($name, $filename) = extract_form_data($disposition);
        (defined $name)
          or die qq/Invalid Content-Disposition: '$disposition'/;

        $part = {
            name    => $name,
            headers => $headers,
        };

        if (defined $filename) {
            $part->{filename} = $filename;

            if (length $filename) {
                my $fh = File::Temp->new(UNLINK => 1);
                $part->{fh}       = $fh;
                $part->{tempname} = $fh->filename;
            }
        }
    },
    on_body => sub {
        my ($chunk, $final) = @_;

        my $fh = $part->{fh};

        if ($fh) {
            print $fh $chunk
              or die qq/Could not write to file handle: '$!'/;
            if ($final) {
                seek($fh, 0, SEEK_SET)
                  or die qq/Could not rewind file handle: '$!'/;
                $part->{size} = -s $fh;
                $uploads->add($part->{name}, $part);
            }
        }
        else {
            $part->{data} .= $chunk;
            if ($final) {
                $params->add($part->{name}, $part->{data});
            }
        }
    }
);

open my $fh, '<:raw', 't/data/001-content.dat'
  or die;

while () {
    my $n = read($fh, my $buffer, 1024);
    unless ($n) {
        die qq/Could not read from fh: '$!'/
          unless defined $n;
        last;
    }
    $parser->parse($buffer);
}

$parser->finish;

