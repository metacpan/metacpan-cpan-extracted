package JSON::Any; # git description: v1.38-9-ga958b5a

use warnings;
use strict;

our $VERSION = '1.39';

use Carp qw(croak carp);

# ABSTRACT: (DEPRECATED) Wrapper Class for the various JSON classes
# KEYWORDS: json serialization serialisation wrapper abstraction

our $UTF8;

my ( %conf, $handler, $encoder, $decoder );
use constant HANDLER => 0;
use constant ENCODER => 1;
use constant DECODER => 2;
use constant UTF8    => 3;

BEGIN {
    %conf = (
        json_1 => {
            encoder       => 'objToJson',
            decoder       => 'jsonToObj',
            get_true      => sub { return JSON::True(); },
            get_false     => sub { return JSON::False(); },
            create_object => sub {
                require JSON;
                my ( $self, $conf ) = @_;
                my @params = qw(
                  autoconv
                  skipinvalid
                  execcoderef
                  pretty
                  indent
                  delimiter
                  keysort
                  convblessed
                  selfconvert
                  singlequote
                  quoteapos
                  unmapping
                  barekey
                );
                my $obj =
                  $handler->new( utf8 => $conf->{utf8} );    ## constructor only

                for my $mutator (@params) {
                    next unless exists $conf->{$mutator};
                    $obj = $obj->$mutator( $conf->{$mutator} );
                }

                $self->[ENCODER] = 'objToJson';
                $self->[DECODER] = 'jsonToObj';
                $self->[HANDLER] = $obj;
            },
        },
        json_2 => {
            encoder       => 'encode_json',
            decoder       => 'decode_json',
            get_true      => sub { return JSON::true(); },
            get_false     => sub { return JSON::false(); },
            create_object => sub {
                JSON->import( '-support_by_pp', '-no_export' );
                my ( $self, $conf ) = @_;
                my @params = qw(
                  ascii
                  latin1
                  utf8
                  pretty
                  indent
                  space_before
                  space_after
                  relaxed
                  canonical
                  allow_nonref
                  allow_blessed
                  convert_blessed
                  filter_json_object
                  shrink
                  max_depth
                  max_size
                  loose
                  allow_bignum
                  allow_barekey
                  allow_singlequote
                  escape_slash
                  indent_length
                  sort_by
                );
                local $conf->{utf8} = !$conf->{utf8};    # it means the opposite
                my $obj = $handler->new;

                for my $mutator (@params) {
                    next unless exists $conf->{$mutator};
                    $obj = $obj->$mutator( $conf->{$mutator} );
                }

                $self->[ENCODER] = 'encode';
                $self->[DECODER] = 'decode';
                $self->[HANDLER] = $obj;
            },
        },
        json_dwiw => {
            encoder       => 'to_json',
            decoder       => 'from_json',
            get_true      => sub { return JSON::DWIW->true; },
            get_false     => sub { return JSON::DWIW->false; },
            create_object => sub {
                my ( $self, $conf ) = @_;
                my @params = qw(bare_keys);
                croak "JSON::DWIW does not support utf8" if $conf->{utf8};
                $self->[ENCODER] = 'to_json';
                $self->[DECODER] = 'from_json';
                $self->[HANDLER] =
                  $handler->new( { map { $_ => $conf->{$_} } @params } );
            },
        },
        json_xs_1 => {
            encoder       => 'to_json',
            decoder       => 'from_json',
            get_true      => sub { return \1; },
            get_false     => sub { return \0; },
            create_object => sub {
                my ( $self, $conf ) = @_;

                my @params = qw(
                  ascii
                  utf8
                  pretty
                  indent
                  space_before
                  space_after
                  canonical
                  allow_nonref
                  shrink
                  max_depth
                );

                my $obj = $handler->new;
                for my $mutator (@params) {
                    next unless exists $conf->{$mutator};
                    $obj = $obj->$mutator( $conf->{$mutator} );
                }
                $self->[ENCODER] = 'encode';
                $self->[DECODER] = 'decode';
                $self->[HANDLER] = $obj;
            },
        },
        json_xs_2 => {
            encoder       => 'encode_json',
            decoder       => 'decode_json',
            get_true      => sub { return JSON::XS::true(); },
            get_false     => sub { return JSON::XS::false(); },
            create_object => sub {
                my ( $self, $conf ) = @_;

                my @params = qw(
                  ascii
                  latin1
                  utf8
                  pretty
                  indent
                  space_before
                  space_after
                  relaxed
                  canonical
                  allow_nonref
                  allow_blessed
                  convert_blessed
                  filter_json_object
                  shrink
                  max_depth
                  max_size
                );

                local $conf->{utf8} = !$conf->{utf8};    # it means the opposite

                my $obj = $handler->new;
                for my $mutator (@params) {
                    next unless exists $conf->{$mutator};
                    $obj = $obj->$mutator( $conf->{$mutator} );
                }
                $self->[ENCODER] = 'encode';
                $self->[DECODER] = 'decode';
                $self->[HANDLER] = $obj;
            },
        },
        json_syck => {
            encoder  => 'Dump',
            decoder  => 'Load',
            get_true => sub {
                croak "JSON::Syck does not support special boolean values";
            },
            get_false => sub {
                croak "JSON::Syck does not support special boolean values";
            },
            create_object => sub {
                my ( $self, $conf ) = @_;
                croak "JSON::Syck does not support utf8" if $conf->{utf8};
                $self->[ENCODER] = sub { Dump(@_) };
                $self->[DECODER] = sub { Load(@_) };
                $self->[HANDLER] = 'JSON::Syck';
              }
        },
    );

    # JSON::PP has the same API as JSON.pm v2
    $conf{json_pp} = { %{ $conf{json_2} } };
    $conf{json_pp}{get_true}  = sub { return JSON::PP::true(); };
    $conf{json_pp}{get_false} = sub { return JSON::PP::false(); };

    # Cpanel::JSON::XS is a fork of JSON::XS (currently)
    $conf{cpanel_json_xs} = { %{ $conf{json_xs_2} } };
    $conf{cpanel_json_xs}{get_true}  = sub { return Cpanel::JSON::XS::true(); };
    $conf{cpanel_json_xs}{get_false} = sub { return Cpanel::JSON::XS::false(); };

    # JSON::XS 3 is almost the same as JSON::XS 2
    $conf{json_xs_3} = { %{ $conf{json_xs_2} } };
    $conf{json_xs_3}{get_true}  = sub { return Types::Serialiser::true(); };
    $conf{json_xs_3}{get_false} = sub { return Types::Serialiser::false(); };
}

