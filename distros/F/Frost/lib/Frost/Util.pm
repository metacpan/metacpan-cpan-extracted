package Frost::Util;

use strict;
use warnings;

our $VERSION = '0.5';			#	see ROOT_VERSION below !!!
$VERSION = eval $VERSION;
our @ISA;
our @EXPORT;

our $UUID_OBJ;
our $UUID_CLEAR;

#	INHERITANCE
#
use Exporter;
@ISA = qw( Exporter );

#	LIBS
#
use Log::Log4perl	1.24		qw(:levels get_logger);
use BerkeleyDB		0.43		();
#	use DB_File			1.820;
use Fcntl			1.05		qw( :DEFAULT :flock );
use File::Path		2.04		();
use Time::HiRes	1.9719	qw(usleep);
use Data::UUID		1.202;
use Data::Dumper	1.125		();
use Carp				1.04		qw(confess);
use Class::MOP		1.08		();
use Moose			1.14		();

use Moose::Util qw(find_meta);

#	DIE HANDLER
#
BEGIN
{
	#	...:~# export Frost_NO_DIE_ON_WARNINGS=1

	$SIG{__DIE__}	= \&Carp::confess;

	if ( $ENV{Frost_NO_DIE_ON_WARNINGS} )	{ $SIG{__WARN__}	= \&Carp::cluck;		}
	else												{ $SIG{__WARN__}	= \&Carp::confess;	}
}

#	CONSTANTS
#
@EXPORT =
(
#	qw ( $VERSION ),
	qw ( IS_DEBUG DEBUG INFO WARN ERROR FATAL ),
	qw ( Dumper Dump ),
	qw ( true false ),
	qw ( TRUE FALSE ),
	qw ( UUID UUID_NEW_TAG UUID_BAD_TAG TIMESTAMP_ZERO ),
	qw ( NULL_KEYS_ALLOWED ),
	qw ( DEFAULT_CACHESIZE ),
	qw ( SORT_INT SORT_FLOAT SORT_DATE SORT_TEXT ),
	qw ( STATUS_NOT_INITIALIZED STATUS_MISSING STATUS_LOADED STATUS_EXISTS STATUS_SAVING ),
	qw ( ROOT_VERSION ROOT_TAG OBJECT_TAG ATTR_TAG VALUE_TAG ),
	qw ( INDEX_TAG ENTRY_TAG ),
	qw ( ID_ATTR NAME_ATTR TYPE_ATTR REF_ATTR ),
	qw ( KEY_ATTR ATTR_ATTR NUM_ATTR VALUE_ATTR ),
	qw ( VALUE_TYPE ARRAY_TYPE HASH_TYPE CLASS_TYPE ),
#	qw ( make_cache_key split_cache_key ),
	qw ( find_attribute_manuel find_type_constraint_manuel check_type_constraint_manuel ),
	qw ( make_path make_file_path ),
	qw ( check_or_create_dir filepath_from_class filename_from_class_and_id class_and_id_from_filename ),
	qw ( touch ),
	qw ( lock_fh unlock_fh ),
	qw ( check_type_manuel ),
);

BEGIN
{
	$Data::Dumper::Bless			= "bless";
	$Data::Dumper::Deepcopy		= 0;
	$Data::Dumper::Deparse		= 0;			#	1 = show source perl
	$Data::Dumper::Freezer		= "";
	$Data::Dumper::Indent		= 1;			#	default = 2			#	keep it small
	$Data::Dumper::Maxdepth		= 0;
	$Data::Dumper::Pad			= "";
	$Data::Dumper::Pair			= ' => ';
	$Data::Dumper::Purity		= 0;
	$Data::Dumper::Quotekeys	= 1;
	$Data::Dumper::Sortkeys		= 1;			#	default = 0			#	need reproduceable order for testing...
	$Data::Dumper::Terse			= 0;
	$Data::Dumper::Toaster		= "";
	$Data::Dumper::Useperl		= 0;
	$Data::Dumper::Useqq			= 1;			#	default = 0			#	nice output of Storable formatting
	$Data::Dumper::Varname		= "VAR";

	binmode STDERR, ":utf8";	#	no wide character error in Log4Perl !!!!!

	Log::Log4perl->easy_init
	(
		{
		#	level		=> ( $ENV{Frost_DEBUG} ? $DEBUG : $INFO ),
			level		=> $DEBUG,
			file		=> 'STDERR',
		#	layout	=> '[%d{dd/MMM/yyyy:HH:mm:ss}] (%P) [%p] %M-%L: %m%n',
			layout	=> '[%d{ISO8601}] (%P) [%p] %M-%L: %m%n',
		},
	);
}

