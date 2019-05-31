package MVC::Neaf::Route;

use strict;
use warnings;

our $VERSION = '0.2701';

=head1 NAME

MVC::Neaf::Route - Route (path+method) class for Not Even A Framework

=head1 DESCRIPTION

This module contains information about a handler defined using
L<MVC::Neaf>: method, path, handling code, connected hooks, default values etc.

It is useless in and off itself.

=head1 METHODS

=cut

use Carp;
use Encode;
use Module::Load;
use Scalar::Util qw( looks_like_number blessed );
use URI::Escape qw( uri_unescape );

use parent qw(MVC::Neaf::Util::Base);
use MVC::Neaf::Util qw( canonize_path path_prefixes run_all run_all_nodie http_date make_getters );

our @CARP_NOT = qw(MVC::Neaf MVC::Neaf::Request);

=head2 new

Route has the following read-only attributes:

=over

=item * parent (required)

=item * path (required)

=item * method (required)

=item * code (required)

=item * default

=item * cache_ttl

=item * path_info_regex

=item * param_regex

=item * description

=item * public

=item * caller

=item * where

=item * tentative

=item * override TODO

=item * hooks

=item * helpers

=back

=cut

# Should just Moo here but we already have a BIG dependency footprint
my @ESSENTIAL = qw( parent method path code );
my @OPTIONAL  = qw(
    param_regex path_info_regex strict
    default helpers hooks
    caller description public where
    override tentative
    cache_ttl
);
my %RO_FIELDS;
$RO_FIELDS{$_}++ for @ESSENTIAL, @OPTIONAL;
my $year = 365 * 24 * 60 * 60;

sub new {
    my ($class, %opt) = @_;

    # kill generated fields
    delete $opt{$_} for qw( lock );

    my @missing = grep { !defined $opt{$_} } @ESSENTIAL;
    my @extra   = grep { !$RO_FIELDS{$_}   } keys %opt;

    $class->my_croak( "Required fields missing: @missing; unknown fields present: @extra" )
        if @extra + @missing;

    # Canonize args
    $opt{method} = uc $opt{method};
    $opt{default} ||= {};
    $opt{path}   = canonize_path($opt{path});
    $opt{public} = $opt{public} ? 1 : 0;

    # Check args
    $class->my_croak("'code' must be a subroutine, not ".(ref $opt{code}||'scalar'))
        unless UNIVERSAL::isa($opt{code}, 'CODE');
    $class->my_croak("'public' endpoint must have a 'description'")
        if $opt{public} and not $opt{description};
    $class->_croak( "'default' must be unblessed hash" )
        if ref $opt{default} ne 'HASH';
    $class->my_croak("'method' must be a plain scalar")
        unless $opt{method} =~ /^[A-Z0-9_]+$/;

    # Always have regex defined to simplify routing
    if (!UNIVERSAL::isa($opt{path_info_regex}, 'Regexp')) {
        $opt{path_info_regex} = (defined $opt{path_info_regex})
            ? qr#^$opt{path_info_regex}$#
            : qr#^$#;
    };

    # Just for information
    $opt{caller}  ||= [caller(0)]; # save file,line
    $opt{where}   ||= "at $opt{caller}[1] line $opt{caller}[2]";

    # preprocess regular expression for params
    if ( my $reg = $opt{param_regex} ) {
        my %real_reg;
        $class->_croak("param_regex must be a hash of regular expressions")
            if ref $reg ne 'HASH' or grep { !defined $reg->{$_} } keys %$reg;
        $real_reg{$_} = qr(^$reg->{$_}$)s
            for keys %$reg;
        $opt{param_regex} = \%real_reg;
    };

    if ( $opt{cache_ttl} ) {
        $class->_croak("cache_ttl must be a number")
            unless looks_like_number($opt{cache_ttl});
        # as required by RFC
        $opt{cache_ttl} = -100000 if $opt{cache_ttl} < 0;
        $opt{cache_ttl} = $year if $opt{cache_ttl} > $year;
        $opt{cache_ttl} = $opt{cache_ttl};
    };

    return bless \%opt, $class;
};

=head2 clone

Create a copy of existing route, possibly overriding some of the fields.

=cut

# TODO 0.30 -> Util::Base?
sub clone {
    my ($self, %override) = @_;

    return (ref $self)->new( %$self, %override );
};

=head2 lock()

Prohibit any further modifications to this route.

=cut

sub lock {
    my $self = shift;
    $self->{lock}++;
    return $self;
};

=head2 is_locked

Check that route is locked.

=cut

sub is_locked {
    my $self = shift;
    return !!$self->{lock};
};

# TODO 0.30 -> Util::Base?
sub _can_modify {
    my $self = shift;
    return unless $self->{lock};
    # oops

    croak "Modification of locked ".(ref $self)." attempted";
};

=head2 add_form()

    add_form( name => $validator )

Create a named form for future query data validation
via C<$request-E<gt>form("name")>.
See L<MVC::Neaf::Request/form>.

The C<$validator> is one of:

=over

=item * An object with C<validate> method accepting one C<\%hashref>
argument (the raw form data).

=item * A CODEREF accepting the same argument.

=back

Whatever is returned by validator is forwarded into the controller.

Neaf comes with a set of predefined validator classes that return
a convenient object that contains collected valid data, errors (if any),
and an is_valid flag.