sub _make_key {
    my $handler = shift;
    ( my $key = lc($handler) ) =~ s/::/_/g;
    if ( 'json_xs' eq $key || 'json' eq $key ) {
        no strict 'refs';
        $key .= "_" . ( split /\./, ${"$handler\::VERSION"} )[0];
    }
    return $key;
}

my @default    = qw(CPANEL XS PP JSON DWIW);
my @deprecated = qw(Syck);

sub _module_name {
    my ($testmod) = @_;
    return 'Cpanel::JSON::XS' if $testmod eq 'CPANEL';
    return 'JSON'             if $testmod eq 'JSON';
    return "JSON::$testmod";
}

sub _try_loading {
    my @order = @_;
    ( $handler, $encoder, $decoder ) = ();
    foreach my $mod (@order) {
        my $testmod = _module_name($mod);
        if (eval "require $testmod; 1") {
            $handler = $testmod;
            my $key = _make_key($handler);
            next unless exists $conf{$key};
            $encoder = $conf{$key}->{encoder};
            $decoder = $conf{$key}->{decoder};
            last;
        }
    }
    return ( $handler, $encoder, $decoder );
}

sub import {
    my $class = shift;
    my @order = @_;

    ( $handler, $encoder, $decoder ) = ();

    @order = split /\s/, $ENV{JSON_ANY_ORDER}
      if !@order and $ENV{JSON_ANY_ORDER};

    if (@order) {
        ( $handler, $encoder, $decoder ) = _try_loading(@order);
        if ( $handler && grep { "JSON::$_" eq $handler } @deprecated ) {
            my @upgrade_to = grep { my $mod = $_; !grep { $mod eq $_ } @deprecated } @order;
            @upgrade_to = @default if not @upgrade_to;
            carp "Found deprecated package $handler. Please upgrade to ",
                _module_name_list(@upgrade_to);
        }
    }
    else {
        ( $handler, $encoder, $decoder ) = _try_loading(@default);
        unless ($handler) {
            ( $handler, $encoder, $decoder ) = _try_loading(@deprecated);
            if ($handler) {
                carp "Found deprecated package $handler. Please upgrade to ",
                  _module_name_list(@default);
            }
        }
    }

    unless ($handler) {
        croak "Couldn't find a JSON package. Need ", _module_name_list(@order ? @order : @default);
    }
    croak "Couldn't find a working decoder method (but found handler $handler ", $handler->VERSION, ")." unless $decoder;
    croak "Couldn't find a working encoder method (but found handler $handler ", $handler->VERSION, ")." unless $encoder;
}

