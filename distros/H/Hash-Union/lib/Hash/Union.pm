package Hash::Union;

use warnings FATAL => 'all';
use strict;

=head1 NAME

Hash::Union - smart hashes merging

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  use Hash::Union 'union';
  use Data::Dumper;                # for debug only

  my $config_base = {              # default application config
      'database' => 'production',  # production database
      'html_dirs' => [             # search paths for html documents
          '/docs/html/main',
          '/docs/html/default'
      ],
      'text_dirs' => [             # search paths fo text documents
          '/docs/text/main',
          '/docs/text/default'
      ]
  };

  my $config_local = {             # locally customized config
      'database' => 'stageing',    # devel database
      'prepend: html_dirs' => [    # local html pages preferred
          '/local/html/main',
          '/local/html/default'
      ],
      'append: text_dirs' => [     # fallback for nonexistent text
          '/local/text/main',
          '/local/text/default'
      ]
  };

  # now merge default with local
  my $config = union( [ $config_base, $config_local ] );

  print Dumper $config;

  ========

  $VAR1 = {
      'database' => 'stageing',
      'html_dirs' => [
          '/local/html/main',
          '/local/html/default',
          '/docs/html/main',
          '/docs/html/default'
      ],
      'text_dirs' => [
          '/docs/text/main',
          '/docs/text/default',
          '/local/text/main',
          '/local/text/default'
      ]
  };

=cut

use base qw'Exporter';
use vars qw'@EXPORT_OK';


=head1 EXPORT_OK

=head2 union( \@hash_references, %options );

Supported options:

=over

=item * reverse

Merge all hash references in reverse order.

=item * simple

Don't apply complex merging logic (ignore keys special meaning).

=back

=cut

@EXPORT_OK = qw'&union';

use Carp qw'croak';
use Storable qw'dclone';

use constant {
	OP_SET     => 0,
	OP_SETIF   => 1,
	OP_PREPEND => 2,
	OP_APPEND  => 3,
};


sub union {
	my ($hashes,%opts) = @_;

	croak "error: arrayref required" unless ref $hashes eq 'ARRAY';

	# never modify source hashes keys nor values
	$hashes = dclone $hashes;

	# exotic option
	@$hashes = reverse @$hashes if $opts{reverse};

	my $left = shift @$hashes;
	croak "error: hashref required" unless ref $left eq 'HASH' || !defined $left;

	while (@$hashes) {
		my $right = shift @$hashes;
		croak "error: hashref required" unless ref $right eq 'HASH' || !defined $right;
		$left = _union($left,$right,%opts);
	}
	return $left;
}

