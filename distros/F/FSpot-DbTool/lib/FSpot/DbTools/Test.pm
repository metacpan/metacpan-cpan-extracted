package FSpot::DbTools::Test;
use Moose::Role;
use MooseX::StrictConstructor;

use Data::Dumper;

use 5.010000;
our $VERSION = '0.2';


=pod

=head1 NAME

FSpot::DbTools::Test

=head1 SYNOPSIS

  use FSpot::DbTool;

  my $fsdb = FSpot::DbTool->new();
  $fsdb->load_tool( 'Test' );

=head1 DESCRIPTION

A test tool - it probably doesn't do anything, but you can add test functions in here

=head1 METHODS

=head2 test()

Test something...

=cut
sub test{
    my( $self ) = @_;
    printf "This is a test designed for db_version %s\n", $self->designed_for_db_version();
#    printf "My db_version is %s\n", FSpot::DbTools::Test->designed_for_db_version();
}



1;

__END__


=head1 AUTHOR

Robin Clarke C<perl@robinclarke.net>

=cut
