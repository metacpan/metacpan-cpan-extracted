package Frost::Burial;

#	LIBS
#
use Moose;

#	use DB_File 1.820;
use BerkeleyDB 0.43;

#s	SPEEDFIX: All checks removed: We will never use this module stand-alone...
#s	Update: Re-introduce some checks...

#s	use Scalar::Util;

use Moose::Util::TypeConstraints;

use Frost::Types;
use Frost::Util;

#	CLASS VARS
#
our $VERSION	= 0.70;
our $AUTHORITY	= 'cpan:ERNESTO';

#	CLASS METHODS
#
sub suffix { die 'Abstract method' }

#	PUBLIC ATTRIBUTES
#
has data_root	=> ( isa => 'Frost::FilePathMustExist',	is => 'ro',								required => true,		);
has classname	=> ( isa => 'ClassName',						is => 'ro',								required => true,		);
has slotname	=> ( isa => 'Str',								is => 'ro',								required => true,		);

has filename	=> ( isa => 'Frost::FilePath',	is => 'ro',	init_arg => undef,	lazy_build => true,	);
has numeric		=> ( isa => 'Bool', 					is => 'ro',	init_arg => undef,	lazy_build => true,	);
has unique		=> ( isa => 'Bool',					is => 'ro',	init_arg => undef,	lazy_build => true,	);
has cachesize	=> ( isa => 'Frost::Natural',		is => 'ro',			default => DEFAULT_CACHESIZE,			);

#	PRIVATE ATTRIBUTES
#
has _dbm_hash		=>
(
	is				=> 'rw',
	isa			=> 'Undef | Frost::DBM_Hash',
	default		=> sub { undef },
);
has _dbm_object	=>
(
	is				=> 'rw',
	isa			=> 'Undef | Frost::DBM_Object',
#	predicate	=> 'is_open',			#	returns true with undef too !!!
	default		=> sub { undef },
);

has _dbm_cursor	=>
(
	is				=> 'rw',
	isa			=> 'Undef | Frost::DBM_Cursor',
	default		=> sub { undef },
);

#	CONSTRUCTORS
#
sub _build_filename
{
	filename_from_class_and_id
		(
			$_[0]->data_root,
			$_[0]->classname,
			$_[0]->slotname,
			false,					#	not dont_create...
			$_[0]->suffix,
		);
}

sub _build_numeric	{ die 'Abstract method' }
sub _build_unique		{ die 'Abstract method' }

sub BUILDARGS
{
	my $class	= shift;

	( $class ne __PACKAGE__ )	or die __PACKAGE__ . ' is an abstract class';

	my $params	= Moose::Object->BUILDARGS ( @_ );

	( defined $params->{data_root} )		or die 'Attribute (data_root) is required';
	( defined $params->{classname} )		or die 'Attribute (classname) is required';
	( defined $params->{slotname} )		or die 'Attribute (slotname) is required';

	( defined find_attribute_manuel ( $params->{classname}, $params->{slotname} ) )
		or die "Class '" . $params->{classname} . "' has no attribute '" . $params->{slotname} . "'";

	return $params;
}