sub _module_name_list {
    my @list = map { _module_name($_) } @_;
    my $last = pop @list;
    return (@list
        ? (join(', ' => @list), " or $last")
        : $last
    );
}

#pod =head1 SYNOPSIS
#pod
#pod     use JSON::Any;
#pod     my $j = JSON::Any->new;
#pod     my $json = $j->objToJson({foo=>'bar', baz=>'quux'});
#pod     my $obj = $j->jsonToObj($json);
#pod
#pod =head1 DEPRECATION NOTICE
#pod
#pod The original need for L<JSON::Any> has been solved (quite some time ago
#pod actually). If you're producing new code it is recommended to use L<JSON::MaybeXS> which
#pod will optionally use L<Cpanel::JSON::XS> for speed purposes.
#pod
#pod JSON::Any will continue to be maintained for compatibility with existing code,
#pod but for new code you should strongly consider using L<JSON::MaybeXS> instead.
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module tries to provide a coherent API to bring together the various JSON
#pod modules currently on CPAN. This module will allow you to code to any JSON API
#pod and have it work regardless of which JSON module is actually installed.
#pod
#pod     use JSON::Any;
#pod
#pod     my $j = JSON::Any->new;
#pod
#pod     $json = $j->objToJson({foo=>'bar', baz=>'quux'});
#pod     $obj = $j->jsonToObj($json);
#pod
#pod or
#pod
#pod     $json = $j->encode({foo=>'bar', baz=>'quux'});
#pod     $obj = $j->decode($json);
#pod
#pod or
#pod
#pod     $json = $j->Dump({foo=>'bar', baz=>'quux'});
#pod     $obj = $j->Load($json);
#pod
#pod or
#pod
#pod     $json = $j->to_json({foo=>'bar', baz=>'quux'});
#pod     $obj = $j->from_json($json);
#pod
#pod or without creating an object:
#pod
#pod     $json = JSON::Any->objToJson({foo=>'bar', baz=>'quux'});
#pod     $obj = JSON::Any->jsonToObj($json);
#pod
#pod On load, JSON::Any will find a valid JSON module in your @INC by looking
#pod for them in this order:
#pod
#pod     Cpanel::JSON::XS
#pod     JSON::XS
#pod     JSON::PP
#pod     JSON
#pod     JSON::DWIW
#pod
#pod And loading the first one it finds.
#pod
#pod You may change the order by specifying it on the C<use JSON::Any> line:
#pod
#pod     use JSON::Any qw(DWIW XS CPANEL JSON PP);
#pod
#pod Specifying an order that is missing modules will prevent those module from
#pod being used:
#pod
#pod     use JSON::Any qw(CPANEL PP); # same as JSON::MaybeXS
#pod
#pod This will check in that order, and will never attempt to load L<JSON::XS>,
#pod L<JSON.pm/JSON>, or L<JSON::DWIW>. This can also be set via the C<$ENV{JSON_ANY_ORDER}>
#pod environment variable.
#pod
#pod L<JSON::Syck> has been deprecated by its author, but in the attempt to still
#pod stay relevant as a "Compatibility Layer" JSON::Any still supports it. This support
#pod however has been made optional starting with JSON::Any 1.19. In deference to a
#pod bug request starting with L<JSON.pm|JSON> 1.20, L<JSON::Syck> and other deprecated modules
#pod will still be installed, but only as a last resort and will now include a
#pod warning.
#pod
#pod     use JSON::Any qw(Syck XS JSON);
#pod
#pod or
#pod
#pod     $ENV{JSON_ANY_ORDER} = 'Syck XS JSON';
#pod
#pod At install time, JSON::Any will attempt to install L<JSON::PP> as a reasonable
#pod fallback if you do not appear have B<any> backends installed on your system.
#pod
#pod WARNING: If you call JSON::Any with an empty list
#pod
#pod     use JSON::Any ();
#pod
#pod It will skip the JSON package detection routines and will die loudly that it
#pod couldn't find a package.
#pod
#pod =head1 WARNING
#pod
#pod L<JSON::XS> 3.0 or higher has a conflict with any version of L<JSON.pm|JSON> less than 2.90
#pod when you use L<JSON.pm|JSON>'s C<-support_by_pp> option, which JSON::Any enables by
#pod default.
#pod
#pod This situation should only come up with JSON::Any if you have L<JSON.pm|JSON> 2.61 or
#pod lower B<and> L<JSON::XS> 3.0 or higher installed, and you use L<JSON.pm|JSON>
#pod via C<< use JSON::Any qw(JSON); >> or the C<JSON_ANY_ORDER> environment variable.
#pod
#pod If you run into an issue where you're getting recursive inheritance errors in a
#pod L<Types::Serialiser> package, please try upgrading L<JSON.pm|JSON> to 2.90 or higher.
#pod
#pod =head1 METHODS
#pod
#pod =head2 C<new>
#pod
#pod =for :stopwords recognised unicode
#pod
#pod Will take any of the parameters for the underlying system and pass them
#pod through. However these values don't map between JSON modules, so, from a
#pod portability standpoint this is really only helpful for those parameters that
#pod happen to have the same name.
#pod
#pod The one parameter that is universally supported (to the extent that is
#pod supported by the underlying JSON modules) is C<utf8>. When this parameter is
#pod enabled all resulting JSON will be marked as unicode, and all unicode strings
#pod in the input data structure will be preserved as such.
#pod
#pod Also note that the C<allow_blessed> parameter is recognised by all the modules
#pod that throw exceptions when a blessed reference is given them meaning that
#pod setting it to true works for all modules. Of course, that means that you
#pod cannot set it to false intentionally in order to always get such exceptions.
#pod
#pod The actual output will vary, for example L<JSON> will encode and decode
#pod unicode chars (the resulting JSON is not unicode) whereas L<JSON::XS> will emit
#pod unicode JSON.
#pod
#pod =cut

