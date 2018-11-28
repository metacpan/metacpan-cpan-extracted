package MODS::Record;

=head1 NAME

MODS::Record - Perl extension for handling MODS records

=head1 SYNOPSIS

 use MODS::Record qw(xml_string);
 use open qw(:utf8);

 my $mods = MODS::Record->new;

 my $collection = MODS::Collection->new;

 my $mods = $collection->add_mods(ID => '1234');

 $mods->add_abstract("Hello", lang => 'eng');
 $mods->add_abstract("Bonjour", lang => 'fra');

 # Set a deeply nested field...
 $mods->add_language()->add_languageTerm('eng');

 # Set a list of deeply nested fields...
 $mods->add_location(sub {
    $_[0]->add_physicalLocation('here');
    $_[0]->add_shelfLocator('here too');
    $_[0]->add_url('http://here.org/there');
 });

 # Set an inline XML extension...
 $mods->add_accessCondition(xml_string("<x:foo><x:bar>21212</x:bar></x:foo>"));

 # Retrieve a field by a filter...
 $mods->get_abstract(lang => 'fra')->body("Bonjour :)");
 $mods->get_abstract(lang => 'fra')->contentType('text/plain');

 for ($mods->get_abstract(lang => 'fra')) {
    printf "%s\n" , $_->body;
 }

 # Set a field to a new value
 my @newabstract;
 for ($mods->get_abstract) {
    push @newabstract, $_ unless $_->lang eq 'fra';
 }
 $mods->set_abstract(@newabstract);

 # Clear all abstracts;
 $mods->set_abstract(undef);

 # Serialize
 print $mods->as_json(pretty => 1);
 print $mods->as_xml;

 # Deserialize
 my $mods = MODS::Record->from_xml(IO::File->new('mods.xml'));
 my $mods = MODS::Record->from_json(IO::File->new('mods.js'));

 my $count = MODS::Record->from_xml(IO::File->new('mods.xml'), sub {
    my $mods = shift;
    ...
 });

 my $count = MODS::Record->from_json(IO::File->new('mods.js'), sub {
    my $mods = shift;
    ...
 });

=head1 DESCRIPTION

