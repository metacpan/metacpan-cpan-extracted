package Grid::Request::Test;

=head1 NAME

Grid::Request::Test - Helper funcations for unit Grid::Request tests.

=head1 SYNOPSIS

 use Grid::Request::Test;

 my $req = Grid::Request:Test->get_test_request();

 my $project = Grid::Request:Test->get_test_project();

 my $hostname = Grid::Request:Test->get_test_host();

=head1 DESCRIPTION

A module that models Grid::Request parameters.

=over 4

=item get_test_request();

B<Description:> This method is used by tests to obtain a test request
object. If the user has the GRID_REQUEST_TEST_PROJECT enviroment variable
defined, for environments in which a project settings is required, then
the returned object will have the project configured so that tests will
run.

B<Parameters:> None.

B<Returns:> A Grid::Request object.

=cut 

use Carp;
use Grid::Request;
use Test::More;

our $GR_PROJECT_NAME = "GRID_REQUEST_TEST_PROJECT";
our $GR_HOST_NAME = "GRID_REQUEST_TEST_HOST";

our $VERSION = '0.11';


sub get_test_request {
    my $req;
    my $project = get_test_project();

    if (defined $project && length $project) {
        $req = Grid::Request->new(project => $project);
    } else {
        $req = Grid::Request->new();
    }
    return $req;
}

=item get_test_project();

B<Description:> Retrieves the project to use when running the
Grid::Request unit tests. Many of the unit tests trigger actual
grid jobs, so the user/tester must be able to specify which project
string to use.

B<Parameters:> None.

B<Returns:> A scalar.

=cut 

sub get_test_project {
    if (exists $ENV{$GR_PROJECT_NAME} && defined $ENV{$GR_PROJECT_NAME} &&
            length($ENV{$GR_PROJECT_NAME})) {

        # Return the value.
        return $ENV{$GR_PROJECT_NAME};
    }
}


=item get_test_host();

B<Description:> Retrieves the host to use to help test the
hosts() method in Grid::Request.

B<Parameters:> None.

B<Returns:> A scalar.

=cut 

sub get_test_host {
    if (exists $ENV{$GR_HOST_NAME} &&
        defined $ENV{$GR_HOST_NAME} &&
        length($ENV{$GR_HOST_NAME})) {

        # Return the value.
        # TODO: Validation.
        return $ENV{$GR_HOST_NAME};
    } else {
        warn "Please define the \"$GR_HOST_NAME\" environment variable.\n";
        croak;
    }
}

sub diagnose {
    my $e;
    if ( $e = Exception::Class->caught('Grid::Request::DRMAAException') ) {
        diag($e->diagnosis());
    } elsif ( $e = Exception::Class->caught('Grid::Request::Exception') ) {
        diag($e->error());
    } else {
        $e = Exception::Class->caught();
        diag($e);
    }
}

1;

__END__

=back

=head1 ENVIRONMENT

This module checks for two (2) environment variables:

  GRID_REQUEST_TEST_PROJECT - Used to set the project to use for grid tests.

  GRID_REQUEST_TEST_HOST - Used to set the hostname to use for grid tests
                           which use the Grid::Request hosts() method.

=head1 BUGS

None known.

=head1 SEE ALSO

 Grid::Request
 Test::More
