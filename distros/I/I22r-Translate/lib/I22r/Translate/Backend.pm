package I22r::Translate::Backend;
use Moose::Role;
use I22r::Translate::Request;
use I22r::Translate::Result;

our $VERSION = '0.96';
requires 'can_translate';
requires 'get_translations';
# requires 'config';

sub name {
    my $pkg = shift;
    $pkg =~ s/.*:://;
    return $pkg;
}

# convenience method to update a configuration hashref,
# usually a lexical variable in another package.
#
# if no @opts provided: return the $config hashref
# if one @opts provided: return the value from the $config hashref
# if >1 @opts provided: update $config with key-value pairs from @opts
sub config {
    my ($class, @opts) = @_;
    my $config = $I22r::Translate::config{$class} //= {};
    if (@opts == 0) {
	return $config;
    }
    if (@opts == 1 && ref($opts[0]) eq '') {
	return $config->{$opts[0]};
    }
    my %opts = ref($opts[0]) eq 'HASH' ? %{$opts[0]} : @opts;
    $config->{$_} = $opts{$_} for keys %opts;
}

sub __config {
    use Carp;
    confess;
    my ($class, $config, @opts) = @_;
    if (@opts == 0) {
        return $config;
    } elsif (@opts == 1 && ref($opts[0]) eq '') {
        return $config->{ $opts[0] };
    } else {
        my %opts = ref($opts[0]) eq 'HASH' ? %{$opts[0]} : @opts;
        $config->{$_} = $opts{$_} for keys %opts;
    }
}

1;

__END__

Backends to consider:

_X_ Google
_X_ Microsoft/Azure
___ SysTrans
___ Apertium
___ InterTran

=head1 NAME

I22r::Translate::Backend - role for I22r::Translate translation sources

=head1 DESCRIPTION

Packages that want to provide translation results in the
L<I22r::Translate> framework must fulfill the 
C<I22r::Translate::Backend> role. 

The rest of this document should only be interesting to
backend developers.

=head1 FUNCTIONS/METHODS

Backend modules are typically accessed "statically", so
a backend does not need a constructor or need to manage
backend "objects". Configuration for a backend should
reside in the global configuration of the L<I22r::Translate>
module (so for a backend called C<My::I22r::Backend>, 
configuration for that backend will be accessible in
C<< $I22r::Translate::config{"My::I22r::Backend"} >>).

In the following function documentation, C<$backend> is a
string and the name of the backend package, B<not> a
backend "object".

=head2 can_translate

=head2 $quality = $backend->can_translate($lang1,$lang2)

Informs the L<I22r::Translate> module about whether a backend
can perform a translation between the given language pair.
The return value should be a value less than or equal to 1,
and indicates the expected "quality" of the translation
in that language pair performed by this backend, where
1 indicates a "perfect" translation and 0 indicates a
very poor translation. The L<I22r::Translate> will call
this function on all available backends and try the
backends that return the highest values first. Backends
that return a value less than or equal to zero will not
be used to translate that language pair.

=head2 config

=head2 $config_hash = $backend->config

=head2 $config_value = $backend->config( $key )

=head2 $backend->config( %opts )

Get or set configuration for this backend.

=head2 get_translations

=head2 @list = $backend->get_translations( $request )

Function that performs the translations specified in
the given L<I22r::Translate::Request> object.

If any translations are successful, this function should
set elements in C<< $request->results >> and return the
list of ids (the keys of the C<< $request->text >> hash)
of the inputs that were translated with this backend.

=head1 SEE ALSO

L<I22r::Translate>, L<I22r::Translate::Request>

=cut