This module provides MODS (http://www.loc.gov/standards/mods/) parsing and creation for MODS Schema 3.5.

=head1 METHODS

=head2 MODS::Record->new(%attribs)

=head2 MODS::Collection->new(%attribs)

Create a new MODS record or collection. Optionally attributes can be provided as
defined by the MODS specification. E.g.

 $mods = MODS::Record->new(ID='123');

=head2 add_xxx()

Add a new element to the record where 'xxx' is the name of a MODS element (e.g. titleInfo, name, genre, etc).
This method returns an instance of the added MODS element. E.g.

 $titleInfo = $mods->add_titleInfo; # $titleInfo is a 'MODS::Element::TitleInfo'

=head2 add_xxx($text,%attribs)

Add a new element to the record where 'xxx' is the name of a MODS element. Set the text content of the element to $text
and optionally provide further attributes. This method returns an instance of the added MODS element. E.g.

 $mods->add_abstract("My abstract", lang=>'eng');

=head2 add_xxx(sub { })

Add a new element to the record where 'xxx' is the name of a MODS element. The provided coderef gets as input an instance
of the added MODS element. This method returns an instance of the added MODS element. E.g.

 $mods->add_abstract(sub {
    my $o = shift;
    $o->body("My abstract");
    $o->lang("eng");
 })

=head2 add_xxx($obj)

Add a new element to the record where 'xxx' is the name of a MODS element. The $obj is an instance of a MODS::Element::Xxx
class (where Xxx is the corresponding MODS element). This method returns an instance of the added MODS element. E.g.

 $mods->add_abstract(
     MODS::Element::Abstract->new(_body=>'My abstract', lang=>'eng')
 );

=head2 get_xxx()

=head2 get_xxx(%filter)

=head2 get_xxx(sub { })

Retrieve an element from the record where 'xxx' is the name of a MODS element. This methods return in array context all the
matching elements or the first match in scalar context. Optionally provide a %filter or a coderef filter function.
E.g.

 @titles = $mods->get_titleInfo();
 $alt    = $mods->get_titleInfo(type=>'alternate');
 $alt    = $mods->get_titleInfo(sub { shift->type eq 'alternate'});

=head2 set_xxxx()

=head2 set_xxx(undef)

=head2 set_xxx($array_ref)

=head2 set_xxx($xxx1,$xxx2,...)

Set an element of the record to a new value where 'xxx' is the name of a MODS element. When no arguments are provided, then this
is a null operation. When undef als argument is provided, then the element is deleted. To overwrite the existing content of the
element an ARRAY (ref) of MODS::Element::Xxx can be provided (where 'Xxx' is the corresponding MODS element). E.g.

 # Delete all abstracts
 $mods->set_abstract(undef);

 # Set all abstracts
 $mods->set_abstract(MODS::Element::Abstract->new(), MODS::Element::Abstract->new(), ...);
 $mods->set_abstract([ MODS::Element::Abstract->new(), MODS::Element::Abstract->new(), ... ]);

=head2 as_xml()

=head2 as_xml(xml_prolog=>1)

Return the record as XML.

=head2 from_xml($string [, $callback])

=head2 from_xml(IO::Handle [, $callback])

Parse an XML string or IO::Handle into a MODS::Record. This method return the parsed JSON.

If a callback function is provided then for each MODS element in the XML stream the callback will be called.
The method returns the number of parsed MODS elements.

 E.g.
    my $mods = MODS::Record->from_xml( IO::File->new(...) );

    my $count = MODS::Record->from_xml( IO::File->new(...) , sub {
        my $mods = shift;
    } );

=head2 as_json()

=head2 as_json(pretty=>1)

Return the record as JSON string.

=head2 from_json($string [, $callback])

=head2 from_json(IO::Handle [, $callback])

Parse and JSON string or JSON::Handle into a MODS::Record. This method return the parsed JSON.

If a callback function is provided then we expect as input a stream of JSON strings
(each line one JSON string). For each MODS object in the JSON stream the callback will be called.
The method returns the number of parsed strings.

 E.g.
    my $mods = MODS::Record->from_json( IO::File->new(...) );

    my $count = MODS::Record->from_json( IO::File->new(...) , sub {
        my $mods = shift;
    } );

=head1 SEE ALSO

=over 4

=item * Library Of Congress MODS pages (http://www.loc.gov/standards/mods/)

=back

=head1 DESIGN NOTES

=over 4

=item * I'm not a MODS expert

=item * I needed a MODS module to parse and create MODS records for our institutional repository

=item * This module is part of the LibreCat/Catmandu project http://librecat.org

=item * This module is not created for speed

=item * This module doesn't have any notion of ordering of MODS elements themselves (e.g. first 'titleInfo', then 'name').
But each sub-element keeps its original order (e.g. each 'title' in 'titleInfo').

=item * Heiko Jansen provides at GitHub a Moose-based MODS parser https://github.com/heikojansen/MODS--Record

=back

=head1 AUTHOR

Patrick Hochstenbach <Patrick.Hochstenbach at UGent.be>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

use vars qw( $VERSION );
$VERSION = '0.13';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(xml_string);

sub new {
    my ($class,@opts) = @_;

    return MODS::Element::Mods->new(@opts);
}

sub from_xml {
    my ($self,@opts) = @_;
    MODS::Parser->new->parse(@opts);
}

sub from_json {
    my ($self,@opts) = @_;
    MODS::Parser->new->parse_json(@opts);
}

sub xml_string {
    my $string = shift;
    return MODS::Record::Xml_String->new(_body => $string);
}

package MODS::Collection;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(xml_string);

sub new {
    my ($class,@opts) = @_;

    return MODS::Element::ModsCollection->new(@opts);
}

sub from_xml {
    my ($self,@opts) = @_;
    MODS::Parser->new->parse(@opts);
}

sub from_json {
    my ($self,@opts) = @_;
    MODS::Parser->new->parse_json(@opts);
}

sub xml_string {
    my $string = shift;
    return MODS::Record::Xml_String->new(_body => $string);
}


package MODS::Record::Util;

use Moo::Role;
use Carp;
use JSON;

sub AUTOLOAD {
    my ($self,@args) = @_;

    my ($meth) = (our $AUTOLOAD =~ /([^:]+)$/);

    if ($meth =~ /^add_(\w+)/) {
        my ($attrib) = $1;

        die "no such method $attrib" unless $self->can($attrib);

        return $self->_adder($attrib,@args);
    }
    elsif ($meth =~ /^get_(\w+)/) {
        my ($attrib) = $1;

        die "no such method $attrib" unless $self->can($attrib);

        return $self->_getter($attrib,@args);
    }
    elsif ($meth =~ /^set_(\w+)/) {
        my ($attrib) = $1;

        die "no such method $attrib" unless $self->can($attrib);

        return $self->_setter($attrib,@args);
    }
}

sub escape {
    my $str = shift;
    return "" unless defined $str;
    $str =~ s{&}{&amp;}g;
    $str =~ s{"}{&quot;}g;
    $str =~ s{'}{&apos;}g;
    $str =~ s{<}{&lt;}g;
    $str =~ s{>}{&gt;}g;
    $str;
}

sub _getter {
    my ($self, $attrib, $where, %guard);

    if (@_ % 2 == 0) {
        ($self, $attrib, %guard) = @_;
    }
    else {
        ($self, $attrib, $where) = @_;
    }

    my @ret = ();

    for (@{ $self->$attrib }) {
        if (ref $where eq 'CODE') {
            push(@ret,$_) if $where->($_);
        }
        else {
            my $ok = 1;
            for my $k (keys %guard) {
                my $val = $guard{$k};
                $ok = 0 unless (defined $_->$k && $_->$k eq $val);
            }
            push(@ret,$_) if $ok == 1;
        }
    }

    wantarray ? @ret : $ret[0];
}

sub _setter {
    my ($self, $attrib, @objs) = @_;
    my $ret;

    if (@objs == 0) {
        $ret = $self->$attrib;
    }
    elsif (@objs == 1 && ref($objs[0]) eq 'ARRAY') {
        $self->$attrib($objs[0]);
        $ret = $objs[0];
    }
    elsif (@objs == 1 && !defined $objs[0]) {
        $self->$attrib([]);
        $ret = [];
    }
    else {
        $self->$attrib(\@objs);
        $ret = \@objs;
    }

    wantarray ? @$ret : $ret;
}

sub _adder {
    my ($self, $attrib, $obj,%opts);

    if (@_ % 2 == 0) {
         ($self, $attrib,%opts) = @_;
    }
    else {
        ($self, $attrib, $obj,%opts) = @_;
    }

    my $class = $attrib;
    $class =~ s{^(.)}{uc($1)}e;
    $class = "MODS::Element::$class";

    if (ref $obj eq 'CODE') {
        my $sub = $obj;
        $obj = $class->new(%opts);
        my $ref = $self->$attrib;
        push (@$ref,$obj);
        $self->$attrib($ref);
        $sub->($obj);
    }
    elsif (ref $obj eq $class) {
        my $ref = $self->$attrib;
        push (@$ref,$obj);
        $self->$attrib($ref);
    }
    elsif (defined $obj && $class->can('_body')) {
        $obj = $class->new(_body => $obj, %opts);
        my $ref = $self->$attrib;
        push (@$ref,$obj);
        $self->$attrib($ref);
    }
    elsif (! defined $obj) {
        $obj = $class->new(%opts);
        my $ref = $self->$attrib;
        push (@$ref,$obj);
        $self->$attrib($ref);
    }
    else {
        croak "eek: self($self) class($class) obj($obj)";
    }

    if ($obj->does('MODS::Record::Unique')) {
        my $ref = $self->$attrib;
        $self->$attrib([$ref->[-1]]);
    }

    $obj;
}

sub _isa {
    my $type = shift;

    die "Need an array of MODS::Element::*" unless ref $type eq 'ARRAY';

    for (@$type) {
        die "Need a element of MODS::Element::*" unless ref($_) =~ /^MODS::Element::/;
    }
}

sub body {
    my ($self,$val) = @_;

    if ($self->can('_body')) {
        $self->_body($val) if defined $val;
        return $self->_body;
    }
    else {
        return undef;
    }
}

sub as_xml {
    my ($self,%opts) = @_;

    my $output = '';
    my $class = ref $self;
    $class =~ s{^(.*)::(.)(.*)}{lc($2) . $3}e;

    my $encoding = $opts{'encoding'} || 'UTF-8';

    $output .= "<?xml version=\"1.0\" encoding=\"$encoding\"?>\n" if $opts{'xml_prolog'};

    $output .= "<mods:$class";

    if ($class eq 'mods' || $class eq 'modsCollection' ) {
        $output .= ' xmlns:mods="http://www.loc.gov/mods/v3"';
        $output .= ' xmlns:xlink="http://www.w3.org/1999/xlink"';
        $output .= ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"';
        $output .= ' xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd"';
    }

    for my $key (keys %$self) {
        my $val = $self->$key;
        if ($key =~ /^_/) {
            next;
        }
        elsif (ref $val eq '') {
            $output .= " $key=\"" . escape($val) . "\"";
        }
    }

    $output .= ">";

    if ($self->can('_body')) {
        if (ref $self->_body && $self->_body->can('as_xml')) {
            $output .= $self->_body->as_xml;
        }
        else {
            $output .= escape($self->_body);
        }
    }

    for my $key (keys %$self) {
        my $val = $self->$key;

        if ($key =~ /^_/ || ref $val ne 'ARRAY') {
            next;
        }

        for (@{ $self->$key} ) {
            $output .= $_->as_xml;
        }
    }

    $output .= "</mods:$class>";
    $output;
}

sub as_json {
    my ($self, %opts) = @_;
    my $class = ref $self;
    $class =~ s{^(.*)::(.)(.*)}{lc($2) . $3}e;
    to_json({$class => $self}, { utf8 => 1, convert_blessed => 1 , allow_blessed => 1 , pretty => $opts{pretty}});
}

sub TO_JSON {
    my $ret = { %{ shift() } };
    for (keys %$ret) {
        if (ref $ret->{$_} eq 'ARRAY' && @{$ret->{$_}} == 0) {
            delete $ret->{$_};
        }
    }
    $ret;
}

package MODS::Record::Unique;

use Moo::Role;

package MODS::Record::Xml_String;

use Moo;

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has _body => (is => 'ro');

sub as_xml {
    my $self = shift;
    $self->_body;
}

sub TO_JSON { return shift->_body; }

package MODS::Element::Abstract;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has displayLabel    => ( is => 'rw' );
has type            => ( is => 'rw' );
has xlink           => ( is => 'rw' );
has shareable       => ( is => 'rw' );
has altRepGroup     => ( is => 'rw' );
has altFormat       => ( is => 'rw' );
has contentType     => ( is => 'rw' );
has _body            => ( is => 'rw' );

package MODS::Element::AccessCondition;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has xlink        => ( is => 'rw' );

has type         => ( is => 'rw' );
has altRepGroup  => ( is => 'rw' );
has altFormat    => ( is => 'rw' );
has contentType  => ( is => 'rw' );
has _body        => ( is => 'rw' );

package MODS::Element::Affiliation;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has _body            => ( is => 'rw' );

package MODS::Element::Classification;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has edition      => ( is => 'rw' );
has displayLabel => ( is => 'rw' );
has altRepGroup  => ( is => 'rw' );
has usage        => ( is => 'rw' );
has generator    => ( is => 'rw' );
has _body        => ( is => 'rw' );

package MODS::Element::Extension;

use Moo;

with('MODS::Record::Util');

has displayLabel => ( is => 'rw' );
has _body        => ( is => 'rw' );

use overload fallback => 1 , '""' => sub { $_[0]->_body };

package MODS::Element::Genre;

# [Warning]
# The genre-element in MODS is used in different context.
# All solution we provide here the broadest possible interpretation.
use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has displayLabel => ( is => 'rw' );
has altRepGroup  => ( is => 'rw' );
has usage        => ( is => 'rw' );
has _body        => ( is => 'rw' );

package MODS::Element::Identifier;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has displayLabel => ( is => 'rw' );
has type         => ( is => 'rw' );
has typeURI      => ( is => 'rw' );
has invalid      => ( is => 'rw' );
has _body        => ( is => 'rw' );

package MODS::Element::Language;

use Moo;

with('MODS::Record::Util');

has objectPart      => ( is => 'rw' );

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has displayLabel    => ( is => 'rw' );
has altRepGroup     => ( is => 'rw' );
has usage           => ( is => 'rw' );
has languageTerm    => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has scriptTerm      => ( is => 'rw' , isa => \&_isa , default => sub { [] });

package MODS::Element::LanguageTerm;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );
has type            => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::ScriptTerm;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has type            => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::Location;

use Moo;

with('MODS::Record::Util');

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has displayLabel     => ( is => 'rw' );
has altRepGroup      => ( is => 'rw' );
has physicalLocation => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has shelfLocator     => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has url              => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has holdingSimple    => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has holdingExternal  => ( is => 'rw' , isa => \&_isa , default => sub { [] } );

package MODS::Element::PhysicalLocation;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has displayLabel    => ( is => 'rw' );
has type            => ( is => 'rw' );
has xlink           => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::Url;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has dateLastAccessed  => ( is => 'rw' );
has displayLabel      => ( is => 'rw' );
has note              => ( is => 'rw' );
has access            => ( is => 'rw' );
has usage             => ( is => 'rw' );
has _body             => ( is => 'rw' );

package MODS::Element::HoldingSimple;

use Moo;

with('MODS::Record::Util','MODS::Record::Unique');

has copyInformation  => ( is => 'rw' , isa => \&_isa , default => sub { [] } );

package MODS::Element::CopyInformation;

use Moo;

with('MODS::Record::Util');

has form              => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has subLocation       => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has shelfLocator      => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has electronicLocator => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has note              => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has enumerationAndChronology => ( is => 'rw' , isa => \&_isa , default => sub { [] } );

package MODS::Element::Form;

use Moo;

# [Warning]
# The form-element is used in more than one context in MODS. One usage
# required unique, the other usag is repeatable. We use the latter here
# for all 'form'-elements.
with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has type            => ( is => 'rw' );
has ID              => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::SubLocation;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::ShelfLocator;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Note;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has ID              => ( is => 'rw' );
has displayLabel    => ( is => 'rw' );
has type            => ( is => 'rw' );
has typeURI         => ( is => 'rw' );
has altRepGroup        => ( is => 'rw' );
has xlink           => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::EnumerationAndChronology;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has unitType        => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::HoldingExternal;

use Moo;

with('MODS::Record::Util','MODS::Record::Unique');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has displayLabel    => ( is => 'rw' );
has _body           => ( is => 'rw' );


package MODS::Element::Name;

use Moo;

with('MODS::Record::Util');

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has ID              => ( is => 'rw' );
has xlink           => ( is => 'rw' );
has displayLabel    => ( is => 'rw' );
has usage           => ( is => 'rw' );
has altRepGroup     => ( is => 'rw' );
has nameTitleGroup  => ( is => 'rw' );
has type            => ( is => 'rw' );

has namePart        => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has displayForm     => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has affiliation     => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has role            => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has description     => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has etal            => ( is => 'rw' , isa => \&_isa , default => sub { [] } );

package MODS::Element::NamePart;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has type            => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::DisplayForm;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Role;

use Moo;

with('MODS::Record::Util');

has roleTerm        => ( is => 'rw' , default => sub{ [] } );


package MODS::Element::RoleTerm;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has type            => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::Description;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Etal;

use Moo;

with('MODS::Record::Util','MODS::Record::Unique');

package MODS::Element::OriginInfo;

use Moo;

with('MODS::Record::Util');

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has displayLabel    => ( is => 'rw' );
has altRepGroup     => ( is => 'rw' );
has eventType       => ( is => 'rw' );

has place           => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has publisher       => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has dateIssued      => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has dateCreated        => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has dateCaptured    => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has dateValid       => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has dateModified    => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has copyrightDate   => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has dateOther       => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has edition         => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has issuance        => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has frequency       => ( is => 'rw' , isa => \&_isa , default => sub { [] });

package MODS::Element::Place;

use Moo;

with('MODS::Record::Util');

has supplied       => ( is => 'rw' );
has placeTerm      => ( is => 'rw' , isa => \&_isa , default => sub { [] } );

package MODS::Element::PlaceTerm;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has type            => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::Publisher;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has supplied        => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::DateIssued;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has encoding        => ( is => 'rw' );
has point           => ( is => 'rw' );
has keyDate         => ( is => 'rw' );
has qualifier       => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::DateCreated;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has encoding        => ( is => 'rw' );
has point           => ( is => 'rw' );
has keyDate         => ( is => 'rw' );
has qualifier       => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::DateCaptured;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has encoding        => ( is => 'rw' );
has point           => ( is => 'rw' );
has keyDate         => ( is => 'rw' );
has qualifier       => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::DateValid;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has encoding        => ( is => 'rw' );
has point           => ( is => 'rw' );
has keyDate         => ( is => 'rw' );
has qualifier       => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::DateModified;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has encoding        => ( is => 'rw' );
has point           => ( is => 'rw' );
has keyDate         => ( is => 'rw' );
has qualifier       => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::CopyrightDate;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has encoding        => ( is => 'rw' );
has point           => ( is => 'rw' );
has keyDate         => ( is => 'rw' );
has qualifier       => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::DateOther;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has encoding        => ( is => 'rw' );
has point           => ( is => 'rw' );
has keyDate         => ( is => 'rw' );
has qualifier       => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::Edition;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has supplied        => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::Issuance;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has _body            => ( is => 'rw' );

package MODS::Element::Frequency;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Part;

use Moo;

with('MODS::Record::Util');

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has ID              => ( is => 'rw' );
has type            => ( is => 'rw' );
has order           => ( is => 'rw' );
has displayLabel    => ( is => 'rw' );
has altRepGroup     => ( is => 'rw' );

has detail          => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has extent          => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has date            => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has text            => ( is => 'rw' , isa => \&_isa , default => sub { [] } );

package MODS::Element::Detail;

use Moo;

with('MODS::Record::Util');

has type            => ( is => 'rw' );
has level           => ( is => 'rw' );

has number          => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has caption         => ( is => 'rw' , isa => \&_isa , default => sub { [] } );
has title           => ( is => 'rw' , isa => \&_isa , default => sub { [] } );

package MODS::Element::Number;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Caption;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Extent;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

# [Warning]
# The 'extent' element is used in MODS in two different contexts.
# As temporary solution we push all possible attributes in one Extent-package...

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has supplied        => ( is => 'rw' );
has unit            => ( is => 'rw' );

has start           => ( is => 'rw' , default => sub {[]});
has end             => ( is => 'rw' , default => sub {[]});
has total           => ( is => 'rw' , default => sub {[]});
has list            => ( is => 'rw' , default => sub {[]});

has _body           => ( is => 'rw' );

package MODS::Element::Start;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::End;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Total;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has _body            => ( is => 'rw' );

package MODS::Element::List;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Date;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has encoding        => ( is => 'rw' );
has point           => ( is => 'rw' );
has qualifier       => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::Text;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has displayLabel    => ( is => 'rw' );
has xlink           => ( is => 'rw' );
has type            => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::PhysicalDescription;

use Moo;

with('MODS::Record::Util');

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has displayLabel    => ( is => 'rw' );
has altRepGroup     => ( is => 'rw' );
has form            => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has reformattingQuality => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has internetMediaType   => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has extent          => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has digitalOrigin   => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has note            => ( is => 'rw' , isa => \&_isa , default => sub { [] });

package MODS::Element::ReformattingQuality;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has _body            => ( is => 'rw' );

package MODS::Element::InternetMediaType;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::DigitalOrigin;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has _body            => ( is => 'rw' );

package MODS::Element::RecordInfo;

use Moo;

with('MODS::Record::Util');

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has displayLabel    => ( is => 'rw' );
has altRepGroup     => ( is => 'rw' );

has recordContentSource  => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has recordCreationDate   => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has recordChangeDate     => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has recordIdentifier     => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has recordOrigin         => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has languageOfCataloging => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has descriptionStandard  => ( is => 'rw' , isa => \&_isa , default => sub { [] });

package MODS::Element::RecordContentSource;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::RecordCreationDate;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has encoding        => ( is => 'rw' );
has point           => ( is => 'rw' );
has keyDate         => ( is => 'rw' );
has qualifier       => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::RecordChangeDate;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has encoding        => ( is => 'rw' );
has point           => ( is => 'rw' );
has keyDate         => ( is => 'rw' );
has qualifier       => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::RecordIdentifier;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has source          => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::RecordOrigin;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::LanguageOfCataloging;

use Moo;

with('MODS::Record::Util');

has objectPart      => ( is => 'rw' );
has altRepGroup     => ( is => 'rw' );
has usage           => ( is => 'rw' );
has displayLabel    => ( is => 'rw' );
has languageTerm    => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has scriptTerm      => ( is => 'rw' , isa => \&_isa , default => sub { [] });

package MODS::Element::DescriptionStandard;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::RelatedItem;

use Moo;

with('MODS::Record::Util');

has ID              => ( is => 'rw' );
has xlink           => ( is => 'rw' );
has displayLabel    => ( is => 'rw' );
has type            => ( is => 'rw' );

has titleInfo       => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has name            => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has typeOfResource  => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has genre           => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has originInfo      => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has language        => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has physicalDescription  => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has abstract        => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has tableOfContents => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has targetAudience  => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has note            => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has subject         => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has classification  => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has relatedItem     => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has identifier      => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has location        => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has accessCondition => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has part            => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has extension       => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has recordInfo      => ( is => 'rw' , isa => \&_isa , default => sub { [] });

package MODS::Element::Subject;

use Moo;

with('MODS::Record::Util');

has ID              => ( is => 'rw' );
has xlink           => ( is => 'rw' );
has displayLabel    => ( is => 'rw' );
has usage           => ( is => 'rw' );
has altRepGroup     => ( is => 'rw' );

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has topic           => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has geographic      => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has temporal        => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has titleInfo       => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has name            => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has geographicCode  => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has genre           => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has hierarchicalGeographic => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has cartographics   => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has occupation      => ( is => 'rw' , isa => \&_isa , default => sub { [] });

package MODS::Element::Topic;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Geographic;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Temporal;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has encoding        => ( is => 'rw' );
has point           => ( is => 'rw' );
has keyDate         => ( is => 'rw' );
has qualifier       => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::GeographicCode;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::HierarchicalGeographic;

use Moo;

with('MODS::Record::Util');

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has continent       => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has country         => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has province        => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has region          => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has state           => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has territory       => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has county          => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has city            => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has island          => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has area            => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has extraterrestrialArea => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has citySection     => ( is => 'rw' , isa => \&_isa , default => sub { [] });

package MODS::Element::Continent;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Country;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Province;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Region;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::State;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Territory;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::County;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::City;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Island;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Area;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::ExtraterrestrialArea;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::CitySection;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Occupation;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Cartographics;

use Moo;

with('MODS::Record::Util');

has scale           => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has projection      => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has coordinates     => ( is => 'rw' , isa => \&_isa , default => sub { [] });

package MODS::Element::Scale;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Projection;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Coordinates;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::TableOfContents;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has xlink           => ( is => 'rw' );
has displayLabel    => ( is => 'rw' );
has type            => ( is => 'rw' );
has shareable       => ( is => 'rw' );
has altRepGroup     => ( is => 'rw' );
has altFormat       => ( is => 'rw' );
has contentType     => ( is => 'rw' );
has _body           => ( is => 'rw' );

package MODS::Element::TargetAudience;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has displayLabel    => ( is => 'rw' );
has altRepGroup     => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::TitleInfo;

use Moo;

with('MODS::Record::Util');

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has authorityURI    => ( is => 'rw' );
has valueURI        => ( is => 'rw' );
has authority       => ( is => 'rw' );

has ID              => ( is => 'rw' );
has type            => ( is => 'rw' );
has otherType       => ( is => 'rw' );
has displayLabel    => ( is => 'rw' );
has supplied        => ( is => 'rw' );
has usage           => ( is => 'rw' );
has altRepGroup     => ( is => 'rw' );
has nameTitleGroup  => ( is => 'rw' );
has altFormat       => ( is => 'rw' );
has contentType     => ( is => 'rw' );

has title           => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has subTitle        => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has partNumber      => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has partName        => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has nonSort         => ( is => 'rw' , isa => \&_isa , default => sub { [] });

package MODS::Element::Title;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::SubTitle;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::PartNumber;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::PartName;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::NonSort;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has lang            => ( is => 'rw' );
has xml_lang        => ( is => 'rw' );
has script          => ( is => 'rw' );
has transliteration => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::TypeOfResource;

use Moo;

with('MODS::Record::Util');

use overload fallback => 1 , '""' => sub { $_[0]->_body };

has collection      => ( is => 'rw' );
has manuscript      => ( is => 'rw' );
has displayLabel    => ( is => 'rw' );
has usage           => ( is => 'rw' );
has altRepGroup     => ( is => 'rw' );

has _body           => ( is => 'rw' );

package MODS::Element::Mods;

use Moo;

with('MODS::Record::Util');

has version         => ( is => 'rw' , default => sub { "3.5"} );
has ID              => ( is => 'rw');
has abstract        => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has accessCondition => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has classification  => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has extension       => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has genre           => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has identifier      => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has language        => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has location        => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has name            => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has note            => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has originInfo      => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has part            => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has physicalDescription => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has recordInfo      => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has relatedItem     => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has subject         => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has tableOfContents => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has targetAudience  => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has titleInfo       => ( is => 'rw' , isa => \&_isa , default => sub { [] });
has typeOfResource  => ( is => 'rw' , isa => \&_isa , default => sub { [] });

package MODS::Element::ModsCollection;

use Moo;

with('MODS::Record::Util');

has mods            => ( is => 'rw' , isa => \&_isa , default => sub { [] });

package MODS::Parser;

use Moo;
use XML::Parser;
use JSON;

with('MODS::Record::Util');

our @stack = ();
our $body;
our $level = 0;
our $flag  = 0;
our $count = 0;

sub parse {
    my ($self,$source,$callback) = @_;

    @stack = ();
    $body  = undef;
    $level = 0;
    $flag  = 0;
    $count = 0;

    my $parser = XML::Parser->new(Handlers => {
                                    Start => \&start ,
                                    Char  => \&char,
                                    End   => \&end ,
                                  } , 'Non-Expat-Options' => { callback => $callback });

    $parser->parse($source);

    if (defined $callback) {
        $count;
    }
    else {
        $stack[0];
    }
}

sub parse_json {
    my ($self, $source, $callback) = @_;

    if (ref($source) =~ /^IO::/) {
        if (defined $callback) {
            my $count = 0;
            while(<$source>) {
                $callback->(_parse_json($_));
                $count++;
            }
            $count;
        }
        else {
            local $/;
            my $json_txt = <$source>;
            _parse_json($json_txt);
        }
    }
    elsif (defined $callback) {
        my $count = 0;
        for (split(/\n/,$source)) {
            $callback->(_parse_json($_));
            $count++;
        }
        $count;
    }
    else {
        _parse_json($source);
    }
}

sub _parse_json {
    my $json_txt = shift;
    my $perl = JSON->new->utf8(1)->decode($json_txt);

    _bless_object($perl);

    [ %{ $perl } ]->[1];
}

sub _bless_object {
    my $obj = shift;

    return unless ref($obj) =~ /^HASH|MODS::Element/;

    for (keys %$obj) {
        my $val = $obj->{$_};
        my $class = $_;
        $class =~ s{^(.)}{uc($1)}e;
        $class = "MODS::Element::$class";

        if (ref($val) eq 'ARRAY') {
            for (@{$val}) {
                _bless_object(bless($_,$class));
            }
        }
        elsif (ref($val) eq 'HASH') {
            _bless_object(bless($val,$class));
        }
    }
}

sub start {
    my ($expat,$element,%attrs) = @_;
    my $local_name = $element; $local_name =~ s/^\w+://;
    my $e;

    if ($level) {
        $level++;
    }
    elsif (@stack == 0) {
        my $module = $local_name;
        $module =~ s{^(.)}{uc($1)}e;
        $module = "MODS::Element::$module";
        $e = $module->new(%attrs);
        $body = undef;
        push(@stack,$e);
    }
    else {
        my $method = "add_$local_name";
        my $module = $local_name;
        $module =~ s{^(.)}{uc($1)}e;
        $module = "MODS::Element::$module";

        # Start recording literal XML if we find an element we cant recognize...
        if ($stack[-1]->can($local_name)) {
            $e = $stack[-1]->$method($module->new(%attrs));
            $body = undef;

            push(@stack,$e);
        }
        else {
            die "$element not allowed in " . ref($stack[-1]) unless ref($stack[-1]) =~ /^MODS::Element::(AccessCondition|Extension)$/;
            $level++;
        }
    }

    if ($level) {
        $body .= "<$element";
        for (keys %attrs) {
            $body .= " $_=\"" . escape($attrs{$_}) . "\"";
        }
        $body .= ">";
    }
}

sub char {
    my ($expat,$string) = @_;

    $body .= $string;
}

sub end {
    my ($expat,$element,%attrs) = @_;
    my $local_name = $element; $local_name =~ s/^\w+://;
    my $callback = $expat->{'Non-Expat-Options'}->{'callback'};

    if ($level) {
        $body .= "</$element>";
        $level--;
        $flag = 1;
    }
    else {
        $body = MODS::Record::Xml_String->new(_body => $body) if $flag;

        $flag = 0;

        $stack[-1]->_body($body) if $stack[-1]->can('_body');

        $body = undef;

        if ($local_name eq 'mods' && defined $callback) {
            $count++;
            $callback->(pop(@stack));
        }
        else {
            pop(@stack) unless @stack == 1;
        }
    }
}

sub debug {
    my $msg = shift;
    print STDERR "$msg\n";
    print STDERR "level: $level\n";
    print STDERR "flag: $flag\n";
    for (@stack) {
        printf STDERR "%s\n" , ref $_;
    }
    print STDERR "---\n";
}

1;
