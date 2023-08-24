package Domain::PublicSuffix;
$Domain::PublicSuffix::VERSION = '0.20';
use strict;
use warnings;
use base 'Class::Accessor::Fast';

use Domain::PublicSuffix::Default ();
use File::Spec ();
use Net::IDN::Encode ();

__PACKAGE__->mk_accessors(qw/
	use_default
	data_file
	allow_unlisted_tld
	domain_allow_underscore
	tld_tree
	error
	root_domain
	tld
	suffix
/);

=head1 NAME

Domain::PublicSuffix - Parse a domain down to root

=head1 SYNOPSIS

 use Domain::PublicSuffix;

 my $suffix = Domain::PublicSuffix->new({
   'data_file' => '/tmp/effective_tld_names.dat'
 });
 my $root = $suffix->get_root_domain('www.google.com');
 # $root now contains "google.com"

 $root = $suffix->get_root_domain('www.google.co.uk');
 # $root now contains google.co.uk

 my $suf = $suffix->suffix();
 # $suf now contains co.uk

 my $tld = $suffix->tld();
 # $tld now contains uk

=head1 DESCRIPTION

This module utilizes the "effective_tld_names.dat" provided by Mozilla as a way
to effectively reduce a fully qualified domain name down to the absolute root.
The Mozilla PublicSuffix file is an open source, fully documented format that
shows absolute root TLDs, primarily for Mozilla's browser products to be able
to determine how far a cookie's security boundaries go.

This module will attempt to search etc directories in /usr/share/publicsuffix,
/usr, /usr/local, and /opt/local for the effective_tld_names.dat file. If a file
is not found, a default file is loaded from Domain::PublicSuffix::Default, which
is current at the time of the module's release. You can override the data file
path by giving the new() method a 'data_file' argument.

When creating a new PublicSuffix object, the module will load the data file as
specified, and use the internal structure to parse each domain sent to the
get_root_domain method. To re-parse the file, you must destroy and create a new
object, or execute the _parse_data_file method directly, though that is not
recommended.

=head1 PUBLIC ACCESSORS

=over 4

=item error()

On unsuccessful parse, contains a human-readable error string.

=item suffix()

Returns the effective tld of the last parsed domain. For the domain
'google.co.uk', this would return 'co.uk'.

=item tld()

Returns the true DNS tld of the last parsed domain. For the domain
'google.co.uk', this would return 'uk'.

=back

=cut

=head1 PUBLIC METHODS

=over 4

=item new(\%arguments)

Instantiate a PublicSuffix object. It is best to instantiate an object
and continue calling get_root_domain instead of continually recreating the
object, as the data file is read and parsed on instantiation.

Can take a hashref of arguments:

=over 4

=item data_file 

A fully qualified path, to override the effective_tld_names.dat file.

=item use_default 

Use the provided publicsuffix file, do not search for any other files.

=item domain_allow_underscore

A flag to indicate that underscores should be allowed in hostnames
(contra to the RFCs). Default: undef.

=item allow_unlisted_tld

A flag to indicate that unlisted TLDs should be passed through. This follows
the spec as listed on publicsuffix.org, but is not how this module works by
default, or before 0.16. Default: undef

=back

=back

=cut

sub new {
	my ( $class, @args ) = @_;

	my $self = $class->SUPER::new(@args);

	# Compatibility fix
	if ( $args[0] and ref($args[0]) eq 'HASH' and $args[0]->{'dataFile'} ) {
		$self->data_file( $args[0]->{'dataFile'} );
	}

	$self->tld_tree($self->_parse_data_to_tree());

	return $self;
}

=over 4

=item get_root_domain( $domain )

Given a fully qualified domain name, return the parsed root domain name.
Returns undefined if an error occurs parsing the given domain, and fills
the error accessor with a human-readable error string.

=back

=cut

sub get_root_domain {
	my ( $self, $inbound ) = @_;

	unless ($inbound) {
		$self->error('No input');
		return;
	}

	my $domain = lc($inbound);

	# Clear meta properties
	foreach ( qw/tld suffix root_domain error/ ) {
		undef( $self->{$_} );
	}

	# Check if domain is valid
	unless ( _validate_domain($domain) ) {
		$self->error('Malformed domain');
		return;
	}

	my @domain_array = split(/\./, $domain);
	my $tld = pop(@domain_array);
	unless ( defined $self->tld_tree->{$tld} ) {
		if ( $self->allow_unlisted_tld ) {
			$self->tld($tld);
			$self->suffix($tld);
			if ( my $next = pop(@domain_array) ) {
				$self->root_domain( join( '.', $next, $tld ) );
			} else {
				$self->root_domain($tld);
			}
			return $self->root_domain;
		} else {
			$self->error('Invalid TLD');
			return;
		}
	}

	$self->tld($tld);
	my $raw_suffix = $self->get_suffix_for_domain($domain);

	# Leave if we still haven't found a suffix
	if ( !$raw_suffix ) {
		$self->error('Domain not valid');
		return;
	}

	my $suffix = $raw_suffix;
	$suffix =~ s/!//g;
	$self->suffix($suffix);

	# Check if we're left with just a suffix
	if ( $raw_suffix !~ /!/ and $self->suffix eq $domain ) {
		$self->error('Domain is already a suffix');
		return;
	}

	# Generate root domain using suffix
	if ($raw_suffix =~ /!/) {
		# Exception suffixes are also domains
		$self->root_domain($suffix);
	} else {
		my $root_domain = $domain;
		$root_domain =~ s/^.*\.(.*?\.$suffix)\.?$/$1/;
		$self->root_domain($root_domain);
	}

	return $self->root_domain;
}