sub new {
    my $class = shift;
    my $self  = bless [], $class;
    my $key   = _make_key($handler);
    if ( my $creator = $conf{$key}->{create_object} ) {
        my @config;
        # undocumented! and yet, people are using this...
        if ( $ENV{JSON_ANY_CONFIG} ) {
            push @config, map { split /=/, $_ } split /,\s*/,
              $ENV{JSON_ANY_CONFIG};
        }
        push @config, @_;
        $creator->( $self, my $conf = {@config} );
        $self->[UTF8] = $conf->{utf8};
    }
    return $self;
}

#pod =head2 C<handlerType>
#pod
#pod Takes no arguments, returns a string indicating which JSON Module is in use.
#pod
#pod =cut

sub handlerType {
    my $class = shift;
    $handler;
}

#pod =head2 C<handler>
#pod
#pod Takes no arguments, if called on an object returns the internal JSON::*
#pod object in use.  Otherwise returns the JSON::* package we are using for
#pod class methods.
#pod
#pod =cut

sub handler {
    my $self = shift;
    if ( ref $self ) {
        return $self->[HANDLER];
    }
    return $handler;
}

#pod =head2 C<true>
#pod
#pod Takes no arguments, returns the special value that the internal JSON
#pod object uses to map to a JSON C<true> boolean.
#pod
#pod =cut

sub true {
    my $key = _make_key($handler);
    return $conf{$key}->{get_true}->();
}

#pod =head2 C<false>
#pod
#pod Takes no arguments, returns the special value that the internal JSON
#pod object uses to map to a JSON C<false> boolean.
#pod
#pod =cut

sub false {
    my $key = _make_key($handler);
    return $conf{$key}->{get_false}->();
}

#pod =head2 C<objToJson>
#pod
#pod Takes a single argument, a hashref to be converted into JSON.
#pod It returns the JSON text in a scalar.
#pod
#pod =cut

sub objToJson {
    my $self = shift;
    my $obj  = shift;
    croak 'must provide object to convert' unless defined $obj;

    my $json;

    if ( ref $self ) {
        my $method;
        unless ( ref $self->[ENCODER] ) {
            croak "No $handler Object created!"
              unless exists $self->[HANDLER];
            $method = $self->[HANDLER]->can( $self->[ENCODER] );
            croak "$handler can't execute $self->[ENCODER]" unless $method;
        }
        else {
            $method = $self->[ENCODER];
        }
        $json = $self->[HANDLER]->$method($obj);
    }
    else {
        $json = $handler->can($encoder)->($obj);
    }

    utf8::decode($json)
      if ( ref $self ? $self->[UTF8] : $UTF8 )
      and !utf8::is_utf8($json)
      and utf8::valid($json);
    return $json;
}

