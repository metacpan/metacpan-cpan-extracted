package Debian::DEP12;

use strict;
use warnings;

# ABSTRACT: interface to Debian DEP 12 format
our $VERSION = '0.1.0'; # VERSION

use Data::Validate::Email qw( is_email_rfc822 );
use Data::Validate::URI qw( is_uri );
use Debian::DEP12::ValidationWarning;
use Encode qw( decode );
use Scalar::Util qw( blessed );
use Text::BibTeX::Validate qw( validate_BibTeX );
use YAML::XS;

# Preventing YAML::XS from doing undesired things:
$YAML::XS::DumpCode = 0;
$YAML::XS::LoadBlessed = 0;
$YAML::XS::UseCode = 0;

my @fields = qw(
    Archive
    ASCL-Id
    Bug-Database
    Bug-Submit
    Cite-As
    Changelog
    CPE
    Documentation
    Donation
    FAQ
    Funding
    Gallery
    Other-References
    Reference
    Registration
    Registry
    Repository
    Repository-Browse
    Screenshots
    Security-Contact
    Webservice
);

my @list_fields = qw(
    Funding
    Reference
    Registry
    Screenshots
);

=head1 NAME

Debian::DEP12 - interface to Debian DEP 12 format

=head1 SYNOPSIS

    use Debian::DEP12;

    my $meta = Debian::DEP12->new;
    $meta->set( 'Bug-Database',
                'https://github.com/merkys/Debian-DEP12/issues' );

    $meta->validate;

=head1 DESCRIPTION

Debian::DEP12 is an object-oriented interface for Debian DEP 12 format,
also known as debian/upstream/metadata. Primary focus of the initial
development was validation and fixing of DEP 12 data.

Contributions welcome!

=head1 METHODS

=head2 new( $what )

Creates a new Debian::DEP12 instance from either YAML,
L<Text::BibTeX::Entry|Text::BibTeX::Entry> or
L<Text::BibTeX::File|Text::BibTeX::File> instances, or plain Perl hash
reference with DEP 12 fields and their values.

=cut

sub new
{
    my( $class, $what ) = @_;

    my $self;
    if( !defined $what ) {
        $self = {};
    } elsif( blessed $what &&
             ( $what->isa( 'Text::BibTeX::Entry' ) ||
               $what->isa( 'Text::BibTeX::File' ) ) ) {

        my @entries;
        if( $what->isa( 'Text::BibTeX::Entry' ) ) {
            push @entries, $what;
        } else {
            require Text::BibTeX::Entry;
            while( my $entry = Text::BibTeX::Entry->new( $what ) ) {
                push @entries, $entry;
            }
        }

        my @references;
        for my $entry (@entries) {
            # FIXME: Filter only supported keys (?)
            push @references,
                 { map { _canonical_BibTeX_key( $_ ) =>
                         decode( 'UTF-8', $entry->get( $_ ) ) }
                   grep { defined $entry->get( $_ ) }
                        $entry->fieldlist };

            for ('number', 'pages', 'volume', 'year') {
                next if !exists $references[-1]->{ucfirst $_};
                next if $references[-1]->{ucfirst $_} !~ /^[1-9][0-9]*$/;
                $references[-1]->{ucfirst $_} =
                    int $references[-1]->{ucfirst $_};
            }
        }

        return $class->new( { Reference => \@references } );
    } elsif( ref $what eq '' ) {
        # Text in YAML format
        if( $YAML::XS::VERSION < 0.69 ) {
            die 'YAML::XS < 0.69 is insecure' . "\n";
        }

        $self = Load $what;
    } elsif( ref $what eq 'HASH' ) {
        $self = $what;
    } else {
        die 'cannot create Debian::DEP12 from ' . ref( $what ) . "\n";
    }

    return bless $self, $class;
}

sub _canonical_BibTeX_key
{
    my( $key ) = @_;
    return uc $key if $key =~ /^(doi|isbn|issn|pmid|url)$/;
    return ucfirst $key;
}

=head2 fields()

Returns an array of fields defined in the instance in any order.

=cut

sub fields
{
    return keys %{$_[0]};
}

=head2 get( $field )

Returns value of a field.

=cut

sub get
{
    my( $self, $field ) = @_;
    return $self->{$field};
}

=head2 set( $field, $value )

Sets a new value for a field. Returns the old value.

=cut

sub set
{
    my( $self, $field, $value ) = @_;
    ( my $old_value, $self->{$field} ) = ( $self->{$field}, $value );
    return $old_value;
}

