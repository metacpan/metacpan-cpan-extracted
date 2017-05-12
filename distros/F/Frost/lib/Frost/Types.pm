package Frost::Types;

use strict;
use warnings;

use Moose::Util::TypeConstraints;

use Frost::Util;

our $VERSION	= 0.64;
our $AUTHORITY	= 'cpan:ERNESTO';

enum 'Frost::SortType',		( SORT_INT, SORT_FLOAT, SORT_DATE, SORT_TEXT, );
enum 'Frost::Status',		( STATUS_NOT_INITIALIZED, STATUS_MISSING, STATUS_LOADED, STATUS_EXISTS, );

subtype 'Frost::Date'
	=> as 'Str'
	=> where
		{
			return undef		unless $_ =~ m#^\d{4}-\d{2}-\d{2}$#;		#	1999-10-03
			return 1;
		};

subtype 'Frost::Time'
	=> as 'Str'
	=> where
		{
			return undef		unless $_ =~ m#^\d{2}:\d{2}:\d{2}$#;		#	15:23:41
			return 1;
		};

subtype 'Frost::TimeStamp'
	=> as 'Str'
	=> where
		{
			return undef		unless $_ =~ m#^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$#;		#	1999-10-03 15:23:41
			return 1;
		};

subtype 'Frost::FilePath'
	=> as 'Str'
	=> where
		{
			return undef		unless $_ =~ m#^(/[-a-zA-Z0-9_\.\@]+)+$#;		#	'/' (root) forbidden!
			return 1;
		};

subtype 'Frost::FilePathMustExist'
	=> as 'Str'
	=> where
		{
			return undef		unless $_ =~ m#^(/[-a-zA-Z0-9_\.\@]+)+$#;		#	'/' (root) forbidden!
			return undef		unless -e $_;											#	must exist
			return 1;
		};

subtype 'Frost::Real'
	=> as 'Num';

subtype 'Frost::RealPositive'
	=> as 'Num'
	=> where { $_ > 0.0 };

subtype 'Frost::Whole'
	=> as 'Int'
	=> where { $_ >= 0 };			#	0 1 2 3...

subtype 'Frost::Natural'
	=> as 'Int'
	=> where { $_ > 0 };				#	1 2 3...

subtype 'Frost::StringId'
	=> as 'Str'
#	=> where { $_ =~ m/^[A-Za-z_][A-Za-z0-9_]*$/;	};					#	starts with '_' or char, no '.'
	=> where { $_ =~ m/^(--|([A-Za-z_][A-Za-z0-9_]*))$/;	};			#	and special case '--' => "catch all", "default" etc.

subtype 'Frost::BSN'
	=> as 'Str'
	=> where { $_ =~ m/^\d+[A-Z]+\d+(-\d+)?$/;	};						#	01A05-2

#	from http://www.regular-expressions.info/email.html
#	/^[A-Za-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}$/
#
#	from CGI::FormBuilder::Field
#	/^[\w\-\+\._]+\@[a-zA-Z0-9][-a-zA-Z0-9\.]*\.[a-zA-Z]+$/
#
#	Email::Valid not considered due to speed...
#
subtype 'Frost::EmailString'
	=> as 'Str',
	=> where { $_ =~ m/^[\w\-\+\.]+\@[a-zA-Z0-9][-a-zA-Z0-9\.]*\.[a-zA-Z]{2,6}$/;	};		#	firstname.lastname@sub.domain.tld

subtype 'Frost::UniqueStringId'
	=> as 'Str'
	=> where { $_ =~ m/^[0-9A-F]+-[0-9A-F]+-[0-9A-F]+-[0-9A-F]+-[0-9A-F]+$/; };			#	1234-5678-90AB-CDEF-42AF

subtype 'Frost::UniqueId'
	=> as 'Frost::Natural | Frost::StringId | Frost::BSN | Frost::UniqueStringId | Frost::EmailString';

subtype 'Frost::DBM_Object'
	=> as 'Object'
#	=> where { $_->isa ( 'DB_File' ) };
	=> where { $_->isa ( 'BerkeleyDB::Btree' ) };

subtype 'Frost::DBM_Hash'
	=> as 'HashRef';

subtype 'Frost::DBM_Cursor'
	=> as 'Object'
	=> where { $_->isa ( 'BerkeleyDB::Cursor' ) };

#######################################

package Frost::Check;

use strict;
use warnings;

use Data::Dumper;

use Moose::Util::TypeConstraints;

Moose::Util::TypeConstraints->export_type_constraints_as_functions;

#	see Frost::Util::check_type_manuel
#	avoid cyclic dependance...
#
sub check_type_manuel ( $$;$ )
{
	no strict 'refs';

#	0.64
#	This works not for namespaced types!
#
#	unless ( $_[0] ( $_[1] ) )
#
#	so:
#
	my $func	= __PACKAGE__ . '::' . $_[0];

	unless ( &$func ( $_[1] ) )
	{
		my ( $type, $value, $silent )	= @_;

		return 0		if $silent;

		$value = 'undef'		unless defined $value;

		Carp::confess "Manual check does not pass the type constraint ($type) with '$value'";
	}

	return 1;
}

1;

__END__


=head1 NAME

Frost::Types - The backstage boys

=head1 ABSTRACT

No documentation yet...

=head1 DESCRIPTION

No user maintainable parts inside ;-)

=head1 TYPES

=head2 Frost::SortType

=head2 Frost::Status

=head2 Frost::Date

=head2 Frost::Time

=head2 Frost::TimeStamp

=head2 Frost::FilePath

=head2 Frost::FilePathMustExist

=head2 Frost::Real

=head2 Frost::RealPositive

=head2 Frost::Whole

=head2 Frost::Natural

=head2 Frost::StringId

=head2 Frost::BSN

=head2 Frost::EmailString

=head2 Frost::UniqueStringId

=head2 Frost::UniqueId

=head2 Frost::DBM_Object

=head2 Frost::DBM_Hash

=head1 PUBLIC FUNCTIONS

=head2 check_type_manuel

Internal function, called by L<Frost::Util/check_type_manuel>.

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