#pod =head2 C<to_json>
#pod
#pod =head2 C<Dump>
#pod
#pod =head2 C<encode>
#pod
#pod Aliases for C<objToJson>, can be used interchangeably, regardless of the
#pod underlying JSON module.
#pod =cut

*to_json = \&objToJson;
*Dump    = \&objToJson;
*encode  = \&objToJson;

#pod =head2 C<jsonToObj>
#pod
#pod Takes a single argument, a string of JSON text to be converted
#pod back into a hashref.
#pod
#pod =cut

sub jsonToObj {
    my $self = shift;
    my $obj  = shift;
    croak 'must provide json to convert' unless defined $obj;

    # some handlers can't parse single booleans (I'm looking at you DWIW)
    if ( $obj =~ /^(true|false)$/ ) {
        return $self->$1;
    }

    if ( ref $self ) {
        my $method;
        unless ( ref $self->[DECODER] ) {
            croak "No $handler Object created!"
              unless exists $self->[HANDLER];
            $method = $self->[HANDLER]->can( $self->[DECODER] );
            croak "$handler can't execute $self->[DECODER]" unless $method;
        }
        else {
            $method = $self->[DECODER];
        }
        return $self->[HANDLER]->$method($obj);
    }
    $handler->can($decoder)->($obj);
}

#pod =head2 C<from_json>
#pod
#pod =head2 C<Load>
#pod
#pod =head2 C<decode>
#pod
#pod Aliases for C<jsonToObj>, can be used interchangeably, regardless of the
#pod underlying JSON module.
#pod
#pod =cut

*from_json = \&jsonToObj;
*Load      = \&jsonToObj;
*decode    = \&jsonToObj;