sub get_suffix_for_domain {
    my ( $self, $domain ) = @_;

    my @labels = split( /\./, $domain );
    my $point = $self->tld_tree;
    my @suffix;
    while ( my $label = pop(@labels) ) {
        # If there is a wildcard here, it is a suffix, except for !exceptions
        # Theoretically, there would be further processing here for .*.
        # wildcards, but those have not existed before in the list, so saving
        # the work until it actually happens.
        if ( $point->{'*'} ) {
			my $exception = '!' . $label;
			if ( $point->{$exception} ) {
				push( @suffix, $exception );
				last;
			}
        } elsif (!$point->{$label}) {
            # If we run out of rules at this point, the root is just below here
            last;
        }
    
        push( @suffix, $label );
        $point = $point->{$label};
    }
    return join('.', reverse(@suffix));
}

sub _load_data {
	my ($self) = @_;

	my $data_stream_ref;

	# Find an effective_tld_names.dat file
	my @tld_lines;
	my $dat;
	if ( $self->use_default ) {
		$data_stream_ref = Domain::PublicSuffix::Default::retrieve();
	} elsif ( $self->data_file and -e $self->data_file ) {
		open( $dat, '<:encoding(UTF-8)', $self->data_file )
			or die "Cannot open \'" . $self->data_file . "\': " . $!;
		@tld_lines = <$dat>;
		close($dat);
		$data_stream_ref = \@tld_lines;

	} else {
		my @paths = (
			File::Spec->catdir(File::Spec->rootdir, qw/ usr share publicsuffix /),
			File::Spec->catdir(File::Spec->rootdir, qw/ etc /),
			File::Spec->catdir(File::Spec->rootdir, qw/ usr etc /),
			File::Spec->catdir(File::Spec->rootdir, qw/ usr local etc /),
			File::Spec->catdir(File::Spec->rootdir, qw/ opt local etc /),
		);
		foreach my $path (@paths) {
			$path = File::Spec->catfile( $path, "effective_tld_names.dat" );
			if ( -e $path ) {
				open( $dat, '<:encoding(UTF-8)', $path )
					or die "Cannot open \'" . $path . "\': " . $!;
				@tld_lines = <$dat>;
				close($dat);
				$data_stream_ref = \@tld_lines;
				last;
			}
		}
	}

	# If we haven't found one, load the default
	unless ( defined $data_stream_ref ) {
		$data_stream_ref = Domain::PublicSuffix::Default::retrieve();
	}

	return $data_stream_ref;
}

sub _parse_data_to_tree {
	my ($self) = @_;

    my $data_stream_ref = $self->_load_data();
    my $tree = {};

    foreach (@{$data_stream_ref}) {
		chomp;
    
		# Remove comments, skip if full line comment, remove if inline comment
		next if ( /^\// or /^[ \t]*?$/ );
		s/[\s\x{0085}\x{000A}\x{000C}\x{000D}\x{0020}].*//;

		# Parse both unicode and ASCII representations, if needed
		my @tlds = ($_);
		my $ascii = Net::IDN::Encode::domain_to_ascii($_);
		push( @tlds, $ascii ) if ( $_ ne $ascii );

		foreach (@tlds) {
			# Split domain and convert to a tree
			my @domain = split( /\./, $_ );
            my $previous = $tree;
            while (my $label = pop(@domain)) {
                $label =~ s/\s.*//;
                $previous->{$label} ||= {};
                $previous = $previous->{$label};
            }
        }
    }
    return $tree;
}

sub _validate_domain {
	my ($domain) = @_;

	return ( _validate_length($domain) and _validate_multiple_segments($domain) );
}

# Domains must have more than one segment with length
sub _validate_multiple_segments {
	my ($domain) = @_;

	my @segments = split( /\./, $domain );
	return unless ( @segments > 1 );
	foreach my $segment (@segments) {
		return unless ( length($segment) > 0 );
	}
	return 1;
}

# Domains may not be more than 255 characters in length
sub _validate_length {
	my ($domain) = @_;

	my $length = length($domain);
	return ( $length > 1 and $length <= 255 );
}

### Compatibility

sub _parseDataFile {
	my ($self) = @_;

	$self->tld_tree($self->_parse_data_to_tree());
}
sub getRootDomain {
	my ( $self, $domain ) = @_;

	return $self->get_root_domain($domain);
}

sub _validateDomain {
	my ($self, $domain) = @_;

	return $self->_validate_domain($domain);
}

sub dataFile {
	my ( $self, $data_file ) = @_;

	return $self->data_file($data_file);
}

sub rootDomain {
	my ( $self, $root_domain ) = @_;

	return $self->root_domain($root_domain);
}

=head1 SEE ALSO

=over 4

=item * GitHub

L<http://www.github.com/nmelnick/Domain-PublicSuffix>

=item * Current List: 

L<http://mxr.mozilla.org/mozilla-central/source/netwerk/dns/effective_tld_names.dat?raw=1> [mxr.mozilla.org]

=item * Mozilla Documentation: 

L<http://wiki.mozilla.org/Gecko:TLD_Service>

=item * Public Info Site: 

L<http://publicsuffix.org/>

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-domain-publicsuffix at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Domain-PublicSuffix>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Domain::PublicSuffix

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Domain-PublicSuffix>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Domain-PublicSuffix>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Domain-PublicSuffix>

=item * Search CPAN

L<http://search.cpan.org/dist/Domain-PublicSuffix>

=back

=head1 CONTRIBUTORS

dkg: Daniel Kahn Gillmor

gavinc: Gavin Carr

jwieland: Jason Wieland

=head1 COPYRIGHT & LICENSE

Copyright 2008-2020 Nicholas Melnick, C<nick at abstractwankery.com>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
