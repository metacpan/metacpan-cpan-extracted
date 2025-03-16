package Koha::Contrib::Tamil::Biblio::Dumper;
# ABSTRACT: Class dumping a Koha Catalog
$Koha::Contrib::Tamil::Biblio::Dumper::VERSION = '0.074';
use Moose;

extends 'AnyEvent::Processor';

use Modern::Perl;
use utf8;
use Koha::Contrib::Tamil::Koha;
use MARC::Moose::Record;
use MARC::Moose::Writer;
use MARC::Moose::Formater::Iso2709;
use C4::Biblio;
use C4::Items qw/ Item2Marc PrepareItemrecordDisplay /;
use Koha::Items;
use Locale::TextDomain 'Koha-Contrib-Tamil';


has file => ( is => 'rw', isa => 'Str', default => 'dump.mrc' );

has branches => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] }
);


has query => ( is => 'rw', isa => 'Str', default => '' );

has convert => (
    is => 'rw',
    default => sub { sub {
        return shift;
    } },
);

has formater => (
    is => 'rw',
    isa => 'Str',
    default => 'marcxml',
);

has koha => (
    is       => 'rw',
    isa      => 'Koha::Contrib::Tamil::Koha',
    required => 0,
);

has decode => ( is => 'rw', isa => 'Bool', default => 0 );

has verbose => ( is => 'rw', isa => 'Bool', default => 0 );

has sth => ( is => 'rw' );
has sth_marcxml => ( is => 'rw' );
has sth_item => ( is => 'rw' );

has writer => ( is => 'rw', isa => 'MARC::Moose::Writer' );

has code_to_value => ( is => 'rw', isa => 'HashRef' );

before 'run' => sub {
    my $self = shift;

    $self->koha( Koha::Contrib::Tamil::Koha->new() ) unless $self->koha;

    my $query = $self->query;
    my $where = "";
    if ( my $branches = $self->branches ) {
        $where = 'homebranch IN (' .
                 join(',', map {"'$_'" } @$branches) . ')'
            if @$branches;
    }
    unless ($query) {
        $query = $where
                 ? "SELECT DISTINCT biblionumber FROM items WHERE $where"
                 : "SELECT biblionumber FROM biblioitems";
    }
    #say $query;
    my $sth = $self->koha->dbh->prepare($query);
    $sth->execute();
    $self->sth($sth);

    $self->sth_marcxml( $self->koha->dbh->prepare(
        "SELECT metadata FROM biblio_metadata WHERE biblionumber=?"
    ) );

    $query = "SELECT * FROM items WHERE biblionumber=?";
    $query .= " AND $where" if $where;
    #say $query;
    $self->sth_item( $self->koha->dbh->prepare($query));

    # Récupération des décodages
    if ($self->decode) {
        my $av;
        my $decode;
        $query = "SELECT category, authorised_value, lib FROM authorised_values";
        for (@{$self->koha->dbh->selectall_arrayref($query)}) {
            my ($category, $code, $decode) = @$_;
            $av->{$category}->{$code} = $decode;
        }
        $query = "SELECT branchcode, branchname FROM branches";
        for (@{$self->koha->dbh->selectall_arrayref($query)}) {
            my ($code, $decode) = @$_;
            $av->{branches}->{$code} = $decode;
        }
        $query = "SELECT itemtype, description FROM itemtypes";
        for (@{$self->koha->dbh->selectall_arrayref($query)}) {
            my ($code, $decode) = @$_;
            $av->{itemtypes}->{$code} = $decode;
        }
        $query = "SELECT tagfield, tagsubfield, authorised_value
                 FROM marc_subfield_structure
                 WHERE frameworkcode='' AND authorised_value<>''";
        for (@{$self->koha->dbh->selectall_arrayref($query)}) {
            my ($tag, $letter, $category) = @$_;
            $decode->{$tag}->{$letter} = $av->{$category};
        }
        $self->code_to_value($decode);
    }

    my $fh = new IO::File '> ' . $self->file;
    binmode($fh, ':encoding(utf8)');
    $self->writer( MARC::Moose::Writer->new(
        formater => $self->formater =~ /marcxml/i
                    ? MARC::Moose::Formater::Marcxml->new()
                    : MARC::Moose::Formater::Iso2709->new(),
        fh => $fh ) );
};


before 'start_process' => sub {
    shift->writer->begin();
};


override 'process' => sub {
    my $self = shift;

    my ($biblionumber) = $self->sth->fetchrow;
    return unless $biblionumber;

    # Get the biblio record
    $self->sth_marcxml->execute($biblionumber);
    my ($marcxml) = $self->sth_marcxml->fetchrow;
    my $record = MARC::Moose::Record::new_from($marcxml, 'marcxml');

    # Construct item fields
    $self->sth_item->execute($biblionumber);
    while ( my $item = $self->sth_item->fetchrow_hashref ) {
        my $imarc = Item2Marc($item, $biblionumber);
        my $field = $imarc->field('952|995');
        my $f = MARC::Moose::Field::Std->new(
            tag => $field->tag,
            subf => [ $field->subfields ]);
        $record->append($f);
    }

    if ($self->decode) {
        my $decode = $self->code_to_value;
        for my $field (@{$record->fields}) {
            my $dec_tag = $decode->{$field->tag};
            next unless $dec_tag;
            for (@{$field->subf}) {
                my ($letter, $value) = @$_;
                my $dec_letter = $dec_tag->{$letter};
                next unless $dec_letter;
                my $decode = $dec_letter->{$value};
                next unless defined $decode;
                $_->[1] = $decode;

            }
        }
    }

    # Specific conversion
    $record = $self->convert->($record);

    $self->writer->write($record) if $record;
    return super();
};


before 'end_process' => sub {
    shift->writer->end();
};


override 'start_message' => sub {
    my $self = shift;
    say __x("Dump of Koha Catalog into file: {file}",
            file => $self->file);
};


override 'process_message' => sub {
    my $self = shift;
    say $self->count;
};


override 'end_message' => sub {
    my $self = shift;
    say __x("Number of biblio records exported: {biblios}",
              biblios => $self->count );
};


no Moose;
__PACKAGE__->meta->make_immutable;

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::Biblio::Dumper - Class dumping a Koha Catalog

=head1 VERSION

version 0.074

=head1 SYNOPSIS

 my $converter = sub {
     # Delete some fields
     $record->fields(
         [ grep { $_->tag !~ /012|014|071|099/ } @{$record->fields} ] );
     return $record;
 };
 my $dumper = Koha::Contrib::Tamil::Biblio::Dumper->new(
     file     => 'biblio.mrc',
     branches => [ qw/ MAIN ANNEX / ],
     query    => "SELECT biblionumber FROM biblio WHERE datecreated LIKE '2014-11%'"
     convert  => $converter,
     formater => 'iso2709',
     verbose  => 1,
 );
 $dumper->run();

=head1 ATTRIBUTES

=head2 file

Name of the file in which biblio records are exported. By default C<dump.mrc>.

=head2 query

Optional query to select biblio records to dump. The query must return a list
of biblio records C<biblionumber>. For example: C<SELECT biblionumber FROM
biblio WHERE biblionumber BETWEEN 1 AND 100>.

=head2 convert

A function which take in parameter a L<MARC::Moose::Record> biblio record, and
returns a converted record.

=head2 formater

Type of formater used to write in L<file> file. Default value is C<marcxml>.
Available values are: C<iso2709>, C<marcxml>, C<text>, C<json>, C<yaml>,
C<json>.

=head2 decode

Decode encoded values

=head2 verbose

Verbosity. By default 0 (false).

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__

1;