#	DESTRUCTORS
#
#	Autosave does SOMETIMES NOT work!
#
#	Frost::Burial::DEMOLISH ( Frost::Cemetery=HASH(0x9f432e0) 1 )
#	Frost::Burial::close
#	$is_closed = 0;
#	$filename = "/tmp/frost/Point/x.cem";
#	$in_global_destruction = 1;
#	Frost::Burial::save
#	$is_closed = 0;
#	$filename = "/tmp/frost/Point/x.cem";
#	$in_global_destruction = 1;
#	Frost::Burial::save B4 sync...
#		(in cleanup) BerkeleyDB Aborting: Database is already closed at ../lib/Frost/Burial.pm line 217 during global destruction.
#	 at ../lib/Frost/Burial.pm line 217
#		Frost::Burial::save('Frost::Cemetery=HASH(0x9f432e0)', 1) called at ../lib/Frost/Burial.pm line 190
#		Frost::Burial::close('Frost::Cemetery=HASH(0x9f432e0)', 1) called at ../lib/Frost/Burial.pm line 104
#		Frost::Burial::DEMOLISH('Frost::Cemetery=HASH(0x9f432e0)', 1) called at generated method (unknown origin) line 7
#		Class::MOP::Method::Generated::__ANON__() called at /usr/local/share/perl/5.10.0/Try/Tiny.pm line 76
#		eval {...} called at /usr/local/share/perl/5.10.0/Try/Tiny.pm line 67
#		Try::Tiny::try('CODE(0xa0f03d8)', 'Try::Tiny::Catch=REF(0x9f63628)') called at generated method (unknown origin) line 8
#		Frost::Cemetery::DESTROY('Frost::Cemetery=HASH(0x9f432e0)') called at 000_moose_recipes/moose_cookbook_basics_recipe1.t line 0
#		eval {...} called at 000_moose_recipes/moose_cookbook_basics_recipe1.t line 0
#	 at generated method (unknown origin) line 8
#		Class::MOP::Method::Generated::__ANON__('BerkeleyDB Aborting: Database is already closed at ../lib/Fro...') called at /usr/local/share/perl/5.10.0/Try/Tiny.pm line 98
#		Try::Tiny::try('CODE(0xa0f03d8)', 'Try::Tiny::Catch=REF(0x9f63628)') called at generated method (unknown origin) line 8
#		Frost::Cemetery::DESTROY('Frost::Cemetery=HASH(0x9f432e0)') called at 000_moose_recipes/moose_cookbook_basics_recipe1.t line 0
#		eval {...} called at 000_moose_recipes/moose_cookbook_basics_recipe1.t line 0
#
#	sub DEMOLISH
#	{
#		print STDERR __PACKAGE__ . "::DEMOLISH ( @_ )\n";
#
#		$_[0]->close ( $_[1] || 0 );		#	in global destruction...
#
#		print STDERR __PACKAGE__ . "::DEMOLISH done\n\n";
#	}

#	0.70	in again for untie!
#
sub DEMOLISH
{
	#print STDERR __PACKAGE__ . "::DEMOLISH ( @_ )\n";

	$_[0]->close ( 1 );		#	flag $from_demolish...

	#print STDERR __PACKAGE__ . "::DEMOLISH done\n\n";
}

#	PUBLIC METHODS
#
sub is_open			{ ( defined $_[0]->{_dbm_object} ) ? true : false }		#	return 'real' boolean
sub is_closed		{ ( defined $_[0]->{_dbm_object} ) ? false : true }

#	sub open
#	{
#		#IS_DEBUG and DEBUG "( @_ )";
#
#		my ( $self )	= @_;
#
#		return true		if $self->is_open;
#
#		my %dbm_hash;
#
#		my $filename	= $self->filename;
#		my $flags		= O_RDWR|O_CREAT;
#		my $mode			= 0700;
#		my $info			= new DB_File::BTREEINFO;
#
#		$info->{'flags'} 		= R_DUP						unless $self->unique;
#		$info->{'cachesize'}	= $self->cachesize;
#	#	$info->{'compare'}	= \&_numeric_compare		if $self->numeric;
#	#
#		my $dbm_object		= tie %dbm_hash, "DB_File", $filename, $flags, $mode, $info
#												or die "Cannot open $filename: $!\n";
#
#		if ( $self->numeric )
#		{
#			no warnings;		#	$_ might be undef !!!
#
#			$dbm_object->filter_fetch_key  ( sub { $_ = unpack	("i", $_) } );
#			$dbm_object->filter_store_key  ( sub { $_ = pack	("i", $_) } );
#		}
#
#		$self->_dbm_hash		( \%dbm_hash );
#		$self->_dbm_object	( $dbm_object );
#
#		return true;
#	}

sub open
{
	my ( $self )	= @_;

	IS_DEBUG and DEBUG Dump [ $self->is_open, $self->filename ], [qw( is_open filename )];

	return true		if $self->is_open;

	my %dbm_hash;

	my $filename	= $self->filename;

	my $info			= {};

	$info->{'-Filename'} 	= $filename;
	$info->{'-Flags'} 		= DB_CREATE;
	$info->{'-Mode'} 			= 0700;
	$info->{'-Property'}		= DB_DUP								unless $self->unique;
	$info->{'-Cachesize'}	= $self->cachesize;
	$info->{'-Compare'}		= sub { $_[0] <=> $_[1] }		if $self->numeric;

	my $dbm_object	= tie %dbm_hash, "BerkeleyDB::Btree", %$info
											or die "Cannot open $filename: $! $BerkeleyDB::Error\n" ;

	$self->_dbm_hash		( \%dbm_hash );
	$self->_dbm_object	( $dbm_object );

	return true;
}