#	SUBS
#
sub IS_DEBUG	()	{ $ENV{Frost_DEBUG}; }

sub DEBUG	{ $Log::Log4perl::caller_depth++;	get_logger(__PACKAGE__)->debug	( @_ );	$Log::Log4perl::caller_depth--;	}
sub INFO		{ $Log::Log4perl::caller_depth++;	get_logger(__PACKAGE__)->info		( @_ );	$Log::Log4perl::caller_depth--;	}
sub WARN		{ $Log::Log4perl::caller_depth++;	get_logger(__PACKAGE__)->warn		( @_ );	$Log::Log4perl::caller_depth--;	}
sub ERROR	{ $Log::Log4perl::caller_depth++;	get_logger(__PACKAGE__)->error	( @_ );	$Log::Log4perl::caller_depth--;	}
sub FATAL	{ $Log::Log4perl::caller_depth++;	get_logger(__PACKAGE__)->fatal	( @_ );	$Log::Log4perl::caller_depth--;	}

sub Dumper				{ "\n" . Data::Dumper->Dump ( [ @_ ] ); }
sub Dump		($;$)		{ "\n" . Data::Dumper->Dump ( $_[0], $_[1] ); }

sub true		() { 1; }
sub false	() { 0; }

sub TRUE		() { 'true'; }
sub FALSE	() { 'false'; }

sub UUID ()
{
	unless ( $UUID_CLEAR )
	{
		$UUID_OBJ	||= new Data::UUID		or die "Cannot create Data::UUID object\n";

		$UUID_OBJ->create_str();
	}
	else
	{
		$UUID_OBJ	||= 0;

		'A-A-A-A-' . ++$UUID_OBJ;
	}
}

sub UUID_NEW_TAG				()	{ 'UNEW-UNEW-UNEW-UNEW-UNEW' }
sub UUID_BAD_TAG				()	{ 'UBAD-UBAD-UBAD-UBAD-UBAD' }

#	see DB_File-1.820/t/db-btree.t
#
#	use constant NULL_KEYS_ALLOWED	=> ( $DB_File::db_ver < 2.004010 || $DB_File::db_ver >= 3.1 );
#	#use constant NULL_KEYS_ALLOWED	=> false;			#	TEST!!!
use constant NULL_KEYS_ALLOWED	=> ( $BerkeleyDB::db_version < 2.004010 || $BerkeleyDB::db_version >= 3.1 );

#	Be careful in the china store:
#
#	10 classes, each with 5 attributes and 2 indices = ( 10 * ( 5 + 2 ) DBs ) * 2 MB Cache = 140 MB !!!
#
sub DEFAULT_CACHESIZE		()	{ 2 * 1024 * 1024 }	#	2 MB

sub TIMESTAMP_ZERO			()	{ '0000-00-00 00:00:00' }

sub SORT_INT					()	{ 'int' }
sub SORT_FLOAT					()	{ 'float' }
sub SORT_DATE					()	{ 'date' }
sub SORT_TEXT					()	{ 'text' }

sub STATUS_NOT_INITIALIZED	()	{ 'not_initialized' }
sub STATUS_MISSING			()	{ 'missing' }
sub STATUS_LOADED				()	{ 'loaded' }
sub STATUS_EXISTS				()	{ 'exists' }
sub STATUS_SAVING				()	{ 'saving' }

sub ROOT_VERSION	()	{ $VERSION		}
sub ROOT_TAG		()	{ 'frost'	}
sub OBJECT_TAG		()	{ 'object'		}
sub ATTR_TAG		()	{ 'attr'			}
sub VALUE_TAG		()	{ 'value'		}

sub INDEX_TAG		()	{ 'index'		}
sub ENTRY_TAG		()	{ 'entry'		}

sub ID_ATTR			()	{ 'id'			}
sub NAME_ATTR		()	{ 'name'			}
sub TYPE_ATTR		()	{ 'type'			}
sub REF_ATTR		()	{ 'ref'			}

