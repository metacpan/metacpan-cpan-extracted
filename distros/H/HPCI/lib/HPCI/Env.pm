package HPCI::Env;

use autodie;
use Carp;

use Moose::Role;
use MooseX::Params::Validate ':all';

=head1 NAME

HPCI::Env - Role for controlled copying of the %ENV hash for child processes to use

=head1 DESCRIPTION

Makes a copy of %ENV (possibly from a previous copy).

Provides choice of whitelist (retaining only specified values),
blacklist (removing specified values), and augmenting with a list
of key value pairs that are determined by the user program.

Typically, only a whitelist or a blacklist would be used - not both
at once (although some special circumstances might use both where
patterns rather than explicit lists are used for one category).
Augmenting can be useful in conjunction with either whitelist
or blacklist.

This module provides both mechanisms, so that the caller can decide
on policy.  Choosing to whitelist has the danger of possibly
removing something that is needed.  Choosing to blacklist has
the danger of possibly failing to remove something that permits
a security failure).  Your business context will determine which
choice is right.

The method B<print_env_settings> takes a filehandle and writes a series
of bash export command lines for all specified env items (if any was
specified).

The B<has_any_env> attribute can be used to limit accessing the
computed env to only be dome if there was at least one env control
parameter provided:

	# only use the env is there was something explicitly put there
	if ($object->has_any_env) {
		use_env( $object->env );
	}

	# always use the env (default to %ENV if nothing explicit)
	use_env( $object->env );

HPCI uses multiple HPCI::Env objects that are cascaded.  The Group's
env object (if any) is copied and modified for each Stage's own
env object.

=head1 ATTRIBUTES

=over 4

=item * env_source

A hash to be used as the basis of the copy.

If env_source is not provided but any other env_* parameters
are provided, then B<$self->default_env_source> is called to get
the soruce.  If this method is not over-ridden, it uses B<%ENV>
as the basis.

As well as for cascading envs (as is done for Stage from Group)
providing a value to B<env_source> allows giving the entire desired
env hash at once, rather than as a set of modifications from B<%ENV>.

=cut

has 'env_source' => (
	is        => 'ro',
	isa       => 'HashRef[Str]',
	lazy      => 1,
	predicate => '_has_env_source',
	builder   => '_default_env_source',
);

sub _default_env_source {
	my $self = shift;
	return $self->_has_env_cascade ? $self->env_cascade->env_source : \%ENV;
}

=item * env_cascade Maybe[Object]

If this attribute is provided, then it will be used as an object
that does the Env role that provides the default env_source value.
The HPCI::Stage object specifies its Group object for this parameter
so that if any Group env parameters were set, they will get used
as a basis for the Stage.

=cut

has 'env_cascade' => (
	is        => 'ro',
	isa       => 'Maybe[Object]',
	lazy      => 1,
	predicate => '_has_env_cascade',
	default   => undef,
);

=item * env_retain ArrayRef[Str]

=item * env_retain_pat RegexpRef

If either of these is provided, then only keys that are explicitly
listed in env_retain, or which match the pattern in env_retain_pat will be
kept.  All other keys will be filtered out.

This is done before processing env_remove, env_remove_pat, or env_set
parameters, so additional keys might be filtered out, and some filtered
keys might still be reinserted in the final resulting environment hash
(but only with a new value that does not depend upon the previous one).

=cut

has 'env_retain' => (
	is        => 'ro',
	isa       => 'ArrayRef[Str]',
	predicate => '_has_env_retain',
	);

has 'env_retain_pat' => (
	is        => 'ro',
	isa       => 'RegexpRef',
	predicate => '_has_env_retain_pat',
	);

=item * env_remove ArrayRef[Str]

=item * env_remove_pat RegExp

If either of these is provided, then any keys that are explicitly
listed in env_remove, or which match the pattern in env_remove_pat will be
deleted.

This is done before processing the env_set parameter, so some filtered keys
could still be reinserted in the final resulting environment hash (but only
with a new value that does not depend upon the previous one).

=cut

has 'env_remove' => (
	is        => 'ro',
	isa       => 'ArrayRef[Str]',
	predicate => '_has_env_remove',
	);

has 'env_remove_pat' => (
	is        => 'ro',
	isa       => 'RegexpRef',
	predicate => '_has_env_remove_pat',
	);

=item * env_set HashRef[Str|CodeRef]

If provided, the env hash that results from applying the env_retain and
env_remove filtering is augmented by adding additional values for each
key in this hash.

If the value is not a CodeRef, it is used (completely replacing the
previous value for that key, if any).

If the value in this hash is a CodeRef, then that function is called to
compute the value to be stored.  The function will be passed one or two
arguments - the first is always the key name, and the second is the value
for that key in the filtered source hash if it exists (or no second
argument is provided if it does not exists).