#	sub close
#	{
#		#IS_DEBUG and DEBUG "( @_ )";
#
#		my ( $self, $igd )	= @_;
#
#		#print STDERR __PACKAGE__ . "::close", Dump [ $self->is_closed, $self->filename, $igd ], [qw( is_closed filename in_global_destruction )];
#
#		return true		if $self->is_closed;
#
#		$self->save ( $igd );
#
#		my $dbm_hash	= $self->_dbm_hash;
#
#		$self->_dbm_cursor	( undef );		#	release cursor
#		$self->_dbm_hash		( undef );
#		$self->_dbm_object	( undef );
#
#		untie %$dbm_hash;
#
#		#print STDERR __PACKAGE__ . "::close done\n\n";
#
#		return true;
#	}

sub close
{
	#IS_DEBUG and DEBUG "( @_ )";

	my ( $self, $from_demolish )	= @_;

	#print STDERR __PACKAGE__ . "::close", Dump [ $self->is_closed, $self->filename, $from_demolish ], [qw( is_closed filename from_demolish )];

	return true		if $self->is_closed;

	$self->save()		unless $from_demolish;

	my $dbm_hash	= $self->_dbm_hash;

	$self->_dbm_cursor	( undef );		#	release cursor
	$self->_dbm_hash		( undef );
	$self->_dbm_object	( undef );

	untie %$dbm_hash;

	#print STDERR __PACKAGE__ . "::close done\n\n";

	return true;
}

#	sub save
#	{
#		#IS_DEBUG and DEBUG "( @_ )";
#
#		my ( $self, $igd )	= @_;
#
#		#print STDERR __PACKAGE__ . "::save", Dump [ $self->is_closed, $self->filename, $igd ], [qw( is_closed filename in_global_destruction )];
#
#		return true			if $self->is_closed;
#
#		#print STDERR __PACKAGE__ . "::save B4 sync...\n";
#
#		my $status	= $self->_dbm_object->db_sync();
#
#		#print STDERR __PACKAGE__ . "::save AF sync... status=", ( $status ? $status : 'OK' ), "\n";
#
#		return false		if $status;
#
#		#print STDERR __PACKAGE__ . "::save done\n\n";
#
#		return true;
#	}

sub save
{
	#IS_DEBUG and DEBUG "( @_ )";

	my ( $self )	= @_;

	#print STDERR __PACKAGE__ . "::save", Dump [ $self->is_closed, $self->filename ], [qw( is_closed filename )];

	return true			if $self->is_closed;

	#print STDERR __PACKAGE__ . "::save B4 sync...\n";

	my $status	= $self->_dbm_object->db_sync();

	#print STDERR __PACKAGE__ . "::save AF sync... status=", ( $status ? $status : 'OK' ), "\n";

	return false		if $status;

	#print STDERR __PACKAGE__ . "::save done\n\n";

	return true;
}

sub clear
{
	#IS_DEBUG and DEBUG "( @_ )";

	my ( $self )	= @_;

	$self->open();

#	$self->_dbm_hash ( {} );			#	This breaks the connection to the dbm file aka %dbm_hash,
												#	thus the dbm file is not emptied !

	%{ $self->_dbm_hash }	= ();		#	That's the right way !
}

sub remove
{
	#IS_DEBUG and DEBUG "( @_ )";

	my ( $self )		= @_;

	if ( $self->is_open )
	{
		$self->clear();

		$self->close();
	}

	my $filename		= $self->filename;

	unlink $filename;
}

sub entomb
{
	my ( $self, $key, $essence )	= @_;

	#IS_DEBUG and DEBUG Dump [ $key, $essence ], [qw( key essence )];

#s	defined $key			or die 'Param key missing';
	defined $essence		or die 'Param essence missing';

#s	( not ref $key )		or die "Can only entomb a SCALAR key";
#s	( not ref $essence )	or die "Can only entomb a SCALAR essence";

#s	return false		unless $self->_validate_key ( $key );

	$self->open();

	$self->_dbm_hash->{$key}	= $essence;

	return true;
}

