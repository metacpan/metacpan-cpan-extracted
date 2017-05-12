package File::Storage::Stat;

use strict;
use Carp;

require Exporter;

our @ISA = qw(Exporter);
our $VERSION = '0.02';

sub new {
    my $class = shift;
    my $options = shift;

    croak('FilePath is not set.')
	unless $options->{FilePath};

    croak('Ther is no (' . $options->{FilePath} . ').')
	unless -e $options->{FilePath};

    if ($options->{Type}) {
	$options->{Type} ='int'
	    unless $options->{Type} eq 'char';
    } else {
	$options->{Type} = 'int';
    }

    my $self = {
	FilePath => $options->{FilePath},
	Type => $options->{Type},
    };

    return bless $self, $class;
}

sub set {
    my $self = shift;
    my @times = (shift, shift);

    if ($self->{Type} eq 'char') {
	foreach (0...1) {
	    if (length($times[$_]) > 4) {
		$times[$_] = 0;
	    } else {
		my $t = 0;
		foreach (split('', $times[$_])) {
		    $t <<= 8;
		    $t += ord($_);
		}
		$times[$_] = $t;
	    }
	}
    }
    
    @times = map {
	my $v = $_;
	if ($v < 0) {
	    $v = 0;
	} elsif ($v >= ((1 << 31) * 2)) {
	    $v = 0;
	}
	$v;
    } @times;

    return utime($times[0], $times[1], $self->{FilePath});
}

sub get {
    my $self = shift;

    my @times = map {
	my $v = $_;
	if ($v < 0) {
	    $v = $v + ((1 << 31) * 2);
	}
	$v;
    } (stat $self->{FilePath})[8,9,10];

    if ($self->{Type} eq 'char') {
	foreach (0...1) {
	    if ($times[$_]) {
		my $t = '';
		while (1) {
		    $t = chr($times[$_] % 256) . $t;
		    $times[$_] >>= 8;
		    last unless $times[$_];
		}
		$times[$_] = $t;
	    } else {
		$times[$_] = '';
	    }
	}
    }

    return @times;
}

1;
__END__

=head1 NAME

File::Storage::Stat - Storage manager of minimum size

=head1 SYNOPSIS

  use File::Storage::Stat;

  my $fss = File::Storage::Stat->new({FilePath => 'filepath'});
  $fss->set(100, 1000);
  my($a, $b) = $fss->get;#max 4byte int.

  my $fss = File::Storage::Stat->new({FilePath => 'filepath', Type => 'char'});
  $fss->set('hoge', 'test');# max 4byte char.
  my($a, $b) = $fss->get;


=head1 DESCRIPTION

small data is stored in atime and mtime of file.

=head1 METHODS

=over 4

=item set(data1, data2)

data is set.
the data of less than 4byte can be preserved respectively.

=item get()

the preserved is loaded.

=head1 AUTHOR

Kazuhiro Osawa  E<lt>ko@yappo.ne.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kazuhiro Osawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
