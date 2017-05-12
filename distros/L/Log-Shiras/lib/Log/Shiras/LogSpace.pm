package Log::Shiras::LogSpace;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare("v0.48.0");
use strict;
use warnings;
use 5.010;
use utf8;
use lib '../../';
use Moose::Role;
use MooseX::Types::Moose qw( Str );

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has log_space =>(
		isa		=> Str,
		reader	=> 'get_log_space',
		writer	=> 'set_log_space',
		predicate	=> 'has_log_space',
		default	=> sub{
			my( $self ) = @_;
			my $ref = ref $self ? ref( $self ) : $self;
			if( $self->can( 'get_class_space' ) ){# avoid duplicating class space at the end
				my $class_space = $self->get_class_space;
				if( $ref =~ /(.*)(::$class_space)/ ){
					$ref = $1;
				}
			}
			return $ref;
		}
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub get_all_space{
	my ( $self, $add_string ) = @_;
	my	$all_space = $self->get_log_space;
	if( $self->can( 'get_class_space' ) and length( $self->get_class_space ) > 0 ){
		$all_space .= '::' . $self->get_class_space;
	}
	if( $add_string and length( $add_string ) > 0 ){
		$all_space .= '::' . $add_string;
	}
	return $all_space;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;
# The preceding line will help the module return a true value

#########1 main POD docs      3#########4#########5#########6#########7#########8#########9

__END__

=head1 NAME

Log::Shiras::LogSpace - Log::Shiras Role for runtime name-spaces

=head1 SYNOPSIS

	use Modern::Perl;
	use MooseX::ShortCut::BuildInstance qw( build_class );
	use Log::Shiras::LogSpace;
	my $test_instance = build_class(
			package => 'Generic',
			roles =>[ 'Log::Shiras::LogSpace' ],
			add_methods =>{
				get_class_space => sub{ 'ExchangeStudent' },
				i_am => sub{
					my( $self )= @_;
					print "I identify as a: " . $self->get_all_space( 'individual' ) . "\n";
				}
			},
		);
	my $Generic = $test_instance->new;
	my $French = $test_instance->new( log_space => 'French' );
	my $Spanish = $test_instance->new( log_space => 'Spanish' );
	$Generic->i_am;
	$French->i_am;
	$Spanish->i_am;

	#######################################################################################
	# Synopsis Screen Output
	# 01: I identify as a: Generic::ExchangeStudent::individual
	# 02: I identify as a: French::ExchangeStudent::individual
	# 03: I identify as a: Spanish::ExchangeStudent::individual
	#######################################################################################

=head1 DESCRIPTION

This attribute is useful to manage runtime L<Log::Shiras> caller namespace.  In the case
where MyCoolPackage with Log::Shiras lines is used in more than one context then it is
possible to pass a context sensitive name to the attribute log_space on intantiation of the
instance and have the namespace bounds only activate the desired context of the package
rather than have it report everywhere it is used.  The telephone call in this case would
look something like this;

	package MyCoolPackage

	sub get_class_space{ 'MyCoolPackage' }

	sub my_cool_sub{
		my( $self, $message ) = @_;
		my $phone = Log::Shiras::Telephone->new(
						name_space => $self->get_all_space . '::my_cool_sub',
					);
		$phone->talk( level => 'debug',
			message => "Arrived at my_cool_sub with the message: $message" );
		# Do something cool here!
	}

In this case if you used my cool package instances with the log_space set to different
values then only the namespace unblocked for 'FirstInstance::MyCoolPackage::my_cool_sub'
would report.  See the documentation for L<get_all_space|/get_all_space> for details.

As a general rule it works best if the subroutine 'get_class_space' is defined in an object 
class file (not a role file).  Each subroutine space can be identified with the $add_string 
passed to get_all_space.

=head2 Attributes

Data passed to new when creating an instance of the consuming class.  For modification of
this attribute see the listed L<attribute methods|/attribute methods>.

=head3 log_space

=over

B<Definition:> This will be the base log_space element returned by L<get_all_space
|/get_all_space>

B<Default> the consuming package name

B<Range> Any string, but Log::Shiras will look for '::' separators

B<attribute methods>

=over

B<get_log_space>

=over

B<Definition:> Returns the attribute value

=back

B<set_log_space( $string )>

=over

B<Definition:> sets the attribute value

=back

B<has_log_space>

=over

B<Definition:> predicate test for the attribute

=back

=back

=back

=head2 Method

=head3 get_all_space( $add_string )

=over

B<Definition:> This method collects the stored 'log_space' attribute value and then
joins it with the results of a method call to 'get_class_space'.  The 'get_class_space'
attribute should be provided somewhere else in the class.  The two values are joined with
'::'.  It will additionally join another string argument passed as $add_string to form a 
complete log space stack. See synopsis.

B<Accepts> $add_string

B<Returns> log_space . '::' . $self->get_class_space . '::' . $add_string as each element 
is available.

=back

=head1 SUPPORT

=over

L<github Spreadsheet::XLSX::Reader::LibXML/issues
|https://github.com/jandrew/Spreadsheet-XLSX-Reader-LibXML/issues>

=back

=head1 TODO

=over

B<1.> Nothing Yet

=back

=head1 AUTHOR

=over

=item Jed Lund

=item jandrew@cpan.org

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DEPENDENCIES

=over

L<Moose::Role>

L<MooseX::Types::Moose>

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9