{
    no strict 'refs';
    delete @{__PACKAGE__.'::'}{qw(croak carp)};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Any - (DEPRECATED) Wrapper Class for the various JSON classes

=head1 VERSION

version 1.39

=head1 SYNOPSIS

    use JSON::Any;
    my $j = JSON::Any->new;
    my $json = $j->objToJson({foo=>'bar', baz=>'quux'});
    my $obj = $j->jsonToObj($json);

=head1 DESCRIPTION

This module tries to provide a coherent API to bring together the various JSON
modules currently on CPAN. This module will allow you to code to any JSON API
and have it work regardless of which JSON module is actually installed.

    use JSON::Any;

    my $j = JSON::Any->new;

    $json = $j->objToJson({foo=>'bar', baz=>'quux'});
    $obj = $j->jsonToObj($json);

or

    $json = $j->encode({foo=>'bar', baz=>'quux'});
    $obj = $j->decode($json);

or

    $json = $j->Dump({foo=>'bar', baz=>'quux'});
    $obj = $j->Load($json);

or

    $json = $j->to_json({foo=>'bar', baz=>'quux'});
    $obj = $j->from_json($json);

or without creating an object:

    $json = JSON::Any->objToJson({foo=>'bar', baz=>'quux'});
    $obj = JSON::Any->jsonToObj($json);

On load, JSON::Any will find a valid JSON module in your @INC by looking
for them in this order:

    Cpanel::JSON::XS
    JSON::XS
    JSON::PP
    JSON
    JSON::DWIW

And loading the first one it finds.

You may change the order by specifying it on the C<use JSON::Any> line:

    use JSON::Any qw(DWIW XS CPANEL JSON PP);

Specifying an order that is missing modules will prevent those module from
being used:

    use JSON::Any qw(CPANEL PP); # same as JSON::MaybeXS

This will check in that order, and will never attempt to load L<JSON::XS>,
L<JSON.pm/JSON>, or L<JSON::DWIW>. This can also be set via the C<$ENV{JSON_ANY_ORDER}>
environment variable.

L<JSON::Syck> has been deprecated by its author, but in the attempt to still
stay relevant as a "Compatibility Layer" JSON::Any still supports it. This support
however has been made optional starting with JSON::Any 1.19. In deference to a
bug request starting with L<JSON.pm|JSON> 1.20, L<JSON::Syck> and other deprecated modules
will still be installed, but only as a last resort and will now include a
warning.

    use JSON::Any qw(Syck XS JSON);

or

    $ENV{JSON_ANY_ORDER} = 'Syck XS JSON';

At install time, JSON::Any will attempt to install L<JSON::PP> as a reasonable
fallback if you do not appear have B<any> backends installed on your system.

WARNING: If you call JSON::Any with an empty list

    use JSON::Any ();

It will skip the JSON package detection routines and will die loudly that it
couldn't find a package.

=head1 DEPRECATION NOTICE

The original need for L<JSON::Any> has been solved (quite some time ago
actually). If you're producing new code it is recommended to use L<JSON::MaybeXS> which
will optionally use L<Cpanel::JSON::XS> for speed purposes.

JSON::Any will continue to be maintained for compatibility with existing code,
but for new code you should strongly consider using L<JSON::MaybeXS> instead.

=head1 WARNING

L<JSON::XS> 3.0 or higher has a conflict with any version of L<JSON.pm|JSON> less than 2.90
when you use L<JSON.pm|JSON>'s C<-support_by_pp> option, which JSON::Any enables by
default.

This situation should only come up with JSON::Any if you have L<JSON.pm|JSON> 2.61 or
lower B<and> L<JSON::XS> 3.0 or higher installed, and you use L<JSON.pm|JSON>
via C<< use JSON::Any qw(JSON); >> or the C<JSON_ANY_ORDER> environment variable.

If you run into an issue where you're getting recursive inheritance errors in a
L<Types::Serialiser> package, please try upgrading L<JSON.pm|JSON> to 2.90 or higher.

=head1 METHODS

=head2 C<new>

=for :stopwords recognised unicode

Will take any of the parameters for the underlying system and pass them
through. However these values don't map between JSON modules, so, from a
portability standpoint this is really only helpful for those parameters that
happen to have the same name.

The one parameter that is universally supported (to the extent that is
supported by the underlying JSON modules) is C<utf8>. When this parameter is
enabled all resulting JSON will be marked as unicode, and all unicode strings
in the input data structure will be preserved as such.

Also note that the C<allow_blessed> parameter is recognised by all the modules
that throw exceptions when a blessed reference is given them meaning that
setting it to true works for all modules. Of course, that means that you
cannot set it to false intentionally in order to always get such exceptions.

The actual output will vary, for example L<JSON> will encode and decode
unicode chars (the resulting JSON is not unicode) whereas L<JSON::XS> will emit
unicode JSON.

=head2 C<handlerType>

Takes no arguments, returns a string indicating which JSON Module is in use.

=head2 C<handler>

Takes no arguments, if called on an object returns the internal JSON::*
object in use.  Otherwise returns the JSON::* package we are using for
class methods.

=head2 C<true>

Takes no arguments, returns the special value that the internal JSON
object uses to map to a JSON C<true> boolean.

=head2 C<false>

Takes no arguments, returns the special value that the internal JSON
object uses to map to a JSON C<false> boolean.

=head2 C<objToJson>

Takes a single argument, a hashref to be converted into JSON.
It returns the JSON text in a scalar.

=head2 C<to_json>

=head2 C<Dump>

=head2 C<encode>

Aliases for C<objToJson>, can be used interchangeably, regardless of the
underlying JSON module.

=head2 C<jsonToObj>

Takes a single argument, a string of JSON text to be converted
back into a hashref.

=head2 C<from_json>

=head2 C<Load>

=head2 C<decode>

Aliases for C<jsonToObj>, can be used interchangeably, regardless of the
underlying JSON module.

=head1 ACKNOWLEDGEMENTS

=for :stopwords Dimas Wistow mst

This module came about after discussions on irc.perl.org about the fact
that there were now six separate JSON perl modules with different interfaces.

In the spirit of Class::Any, JSON::Any was created with the considerable
help of Matt 'mst' Trout.

Simon Wistow graciously supplied a patch for backwards compatibility with JSON::XS
versions previous to 2.01

San Dimas High School Football Rules!

=head1 AUTHORS

=over 4

=item *

Chris Thompson <cthom@cpan.org>

=item *

Chris Prather <chris@prather.org>

=item *

Robin Berjon <robin@berjon.com>

=item *

Marc Mims <marc@questright.com>

=item *

Tomas Doran <bobtfish@bobtfish.net>

=back

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge יובל קוג'מן (Yuval Kogman) Dagfinn Ilmari Mannsåker Justin Hunter Todd Rinaldo Matthew Horsfall

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=item *

Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>

=item *

Justin Hunter <justin.d.hunter@gmail.com>

=item *

Todd Rinaldo <toddr@cpan.org>

=item *

Matthew Horsfall <wolfsage@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Chris Thompson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
