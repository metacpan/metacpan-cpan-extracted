package MIME::Detect;
use Moo;
use if $] < 5.020, 'Filter::signatures';
use feature 'signatures';
no warnings 'experimental::signatures';
use Carp qw(croak);
use XML::LibXML;
use MIME::Detect::Type;

use vars '$VERSION';
$VERSION = '0.09';

=head1 NAME

MIME::Detect - MIME file type identification

=head1 SYNOPSIS

  my $mime = MIME::Detect->new();

  for my $file (@ARGV) {
    print sprintf "%s: %s\n", $file, $_->mime_type
        for $mime->mime_types($file);
  };

=head1 METHODS

=head2 C<< MIME::Detect->new( ... ) >>

  my $mime = MIME::Detect->new();

Creates a new instance and reads the database distributed with this module.

  my $mime = MIME::Detect->new(
      files => [
          '/usr/share/freedesktop.org/mimeinfo.xml',
          't/mimeinfo.xml',
      ],
  );

=cut

sub BUILD( $self, $args ) {
    my %db_args = map { exists( $args->{$_} )? ($_ => $args->{$_}) : () } (qw(xml files));
    $self->read_database( %db_args );
}

has 'typeclass' => (
    is => 'ro',
    default => 'MIME::Detect::Type',
);

has 'types' => (
    is => 'rw',
    default => sub { [] },
);

# References into @types
has 'known_types' => (
    is => 'rw',
    default => sub { {} },
);

# The XPath context we use
has 'xpc' => (
    is => 'lazy',
    default => sub {
        my $XPC = XML::LibXML::XPathContext->new;
        $XPC->registerNs('x', 'http://www.freedesktop.org/standards/shared-mime-info');
        $XPC
    },
);

=head2 C<< $mime->read_database %options >>

  $mime->read_database(
      xml => MIME::Detect::FreeDesktopOrgDB->get_xml,
      files => [
          'mymime/mymime.xml',
          '/usr/share/freedesktop.org/mime.xml',
      ],
  );

If you want rules in addition to the default
database included with the distribution, you can load the rules from another file.
Passing in multiple filenames will join the multiple
databases. Duplicate file type definitions will not be detected
and will be returned as duplicates.

The rules will be sorted according to the priority specified in the database
file(s).

By default, the XML database stored alongside
L<MIME::Detect::FreeDesktopOrgDB>
will be loaded after all custom files have been loaded.
To pass in a different fallback database, either pass in a reference
to the XML string or the name of a package that has an C<get_xml> subroutine.

To prevent loading the default database, pass undef
for the C<xml> key.

=cut

sub read_database( $self, %options ) {
    $options{ files } ||= [];
    if( ! exists $options{ xml }) {
        $options{ xml } = 'MIME::Detect::FreeDesktopOrgDB';
    };
    
    if( $options{ xml } and not ref $options{ xml }) {
        # Load the class name
        if( !eval "require $options{ xml }; 1") {
            croak $@;
        };
        $options{ xml } = $options{ xml }->get_xml;
    };
    
    my @types = map {
        my @args = ref $_ eq 'SCALAR' ? (string   => $_) :
                   ref $_             ? (IO       => $_) :
                                        (location => $_);
        my $doc = XML::LibXML->load_xml(
            no_network => 1,
            load_ext_dtd => 0,
            @args
        );
        $self->_parse_types($doc);
    } @{$options{ files }}, $options{ xml };
    $self->reparse(@types);
}

sub _parse_types( $self, $document ) {
    map { $self->fragment_to_type( $_ ) }
    $self->xpc->findnodes('/x:mime-info/x:mime-type',$document);
}

sub reparse($self, @types) {
    @types = sort { ($b->priority || 50 ) <=> ($a->priority || 50 ) }
             @types;
    $self->types(\@types);

    # Build the map from mime_type to object
    my %mime_map;
    for my $t (@types) {
        $mime_map{ $t->mime_type } = $t;
        for my $a (@{$t->aliases}) {
            $mime_map{ $a } ||= $t;
        };
    };
    $self->known_types(\%mime_map);

    # Now, upgrade the strings to objects:
    my $m = $self->known_types;
    for my $t (@types) {
        my $s = $t->superclass;
        if( $s ) {
            if( my $sc = $m->{ $s } ) {
                $t->superclass( $sc );
            } else {
                warn sprintf "No superclass found for '%s' used by '%s'",
                    $s,
                    $t->mime_type;
            };
        };
    };
};

sub fragment_to_type( $self, $frag ) {
    my $mime_type = $frag->getAttribute('type');
    my $comment = $self->xpc->findnodes('./x:comment', $frag);
    my @globs = map { $_->getAttribute('pattern')} $self->xpc->findnodes('./x:glob', $frag);
    (my $superclass) = $self->xpc->findnodes('./x:sub-class-of',$frag);
    $superclass = $superclass->getAttribute('type')
        if $superclass;

    my @aliases = map { $_->getAttribute('type') } $self->xpc->findnodes('./x:alias',$frag);

    (my $magic) = $self->xpc->findnodes('./x:magic', $frag);
    my( $priority, @rules );
    if( $magic ) {
        $priority = $magic->getAttribute('priority');
        $priority = 50 if !defined $priority;
        @rules = grep { $_->nodeType != 3 } # exclude text nodes
                    $magic->childNodes;
        for my $rule (@rules) {
            $rule = $self->parse_rule( $rule );
        };
    };

    $self->typeclass->new(
        aliases => \@aliases,
        priority => $priority,
        mime_type => $mime_type,
        comment => $comment,
        superclass => $superclass,
        rules => \@rules,
        globs => \@globs,
    );
}