The C<engine> parameter of the functional form has predefined values
C<Neaf> (the default), C<LIVR>, and C<Wildcard> (all case-insensitive)
pointing towards L<MVC::Neaf::X::Form>, L<MVC::Neaf::X::Form::LIVR>,
and L<MVC::Neaf::X::Form::Wildcard>, respectively.

You are encouraged to use C<LIVR>
(See L<Validator::LIVR> and L<LIVR grammar|https://github.com/koorchik/LIVR>)
for anything except super-basic regex checks.

If an arbitrary class name is given instead, C<new()> will be called
on that class with \%spec ref as first parameter.

Consider the following script:

    use MVC::Neaf;
    neaf form => my => { foo => '\d+', bar => '[yn]' };
    get '/check' => sub {
        my $req = shift;
        my $in = $req->form("my");
        return $in->is_valid ? { ok => $in->data } : { error => $in->error };
    };
    neaf->run

And by running this one gets

    bash$ curl http://localhost:5000/check?bar=xxx
    {"error":{"bar":"BAD_FORMAT"}}
    bash$ curl http://localhost:5000/check?bar=y
    {"ok":{"bar":"y"}}
    bash$ curl http://localhost:5000/check?bar=yy
    {"error":{"bar":"BAD_FORMAT"}}
    bash$ curl http://localhost:5000/check?foo=137\&bar=n
    {"ok":{"bar":"n","foo":"137"}}
    bash$ curl http://localhost:5000/check?foo=leet
    {"error":{"foo":"BAD_FORMAT"}}

=cut

my %FORM_ENGINE = (
    neaf     => 'MVC::Neaf::X::Form',
    livr     => 'MVC::Neaf::X::Form::LIRV',
    wildcard => 'MVC::Neaf::X::Form::Wildcard',
);

sub add_form {
    my ($self, $name, $spec, %opt) = @_;
    # TODO 0.30 Make path-based?

    $name and $spec
        or $self->my_croak( "Form name and spec must be nonempty" );
    exists $self->{forms}{$name}
        and $self->my_croak( "Form $name redefined" );

    if (!blessed $spec) {
        my $eng = delete $opt{engine} || 'MVC::Neaf::X::Form';
        $eng = $FORM_ENGINE{ lc $eng } || $eng;

        if (!$eng->can("new")) {
            eval { load $eng; 1 }
                or $self->my_croak( "Failed to load form engine $eng: $@" );
        };

        $spec = $eng->new( $spec, %opt );
    };

    $self->{forms}{$name} = $spec;
    return $self;
};

=head2 get_form()

    $neaf->get_form( "name" )

Fetch form named "name" previously added via add_form to
this route or one of its parent routes.

See L<MVC::Neaf::Request/form>.
See also L</add_form>.

=cut

sub get_form {
    my ($self, $name) = @_;

    # Aggressive caching for the win
    return $self->{forms}{$name} ||= do {
        my $parent = $self->parent;
        $self->my_croak("Failed to locate form named $name")
            unless $parent;
        $parent->get_form($name);
    };
};

=head2 get_view

=cut

sub get_view {
    my ($self, $name) = @_;

    return $self->{views}{$name} ||= do {
        my $parent = $self->parent;
        $self->my_croak("Failed to locate view named $name")
            unless $parent;
        $parent->get_view($name);
    };
};

=head2 post_setup

Calculate hooks and path-based defaults.

Locks route, dies if already locked.

=cut

sub post_setup {
    my $self = shift;

    # LOCK PROFILE
    confess "Attempt to repeat route setup. MVC::Neaf broken, please file a bug"
        if $self->is_locked;

    my $neaf = $self->parent;
    # CALCULATE DEFAULTS
    # merge data sources, longer paths first
    $self->{default} = $neaf->get_path_defaults ( $self->method, $self->path, $self->{default} );
    $self->{hooks}   = $neaf->get_hooks   ( $self->method, $self->path );
    $self->{helpers} = $neaf->get_helpers ( $self->method, $self->path );

    $self->lock;

    return;
};

=head2 INTERNAL LOGIC

The following methods are part of NEAF's core and should not be called
unless you want something I<very> special.

=head2 dispatch_logic

    dispatch_logic( $req, $stem, $suffix )

May die. May spoil request.

Apply controller code to given request object, path stem, and path suffix.

Upon success, return a Neaf response hash (see L<MVC::Neaf/THE-RESPONSE>).

=cut

sub dispatch_logic {
    my ($self, $req, $stem, $suffix) = @_;

    $self->post_setup
        unless $self->{lock};

    # TODO 0.90 optimize this or do smth. Still MUST keep route_re a prefix tree
    if ($suffix =~ /%/) {
        $suffix = decode_utf8( uri_unescape( $suffix ) );
    };
    my @split = $suffix =~ $self->path_info_regex
        or die "404\n";
    $req->_import_route( $self, $stem, $suffix, \@split );

    # execute hooks
    run_all( $self->{hooks}{pre_logic}, $req)
        if exists $self->{hooks}{pre_logic};

    # Run the controller!
    my $reply = $self->code->($req);
#   TODO cannot write to request until hash type-checked
#    $req->_set_reply( $reply );
    $reply;
};

# Setup getters
make_getters( %RO_FIELDS );

=head1 LICENSE AND COPYRIGHT

This module is part of L<MVC::Neaf> suite.

Copyright 2016-2019 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