=head2 delete( $field )

Unsets value for a field. Returns the old value.

=cut

sub delete
{
    my( $self, $field ) = @_;

    my $old_value = $self->{$field};
    delete $self->{$field};

    return $old_value;
}

sub _to_BibTeX
{
    my( $self ) = @_;

    my $reference = $self->get( 'Reference' );
    if( ref $reference eq 'HASH' ) {
        $reference = [ $reference ];
    }

    my @BibTeX;
    for my $reference (@$reference) {
        push @BibTeX,
             { map { lc( $_ ) => $reference->{$_} } keys %$reference };
    }
    return @BibTeX;
}

=head2 to_YAML()

Returns a string with YAML representation.

=cut

sub to_YAML
{
    my( $self ) = @_;
    my $yaml = Dump $self;

    # HACK: no better way to serialize plain data?
    $yaml =~ s/^---[^\n]*\n//m;
    return $yaml;
}

=head2 validate()

Performs checks of DEP 12 data in the instance and returns an array of
validation messages as instances of
L<Debian::DEP12::ValidationWarning|Debian::DEP12::ValidationWarning>.

=cut

sub validate
{
    my( $self ) = @_;

    my @warnings;

    # TODO: validate other fields

    for my $key (sort $self->fields) {
        if( !grep { $_ eq $key } @fields ) {
            push @warnings,
                 _warn_value( 'unknown field', $key, $self->get( $key ) );
        }

        if( ref $self->get( $key ) && !grep { $_ eq $key } @list_fields ) {
            push @warnings,
                 _warn_value( 'scalar value expected',
                              $key,
                              $self->get( $key ) );
        }
    }

    for my $key ('Bug-Database', 'Bug-Submit', 'Changelog',
                 'Documentation', 'Donation', 'FAQ', 'Gallery',
                 'Other-References', 'Registration', 'Repository',
                 'Repository-Browse', 'Screenshots', 'Webservice') {
        next if !defined $self->get( $key );

        my @values;
        if( ref $self->get( $key ) eq 'ARRAY' ) {
            @values = @{$self->get( $key )};
        } else {
            @values = ( $self->get( $key ) );
        }

        for my $i (0..$#values) {
            my $yamlpath = $key .
                           (ref $self->get( $key ) eq 'ARRAY' ? "[$i]" : '');
            $_ = $values[$i];

            if( ref $_ ) {
                push @warnings,
                     _warn_value( 'non-scalar value',
                                  $yamlpath,
                                  $_ );
                next;
            }

            next if defined is_uri $_;

            if( /^(.*)\n$/ && defined is_uri $1 ) {
                push @warnings,
                     _warn_value( 'URL has trailing newline character',
                                  $yamlpath,
                                  $_,
                                  { suggestion => $1 } );
                next;
            }

            if( is_email_rfc822( $_ ) ) {
                push @warnings,
                     _warn_value( 'value \'%(value)s\' is better written as \'%(suggestion)s\'',
                                  $yamlpath,
                                  $_,
                                  { suggestion => 'mailto:' . $_ } );
                next;
            }

            push @warnings,
                 _warn_value( 'value \'%(value)s\' does not look like valid URL',
                              $yamlpath,
                              $_ );
        }
    }

    my @BibTeX = $self->_to_BibTeX;
    for my $i (0..$#BibTeX) {
        my $BibTeX = $BibTeX[$i];
        my @BibTeX_warnings = validate_BibTeX( $BibTeX );
        for (@BibTeX_warnings) {
            # For everything under Reference outputting YAML paths like
            # https://github.com/wwkimball/yamlpath/wiki/Segments-of-a-YAML-Path
            $_->set( 'field',
                     "Reference" .
                     (ref $self->get( 'Reference' ) eq 'ARRAY' ? "[$i]" : '') . '.' .
                     _canonical_BibTeX_key( $_->get( 'field' ) ) );
            bless $_, Debian::DEP12::ValidationWarning::;
        }
        push @warnings, @BibTeX_warnings;
    }

    return @warnings;
}

sub _warn_value
{
    my( $message, $field, $value, $extra ) = @_;
    $extra = {} unless $extra;
    return Debian::DEP12::ValidationWarning->new(
            $message,
            { field => $field,
              value => $value,
              %$extra } );
}

=head1 SEE ALSO

For the description of DEP 12 refer to
L<https://dep-team.pages.debian.net/deps/dep12/>.

=head1 AUTHORS

Andrius Merkys, E<lt>merkys@cpan.orgE<gt>

=cut

1;
