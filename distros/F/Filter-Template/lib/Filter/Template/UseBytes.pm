package Filter::Template::UseBytes;
{
  $Filter::Template::UseBytes::VERSION = '1.043';
}
use Filter::Template;

# Make the "use_bytes" template evaluate to C<use bytes;> in Perl on or
# after 5.005_55.  Systems before then don't have the option, so the
# template evaluates to emptiness.

# Template definitions can't be indented, so this looks ugly.

# The "# include" modifier causes the conditional to be evaluated at
# compile time.  This turns regular if/else logic into the moral
# equivalent of the C preprocessor's #if/#else.

# Because the conditionals are evaluated at compile time, it's
# imperative that the things they test be defined.  The BEGIN block
# makes sure HAS_BYTES is defined before the tests are executed.

BEGIN {
	eval "use bytes; sub HAS_BYTES () { 1 }";
	eval "sub HAS_BYTES () { 0 }" if $@;
};

if (HAS_BYTES) { # include
template use_bytes {
	use bytes;
}
} else { # include
template use_bytes {
}
} # include

1;

__END__

=head1 NAME

Filter::Template::UseBytes - conditionally use bytes.pm depending on availability

=head1 VERSION

version 1.043

=head1 SYNOPSIS

	use Filter::Template ( isa => "Filter::Template::UseBytes" );

	print "Phi length in characters: ", length(chr(0x618)), "\n";
	{% use_bytes %}
	print "Phi length in bytes: ", length(chr(0x618)), "\n";

=head1 DESCRIPTION

The UseBytes template evaluates to C<use bytes;> if Perl 5.005_55 or
later is running.  Otherwise it evaluates to an empty string, which
does nothing but doesn't throw an exception either.

=head1 BUGS

All the caveats of L<Filter::Template> apply here.

=head1 SEE ALSO

L<Filter::Template>.

=head1 AUTHOR & COPYRIGHT

Filter::Template::UseBytes is Copyright 2000-2013 Rocco Caputo.  All
rights reserved.  Filter::Template::UseBytes is free software; you may
redistribute it and/or modify it under the same terms as Perl itself.

Filter::Template::UseBytes was previously known as
POE::Macro::UseBytes.

=cut