sub exhume
{
	my ( $self, $key )	= @_;

	#IS_DEBUG and DEBUG Dump [ $key ], [qw( key )];

#s	defined $key			or die 'Param key missing';

#s	( not ref $key )		or die "Can only get a SCALAR key";

#s	return ( wantarray ? () : '' )		unless $self->_validate_key ( $key );

	$self->open();

	my @list		= ();
	my $essence	= '';

	if ( $self->unique )
	{
		$essence	= $self->_dbm_hash->{$key};

		@list		= ( $essence )	if defined $essence;
		$essence	= ''				unless defined $essence;
	}
	else
	{
		@list		= $self->_dbm_object->get_dup ( $key );

		$essence	= $list[0]		if @list;
	}

	return wantarray ? @list : $essence;
}

sub forget
{
	my ( $self, $key, $essence )	= @_;

	#IS_DEBUG and DEBUG Dump [ $key, $essence ], [qw( key essence )];

#s	defined $key			or die 'Param key missing';

#s	( not ref $key )		or die "Can only erase a SCALAR key";

#s	return false		unless $self->_validate_key ( $key );

	$self->open();

	if ( defined $essence )
	{
#s		( not ref $essence )		or die "Can only erase a SCALAR essence";

		$self->_dbm_object->del_dup ( $key, $essence );
	}
	else
	{
		delete $self->_dbm_hash->{$key};
	}

	return true;
}

sub count
{
	my ( $self, $key )	= @_;

	#IS_DEBUG and DEBUG Dump [ $key ], [qw( key )];

	$self->open();

	my $count	= 0;

	if ( defined $key )
	{
#s		return 0		unless $self->_validate_key ( $key );
		#
		#	count is called from outside, i.e. via Frost::Asylum::exists
		#
		return 0		unless $self->_check_key ( $key );

		$count	= $self->_dbm_object->get_dup ( $key );
	}
	else
	{
		$count	= scalar keys %{ $self->_dbm_hash };		#	returns number of duplicate keys as well!
	}

	return $count;
}

sub match		{ $_[0]->first	( $_[1], -1 ); }
sub match_last	{ $_[0]->last	( $_[1], -1 ); }

sub match_next	{ $_[0]->next	( $_[1], -1 ); }
sub match_prev	{ $_[0]->prev	( $_[1], -1 ); }

sub find			{ $_[0]->first	( $_[1], 1 ); }
sub find_last	{ $_[0]->last	( $_[1], 1 ); }

sub find_next	{ $_[0]->next	( $_[1], 1 ); }
sub find_prev	{ $_[0]->prev	( $_[1], 1 ); }

sub first
{
	my ( $self, $key, $match )	= @_;

	$match	||= 0;

	#IS_DEBUG and DEBUG 'PARAM', Dump [ $key, $match ], [qw( key match )];

	$self->open();

	my @kv		= ();
	my $essence	= '';

	my $reset_key	= undef;

#	from DB_File-1.820\DB_File.xs
#
#define R_CURSOR        DB_SET_RANGE
#define R_FIRST         DB_FIRST
#define R_IAFTER        DB_AFTER
#define R_IBEFORE       DB_BEFORE
#define R_LAST          DB_LAST
#define R_NEXT          DB_NEXT
#define R_NOOVERWRITE   DB_NOOVERWRITE
#define R_PREV          DB_PREV

	@kv			= $self->_seq ( $reset_key, DB_FIRST()	);			#	reset cursor...

	#IS_DEBUG and DEBUG 'RESET', Dump [ \@kv ], [qw( kv )];

	unless ( defined $key )
	{
		$key		= '';
		$key		= $kv[0]		if @kv;

		return ( wantarray ? @kv : $key );
	}

	$essence		= '';

	#	we need the partial match here...
	#
	@kv			= $self->_seq ( $key, DB_SET_RANGE() );

	$self->_match_key ( $key, \@kv, \$essence, $match );

	#IS_DEBUG and DEBUG 'CURSOR', Dump [ \@kv, $essence ], [qw( kv essence )];

	return wantarray ? @kv : $essence;
}