sub KEY_ATTR		()	{ 'key'			}
sub ATTR_ATTR		()	{ 'attr'			}
sub NUM_ATTR		()	{ 'numeric'		}
sub VALUE_ATTR		()	{ 'value'		}

sub VALUE_TYPE		()	{ '__VALUE__'	}
sub ARRAY_TYPE		()	{ '__ARRAY__'	}
sub HASH_TYPE		()	{ '__HASH__'	}
sub CLASS_TYPE		()	{ '__CLASS__'	}

#	Inlined! 4 times faster!
#
#	sub make_cache_key	( $$ )	{ $_[0] . '|' . $_[1] }
#	sub split_cache_key	( $ )		{ split /\|/, $_[0] }

sub find_attribute_manuel ( $$ )
{
	my ( $class_or_obj, $name )	= @_;

	defined $class_or_obj	or die "Param class_or_obj missing";
	defined $name				or die "Param name missing";

	my $meta	= find_meta ( $class_or_obj );

	return undef	unless defined $meta;

	my $attr	= $meta->get_attribute ( $name );												#	fast...

	$attr		= $meta->find_attribute_by_name ( $name )		unless defined $attr;	#	slow...

	return $attr;
}

sub find_type_constraint_manuel ( $$ )
{
	my ( $class_or_obj, $name )	= @_;

	my $attr	= find_attribute_manuel ( $class_or_obj, $name );

	return undef	unless defined $attr;

	return $attr->type_constraint;
}

sub check_type_constraint_manuel ( $$$ )
{
	my ( $class_or_obj, $name, $value )	= @_;

	#	6000	28.2ms	5µs
	#
#	my $class	= blessed ( $class_or_obj ) || $class_or_obj;

	#	6000	4.12ms	686ns		ref is 6,67 times faster...
	#
	my $class	= ref ( $class_or_obj ) || $class_or_obj;
	#
	#	use of blessed checked everywhere!

	my $type_constraint	= find_type_constraint_manuel ( $class_or_obj, $name );

	( defined $type_constraint )
		|| die "Could not find a type constraint for the attribute by the name of '$name' in '$class'";

	$type_constraint->check ( $value )
		|| die "$class\::Attribute ("
				. $name
				. ") does not pass the type constraint because: "
				. $type_constraint->get_message ( $value );

	return 1;
}

sub make_path ( @ )
{
	my @parts	= @_;

	my $path		= '';

	foreach my $part ( @parts )
	{
		next	unless $part;

		$path .= '/' . $part;
	}
	$path .= '/';

	$path =~ s#//#/#g		while $path =~ m#//#g;

	return $path;
}

sub make_file_path ( @ )
{
	my @parts	= @_;

	my @rest		= split '/', ( pop @parts );
	my $file		= pop @rest;

	my $path		= make_path @parts, @rest;

	$path	.= $file || '';

	return $path;
}

sub check_or_create_dir ($;$)
{
	my ( $dir, $dont_create )	= @_;

	defined $dir		or die "Param dir missing";

	$dir	= make_path $dir;
	$dir	=~ s#/$##;

	return $dir		if $dont_create;

	$@	= '';

	( -e $dir && -d _ )		or eval { File::Path::mkpath ( $dir, false, 0700 ) };		#	$paths, $verbose, $mode

	die "Cannot access directory '$dir': $@"		if $@;

	return $dir;
}

sub filepath_from_class ( $$;$ )
{
	my ( $base_dir, $class, $dont_create )	= @_;

	defined $base_dir		or die "Param base_dir missing";
	defined $class			or die "Param class missing";

	my $dir	= $base_dir . '/' . $class;

	$dir		=~ s#::#/#g;

	check_or_create_dir ( $dir, $dont_create );
}

sub filename_from_class_and_id ( $$$;$$ )
{
	my ( $base_dir, $class, $id, $dont_create, $suffix )	= @_;

	defined $id			or die "Param id missing";

	$suffix				||= '.xml';

	my $filepath	= filepath_from_class ( $base_dir, $class, $dont_create );

	my $filename	= make_file_path $filepath, $id . $suffix;

	return $filename;
}

sub class_and_id_from_filename ( $$ )
{
	my ( $base_dir, $filename )	= @_;

	defined $base_dir		or die "Param base_dir missing";
	defined $filename		or die "Param filename missing";

	$filename	=~ s#^$base_dir/##;

	my @path		= split '/', $filename;

	my $id		= pop @path;

	$id			=~ s/\..+$//;

	my $class	= join '::', @path;

	return ( $class, $id );
}

