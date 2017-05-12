package MARC::Charset::Table;

=head1 NAME 

MARC::Charset::Table - character mapping db

=head1 SYNOPSIS

    use MARC::Charset::Table;
    use MARC::Charset::Constants qw(:all);

    # create the table object
    my $table = MARC::Charset::Table->new();
   
    # get a code using the marc8 character set code and the character
    my $code = $table->lookup_by_marc8(CYRILLIC_BASIC, 'K');

    # get a code using the utf8 value
    $code = $table->lookup_by_utf8(chr(0x043A));

=head1 DESCRIPTION

MARC::Charset::Table is a wrapper around the character mapping database, 
which is implemented as a tied hash on disk. This database gets generated 
by Makefile.PL on installation of MARC::Charset using 
MARC::Charset::Compiler.

The database is essentially a key/value mapping where a key is a 
MARC-8 character set code + a MARC-8 character, or an integer representing the
UCS code point. These keys map to a serialized MARC::Charset::Code object.

=cut

use strict;
use warnings;
use POSIX;
BEGIN {
    @AnyDBM_File::ISA = qw(GDBM_File DB_File NDBM_File ODBM_File SDBM_File);
    # SDBM_File is last on the list because it produces the largest database
    # on disk.
}
use AnyDBM_File;
use MARC::Charset::Code;
use MARC::Charset::Constants qw(:all);
use Storable qw(nfreeze thaw);

=head2 new()

The consturctor.

=cut

sub new
{
    my $class = shift;
    my $self = bless {}, ref($class) || $class;
    $self->_init(O_RDONLY);
    return $self;
}


=head2 add_code()

Add a MARC::Charset::Code to the table.

=cut


sub add_code
{
    my ($self, $code) = @_;

    # the Code object is serialized
    my $frozen = nfreeze($code);

    # to support lookup by marc8 and utf8 values we 
    # stash away the rule in the db using two keys
    my $marc8_key = $code->marc8_hash_code();
    my $utf8_key = $code->utf8_hash_code();

    # stash away the marc8 lookup key
    $self->{db}->{$marc8_key} = $frozen;

    # stash away the utf8 lookup key (only if it's not already there!)
    # this means that the sets that appear in the xml file will have
    # precedence ascii/ansel.  Note that we're using 'defined' instead of
    # 'exists' because NDBM_File and ODBM_File don't support 'exists'.
    $self->{db}->{$utf8_key} = $frozen unless defined $self->{db}->{$utf8_key};
}


=head2 get_code()

Retrieve a code using a hash key.

=cut

sub get_code
{
    my ($self, $key) = @_;
    my $db = $self->db();
    my $frozen = $db->{$key};
    return thaw($frozen) if $frozen;
    return;
}


=head2 lookup_by_marc8()

Looks up MARC::Charset::Code entry using a character set code and a MARC-8 
value.

    use MARC::Charset::Constants qw(HEBREW);
    $code = $table->lookup_by_marc8(HEBREW, chr(0x60));

=cut

sub lookup_by_marc8
{
    my ($self, $charset, $marc8) = @_;
    $charset = BASIC_LATIN if $charset eq ASCII_DEFAULT;
    return $self->get_code(sprintf('%s:%s', $charset, $marc8));
}


=head2 lookup_by_utf8()

Looks up a MARC::Charset::Code object using a utf8 value.

=cut

sub lookup_by_utf8
{
    my ($self, $value) = @_;
    return $self->get_code(ord($value));
}




=head2 db()

Returns a reference to a tied character database. MARC::Charset::Table
wraps access to the db, but you can get at it if you want.

=cut

sub db 
{
    return shift->{db};
}


=head2 db_path()

Returns the path to the character encoding database. Can be called 
statically too: 

    print MARC::Charset::Table->db_path();

=cut

sub db_path
{
    my $path = $INC{'MARC/Charset/Table.pm'};
    $path =~ s/\.pm$//;
    return $path;
}


=head2 brand_new()

An alternate constructor which removes the existing database and starts
afresh. Be careful with this one, it's really only used on MARC::Charset
installation.

=cut

sub brand_new 
{
    my $class = shift;
    my $self = bless {}, ref($class) || $class;
    $self->_init(O_CREAT|O_RDWR);

    return $self;
}


# helper function for initializing table internals

sub _init 
{
    my ($self, $dbm_opts) = @_;
    tie my %db, 'AnyDBM_File', db_path(), $dbm_opts, 0644; ## no critic (ValuesAndExpressions::ProhibitLeadingZeros)
    $self->{db} = \%db;
}





1;
