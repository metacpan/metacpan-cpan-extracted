## no critic: Modules::ProhibitAutomaticExportation

package Hash::DefHash;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-21'; # DATE
our $DIST = 'Hash-DefHash'; # DIST
our $VERSION = '0.072'; # VERSION

use 5.010001;
use strict;
use warnings;

use Regexp::Pattern::DefHash;
use Scalar::Util qw(blessed);
use String::Trim::More qw(trim_blank_lines);

use Exporter qw(import);
our @EXPORT = qw(defhash);

our $re_prop = $Regexp::Pattern::DefHash::RE{prop}{pat};
our $re_attr = $Regexp::Pattern::DefHash::RE{attr}{pat};
our $re_attr_part = $Regexp::Pattern::DefHash::RE{attr_part}{pat};
our $re_key  = $Regexp::Pattern::DefHash::RE{key} {pat};

sub defhash {
    # avoid wrapping twice if already a defhash
    return $_[0] if blessed($_[0]) && $_[0]->isa(__PACKAGE__);

    __PACKAGE__->new(@_);
}

sub new {
    my $class = shift;

    my ($hash, %opts) = @_;
    $hash //= {};

    my $self = bless {hash=>$hash, parent=>$opts{parent}}, $class;
    if ($opts{check} // 1) {
        $self->check;
    }
    $self;
}

sub hash {
    my $self = shift;

    $self->{hash};
}

sub check {
    my $self = shift;
    my $h = $self->{hash};

    for my $k (keys %$h) {
        next if $k =~ $re_key;
        die "Invalid hash key '$k'";
    }
    1;
}