sub touch ( $ )
{
	my ( $filename )	= @_;

	my @path		= split '/', $filename;

	pop @path;

	check_or_create_dir ( make_path ( @path ) );

	sysopen my $fh, $filename, O_WRONLY | O_CREAT, 0600 		or die "Cannot create $filename : $!";
	close $fh																or die "Cannot close $filename : $!";
}

sub lock_fh ( $;$$$ )
{
	my ( $fh, $how, $wait, $sleep )	= @_;

	IS_DEBUG and DEBUG "start...";

	return false	unless defined $fh;
	return false	unless $fh->opened;

	$how	||= O_RDONLY;

	my $flag		= ( $how & O_RDWR )
						? ( LOCK_EX | LOCK_NB )
						: ( LOCK_SH | LOCK_NB );

	$wait			||= 30;		#	seconds
	$sleep		||= 0.2;		#	seconds

	my $i			= 1;
	my $max_i	= int ( $wait / $sleep );

	my $success	= false;

	my $usleep	= $sleep * 1_000_000;		#	usec

	while ( true )
	{
		$success	= flock ( $fh, $flag );

		last	if $success;

		$i++;

		return false	if $i > $max_i;

		usleep ( $usleep );
	}

	IS_DEBUG and DEBUG "done";

	return true;
}

sub unlock_fh ( $ )
{
	my ( $fh )	= @_;

	IS_DEBUG and DEBUG "start...";

	return false	unless defined $fh;
	return false	unless $fh->opened;

	my $flag		= LOCK_UN;

	my $success	= flock ( $fh, $flag );

	IS_DEBUG and DEBUG "done";

	return $success;
}

sub check_type_manuel ( $$;$ )
{
	#	see Frost::Types !
	#
	Frost::Check::check_type_manuel ( @_ );
}

1;

__END__


=head1 NAME

Frost::Util - The handyman

=head1 ABSTRACT

No documentation yet...

=head1 DESCRIPTION

=for comment CLASS VARS

=head1 CLASS METHODS

=head1 PUBLIC ATTRIBUTES

=head1 PRIVATE ATTRIBUTES

=head1 CONSTRUCTORS

=head1 DESTRUCTORS

=head2 DEMOLISH

=head1 PUBLIC FUNCTIONS

=head2 IS_DEBUG

=head2 DEBUG

=head2 INFO

=head2 WARN

=head2 ERROR

=head2 FATAL

=head2 Dumper

=head2 Dump

=head2 true

=head2 false

=head2 TRUE

=head2 FALSE

=head2 UUID

=head2 UUID_NEW_TAG

=head2 UUID_BAD_TAG

=head2 DEFAULT_CACHESIZE

=head2 TIMESTAMP_ZERO

=head2 SORT_INT

=head2 SORT_FLOAT

=head2 SORT_DATE

=head2 SORT_TEXT

=head2 STATUS_NOT_INITIALIZED

=head2 STATUS_MISSING

=head2 STATUS_LOADED

=head2 STATUS_EXISTS

=head2 STATUS_SAVING

=head2 ROOT_VERSION

=head2 ROOT_TAG

=head2 OBJECT_TAG

=head2 ATTR_TAG

=head2 VALUE_TAG

=head2 INDEX_TAG

=head2 ENTRY_TAG

=head2 ID_ATTR

=head2 NAME_ATTR

=head2 TYPE_ATTR

=head2 REF_ATTR

=head2 KEY_ATTR

=head2 ATTR_ATTR

=head2 NUM_ATTR

=head2 VALUE_ATTR

=head2 VALUE_TYPE

=head2 ARRAY_TYPE

=head2 HASH_TYPE

=head2 CLASS_TYPE

=head2 find_attribute_manuel

=head2 find_type_constraint_manuel

=head2 check_type_constraint_manuel

=head2 make_path

=head2 make_file_path

=head2 check_or_create_dir

=head2 filepath_from_class

=head2 filename_from_class_and_id

=head2 class_and_id_from_filename

=head2 touch

=head2 lock_fh

=head2 unlock_fh

=head2 check_type_manuel

=head1 PUBLIC METHODS

=head1 PRIVATE METHODS

=head1 CALLBACKS

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