sub last
{
	my ( $self, $key, $match )	= @_;

	$match	||= 0;

	#IS_DEBUG and DEBUG 'PARAM', Dump [ $key, $match ], [qw( key match )];

	$self->open();

	my @kv		= ();
	my $essence	= '';

	my $reset_key	= undef;

	@kv			= $self->_seq ( $reset_key, DB_LAST()	);			#	reset cursor...

	#IS_DEBUG and DEBUG 'RESET', Dump [ \@kv ], [qw( kv )];

	unless ( defined $key )
	{
		$key		= '';
		$key		= $kv[0]		if @kv;

		return ( wantarray ? @kv : $key );
	}

	$essence		= '';

	#	we need the partial match here...
	#
	@kv			= $self->_seq ( $key, DB_SET_RANGE() );		#	matches FIRST entry!

	$self->_match_key ( $key, \@kv, \$essence, $match );

	#IS_DEBUG and DEBUG 'CURSOR', Dump [ \@kv, $essence ], [qw( kv essence )];

	return wantarray ? @kv : $essence;
}

sub next
{
	my ( $self, $key, $match )	= @_;

	$match	||= 0;

	#IS_DEBUG and DEBUG 'PARAM', Dump [ $key, $match ], [qw( key match )];

	$self->open();

	my @kv		= ();
	my $essence	= '';

	@kv			= $self->_seq ( $key, DB_NEXT()	);

	unless ( defined $key )
	{
		$key		= '';
		$key		= $kv[0]		if @kv;

		return ( wantarray ? @kv : $key );
	}

	$self->_match_key ( $key, \@kv, \$essence, $match );

	#IS_DEBUG and DEBUG 'CURSOR', Dump [ \@kv, $essence ], [qw( kv essence )];

	return wantarray ? @kv : $essence;
}

sub prev
{
	my ( $self, $key, $match )	= @_;

	$match	||= 0;

	#IS_DEBUG and DEBUG 'PARAM', Dump [ $key, $match ], [qw( key match )];

	$self->open();

	my @kv		= ();
	my $essence	= '';

	@kv			= $self->_seq ( $key, DB_PREV()	);

	unless ( defined $key )
	{
		$key		= '';
		$key		= $kv[0]		if @kv;

		return ( wantarray ? @kv : $key );
	}

	$self->_match_key ( $key, \@kv, \$essence, $match );

	#IS_DEBUG and DEBUG 'CURSOR', Dump [ \@kv, $essence ], [qw( kv essence )];

	return wantarray ? @kv : $essence;
}

#	PRIVATE METHODS
#
sub _seq
{
	my ( $self, $key, $cursor )	= @_;

	#IS_DEBUG and DEBUG 'PARAM', Dump [ $key, $cursor ], [qw( key cursor )];

	if ( defined $key )
	{
#s		return ( wantarray ? () : '' )		unless $self->_validate_key ( $key );
		#
		#	find is called from outside, i.e. via Frost::Asylum::find
		#
#		return ( wantarray ? () : '' )		unless $self->_check_key ( $key );
#
		unless ( $self->_check_key ( $key ) )
		{
			$self->_dbm_cursor ( undef );		#	release cursor

			return ( wantarray ? () : '' );
		}
	}

	my ( $seq_key, $seq_value, $status );

	$seq_key		= defined $key ? $key : '';	#	do not change param!		must be defined for BerkeleyDB!
	$seq_value	= '';

#	$status	= $self->_dbm_object->seq ( $seq_key, $seq_value, $cursor );

	#	reuse cursor or make new one
	#
	#	document/test this... always: ->first ... -> next until empty etc.
	#
	$self->_dbm_cursor ( $self->_dbm_object->db_cursor() )		unless $self->_dbm_cursor;

	IS_DEBUG and DEBUG 'CURSOR B4', Dump [ $seq_key, $seq_value, $status, $self->_dbm_cursor ], [qw( seq_key seq_value status db_cursor)];

	$status			= $self->_dbm_cursor->c_get ( $seq_key, $seq_value, $cursor );

#	#IS_DEBUG and DEBUG 'STATUS', Dump [ $seq_key, $seq_value, $status ], [qw( seq_key seq_value status )];
	IS_DEBUG and DEBUG 'CURSOR AF', Dump [ $seq_key, $seq_value, $status, $self->_dbm_cursor ], [qw( seq_key seq_value status db_cursor)];

	$self->_dbm_cursor ( undef )			if $status;									#	release cursor

	return ( wantarray ? () : '' )		if $status;

	$self->_dbm_cursor ( undef )			unless defined $seq_value;				#	release cursor
	$seq_value	= ''							unless defined $seq_value;

	return wantarray ? ( $seq_key, $seq_value ) : $seq_value;
}