The function can then either modify the original value (if any was
originally present and has not been filtered out by the previous steps)
or replace it completely (regardless of whether it was present).  A
typical example of modifying would be to prepend a directory to PATH.

    ... env_set => { DIRS =>
            sub {
                shift; # throw away 'DIRS' argument
                # prepend DIRS, if present, create it if not present
                return join( ':', "home/joe/lib", @_ );
            }

=cut

has 'env_set' => (
	is        => 'ro',
	isa       => 'HashRef[Str|CodeRef]',
	predicate => '_has_env_set',
	);

=item * has_any_env Bool (not settable)

This attribute is true if any attributes were initialized that
determine (potential) filtering of %ENV.  (It is potential because
if the values provided could end up "filtering" to a result that is
identical to the original %ENV.)  (The "filtering" attributes are
env_source, env_retain, env_retain_pat, env_deletem env_delete_pat,
and env_set._

It is also true if there was an env_cascade object provided and it
had any filtering attributes initialized.

=cut

has 'has_any_env' => (
	is       => 'ro',
	isa      => 'Bool',
	init_arg => undef,
	lazy     => 1,
	builder  => '_build_has_any_env',
);

sub _build_has_any_env {
	my $self = shift;
	return $self->_has_env_source
		|| $self->_has_env_retain
		|| $self->_has_env_retain_pat
		|| $self->_has_env_remove
		|| $self->_has_env_remove_pat
		|| $self->_has_env_set
		|| ($self->_has_env_cascade && $self->env_cascade->has_any_env);
}

=item * env HashRef[Str]

This is the hash resulting from the specified filtering and augmentation.

=back

=cut

has 'env' => (
	is      => 'ro',
	isa     => 'HashRef[Str]',
	lazy    => 1,
	builder => '_build_env',
);

sub _build_env {
	my $self = shift;

	# make sure that has_any_env has been initialized before we possibly
	# cause forced use of default values, which would lead us to forget
	# that they were all uninitialized
	$self->has_any_env;

	my $fail_pat = qr(^(?<=.)); # pattern that always fails
	my $source   = $self->env_source;
	my @keepers = keys %$source;
	if ($self->_has_env_retain || $self->_has_env_retain_pat) {
		my %ret_keys;
		%ret_keys = map { $_ => 1 } @{ $self->env_retain } if $self->_has_env_retain;
		my $ret_pat = $fail_pat;
		$ret_pat = $self->env_retain_pat if $self->_has_env_retain_pat;
		@keepers = grep { $_ =~ $ret_pat || $ret_keys{$_} } @keepers;
	}
	if ($self->_has_env_remove || $self->_has_env_remove_pat) {
		# a missing parameter should not remove anything
		my %rem_keys;
		%rem_keys = map { $_ => 1 } @{ $self->env_remove } if $self->_has_env_remove;
		my $rem_pat = $fail_pat;
		$rem_pat = $self->env_remove_pat if $self->_has_env_remove_pat;
		@keepers =
			grep { not( $_ =~ $rem_pat || exists $rem_keys{$_} ) } @keepers;
	}
	$source = { map { $_ => $source->{$_} } @keepers };   # a new hash with only the chosen keys
	if ($self->_has_env_set) {
		while (my ( $key, $value ) = each %{ $self->env_set }) {
			$source->{$key} =
				ref($value) eq 'CODE'
				? $value->( $key, $source->{$key} )
				: $value;
		}
	}
	return $source;
}

=head1 ATTRIBUTES

=over 4

=item * print_env_setting

Prints a series of (Bourne-compatible) shel export command lines
tp the provided file handle that will set the computed environment
values.

Prints nothing if no values have been set.

(If you really want to have the entire B<%ENV> hash expanded, you
have a number of ways to do it:

    ... env_source => \%ENV, ...      # pull in %ENV explicitly

    ... env_retain_pat => qr/^/, ...  # retain everything

    ... env_delete_pat => qr/\0/, ... # delete nothing (NULL can't be in an env name

    ... env_set => { }. ...           # add nothing

All of those would work, you can probably thing of others if your
mind if sufficiently warped in the appropriate direction.)

=back

=cut

sub print_env_settings {
	my $self = shift;
	my $fh   = shift;
	if ($self->has_any_env) {
		while (my ( $k, $v ) = each %{ $self->env }) {
			$v =~ s{([\"\$\`\\])} {\\$1}g;
			print $fh qq{export $k="$v"\n};
		}
	}
}

=item * has_any_env

Returns true if any attribute was explicitly set.

This allows the user to follow the convention (also used internally)
that if no attributes were set, then no env is to be provided.

This method can be wrapped with an B<around>.  That is done by a
Stage object to have this attribute return true if either the Stage
or the parent Group had an attribute set.

=item * default_env_source

Selects the default has to be used.  The provided method selects
B<%ENV> but since this is a role, this method can be wrapped with
an B<around> that modifies that choice.  This method gets called
internally, and only if the env attribute is actually being set up.
The env used in a Stage is wrapped to use the Group's env (if it
was set up) as the default source.

=cut

1;
