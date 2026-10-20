# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to provide information on languages


package Lingua::Generic::Information::Language;

use v5.20;
use strict;
use warnings;

use Carp;
use List::Util qw(any);
use I18N::LangTags ();
use I18N::LangTags::List;
use Data::Identifier v0.36;
use Data::Identifier::Generate;
use Lingua::Generic::Information::Data;

use parent qw(Data::Identifier::Interface::Subobjects Data::Identifier::Interface::Simple Data::Identifier::Interface::Known);

use constant {
    WK_LTI => Data::Identifier->new(uuid => 'd0a4c6e2-ce2f-4d4c-b079-60065ac681f1')->register, # language-tag-identifier
    WK_SID => Data::Identifier->new(uuid => 'f87a38cb-fd13-4e15-866c-e49901adbec5')->register, # small-identifier
};

our $VERSION = v0.01;

my %_filter_types = (
    (map {$_ => 'bool'} qw(question)),
    (map {$_ => 'dimension'} Lingua::Generic::Information::Data->_get_dimension_names),
);

my %_property_info = (
    dimensions_excluded => {allow_empty_list => 1, to_object => sub { (Lingua::Generic::Information::Data->_get_dimensions(@_))[0] }},
);

my %_by = map {$_ => {}} qw(uuid lti sid wd);

my %_defaults_for_latin_script = (
    dimensions_excluded => [
        [{} => {raw => []}],
    ],
    sentence_separator => [
        [{} => {raw => ' '}],
    ],
    sentence_terminator => [
        [{question    => 1} => {raw => '?'}],
        [{no_defaults => 0} => {raw => '.'}],
    ],
    sentence_preamble => [
        [{} => {allow_undef => 1}],
    ],
    word_separator => [
        [{} => {raw => ' '}],
    ],
    sentence_first_word_case => [
        [{} => {raw => 'ucfirst'}],
    ],
    term_scan_ahead => [
        [{} => {raw => 5}],
    ],
);

{
    my __PACKAGE__ $l = __PACKAGE__->_find(lti => 'de');
    $l->_add_identifier(wd => 'Q188');
    $l->{values} = {
        %_defaults_for_latin_script,
    };
}

{
    my __PACKAGE__ $l = __PACKAGE__->_find(lti => 'en');
    $l->_add_identifier(wd => 'Q1860');
    $l->{values} = {
        %_defaults_for_latin_script,
    };
}

{
    # famibeib has no lti
    my __PACKAGE__ $l;

    Data::Identifier->new(uuid => '1d668738-8aef-4cb4-a4ed-9368e872a93f', tagname => 'famibeib')->register;

    $l = __PACKAGE__->_new('1d668738-8aef-4cb4-a4ed-9368e872a93f', displayname => 'famibeib');
    $l->{values} = {
        %_defaults_for_latin_script,
        sentence_terminator => [
            [{question    => 1} => {raw => ' be'}],
            [{no_defaults => 0} => {raw => ' ba'}],
        ],
        sentence_first_word_case => [
            [{} => {allow_undef => 1}],
        ],
    };
}

{
    # Build Toki Pona (tok)
    # Be aware that I18N::LangTags::List does not include it in at least up to version 0.40.
    # This complicates generation.
    my $l;

    eval { Data::Identifier::Generate->language('tok')->register }; # we first try to generate the identifier as normal.
    Data::Identifier->new(uuid => 'f21986c8-baa1-5b7e-b357-2a76285c4778', tagname => 'Toki Pona')->register; # do it manually

    $l = __PACKAGE__->_new('f21986c8-baa1-5b7e-b357-2a76285c4778', displayname => 'Toki Pona');
    $l->_add_identifier(lti => 'tok', wd => 'Q36846');
    $l->{values} = {
        %_defaults_for_latin_script,
        dimensions_excluded => [
            [{} => {raw => 'numerus'}],
        ],
        sentence_first_word_case => [
            [{} => {raw => 'lc'}],
        ],
    };
}

my @_wellknown = __PACKAGE__->known('registered');


sub langtag {
    my ($self, @opts) = @_;

    return $self->{lti} if defined($self->{lti}) && scalar(@opts) == 0;
    return $self->_getter_object(raw => $self->{lti}, idtype => WK_LTI, @opts);
}


sub sid {
    my ($self, @opts) = @_;

    return $self->{sid} if defined($self->{sid}) && scalar(@opts) == 0;
    return $self->_getter_object(raw => $self->{sid}, idtype => WK_SID, @opts);
}


