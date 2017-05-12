package Log::Shiras::Report;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare("v0.48.0");
use strict;
use warnings;
use 5.010;
use utf8;
#~ use lib '../../';
#~ use Log::Shiras::Unhide qw( :InternalReporT );
###InternalReporT	warn "You uncovered internal logging statements for Log::Shiras::Report-$VERSION" if !$ENV{hide_warn};
###InternalReporT	use Log::Shiras::Switchboard;
###InternalReporT	my	$switchboard = Log::Shiras::Switchboard->instance;
use Carp qw( confess cluck );
use MooseX::Types::Moose qw( ArrayRef HashRef );
use Moose::Role;
requires 'add_line';

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9



#########1 Public Methods     3#########4#########5#########6#########7#########8#########9



#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9
	


#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

around add_line => sub{
		my( $_add_line, $self, $message_ref ) = @_;
		###InternalReporT	$switchboard->master_talk( { report => 'log_file', level => 1,
		###InternalReporT		name_space => 'Log::Shiras::Report::add_line',
		###InternalReporT		message =>[ 'Scrubbing the message ref:',  $message_ref ], } );
		
		# Scrub the input
		if( !is_HashRef( $message_ref ) ){
			confess "Expected the message to be passed as a hashref";
		}elsif( !exists $message_ref->{message} ){
			cluck "Passing an empty message to the report";
			$message_ref->{message} = [];
			###InternalReporT	$switchboard->master_talk( { report => 'log_file', level => 3,
			###InternalReporT		name_space => 'Log::Shiras::Report::CSVFile::add_line',
			###InternalReporT		message =>[ 'Message ref has no message:', $message_ref ], } );
		}elsif( !is_ArrayRef( $message_ref->{message} ) ){
			confess "The passed 'message' key value is not an array ref";
		}
		
		# Check for a manage_message add on
		if( $self->can( 'manage_message' ) ){
			$message_ref = $self->manage_message( $message_ref );
			###InternalReporT	$switchboard->master_talk( { report => 'log_file', level => 1,
			###InternalReporT		name_space => 'Log::Shiras::Report::CSVFile::add_line',
			###InternalReporT		message =>[ 'Updated the message to:', $message_ref->{message} ], } );
		}
		
		# Implement the method
		my $times = $self->$_add_line( $message_ref );
		###InternalReporT	$switchboard->master_talk( { report => 'log_file', level => 2,
		###InternalReporT		name_space => 'Log::Shiras::Report::add_line',
		###InternalReporT		message =>[ 'add_line wrap finished', $times, $message_ref ], } );
		return $times;
	};
	
sub _my_test_for_around_add_line{ 1 };
	

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;
# The preceding line will help the module return a true value

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras::Report - Report Role (Interface) for Log::Shiras

=head1 SYNOPSIS

	use Modern::Perl;
	use Log::Shiras::Switchboard;
	use Log::Shiras::Report;
	use Log::Shiras::Report::CSVFile;
	my	$operator = Log::Shiras::Switchboard->get_operator(
			name_space_bounds =>{
				UNBLOCK =>{
					to_file => 'info',# for info and more urgent messages
				},
			},
			reports =>{
				to_file =>[{
					superclasses =>[ 'Log::Shiras::Report::CSVFile' ],
					add_roles_in_sequence =>[ 
						'Log::Shiras::Report',
						'Log::Shiras::Report::MetaMessage',
					],# Effectivly an early class type check
					file => 'test.csv',
				}],
			}
		);
    
=head1 DESCRIPTION

This is a simple interface that ensures the report object has an 'add_line' method.  It also 
scrubs the input to 'add_line' method to ensure the message is a hashref with the key message.  
Finally, it calls a method 'manage_message' if it has been composed into the larger class.  
For an example see L<Log::Shiras::Report::MetaMessage>.  If you wish to build your own report 
object it just has to have an add_line method.  To use the report it is registered to the 
switchboard using L<Log::Shiras::Switchboard/reports>  For an example of a simple report see 
L<Log::Shiras::Report::Stdout>  For an example of a complex report see 
L<Log::Shiras::Report::CSVFile>  Upon registration the reports will receive their messages from 
L<Log::Shiras::Switchboard/master_talk( $args_ref )>.

=head1 SUPPORT

=over

L<Log-Shiras/issues|https://github.com/jandrew/Log-Shiras/issues>

=back

=head1 TODO

=over

B<1.> Nothing L<currently|/SUPPORT>

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

L<version>

L<Moose::Role> - requires (add_line)

L<MooseX::Types::Moose>

L<Carp> - confess cluck

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9