sub parse_rule( $self, $rule ) {
    my $value = $rule->getAttribute('value');
    my $offset = $rule->getAttribute('offset');
    my $type = $rule->getAttribute('type');

    my @and = map { $self->parse_rule( $_ ) } grep { $_->nodeType != 3 } $rule->childNodes;
    my $and = @and ? \@and : undef;

    return {
        value => $value,
        offset => $offset,
        type => $type,
        and => $and,
    };
}

=head2 C<< $mime->mime_types >>

    my @types = $mime->mime_types( 'some/file' );
    for( @types ) {
        print $type->mime_type, "\n";
    };

Returns the list of MIME types according to their priority.
The first type is the most likely. The returned objects
are of type L<MIME::Detect::Type>.

=cut

sub mime_types( $self, $file ) {
    if( ! ref $file) {
        open my $fh, '<', $file
            or croak "Couldn't read '$file': $!";
        binmode $fh;
        $file = $fh;
    };
    my $buffer = MIME::Detect::Buffer->new(fh => $file);
    $buffer->request(0,4096); # should be enough for most checks

    my @candidates;
    my $m = $self->known_types;

    # Already sorted by priority
    my @types = @{ $self->{types} };

    # Let's just hope we don't have infinite subtype loops in the XML file
    for my $k (@types) {
        my $t = ref $k ? $k : $m->{ $k };
        if( $t->matches($buffer) ) {
            #warn sprintf "*** found '%s'", $t->mime_type;
            push @candidates, $m->{$t->mime_type};
        };
    };

    @candidates;
}

=head2 C<< $mime->mime_type >>

    my $type = $mime->mime_type( 'some/file' );
    print $type->mime_type, "\n"
        if $type;

Returns the most likely type of a file as L<MIME::Detect::Type>. Returns
C<undef> if no file type can be determined.

=cut

sub mime_type( $self, $file ) {
    ($self->mime_types($file))[0]
}

=head2 C<< $mime->mime_types_from_name >>

    my $type = $mime->mime_types_from_name( 'some/file.ext' );
    print $type->mime_type, "\n"
        if $type;

Returns the list of MIME types for a file name based on the extension
according to their priority.
The first type is the most likely. The returned objects
are of type L<MIME::Detect::Type>.

=cut

sub mime_types_from_name( $self, $file ) {
    my @candidates;
    my $m = $self->known_types;

    # Already sorted by priority
    my @types = @{ $self->{types} };

    # Let's just hope we don't have infinite subtype loops in the XML file
    for my $k (@types) {
        my $t = ref $k ? $k : $m->{ $k };
        if( $t->valid_extension($file) ) {
            #warn sprintf "*** found '%s'", $t->mime_type;
            push @candidates, $m->{$t->mime_type};
        };
    };

    @candidates;
}

=head2 C<< $mime->mime_type_from_name >>

    my $type = $mime->mime_type_from_name( 'some/file.ext' );
    print $type->mime_type, "\n"
        if $type;

Returns the most likely type of a file name as L<MIME::Detect::Type>. Returns
C<undef> if no file type can be determined.

=cut

sub mime_type_from_name( $self, $file ) {
    ($self->mime_types_from_name($file))[0]
}

package MIME::Detect::Buffer;
use Moo;
use if $] < 5.020, 'Filter::signatures';
use feature 'signatures';
no warnings 'experimental::signatures';
use Fcntl 'SEEK_SET';

has 'offset' => (
    is => 'rw',
    default => 0,
);

has 'buffer' => (
    is => 'rw',
    default => undef,
);

has 'fh' => (
    is => 'ro',
);

sub length($self) {
    length $self->buffer || 0
};

sub request($self,$offset,$length) {
    my $fh = $self->fh;

    if( $offset =~ m/^(\d+):(\d+)$/) {
        $offset = $1;
        $length += $2;
    };

    #warn sprintf "At %d to %d (%d), want %d to %d (%d)",
    #         $self->offset, $self->offset+$self->length, $self->length,
    #         $offset, $offset+$length, $length;
    if(     $offset < $self->offset
        or  $self->offset+$self->length < $offset+$length ) {
        # We need to refill the buffer
        my $buffer;
        my $updated = 0;
        if (ref $fh eq 'GLOB') {
            if( seek($fh, $offset, SEEK_SET)) {
                read($fh, $buffer, $length);
                $updated = 1;
            };
        } else {
            # let's hope you have ->seek and ->read:
            if( $fh->seek($offset, SEEK_SET) ) {
                $fh->read($buffer, $length);
                $updated = 1;
            };
        }
        
        # Setting all three in one go would be more object-oriented ;)
        if( $updated ) {
            $self->offset($offset);
            $self->buffer($buffer);
        };
    };

    if(     $offset >= $self->offset
        and $self->offset+$self->length >= $offset+$length ) {
        substr $self->buffer, $offset-$self->offset, $length
    } elsif(     $offset >= $self->offset ) {
        substr $self->buffer, $offset-$self->offset
    } else {
        return ''
    };
}

1;

=head1 SEE ALSO

L<https://www.freedesktop.org/wiki/Software/shared-mime-info/> - the website
where the XML file is distributed

L<File::MimeInfo> - module to read your locally installed and converted MIME database

L<File::LibMagic> - if you can install C<libmagic> and the appropriate C<magic> files

L<File::MMagic> - if you have the appropriate C<magic> files

L<File::MMagic::XS> - if you have the appropriate C<magic> files but want more speed

L<File::Type> - inlines its database, unsupported since 2004?

L<File::Type::WebImages> - if you're only interested in determining whether
a file is an image or not

L<MIME::Types> - for extension-based detection

=head1 REPOSITORY

The public repository of this module is 
L<http://github.com/Corion/mime-detect>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=MIME-Detect>
or via mail to L<mime-detect-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2015-2016 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