sub wd {
    my ($self, @opts) = @_;

    return $self->{wd} if defined($self->{wd}) && scalar(@opts) == 0;
    return $self->_getter_object(raw => $self->{wd}, idtype => 'wd', @opts);
}


sub super {
    my ($self, @opts) = @_;

    unless (exists $self->{super}) {
        my @supers = defined $self->{lti} ? I18N::LangTags::super_languages($self->{lti}) : ();

        if (scalar(@supers)) {
            $self->{super} = __PACKAGE__->_find(lti => $supers[-1]);
        } else {
            $self->{super} = undef;
        }
    }

    return $self->{super} if defined($self->{super}) && scalar(@opts) == 0;
    return $self->_getter_object(raw => $self->{super}, @opts);
}


sub query {
    my ($self, $property, %opts) = @_;
    my $candidates = $self->{values} //= {};
    my $filter = delete($opts{filter}) // {};

    # TODO handle case where $property is a Data::Identifier::Interface::Simple

    $candidates = $candidates->{$property} // croak 'Nothing known about this property in this language';

    outer:
    foreach my $candidate (@{$candidates}) {
        my ($c_requiements, $res) = @{$candidate};

        foreach my $c_key (keys %{$c_requiements}) {
            my $c_v = $c_requiements->{$c_key};

            if ($c_key eq 'no_defaults') {
                next outer if ($opts{no_defaults} xor $c_v);
            } elsif (defined(my $type = $_filter_types{$c_key})) {
                my $f_v = $filter->{$c_key};

                if ($type eq 'bool') {
                    next outer if ($f_v xor $c_v);
                } elsif ($type eq 'dimension') {
                    next outer unless defined $f_v;
                    ($f_v) = Lingua::Generic::Information::Data->_get_values_by_dimension($c_key => $f_v);
                    next outer unless any {$_->eq($f_v)} Lingua::Generic::Information::Data->_get_values_by_dimension($c_key => ref($c_v) ? @{$c_v} : $c_v);
                } else {
                    croak 'BUG!';
                }
            } else {
                croak 'BUG!';
            }
        }

        return $self->_getter_object(%opts, %{$_property_info{$property} // {}}, %{$res});
    }

    if (exists $opts{default}) {
        return @{$opts{default}} if $opts{list};
        return $opts{default};
    }

    croak 'No match';
}

# ---- Private helpers ----

sub displayname {
    my ($self, @opts) = @_;

    if (scalar(@opts) == 0 && defined($self->{displayname})) {
        return $self->{displayname};
    }

    return $self->SUPER::displayname(@opts);
}

sub as {
    my ($self, $as, @opts) = @_;

    if (defined($as) && scalar(@opts) == 0) {
        if ($as eq 'Data::Identifier') {
            return $self->{id};
        } elsif (ref($as) && WK_LTI->eq($as) && defined($self->{lti})) {
            return $self->{lti};
        } elsif ($self->isa($as)) {
            return $self;
        }
    }

    return $self->SUPER::as($as, @opts);
}

sub ise {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{uuid};
}

sub _known_provider {
    my ($pkg, $class, %opts) = @_;
    croak 'Unsupported options passed' if scalar(keys %opts);
    if ($class eq ':all') {
        my %all = map {$_->ise => $_} values %{$_by{uuid}};
        return ([values %all], rawtype => 'Data::Identifier::Interface::Simple');
    } elsif ($class eq 'wellknown') {
        return (\@_wellknown, rawtype => __PACKAGE__);
    } elsif ($class eq 'registered') {
        my %langs = map {$_ => $_} values %{$_by{uuid}};
        return ([values %langs], rawtype => __PACKAGE__);
    }

    croak 'Unsupported class';
}

sub _new {
    my ($pkg, $id, %opts) = @_;
    my $self = bless {}, $pkg;
    my $displayname;
    my $di;
    my $uuid;
    my $lti;

    if ($id =~ /^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/) {
        $uuid = $id;
        $di = Data::Identifier->new(uuid => $id);
    } elsif (I18N::LangTags::List::is_decent($id)) {
        $lti = $id;
        $di = Data::Identifier::Generate->language($id);
        $uuid = $di->uuid;
    } else {
        croak 'Invalid language';
    }

    if (defined $lti) {
        $displayname = I18N::LangTags::List::name($lti);
    }

    $displayname //= $opts{displayname};

    $di->register;
    Data::Identifier->new(from => $di, displayname => $displayname) if defined $displayname; # update $di

    $self->{id} = $di;
    $self->{uuid} = $uuid;
    $self->{lti} = $lti if defined $lti;
    $self->{displayname} = $displayname if defined $displayname;

    $_by{uuid}{$uuid} = $self;
    $_by{lti}{lc $lti} = $self if $lti;

    if (defined(my $sid = $di->sid(default => undef, no_defaults => 1))) {
        $self->{sid} = $sid;
        $_by{sid}{$sid} = $self;
    }

    return $self;
}

sub _find {
    my ($pkg, $idtype, $id) = @_;

    if (defined($idtype) && !defined($id)) {
        # one argument form.

        if (ref $idtype) {
            if ($idtype->isa(__PACKAGE__)) {
                return $idtype;
            }

            unless ($idtype->isa('Data::Identifier::Interface::Simple')) {
                eval {$idtype = Data::Identifier->new(from => $idtype)};
            }

            if ($idtype->isa('Data::Identifier::Interface::Simple')) {
                if (defined(my $v = eval {$idtype->as(WK_LTI)})) {
                    return $pkg->_find(lti => $v);
                }

                foreach my $key (qw(sid wd fc uuid)) {
                    my $keyid = Data::Identifier->new(wellknown => $key);
                    my $v = eval {$idtype->as($keyid)} // next;
                    return $_by{$key}{$v} // next;
                }

                $idtype = $idtype->as('Data::Identifier') && redo unless $idtype->isa('Data::Identifier');
            }

            croak 'Unsupported object passed';
        } else {
            ($idtype, $id) = (lti => $idtype);
        }
    }

    croak 'Invalid language identification' unless defined($idtype) && defined($id);

    if ($idtype eq 'sid' && defined(my $lti = $Lingua::Generic::Information::Data::_sid_to_lti{$id})) {
        ($idtype, $id) = (lti => $lti);
    } elsif ($idtype eq 'uuid' && !defined($_by{uuid}{$id})) {
        return $pkg->_find(Data::Identifier->new(uuid => $id));
    }

    if ($idtype eq 'lti') {
        my $table = $_by{$idtype} // croak 'Invalid type';
        return $table->{lc $id} if defined $table->{lc $id};
        return $pkg->_new($id);
    } else {
        my $table = $_by{$idtype} // croak 'Invalid type';
        return $table->{$id} // croak 'Unknown language';
    }
}

sub _add_identifier {
    my ($self, %ids) = @_;

    foreach my $idtype (keys %ids) {
        my $table = $_by{$idtype} // croak 'Invalid type';
        my $v = $ids{$idtype} // next;
        $table->{$v} //= $self;
        $self->{$idtype} //= $v;
    }
}

sub _getter_object {
    my ($self, %opts) = @_;
    my @raw = (delete $opts{raw});
    my $has_default = exists $opts{default};
    my $default = delete $opts{default};
    my $list = delete $opts{list};
    my $as = delete $opts{as};
    my $idtype = delete $opts{idtype};
    my $allow_undef = delete $opts{allow_undef};
    my $allow_empty_list = delete $opts{allow_empty_list};
    my $to_object = delete $opts{to_object};

    delete $opts{no_defaults};

    croak 'Stray options passed' if scalar keys %opts;

    @raw = @{$raw[0]} if ref($raw[0]) eq 'ARRAY';

    if ((scalar(@raw) == 0 && !$allow_empty_list) || (scalar(@raw) == 1 && !defined($raw[0]) && !$allow_undef)) {
        if ($has_default) {
            return @{$default} if $list;
            return $default;
        }
        croak 'No value found';
    }

    if (defined $as) {
        foreach my $raw (@raw) {
            $raw = Data::Identifier->new($idtype => $raw) if defined $idtype;
            $raw = $to_object->($raw) if defined $to_object;

            next if $raw->isa($as);

            if ($raw->isa('Data::Identifier::Interface::Simple')) {
                $raw = $raw->as($as, so => $self);
            } else {
                $raw = $raw->Data::Identifier::as($as, so => $self);
            }
        }
    }

    if ($list) {
        return @raw;
    } else {
        if (scalar(@raw) == 1) {
            return $raw[0];
        } else {
            croak 'Multiple values found';
        }
    }
}

# ---- POD ----


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Generic::Information::Language - module to provide information on languages

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use Lingua::Generic::Information::Language;

    my @languages = Lingua::Generic::Information::Language->known('wellknown');

    use Lingua::Generic::Information;

    my $language = Lingua::Generic::Information->lookup_language('de');

    say $language->displayname;

This module proviles an interface to query language parameters in a language independent way.

B<Note:>
This all instances of thos package are registered.
This means that for every language there is only one shared instance.
In addition, instances of L<Data::Identifier> relevant to languages are also registered by this module.

This package inherits from L<Data::Identifier::Interface::Subobjects>,
L<Data::Identifier::Interface::Known>,
and L<Data::Identifier::Interface::Simple>.

=head1 METHODS

=head2 langtag

    my $langtag = $language->langtag;

(since v0.01)

Returns the language tag if any.

Accepts the following universal options: C<as>, C<default>, C<no_defaults>.

=head2 sid

    my $sid = $language->sid;

(since v0.01)

Returns the small identifier if any.

Accepts the following universal options: C<as>, C<default>, C<no_defaults>.

=head2 wd

    my $sid = $language->wd;

(since v0.01)

Returns the wikidata identifier if any.

Accepts the following universal options: C<as>, C<default>, C<no_defaults>.

=head2 super

    my Lingua::Generic::Information::Language $super = $language->super;

(since v0.01)

Returns the super language (in terms of language tags) if any.

Accepts the following universal options: C<as>, C<default>, C<no_defaults>.

=head2 query

    my $value = $language->query($property, %opts);

(since v0.01)

Returns the value for the property C<$property>.
The type of the returned value depends on the property and the passed parameters.
See L</PROPERTIES> for details on which properties are available.

Accepts the following universal options: C<as>, C<default>, C<no_defaults>.

In addition the option C<filter> is accepted, which allows to select the value based on the context.
The filter is an hashref containing of key value pairs.
The key can be any aspect that is related to the given option such as a dimension.
The possible values depend on the key.

If the value is not known, or no match with the given filter is found, the options C<default>, and C<no_defaults>
control the return value and whether or not the method will die (which is the default).

=head1 PROPERTIES

=head2 Dimensions

The dimensions of a language refer to attributes words may carry.
Common examples include the C<numerus> (singular, plural, ...), or the C<class> (noun, verb, adjective, ...).

As this highly depends on the language, and this module may not know about any detail of all languages lists containing dimensions
are generally considered incomplete. The module tries to provide the most safe values.

All dimensions are valid as keys in filters, even if those dimensions are not part of the language.

=head2 Types

Most properties can return strings, booleans, or identifier-based values.
The exact type to be returned can be enforced using the C<as>-parameter.

Below identifier-based means all types L<Data::Identifier/as> can convert from or to.

=head2 properties

=head3 dimensions_excluded

(since v0.01)

This property will return a list of dimensions that are safe to ignore in matching specific words.
The list may not be complete.
The values generally depend on values from other dimensions, so those should be added to the filter.

Supported types: string, identifier-based.

=head3 sentence_first_word_case

(since v0.01)

The case of the first word in a sentence.

Possible values: C<'ucfirst'>, C<'lcfirst'>, C<'uc'>, C<'lc'>.
C<undef> can be returned in case no simple transformation is possible.

Supported types: enum.

=head3 sentence_preamble

(since v0.01)

The sentence preamble is a string that starts a sentence, such as a E<0x00A1>.
It is part of the sentence it belongs to.

Supported types: string.

=head3 sentence_separator

(since v0.01)

The sentence separator is a string that is used between two sentences, often a single space, to keep them apart.
The separator is not part of any of the sentences.

Supported types: string.

=head3 sentence_terminator

(since v0.01)

The sentence terminator is a string that ends a sentence, such as a full stop (C<.>).
It is part of the sentence it belongs to.

Supported types: string.

=head3 term_scan_ahead

(since v0.01)

The number of words to look ahead to find a term (e.g. a proper name or compound).

=head3 word_separator

(since v0.01)

The word separator is a string that is used between two words within the same sentence, often a single space, to keep them apart.
The separator is not part of any of the words.

Supported types: string.

=head1 KNOWN CLASSES

The following classes are defined for the use with L<Data::Identifier::Interface::Known/known>.

=head2 :all

This class contains all values module is aware of.

=head2 wellknown

This class contains all languages actually known by this module.

=head2 registered

This class contains all languages for which an object was generated.
This might be different from C<wellknown> in that it may also include dynamically created objects.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