#s	#	See below _numeric_compare
#s	#
#s	sub _validate_key
#s	{
#s		unless ( NULL_KEYS_ALLOWED )
#s		{
#s			return false	if ( not $_[0]->numeric ) and ( $_[1] eq '' );		#	allow key = "0"...
#s		}
#s
#s		return false	if $_[0]->numeric and ( not Scalar::Util::looks_like_number ( $_[1] ) );
#s		return true;
#s	}
#s
#s	Update: Since count and _seq are called from outside, we have to do checks...
#s
sub _check_key
{
	( defined $_[1] )							or die "Key is not defined";
	( not ref $_[1] )							or die "Key is not a SCALAR";

	unless ( NULL_KEYS_ALLOWED )
	{
		return false	if ( not $_[0]->numeric ) and ( $_[1] eq '' );		#	allow key = "0"...
	}

	return false	if $_[0]->numeric and ( not Scalar::Util::looks_like_number ( $_[1] ) );
	return true;
}

sub _match_key
{
	my ( $self, $key, $kv, $ref_essence, $match )	= @_;

	if ( @$kv )
	{
		if		( $match > 0 and $kv->[0] =~ /^\Q$key\E/ )	#	starts-with match...
		{
			$$ref_essence	= $kv->[1];
		}
		elsif	( $match < 0 )											#	multi match...
		{
			$$ref_essence	= $kv->[1];
		}
		else
		{
			if ( $kv->[0] eq $key )									#	exact match...
			{
				$$ref_essence	= $kv->[1];
			}
			else
			{
				@$kv				= ();
				$$ref_essence	= '';
			}
		}
	}
}

#	CALLBACKS
#

#	If we die here with the warning 'Argument "..." isn't numeric in numeric comparison',
#	the whole system hangs during global destroy...
#	So we need to _validate_key
#
#s	Update:
#s	All methods are only called internally, so all checks removed
#s	except from count and _seq !
#s
#	sub _numeric_compare	{ $_[0] <=> $_[1] }

#	IMMUTABLE
#
no Moose;

__PACKAGE__->meta->make_immutable ( debug => 0 );

1;

__END__

=head1 NAME

Frost::Burial - Deep-six it

=head1 ABSTRACT

No documentation yet...

=head1 DESCRIPTION

Base object of
L<Frost::Cemetery|Frost::Cemetery>,
L<Frost::Illuminator|Frost::Illuminator> and
L<Frost::Vault|Frost::Vault>.

No user maintainable parts inside ;-)

=for comment CLASS VARS

=head1 CLASS METHODS

=head2 Frost::Burial->suffix()

Abstract method - to be overwritten.

=head1 PUBLIC ATTRIBUTES

=head2 data_root

=head2 classname

=head2 slotname

=head2 filename

=head2 numeric

=head2 unique

=head2 cachesize

=head1 PRIVATE ATTRIBUTES

=head2 _dbm_hash

=head2 _dbm_object

=head1 CONSTRUCTORS

=head2 Frost::Burial->new ( %params )

=head2 _build_filename

=head2 _build_numeric

Abstract method - overwrite.

=head2 _build_unique

Abstract method - overwrite.

=head2 BUILDARGS

=head1 DESTRUCTORS

=head2 NO Autosave!

Not saying $ASYLUM->close at the end of a program might cause loss of data!

=head1 PUBLIC METHODS

=head2 is_open

=head2 is_closed

=head2 open

=head2 close

=head2 save

=head2 clear

=head2 remove

=head2 entomb

=head2 exhume

=head2 forget

=head2 count

=head2 match

=head2 match_last

=head2 match_next

=head2 match_prev

=head2 find

=head2 find_last

=head2 find_next

=head2 find_prev

=head2 first

=head2 last

=head2 next

=head2 prev

=head1 PRIVATE METHODS

=head2 _seq

=head2 _check_key

=head2 _match_key

=cut

#	=head1 CALLBACKS
#
#	=head2 _numeric_compare

=pod

=for comment IMMUTABLE

=head1 GETTING HELP

I'm reading the Moose mailing list frequently, so please ask your
questions there.

The mailing list is L<moose@perl.org>. You must be subscribed to send
a message. To subscribe, send an empty message to
L<moose-subscribe@perl.org>

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception.

Please report any bugs to me or the mailing list.

=head1 AUTHOR

Ernesto L<ernesto@dienstleistung-kultur.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Dienstleistung Kultur Ltd. & Co. KG

L<http://dienstleistung-kultur.de/frost/>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

