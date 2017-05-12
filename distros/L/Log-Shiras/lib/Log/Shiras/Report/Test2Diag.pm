package Log::Shiras::Report::Test2Diag;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare("v0.48.0");
use strict;
use warnings;
use 5.010;
use utf8;
use Moose;
use namespace::autoclean;
use MooseX::StrictConstructor;
use Data::Dumper;
use Test2::Tools::Basic;

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub add_line{
	shift;
	my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ? 
					@{$_[0]->{message}} : $_[0]->{message};
	my ( @print_list, @initial_list, $first_line, $last_line, $sprintf_string );
	no warnings 'uninitialized';
	for my $value ( @input ){
		push @initial_list, (( ref $value ) ? Dumper( $value ) : $value );
	}
	$first_line = shift @initial_list;
	chomp $first_line;
	$first_line =~ s/\r//g;
	$first_line =~ s/\n//g;
	if( !@initial_list ){
		$sprintf_string = "| level - %-6s | name_space - %-s\n| line  - %04d   | file_name  - %-s\n\t:(\t%s ):";
	}else{
		$last_line = pop @initial_list;
		chomp $last_line;
		$last_line = length( $last_line ) ? $last_line : "''";
		$sprintf_string = "| level - %-6s | name_space - %-s\n| line  - %04d   | file_name  - %-s\n\t:( %s";
	}
	diag sprintf( $sprintf_string, 
				$_[0]->{level}, $_[0]->{name_space},
				$_[0]->{line}, $_[0]->{filename}, $first_line );
	for my $middle_line ( @initial_list ){
		diag sprintf( "\t   %s", $middle_line );
	}
	diag sprintf( "\t   %s ):", $last_line ) if $last_line;
	
	use warnings 'uninitialized';
}

#########1 Phinish    	      3#########4#########5#########6#########7#########8#########9

__PACKAGE__->meta->make_immutable;

1;
# The preceding line will help the module return a true value

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9

__END__

=head1 NAME

Log::Shiras::Report::Test2Diag - Log::Shiras Test2 diag output

=head1 SYNOPSIS

	use Test2::Bundle::Extended qw( !meta );
	use Test2::Plugin::UTF8;
	plan( ? );
	use Log::Shiras::Report::Test2Diag;
	use Log::Shiras::Switchboard;
	my( $switchboard, $test_class );
	ok( lives{	my $switchboard = Log::Shiras::Switchboard->get_operator(
				name_space_bounds =>{
					UNBLOCK =>{
						log_file => 'warn',
					},
				},
				reports =>{
					log_file =>[ Log::Shiras::Report::Test2Diag->new ], #Raise visibility to the actions being tested
				},) },						"Start the switchboard");
    
=head1 DESCRIPTION

This is a simple L<Report|Log::Shiras::Report> class that can be used to provide 
troubleshooting output to L<Test2> tests with L<Log::Shiras> content.  The goal 
is for the messages to integrate with the TAP format.

=head2 Attributes

None

=head2 Methods

=head3 new

=over

B<Definition:> This creates a new instance of the Test2Note L<report
|Log::Shiras::Switchboard/reports> class.

B<Returns:> A report class to be stored in the switchboard.

=back

=head3 add_line( $ref )

=over

B<Definition:> This only accepts a switchboard scrubbed message ref.

B<Returns:> 1 (or dies)

=back

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

L<Data::Dumper>

L<Test2::Tools::Basic>

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9