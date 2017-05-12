package File::CounterSS;

use strict;
use Carp;
use File::Path;
use File::Storage::Stat;

require Exporter;

our @ISA = qw(Exporter);
our $VERSION = '0.01';


sub new {
    my $class = shift;
    my $options = shift;

    croak('Id is not set.')
	unless $options->{Id};

    croak('Format error of Id.')
	unless $options->{Id} =~ /^[a-zA-Z0-9\-\_\/]+/;

    my $filepath = $options->{DirPath} . '/' . $options->{Id};
    my $dirpath = $filepath;
    $dirpath =~ s|/[^/]+$||;

    mkpath($dirpath, 0, 0777)
	unless -d $dirpath;

    unless (-e $filepath) {
        open(C, ">$filepath");
        close(C);
        chmod(0666, $filepath);
        utime(0, 0, $filepath);
    }

    my $fss = File::Storage::Stat->new({FilePath => $filepath});

    my $range = lc($options->{Range});
    $range = 'day'
	unless ($range =~ /^(hour|day|week|mon|year)$/);

    my $type = lc($options->{Type});
    $type = 'total'
	unless ($type =~ /^(total|last)$/);

    my $self = {
	filepath => $filepath,
	dirpath  => $dirpath,

	fss => $fss,

	range => $range,
	type  => $type,
    };


    return bless $self, $class;
}

sub count {
    my $self = shift;

    my($atime, $mtime, $ctime) = $self->{fss}->get;

    my $last_atime = $atime;
    my $clear = 0;
    if ($self->{range} eq 'week') {
	$clear = 1
	    unless (localtime($ctime))[6] eq 6 && (localtime(time))[6] eq 0;
    } else {
	my $f;
	if ($self->{range} eq 'hour') {
	    $f = 2;
	} elsif ($self->{range} eq 'day') {
	    $f = 3;
	} elsif ($self->{range} eq 'mon') {
	    $f = 4;
	} elsif ($self->{range} eq 'year') {
	    $f = 5;
	}
	$clear = 1
	    unless (localtime($ctime))[$f] eq (localtime(time))[$f];
    }

    if ($clear) {
	$atime = 0;
	$mtime = $last_atime - 1
	    if $self->{type} eq 'last';
    }
    ++$atime; ++$mtime;
    $self->{fss}->set($atime, $mtime);

    return ($atime, $mtime);
}

1;
__END__

=head1 NAME

File::CounterSS - Counter that used File::Storage::Stat

=head1 SYNOPSIS

  use File::CounterSS;
  my $c = File::CounterSS->new({DirPath => 'dirpath', Id => 'id'});#Id =~ m|^[a-zA-Z0-9\-\_\/]+$|
  my ($day, $total) = $c->count;

  my $c = File::CounterSS->new({DirPath => 'dirpath', Id => 'id', type => 'last'});#'total' is default value of type
  my ($day, $yesterday) = $c->count;

  my $c = File::CounterSS->new({DirPath => 'dirpath', Id => 'id', range => 'week'});'day' is default value of range
  my $c = File::CounterSS->new({DirPath => 'dirpath', Id => 'id', range => 'mon'});
  my $c = File::CounterSS->new({DirPath => 'dirpath', Id => 'id', range => 'year'});


  my $c = File::CounterSS->new({DirPath => 'dirpath', Id => 'id', range => 'day', type => 'last'});
  my $c = File::CounterSS->new({DirPath => 'dirpath', Id => 'id', range => 'week', type => 'last'});
  my $c = File::CounterSS->new({DirPath => 'dirpath', Id => 'id', range => 'mon', type => 'last'});
  my $c = File::CounterSS->new({DirPath => 'dirpath', Id => 'id', range => 'year', type => 'last'});

=head1 DESCRIPTION

counter with two kinds of values at the same time.
the first value is counted according to hour, day, week, mon, year.
the second value is the last count or a count of the total.

=head1 AUTHOR

Kazuhiro Osawa  E<lt>ko@yappo.ne.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kazuhiro Osawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