sub contents {
    my $self = shift;
    my $h = $self->{hash};

    my %props;
    for my $k (keys %$h) {
        my ($p_prop, $p_prop_of_attr, $p_attr) = $k =~ $re_key
            or die "Invalid hash key '$k'";
        my $v = $h->{$k};
        if (defined $p_prop) {
            next if $p_prop =~ /\A_/;
            $props{$p_prop} //= {};
            $props{$p_prop}{''} = $v;
        } else {
            next if $p_attr =~ /(?:\A|\.)_/;
            $props{$p_prop_of_attr // ""}{$p_attr} = $v;
        }
    }
    %props;
}

sub props {
    my $self = shift;
    my $h = $self->{hash};

    my %props;
    for my $k (keys %$h) {
        my ($p_prop, $p_prop_of_attr, $p_attr) = $k =~ $re_key
            or die "Invalid hash key '$k'";
        next unless defined $p_prop;
        next if $p_prop =~ /\A_/;
        $props{$p_prop}++;
    }
    sort keys %props;
}

sub prop {
    my ($self, $prop, $opts) = @_;
    $opts //= {};

    my $opt_die = $opts->{die} // 1;
    my $opt_mark_different_lang = $opts->{mark_different_lang} // 0;
    my $h = $self->{hash};

    if ($opts->{alt}) {
        my %alt = %{ $opts->{alt} };
        my $default_lang = $self->default_lang;
        $alt{lang} //= $default_lang;
        my $has_v_different_lang;
        my $v_different_lang;
        my $different_lang;
      KEY:
        for my $k (keys %$h) {
            my ($p_prop, $p_prop_of_attr, $p_attr) = $k =~ $re_key
                or die "Invalid hash key '$k'";
            my %prop_alt;
            if (defined $p_prop) {
                next unless $p_prop eq $prop;
                %prop_alt = (lang=>$default_lang);
            } else {
                next unless $p_prop_of_attr eq $prop;
                next unless $p_attr =~ /\Aalt\./;
                my @attr_elems = split /\./, $p_attr;
                shift @attr_elems; # the "alt"
                while (my ($k2, $v2) = splice @attr_elems, 0, 2) {
                    $prop_alt{$k2} = $v2;
                }
                $prop_alt{lang} //= $default_lang;
            }

            if ($opt_mark_different_lang) {
                for my $an (keys %alt) {
                    next if $an eq 'lang';
                    next KEY unless defined $prop_alt{$an};
                    next KEY unless $prop_alt{$an} eq $alt{$an};
                }
                if ($alt{lang} eq $prop_alt{lang}) {
                    return $h->{$k};
                } elsif (!$has_v_different_lang) {
                    $has_v_different_lang = 1;
                    $v_different_lang = $h->{$k};
                    $different_lang = $prop_alt{lang};
                }
            } else {
                for my $an (keys %alt) {
                    next KEY unless defined $prop_alt{$an};
                    next KEY unless $prop_alt{$an} eq $alt{$an};
                }
                return $h->{$k};
            }
        }

        if ($opt_mark_different_lang && $has_v_different_lang) {
            return "{$different_lang $v_different_lang}";
        } else {
            die "Property '$prop' (with requested alt ".join(".", %alt).") not found" if $opt_die;
            return undef;
        }
    } else {
        die "Property '$prop' not found" if !(exists $h->{$prop}) && $opt_die;
        return $h->{$prop};
    }
}

sub get_prop {
    my ($self, $prop, $opts) = @_;
    $opts = !defined($opts) ? {} : {%$opts};

    $opts->{die} = 0;
    $self->prop($prop, $opts);
}

sub prop_exists {
    my ($self, $prop) = @_;
    my $h = $self->{hash};

    exists $h->{$prop};
}

sub add_prop {
    my ($self, $prop, $val) = @_;
    my $h = $self->{hash};

    die "Invalid property name '$prop'" unless $prop =~ $re_prop;
    die "Property '$prop' already exists" if exists $h->{$prop};
    $h->{$prop} = $val;
}

sub set_prop {
    my ($self, $prop, $val) = @_;
    my $h = $self->{hash};

    die "Invalid property name '$prop'" unless $prop =~ $re_prop;
    if (exists $h->{$prop}) {
        my $old = $h->{$prop};
        $h->{$prop} = $val;
        return $old;
    } else {
        $h->{$prop} = $val;
        return undef;
    }
}

sub del_prop {
    my ($self, $prop, $val) = @_;
    my $h = $self->{hash};

    die "Invalid property name '$prop'" unless $prop =~ $re_prop;
    if (exists $h->{$prop}) {
        return delete $h->{$prop};
    } else {
        return undef;
    }
}

sub del_all_props {
    my ($self, $delattrs) = @_;
    my $h = $self->{hash};

    for my $k (keys %$h) {
        my ($p_prop, $p_prop_of_attr, $p_attr) = $k =~ $re_key
            or die "Invalid hash key '$k'";
        next if defined $p_prop && $p_prop =~ /\A_/;
        next if defined $p_attr && $p_attr =~ /(?:\A|\.)_/;
        if (defined $p_attr) {
            delete $h->{$k} if $delattrs;
        } else {
            delete $h->{$k};
        }
    }
}

sub attrs {
    my ($self, $prop) = @_;
    $prop //= "";
    my $h = $self->{hash};

    unless ($prop eq '') {
        die "Invalid property name '$prop'" unless $prop =~ $re_prop;
    }

    my %attrs;
    for my $k (keys %$h) {
        my ($p_prop, $p_prop_of_attr, $p_attr) = $k =~ $re_key
            or die "Invalid hash key '$k'";
        next if defined $p_prop;
        my $v = $h->{$k};
        $p_prop_of_attr //= "";
        next unless $p_prop_of_attr eq $prop;
        next if $p_attr =~ /(?:\A|\.)_/;
        $attrs{$p_attr} = $v;
    }
    %attrs;
}

sub attr {
    my ($self, $prop, $attr) = @_;
    $prop //= "";
    my $h = $self->{hash};

    my $k = "$prop.$attr";
    die "Attribute '$attr' for property '$prop' not found" if !exists($h->{$k});
    $h->{$k};
}

sub get_attr {
    my ($self, $prop, $attr) = @_;
    $prop //= "";
    my $h = $self->{hash};

    my $k = "$prop.$attr";
    $h->{$k};
}

sub attr_exists {
    my ($self, $prop, $attr) = @_;
    $prop //= "";
    my $h = $self->{hash};

    my $k = "$prop.$attr";
    exists $h->{$k};
}

sub add_attr {
    my ($self, $prop, $attr, $val) = @_;
    $prop //= "";
    my $h = $self->{hash};

    if ($prop ne '') {
        die "Invalid property name '$prop'"  unless $prop =~ $re_prop;
    }
    die "Invalid attribute name '$attr'" unless $attr =~ $re_attr_part;
    my $k = "$prop.$attr";
    die "Attribute '$attr' for property '$prop' already exists"
        if exists($h->{$k});
    $h->{$k} = $val;
}

sub set_attr {
    my ($self, $prop, $attr, $val) = @_;
    $prop //= "";
    my $h = $self->{hash};

    if ($prop ne '') {
        die "Invalid property name '$prop'"  unless $prop =~ $re_prop;
    }
    die "Invalid attribute name '$attr'" unless $attr =~ $re_attr_part;
    my $k = "$prop.$attr";
    if (exists($h->{$k})) {
        my $old = $h->{$k};
        $h->{$k} = $val;
        return $old;
    } else {
        $h->{$k} = $val;
        return undef;
    }
}

sub del_attr {
    my ($self, $prop, $attr) = @_;
    $prop //= "";
    my $h = $self->{hash};

    if ($prop ne '') {
        die "Invalid property name '$prop'"  unless $prop =~ $re_prop;
    }
    die "Invalid attribute name '$attr'" unless $attr =~ $re_attr_part;
    my $k = "$prop.$attr";
    if (exists($h->{$k})) {
        return delete $h->{$k};
    } else {
        return undef;
    }
}

sub del_all_attrs {
    my ($self, $prop) = @_;
    $prop //= "";
    my $h = $self->{hash};

    for my $k (keys %$h) {
        my ($p_prop, $p_prop_of_attr, $p_attr) = $k =~ $re_key
            or die "Invalid hash key '$k'";
        next if defined $p_prop;
        $p_prop_of_attr //= "";
        next if $p_attr =~ /(?:\A|\.)_/;
        next unless $p_prop_of_attr eq $prop;
        delete $h->{$k};
    }
}

sub defhash_v {
    my ($self) = @_;
    $self->get_prop('defhash_v') // 1;
}

sub v {
    my ($self) = @_;
    $self->get_prop('v') // 1;
}

sub default_lang {
    my ($self) = @_;
    my $par;
    if ($self->{parent}) {
        $par = $self->{parent}->default_lang;
    }
    my $res = $self->get_prop('default_lang') // $par // $ENV{LANG} // "en_US";
    $res = "en_US" if $res eq "C";
    $res;
}

sub name {
    my ($self) = @_;
    $self->get_prop('name');
}

sub summary {
    my ($self) = @_;
    $self->get_prop('summary');
}

sub description {
    my ($self) = @_;
    $self->get_prop('description');
}

sub tags {
    my ($self) = @_;
    $self->get_prop('tags');
}

sub get_prop_lang {
    my ($self, $prop, $lang, $opts) = @_;
    my $h = $self->{hash};
    $opts = !defined($opts) ? {} : {%$opts};

    $opts->{die} //= 0;
    $opts->{alt} //= {};
    $opts->{alt}{lang} //= $lang;
    $opts->{mark_different_lang} //= 1;
    $self->prop($prop, $opts);
}

sub get_prop_all_langs {
    die "Not yet implemented";
}

sub set_prop_lang {
    die "Not yet implemented";
}

1;
# ABSTRACT: Manipulate defhash

__END__

=pod

=encoding UTF-8

=head1 NAME

Hash::DefHash - Manipulate defhash

=head1 VERSION

This document describes version 0.072 of Hash::DefHash (from Perl distribution Hash-DefHash), released on 2021-07-21.

=head1 SYNOPSIS

 use Hash::DefHash; # imports defhash()

 # create a new defhash object, die when hash is invalid defhash
 $dh = Hash::DefHash->new;                        # creates an empty defhash
 $dh = Hash::DefHash->new({a=>1});                # use the hashref
 $dh = Hash::DefHash->new({"contains space"=>1}); # dies!

 # defhash() is a synonym for Hash::DefHash->new().
 $dh = defhash({foo=>1});

 # return the original hash
 $hash = $dh->hash;

 # list properties
 @props = $dh->props;

 # list property names, values, and attributes, will return ($prop => $attrs,
 # ...). Property values will be put in $attrs with key "". For example:
 %content = DefHash::Hash->new({p1=>1, "p1.a"=>2, p2=>3})->contents;
 # => (p1 => {""=>1, a=>2}, p2=>3)

 # get property value, will die if property does not exist
 $propval = $dh->prop($prop);

 # like prop(), but will return undef if property does not exist
 $propval = $dh->get_prop($prop);

 # check whether property exists
 say "exists" if $dh->prop_exists($prop);

 # add a new property, will die if property already exists
 $dh->add_prop($prop, $propval);

 # add new property, or set value for existing property
 $oldpropval = $dh->set_prop($prop, $propval);

 # delete property, noop if property already does not exist. set $delattrs to
 # true to delete all property's attributes.
 $oldpropval = $dh->del_prop($prop, $delattrs);

 # delete all properties, set $delattrs to true to delete all properties's
 # attributes too.
 $dh->del_all_props($delattrs);

 # get property's attributes. to list defhash attributes, set $prop to undef or
 # ""
 %attrs = $dh->attrs($prop);

 # get attribute value, will die if attribute does not exist
 $attrval = $dh->attr($prop, $attr);

 # like attr(), but will return undef if attribute does not exist
 $attrval = $dh->get_attr($prop, $attr);

 # check whether an attribute exists
 @attrs = $dh->attr_exists($prop, $attr);

 # add attribute to a property, will die if attribute already exists
 $dh->add_attr($prop, $attr, $attrval);

 # add attribute to a property, or set value of existing attribute
 $oldatrrval = $dh->set_attr($prop, $attr, $attrval);

 # delete property's attribute, noop if attribute already does not exist
 $oldattrval = $dh->del_attr($prop, $attr, $attrval);

 # delete all attributes of a property
 $dh->del_all_attrs($prop);

 # get predefined properties
 say $dh->v;            # shortcut for $dh->get_prop('v')
 say $dh->default_lang; # shortcut for $dh->get_prop('default_lang')
 say $dh->name;         # shortcut for $dh->get_prop('name')
 say $dh->summary;      # shortcut for $dh->get_prop('summary')
 say $dh->description;  # shortcut for $dh->get_prop('description')
 say $dh->tags;         # shortcut for $dh->get_prop('tags')

 # get value in alternate languages
 $propval = $dh->get_prop_lang($prop, $lang);

 # get value in all available languages, result is a hash mapping lang => val
 %vals = $dh->get_prop_all_langs($prop);

 # set value for alternative language
 $oldpropval = $dh->set_prop_lang($prop, $lang, $propval);

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <sharyanto@cpan.org>

=head1 FUNCTIONS

=head2 defhash([ $hash ]) => OBJ

Shortcut for C<< Hash::DefHash->new($hash) >>. As a bonus, can also detect if
C<$hash> is already a defhash and returns it immediately instead of wrapping it
again. Exported by default.

=head1 METHODS

=head2 new

Usage:

 $dh = Hash::DefHash->new([ $hash ],[ %opts ]);

Constructor. Create a new Hash::DefHash object, which is a thin OO skin over the
regular Perl hash. If C<$hash> is not specified, a new anonymous hash is
created.

Internally, the object contains a hash reference which contains reference to the
hash (C<< bless({hash=>$orig_hash, ...}, 'Hash::DefHash') >>). It does not
create a copy of the hash or bless the hash directly. Be careful not to assume
that the two are the same!

Will check the keys of hash for invalid properties/attributes and will die if
one is found, e.g..

 $dh = Hash::DefHash->new({"contains space" => 1}); # dies!

Known options:

=over 4

=item * check => BOOL (default: 1)

Whether to check that hash is a valid defhash. Will die if hash turns out to
contain invalid keys/values.

=item * parent => HASH/DEFHASH_OBJ

Set defhash's parent. Default language (C<default_lang>) will follow parent's if
unset in the current hash.

=back

=head2 hash

Usage:

 $hashref = $dh->hash;

Return the original hashref.

=head2 check

Usage:

 $dh->check;

=head2 contents

Usage:

 my %contents = $dh->contents;

=head2 default_lang

Usage:

 $default_lang = $dh->default_lang;

=head2 props

Usage:

 @props = $dh->props;

Return list of properties. Will ignore properties that begin with underscore,
e.g.:

 $dh = defhash({a=>1, _b=>2});
 $dh->props;

=head2 prop

Usage:

 $val = $dh->prop($prop [ , \%opts ]);

Get property value, will die if property does not exist.

Known options:

=over

=item * die

Bool. Default true. Whether to die when requested property is not found.

=item * alt

Hashref.

=item * mark_different_lang

Bool. Default false. If set to true, then when a requested property is found but
differs (only) in the language it will be returned but with a mark. For example,
with this defhash:

 {name=>"Chair", "name.alt.lang.id_ID"=>"Kursi"}

then:

 $dh->prop("name", {lang=>"fr_FR"});

will die. But:

 $dh->prop("name", {lang=>"fr_FR", mark_different_lang=>1});

will return:

 "{en_US Chair}"

or:

 "{id_ID Kursi}"

=back

=head2 get_prop

Usage:

 my $val = $dh->get_prop($prop [ , \%opts ]);

Like L</prop>(), but will return undef if property does not exist.

=head2 prop_exists

Usage:

 $exists = $dh->prop_exists;

=head2 add_prop

=head2 set_prop

=head2 del_prop

=head2 del_all_props

=head2 attrs

=head2 attr

=head2 get_attr

=head2 attr_exists

=head2 add_attr

=head2 set_attr

=head2 del_attr

=head2 del_all_attrs

=head2 defhash_v

=head2 v

=head2 name

=head2 summary

=head2 description

=head2 tags

=head2 get_prop_lang

Usage:

 my $val = $dh->get_prop_lang($prop, $lang [ , \%opts ]);

This is just a special case for:

 $dh->prop($prop, {alt=>{lang=>$lang}, mark_different_lang=>1, %opts});

=head2 get_prop_all_langs

=head2 set_prop_lang

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Hash-DefHash>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Hash-DefHash>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Hash-DefHash>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DefHash> specification

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2018, 2016, 2015, 2014, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
