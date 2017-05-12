package Elive::Util;
use warnings; use strict;

use Term::ReadKey;
use Term::ReadLine;
use IO::Interactive;
use Scalar::Util;
use Clone;
use YAML::Syck;
use Try::Tiny;

our $VERSION = '1.37';

use Elive::Util::Type;

=head1 NAME

Elive::Util - Utility functions for Elive

=cut

=head1 METHODS

=cut

=head2 inspect_type

       $type = Elive::Util::inspect_type('Elive::Entity::Participants');
       if ($type->is_array) {
           # ...
       }

Returns an object of type L<Elive::Util::Type>.

=cut

sub inspect_type {
    my $type_union = shift;

    my @types = split(/\|/, $type_union);

    return Elive::Util::Type->new($types[0])
}

sub _freeze {
    my ($val, $type) = @_;

    for ($val) {

	if (!defined) {
	    warn "undefined value of type $type\n"
	}
	else {
	    $_ = string($_, $type);
	    my $raw_val = $_;

	    if ($type =~ m{^Bool}ix) {

		#
		# DBize boolean flags..
		#
		$_ =  $_ ? 'true' : 'false';
	    }
	    elsif ($type =~ m{^(Str|enum)}ix) {

		#
		# low level check for taintness. Only applicible when
		# perl program is running in taint mode
		#
		die "attempt to freeze tainted data (type $type): $_"
		    if _tainted($_);
		#
		# l-r trim
		#
		$_ = $1
		    if m{^ \s* (.*?) \s* $}x;
		$_ = lc if $type =~ m{^enum};
	    }
	    elsif ($type =~ m{^(Int|HiResDate)}ix) {
		$_ = _tidy_decimal("$_");
	    }
	    elsif ($type =~ m{^Ref|Any}ix) {
		$_ = undef;
	    }
	    else {
		die "unable to convert $raw_val to $type\n"
		    unless defined;
	    }
	}
    };

    return $val;
}

#
# thawing of elementry datatypes
#

sub _thaw {
    my ($val, $type) = @_;

    return $val if $type =~ m{Ref}i
	|| ref( $val);

    return unless defined $val;

    for ($val) {

	if ($type =~ m{^Bool}i) {
	    #
	    # Perlise boolean flags..
	    #
	    $_ = m{^(true|1)$}i ? 1 : 0;
	}
	elsif ($type =~ m{^(Str|enum)}i) {
	    #
	    # l-r trim
	    #
	    $_ = $1
		if m{^ \s* (.*?) \s* $}x;
	    $_ = lc if $type =~ m{^enum}i;
	}
	elsif ($type =~ m{^Int|HiResDate}i) {

	    $_ = _tidy_decimal("$_");

	}
	elsif ($type eq 'Any') {
	    # more or less a placeholder type
	    $_ = string($_);
	}
	else {
	    die "unknown type: $type";
	}
    };

    return $val;
}

#
# _tidy_decimal(): general cleanup and normalisation of an integer.
#               used to clean up numbers for data storage or comparison

sub _tidy_decimal {
    my ($i) = @_;
    #
    # well a number really. don't convert or sprintf etc
    # to avoid overflow. Just normalise it for potential
    # string comparisons
    #
    # l-r trim, also untaint
    #
    if ($i =~ m{^ [\s\+]* (-?\d+) \s* $}x) {
	$i = $1;
    }
    else {
	return;
    }

    #
    # remove any leading zeros:
    # 000123 => 123
    # -00045 => -45
    # -000 => 0
    #

    $i =~ s{^
            (-?)   # leading minus retained (for now)
            0*     # leading zeros discarded
            (\d+?) # number - retained
            $}
	    {$1$2}x;

    #
    # reduce -0 => 0
    $i = 0 if ($i eq '-0');

    #
    # sanity check.
    #
    die "bad integer: $_[0]"
	unless $i =~ m{^[+-]?\d+$};

    return $i;
}

=head2 prompt

    my $password = Elive::Util::prompt('Password: ', password => 1)

Prompt for user input

=cut

sub prompt {
    my ($prompt,%opt) = @_;

    chomp($prompt ||= 'input:');

    ReadMode $opt{password}? 2: 1; # Turn off controls keys

    my $input;
    my $n = 0;

    do {
	die "giving up on input of $prompt" if ++$n > 100;
	print $prompt if IO::Interactive::is_interactive();
	$input = ReadLine(0);
	return
	    unless (defined $input);
	chomp($input);
    } until (defined($input) && length($input));

    ReadMode 0; # Reset tty mode before exiting

    return $input;
}

sub _reftype {
    return Scalar::Util::reftype( shift() ) || '';
}

sub _clone {
    return Clone::clone(shift);
}

sub _tainted {
    return grep { Scalar::Util::tainted($_) } @_;
}

#
# Hex encoding/decoding. Use for data streaming. E.g. upload & download
# of preload data.
#

sub _hex_decode {
    my $data = shift;

    return
	unless defined $data;

    $data = '0'.$data
	unless length($data) % 2 == 0;

    my ($non_hex_char) = ($data =~ m{([^0-9a-f])}ix);

    die "non hex character in data: ".$non_hex_char
	if (defined $non_hex_char);
    #
    # Works for simple ascii
    $data =~ s{(..)}{chr(hex($1))}gex;

    return $data;
}

sub _hex_encode {
    my $data = shift;

    $data =~ s{(.)}{sprintf("%02x", ord($1))}gesx;

    return $data;
}

=head2 string

    print Elive::Util::string($myscalar);
    print Elive::Util::string($myobj);
    print Elive::Util::string($myref, $datatype);

Return a string for an object. This method is widely used for casting
objects to ids.

=over 4

=item

If it's a simple scalar, just pass the value back.

=item

If it's an object use the C<stringify> method.

=item

If it's a reference, resolve datatype to a class, and use its
C<stringify> method.

=back

=cut

sub string {
    my $obj = shift;
    my $data_type = shift;

    for ($obj) {

	if ($data_type) {
	    my ($dt) = ($data_type =~ m{(.*)});

	    return $dt->stringify($_)
		if try {$dt->can('stringify')};
	}

	my $reftype =  _reftype($_);

	return $_
	    unless $reftype;

	return $_->stringify
	    if (Scalar::Util::blessed($_) && $_->can('stringify'));

	if ($reftype eq 'ARRAY') {
	    return join(',', sort map {string($_ => $data_type)} @$_)
	}
    }

    #
    # Nothing else worked; dump it.
    #
    return YAML::Syck::Dump($obj);
}

=head2 next_quarter_hour

Quarter hour advancement for the Time Module impoverished.

    my $start = Elive::Util::next_quarter_hour();
    my $end = Elive::Util::next_quarter_hour($start);

Advance to the next quarter hour without the use of any supporting
time modules. We just simply increment in seconds until C<localtime>
indicates that we're exactly on a quarter hour and ahead of the start time.

A small initial increment is added to ensure that the date remains
in the future, allowing for minor gotchas such as leap seconds, general
latency and smallish time drifts between the client and server.

=cut

sub next_quarter_hour {
    my $time = shift || time();

    $time += 30;

    for (;;) {
	my @t = localtime(++$time);
	my $sec = $t[0];
	my $min = $t[1];

	last unless $min % 15 || $sec;
    }

    return $time;
}

1;