# internal routine
sub _union {
	my ($l,$r,%opts) = @_;

	# undef handling
	$l ||= {};
	$r ||= {};

	# normalize left keys
	unless ($opts{simple}) {
		for (keys %$l) {
			if (/^(?:\?=|ifnone:)\s*(.*)/) {            # '?= key', 'ifnone: key'
				croak "left '$_' violates with '$1'" if exists $l->{$1};
				$l->{$1} = delete $l->{$_};
			} elsif (/^(?:\+=|prepend:)\s*(.*)/) {      # '+= key', prepend: key'
				croak "left '$_' violates with '$1'" if exists $l->{$1};
				$l->{$1} = delete $l->{$_};
			} elsif (/^(?:=\+|append:)\s*(.*)/) {       # '=+ key', 'append: key'
				croak "left '$_' violates with '$1'" if exists $l->{$1};
				$l->{$1} = delete $l->{$_};
			} elsif (/^(?:=|set:)\s*(.*)/) {            # '= key', 'set: key'
				croak "left '$_' violates with '$1'" if exists $l->{$1};
				$l->{$1} = delete $l->{$_};
			}
		}
	}

	# now right...
	for my $k (keys %$r) {
		my ($lk, $op) = ($k, OP_SET);

		unless ($opts{simple}) {
			if ($k=~/^(?:\?=|ifnone:)\s*(.*)/) {        # '?= key', 'ifnone: key'
				croak "right '$_' violates with '$1'" if exists $r->{$1};
				($lk, $op) = ($1, OP_SETIF);
			} elsif ($k=~/^(?:\+=|prepend:)\s*(.*)/) {  # '+= key', 'prepend: key'
				croak "right '$_' violates with '$1'" if exists $r->{$1};
				($lk, $op) = ($1, OP_PREPEND);
			} elsif ($k=~/^(?:=\+|append:)\s*(.*)/) {   # '=+ key', 'append: key'
				croak "right '$_' violates with '$1'" if exists $r->{$1};
				($lk, $op) = ($1, OP_APPEND);
			} elsif ($k=~/^(?:=|set:)\s*(.*)/) {        # '= key', 'set: key'
				croak "right '$_' violates with '$1'" if exists $r->{$1};
				($lk, $op) = ($1, OP_SET);
			}
		}

		# undefs cases
		next unless defined $r->{$k};
		unless (defined $l->{$lk}) {
			$l->{$lk} = $r->{$k};
			next;
		}

		# res vs !ref
		croak "left '$lk' is ref, right '$k' isn't" if ref $l->{$lk} && !ref $r->{$k};
		croak "left '$lk' isn't ref, right '$k' is" if !ref $l->{$lk} && ref $r->{$k};

		# scalars
		unless (ref $l->{$lk}) {
			if ($op==OP_SET) {
				$l->{$lk} = $r->{$k};
			} elsif ($op==OP_SETIF) {
				$l->{$lk} ||= $r->{$k};
			} elsif ($op==OP_PREPEND) {
				$l->{$lk} = $r->{$k}.$l->{$lk};
			} elsif ($op==OP_APPEND) {
				$l->{$lk} .= $r->{$k};
			}
			next;
		}

		# incompatible kind of refs
		croak "type of left '$lk' incompatible with type of right '$k'" if ref $l->{$lk} ne ref $r->{$k};

		# scalars
		if (ref $l->{$lk} eq 'SCALAR') {
			if ($op==OP_SET) {
				$l->{$lk} = $r->{$k};
			} elsif ($op==OP_SETIF) {
				$l->{$lk} = $r->{$k} unless ${$l->{$lk}};
			} elsif ($op==OP_PREPEND) {
				${$l->{$lk}} = ${$r->{$k}}.${$l->{$lk}};
			} elsif ($op==OP_APPEND) {
				${$l->{$lk}} .= ${$r->{$k}};
			}
			next;
		}

		# arrays
		if (ref $l->{$lk} eq 'ARRAY') {
			if ($op==OP_SET) {
				$l->{$lk} = $r->{$k};
			} elsif ($op==OP_SETIF) {
				$l->{$lk} = $r->{$k} unless @{$l->{$lk}};
			} elsif ($op==OP_PREPEND) {
				unshift @{$l->{$lk}}, @{$r->{$k}};
			} elsif ($op==OP_APPEND) {
				push @{$l->{$lk}}, @{$r->{$k}};
			}
			next;
		}

		# hashes
		if (ref $l->{$lk} eq 'HASH') {
			if ($op==OP_SET) {
				$l->{$lk} = _union($l->{$lk}, $r->{$k},%opts);
			} elsif ($op==OP_SETIF) {
				$l->{$lk} = _union($l->{$lk}, $r->{$k}, %opts) unless %{$l->{$lk}};
			} elsif ($op==OP_PREPEND) {
				$l->{$lk} = _union($r->{$k}, $l->{$lk}, %opts);
			} elsif ($op==OP_APPEND) {
				$l->{$lk} = _union($l->{$lk}, $r->{$k}, %opts);
			}
			next;
		}

		# wtf?
		croak "unknown type of left '$lk'";
	}

	return $l;
}

1;

__END__

=head1 KEYS SPECIAL MEANING

=over

=item Setting new value unconditionally:

Key syntax: '=KEY', '= KEY', 'set:KEY', 'set: KEY'

Previous value of KEY will be lost and new value will be set unconditionally.
This kind of merging logic applies to any 'plain' keys by default. Passed option 'simple'
forces this method for 'complex' keys too.

=item Setting new value only if no true value still exists:

Key syntax: '?=KEY', '?= KEY' , 'ifnone:KEY', 'ifnone: KEY'

If C<true> (from perl point of view) value for this key exists just skip new value assignment.
Otherwise assign new value (possible even C<false>).

=item Prepending new value to existing:

Key syntax: '+=KEY', '+= KEY', 'prepend:KEY', 'prepend: KEY'

Prepend new value to any existing value of key. Raise an exception on an incompatible value types.
Scalars will be concatenated, arrays unshifted, hashes traversed deeply in proper order.

=item Appending new value to existing:

Key syntax: '=+KEY', '=+ KEY', 'append:KEY', 'append: KEY'

Append new value to any existing value of key. Raise an exception on an incompatible value types.
Scalars will be concatenated, arrays pushed, hashes traversed deeply in proper order.

=back

B<NOTE>: In all syntax forms spaces between operation and key are optional.


=head1 AUTHOR

Oleg A. Mamontov, C<< <oleg at mamontov.net> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-hash-union at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-Union>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::Union

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-Union>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-Union>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-Union>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-Union/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Oleg A. Mamontov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

